import argparse
import importlib.util
import json
import os
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

import yaml

ROOT = Path(__file__).resolve().parents[2]
SHELL = ROOT / "home/dot_config/quickshell/dofs"
SPEC = importlib.util.spec_from_file_location(
    "wallpaper_backend", SHELL / "wallpaper/backend.py"
)
backend = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(backend)


class BackendTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.env = dict(
            os.environ,
            HOME=str(self.directory),
            XDG_CONFIG_HOME=str(self.directory / "config"),
            XDG_CACHE_HOME=str(self.directory / "cache"),
            XDG_STATE_HOME=str(self.directory / "state"),
        )
        self.addCleanup(patch.stopall)
        patch.dict(os.environ, self.env).start()
        self.wallpapers = backend.Wallpapers()
        self.wallpapers.directory.mkdir(parents=True)
        self.workspace = self.image("first.jpg")
        self.backdrop = self.image("second.jpg")
        self.calls = []
        self.wallpapers.run_magick = self.magick

    def image(self, name):
        target = self.wallpapers.directory / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(b"fixture image")
        return target

    def magick(self, args):
        self.calls.append(args)
        if args[0] != "identify":
            Path(args[-1]).write_bytes(b"blurred fixture")

    def apply(self):
        return self.wallpapers.apply(
            argparse.Namespace(images=[], workspace=None, backdrop=None, blur=False)
        )

    def select(self, *images):
        return self.wallpapers.apply(
            argparse.Namespace(
                images=list(map(str, images)), workspace=None, backdrop=None, blur=False
            )
        )

    def test_independent_backdrop_survives_restore_and_workspace_change(self):
        original = self.select(self.workspace, self.backdrop)
        restored = self.apply()
        self.assertEqual(restored["backdrop"], original["backdrop"])
        changed = self.wallpapers.apply(
            argparse.Namespace(
                images=[],
                workspace=str(self.image("third.jpg")),
                backdrop=None,
                blur=False,
            )
        )
        self.assertEqual(changed["mode"], "independent")
        self.assertEqual(changed["backdrop"], str(self.backdrop))
        self.assertEqual(self.wallpapers.backdrop_link.resolve(), self.backdrop)

    def test_migration_preserves_existing_separate_links(self):
        self.wallpapers.workspace_link.symlink_to(self.workspace)
        self.wallpapers.backdrop_link.symlink_to(self.backdrop)
        restored = self.apply()
        self.assertEqual(restored["workspace"], str(self.workspace))
        self.assertEqual(restored["backdrop"], str(self.backdrop))
        self.assertEqual(restored["mode"], "independent")

    def test_blur_follows_workspace_and_reuses_cache(self):
        first = self.select(self.workspace)
        restored = self.apply()
        self.assertEqual(restored["mode"], "blur")
        self.assertEqual(first["backdrop"], restored["backdrop"])
        self.assertEqual(len([call for call in self.calls if call[0] != "identify"]), 1)
        changed = self.select(self.backdrop)
        self.assertNotEqual(first["backdrop"], changed["backdrop"])

    def test_blur_cache_does_not_collide_for_equal_basenames_or_updated_files(self):
        first = self.select(self.workspace)
        another = self.image("different/first.jpg")
        second = self.select(another)
        self.assertNotEqual(first["backdrop"], second["backdrop"])
        self.workspace.write_bytes(b"new image content")
        self.assertNotEqual(first["backdrop"], self.select(self.workspace)["backdrop"])

    def test_follow_blur_replaces_independent_mode(self):
        self.select(self.workspace, self.backdrop)
        state = self.wallpapers.apply(
            argparse.Namespace(images=[], workspace=None, backdrop=None, blur=True)
        )
        self.assertEqual(state["mode"], "blur")
        self.assertNotEqual(state["backdrop"], str(self.backdrop))

    def test_explicit_backdrop_only_preserves_workspace(self):
        original = self.select(self.workspace)
        state = self.wallpapers.apply(
            argparse.Namespace(
                images=[], workspace=None, backdrop=str(self.backdrop), blur=False
            )
        )
        self.assertEqual(state["workspace"], original["workspace"])
        self.assertEqual(state["backdrop"], str(self.backdrop))
        self.assertEqual(state["mode"], "independent")

    def test_failed_selection_keeps_state_and_both_links(self):
        original = self.select(self.workspace, self.backdrop)
        for failure in [
            self.wallpapers.directory / "missing.jpg",
            self.image("invalid.jpg"),
        ]:
            with self.subTest(failure=failure):
                self.wallpapers.run_magick = lambda args: (_ for _ in ()).throw(
                    ValueError("invalid image")
                )
                with self.assertRaises(ValueError):
                    self.select(failure)
                self.assertEqual(self.wallpapers.read_state(), original)
                self.assertEqual(
                    self.wallpapers.workspace_link.resolve(), self.workspace
                )
                self.assertEqual(self.wallpapers.backdrop_link.resolve(), self.backdrop)

    def test_restore_recovers_from_missing_links_and_missing_custom_backdrop(self):
        self.select(self.workspace, self.backdrop)
        self.wallpapers.workspace_link.unlink()
        self.wallpapers.backdrop_link.unlink()
        restored = self.apply()
        self.assertEqual(restored["backdrop"], str(self.backdrop))
        self.backdrop.unlink()
        recovered = self.apply()
        self.assertEqual(recovered["mode"], "blur")
        self.assertTrue(Path(recovered["backdrop"]).is_file())

    def test_fresh_setup_uses_default_and_handles_damaged_state(self):
        default = self.image("sea.jpg")
        self.wallpapers.state_file.parent.mkdir(parents=True)
        self.wallpapers.state_file.write_text("{broken")
        restored = self.apply()
        self.assertEqual(restored["workspace"], str(default))
        self.assertEqual(restored["mode"], "blur")

    def test_restore_ignores_invalid_persisted_path_types(self):
        default = self.image("sea.jpg")
        self.wallpapers.state_file.parent.mkdir(parents=True)
        self.wallpapers.state_file.write_text(
            json.dumps({"workspace": 42, "backdrop": {"invalid": "path"}})
        )
        restored = self.apply()
        self.assertEqual(restored["workspace"], str(default))
        self.assertEqual(restored["mode"], "blur")

    def test_failed_link_or_state_replacement_rolls_back_both_selections(self):
        original = self.select(self.workspace, self.backdrop)
        replacement = self.image("replacement.jpg")
        replace = Path.replace
        for failure in ["link", "state"]:

            def failing_replace(source, destination):
                if (
                    failure == "link"
                    and Path(destination) == self.wallpapers.backdrop_link
                ) or (
                    failure == "state"
                    and Path(destination) == self.wallpapers.state_file
                ):
                    if source.is_symlink() and source.readlink() == replacement:
                        raise OSError("Simulated failed link replacement")
                    if failure == "state":
                        raise OSError("Simulated failed state replacement")
                return replace(source, destination)

            with self.subTest(failure=failure), patch.object(
                Path, "replace", failing_replace
            ):
                with self.assertRaises(OSError):
                    self.select(replacement, replacement)
            self.assertEqual(self.wallpapers.read_state(), original)
            self.assertEqual(self.wallpapers.workspace_link.resolve(), self.workspace)
            self.assertEqual(self.wallpapers.backdrop_link.resolve(), self.backdrop)

    def test_failed_first_save_removes_uncommitted_links(self):
        replace = Path.replace

        def failing_replace(source, destination):
            if Path(destination) == self.wallpapers.state_file:
                raise OSError("Simulated failed state replacement")
            return replace(source, destination)

        with patch.object(Path, "replace", failing_replace), self.assertRaises(OSError):
            self.select(self.workspace, self.backdrop)
        self.assertFalse(self.wallpapers.workspace_link.is_symlink())
        self.assertFalse(self.wallpapers.backdrop_link.is_symlink())
        self.assertFalse(self.wallpapers.state_file.exists())

    def test_failed_save_restores_regular_files_and_relative_links(self):
        self.wallpapers.workspace_link.write_bytes(b"original regular image")
        self.wallpapers.backdrop_link.symlink_to(self.backdrop.name)
        replace = Path.replace

        def failing_replace(source, destination):
            if Path(destination) == self.wallpapers.state_file:
                raise OSError("Simulated failed state replacement")
            return replace(source, destination)

        with patch.object(Path, "replace", failing_replace), self.assertRaises(OSError):
            self.select(self.workspace, self.backdrop)
        self.assertFalse(self.wallpapers.workspace_link.is_symlink())
        self.assertEqual(
            self.wallpapers.workspace_link.read_bytes(), b"original regular image"
        )
        self.assertEqual(
            self.wallpapers.backdrop_link.readlink(), Path(self.backdrop.name)
        )

    @unittest.skipUnless(shutil.which("magick"), "requires ImageMagick")
    def test_animated_webp_produces_one_valid_backdrop_and_repairs_empty_cache(self):
        self.wallpapers.run_magick = backend.Wallpapers.run_magick
        image = self.wallpapers.directory / "animated.webp"
        subprocess.run(
            ["magick", "-size", "24x16", "xc:red", "xc:blue", "-loop", "0", str(image)],
            check=True,
            capture_output=True,
        )
        for attempt in range(2):
            state = self.select(image)
            target = Path(state["backdrop"])
            self.assertGreater(target.stat().st_size, 0)
            subprocess.run(
                ["magick", "identify", str(target)], check=True, capture_output=True
            )
            self.assertEqual(list(self.wallpapers.cache.iterdir()), [target])
            if attempt == 0:
                target.write_bytes(b"")

    def test_listing_deduplicates_links_excludes_generated_and_encodes_urls(self):
        special = self.image("snow #1 %.png")
        self.image("current-other.png")
        self.image("blurry-other.jpg")
        self.image("generated-other.jpg")
        self.wallpapers.workspace_link.symlink_to(self.workspace)
        (self.wallpapers.directory / "alias.jpg").symlink_to(self.workspace)
        listed = self.wallpapers.listing()
        self.assertEqual(len(listed), 3)
        self.assertEqual(
            {entry["path"] for entry in listed},
            {str(self.workspace), str(self.backdrop), str(special)},
        )
        self.assertIn(special.as_uri(), [entry["url"] for entry in listed])

    def test_listing_prefers_installed_images_over_source_copies(self):
        source = self.directory / "dofs/home/dot_config/backgrounds"
        source.mkdir(parents=True)
        (source / self.workspace.name).write_bytes(b"different source copy")
        (source / "extra.png").write_bytes(b"extra source image")
        listed = self.wallpapers.listing()
        self.assertEqual(len(listed), 3)
        self.assertIn(str(self.workspace), [entry["path"] for entry in listed])
        self.assertNotIn(
            str(source / self.workspace.name), [entry["path"] for entry in listed]
        )

    @unittest.skipUnless(shutil.which("magick"), "requires ImageMagick")
    def test_real_cli_preserves_theme_interface_and_handles_spaces(self):
        image = self.wallpapers.directory / "snow #1 %.png"
        subprocess.run(
            ["magick", "-size", "24x16", "xc:red", str(image)],
            check=True,
            capture_output=True,
        )

        def run(*args):
            return subprocess.run(
                [
                    "python3",
                    "-B",
                    str(SHELL / "wallpaper/backend.py"),
                    *map(str, args),
                    "--silent",
                    "--json",
                ],
                env=self.env,
                capture_output=True,
                text=True,
                timeout=20,
            )

        result = run(image, "")
        self.assertEqual(result.returncode, 0, result.stderr)
        state = json.loads(result.stdout)
        self.assertEqual(state["mode"], "blur")
        result = run("--restore")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["workspace"], str(image))
        original = self.wallpapers.state_file.read_text()
        result = run(image, self.directory / "missing.jpg")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.wallpapers.state_file.read_text(), original)


class IntegrationTests(unittest.TestCase):
    def test_wallpaper_processing_does_not_block_session_startup(self):
        autostart = (
            ROOT / "home/dot_config/niri/scripts/executable_autostart.sh"
        ).read_text()
        self.assertNotIn('/scripts/wallpaper.sh"', autostart)
        self.assertIn(
            'Component.onCompleted: apply(["--restore"])',
            (SHELL / "wallpaper/Service.qml").read_text(),
        )

    def test_niri_assigns_distinct_noninteractive_background_surfaces(self):
        rules = (ROOT / "home/dot_config/niri/rules.kdl").read_text()
        self.assertIn(
            'match namespace="^dofs-wallpaper-workspace$"\n    place-within-backdrop false',
            rules,
        )
        self.assertIn(
            'match namespace="^dofs-wallpaper-backdrop$"\n    place-within-backdrop true',
            rules,
        )
        self.assertNotIn('match namespace="wallpaper"', rules)
        surface = (SHELL / "wallpaper/Surface.qml").read_text()
        for setting in [
            "WlrLayershell.layer: WlrLayer.Background",
            "exclusionMode: ExclusionMode.Ignore",
            "WlrLayershell.keyboardFocus: WlrKeyboardFocus.None",
            "mask: Region {}",
        ]:
            self.assertIn(setting, surface)
        self.assertIn(
            "model: Quickshell.screens", (SHELL / "wallpaper/Host.qml").read_text()
        )

    def test_packages_and_existing_entry_points_use_quickshell(self):
        packages = yaml.safe_load(
            (ROOT / "ansible/roles/packages/vars/main.yml").read_text()
        )
        for package in ["swww", "swaybg"]:
            self.assertNotIn(package, packages["dnf_packages"])
        self.assertNotIn("agonie/swww", packages["copr_repos"])
        self.assertIn("ImageMagick", packages["dnf_packages"])
        shell = (SHELL / "shell.qml").read_text()
        self.assertIn('import "wallpaper" as Wallpaper', shell)
        self.assertIn('else if (id === "wallpapers") wallpaper.open();', shell)
        self.assertIn(
            '"wallpaper", "open"', (SHELL / "launcher/entries.jsonc").read_text()
        )
        setter = (
            ROOT / "home/dot_config/niri/scripts/executable_wallpaper.sh"
        ).read_text()
        self.assertIn("wallpaper/backend.py", setter)
        self.assertNotIn("swww", setter)
        self.assertNotIn("swaybg", setter)
        self.assertIn(
            "/backgrounds/current-blurry.jpg",
            (ROOT / "home/dot_config/quickshell/dofs-lock/shell.qml").read_text(),
        )


@unittest.skipUnless(
    os.environ.get("DOFS_QML_TEST") == "1", "requires a live Wayland session and qs"
)
class QmlTests(unittest.TestCase):
    def test_both_images_load_and_watch_repeated_atomic_updates(self):
        with tempfile.TemporaryDirectory(prefix="dofs-wallpaper-test-") as temporary:
            directory = Path(temporary)
            for name in ["wallpaper", "bar", "notifications", "services"]:
                (directory / name).symlink_to(SHELL / name, target_is_directory=True)
            config = directory / "config"
            backgrounds = config / "backgrounds"
            backgrounds.mkdir(parents=True)
            first = backgrounds / "snow #1 %.png"
            second = backgrounds / "blue.png"
            for image, color in [(first, "red"), (second, "blue")]:
                subprocess.run(
                    ["magick", "-size", "32x24", "xc:" + color, str(image)],
                    check=True,
                    capture_output=True,
                )
            env = dict(
                os.environ,
                HOME=temporary,
                XDG_CONFIG_HOME=str(config),
                XDG_STATE_HOME=str(directory / "state"),
                XDG_CACHE_HOME=str(directory / "cache"),
                QT_QPA_PLATFORM="wayland",
            )
            env.pop("LD_LIBRARY_PATH", None)
            env.pop("LD_PRELOAD", None)
            (directory / "shell.qml").write_text("""import QtQuick
import Quickshell
import Quickshell.Io
import "wallpaper" as Wallpaper
import "bar"
ShellRoot {
    Wallpaper.Service { id: service }
    BarPalette { id: palette }
    Wallpaper.Surface {
        id: workspace
        visible: false
        service: service
        screen: Quickshell.screens[0]
        roleName: "workspace"
        imageSource: service.state.workspaceUrl
        revision: service.state.revision
    }
    Wallpaper.Surface {
        id: backdrop
        visible: false
        service: service
        screen: Quickshell.screens[0]
        roleName: "backdrop"
        imageSource: service.state.backdropUrl
        revision: service.state.revision
    }
    Wallpaper.Panel {
        service: service
        palette: palette
        opened: false
        targetScreen: Quickshell.screens[0]
        barHeight: 24
    }
    IpcHandler {
        target: "test"
        function state(): string {
            return JSON.stringify({state: service.state, error: service.error, busy: service.busy,
                workspaceReady: workspace.ready, backdropReady: backdrop.ready, images: service.images.length,
                workspaceError: workspace.error, backdropError: backdrop.error, current: workspace.current});
        }
        function scan(): void { service.scan(); }
        function fail(): void { service.select("/missing-wallpaper-test.png", "workspace"); }
        function broken(): void { service.state = Object.assign({}, service.state, {workspaceUrl: "file:///missing-wallpaper-test.png"}); }
    }
}""")
            with tempfile.TemporaryFile() as log:
                process = subprocess.Popen(
                    ["qs", "-p", temporary, "--no-color"],
                    stdout=log,
                    stderr=subprocess.STDOUT,
                    env=env,
                )

                def ipc(*args):
                    return subprocess.run(
                        ["qs", "-p", temporary, "ipc", "call", "test", *args],
                        capture_output=True,
                        text=True,
                        env=env,
                        timeout=5,
                    ).stdout.strip()

                def wait(predicate):
                    deadline = time.monotonic() + 20
                    last = None
                    while time.monotonic() < deadline:
                        try:
                            last = json.loads(ipc("state"))
                            if predicate(last):
                                return last
                        except ValueError:
                            pass
                        if process.poll() is not None:
                            break
                        time.sleep(0.1)
                    log.seek(0)
                    self.fail(str(last) + "\n" + log.read().decode())

                try:
                    wait(
                        lambda state: state["workspaceReady"]
                        and state["backdropReady"]
                        and not state["busy"]
                    )
                    ipc("scan")
                    wait(lambda state: state["images"] >= 2)
                    ipc("fail")
                    wait(lambda state: bool(state["error"]) and not state["busy"])
                    for target, image in [
                        ("--backdrop", second),
                        ("--workspace", second),
                        ("--workspace", first),
                    ]:
                        result = subprocess.run(
                            [
                                "python3",
                                "-B",
                                str(SHELL / "wallpaper/backend.py"),
                                target,
                                str(image),
                                "--silent",
                            ],
                            capture_output=True,
                            text=True,
                            env=env,
                            timeout=20,
                        )
                        self.assertEqual(result.returncode, 0, result.stderr)
                        key = "backdrop" if target == "--backdrop" else "workspace"
                        state = wait(
                            lambda state: state["state"].get(key) == str(image)
                            and state["workspaceReady"]
                            and state["backdropReady"]
                        )
                        self.assertEqual(state["state"]["mode"], "independent")
                        self.assertEqual(state["state"]["backdrop"], str(second))
                        self.assertEqual(
                            state["error"],
                            "",
                            "successful external changes clear previous selection errors",
                        )
                    previous = state["state"]["revision"]
                    subprocess.run(
                        ["magick", "-size", "32x24", "xc:green", str(first)],
                        check=True,
                        capture_output=True,
                    )
                    subprocess.run(
                        [
                            "python3",
                            "-B",
                            str(SHELL / "wallpaper/backend.py"),
                            "--workspace",
                            str(first),
                            "--silent",
                        ],
                        check=True,
                        capture_output=True,
                        env=env,
                        timeout=20,
                    )
                    wait(
                        lambda state: state["state"]["revision"] != previous
                        and state["workspaceReady"]
                        and state["backdropReady"]
                    )
                    ipc("broken")
                    state = wait(lambda state: bool(state["workspaceError"]))
                    self.assertGreaterEqual(
                        state["current"],
                        0,
                        "keep the previous image on loading failure",
                    )
                finally:
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait(timeout=5)
                log.seek(0)
                combined = log.read().decode()
            for marker in [
                "ReferenceError",
                "TypeError",
                "Binding loop",
                "Cannot assign",
                "Unable to assign",
                "Failed to load configuration",
            ]:
                self.assertNotIn(marker, combined)


if __name__ == "__main__":
    unittest.main()
