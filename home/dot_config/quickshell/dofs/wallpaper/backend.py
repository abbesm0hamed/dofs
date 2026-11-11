import argparse
import fcntl
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

EXTENSIONS = {".jpg", ".jpeg", ".jpe", ".png", ".webp"}


class Wallpapers:
    def __init__(self):
        home = Path.home()
        config = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
        self.directory = config / "backgrounds"
        self.cache = (
            Path(os.environ.get("XDG_CACHE_HOME", home / ".cache")) / "wallpaper"
        )
        self.state_file = (
            Path(os.environ.get("XDG_STATE_HOME", home / ".local/state"))
            / "dofs/wallpaper.json"
        )
        self.workspace_link = self.directory / "current.jpg"
        self.backdrop_link = self.directory / "current-blurry.jpg"

    def read_state(self):
        try:
            state = json.loads(self.state_file.read_text())
            return state if isinstance(state, dict) else {}
        except (OSError, ValueError):
            return {}

    @staticmethod
    def existing(path):
        if not isinstance(path, (str, os.PathLike)) or not path:
            return None
        candidate = Path(path).expanduser()
        return candidate.resolve() if candidate.is_file() else None

    def selections(self):
        state = self.read_state()
        workspace = self.existing(self.workspace_link) or self.existing(
            state.get("workspace")
        )
        backdrop = self.existing(self.backdrop_link) or self.existing(
            state.get("backdrop")
        )
        mode = state.get("mode")
        if mode not in ("blur", "independent"):
            mode = (
                "blur"
                if not backdrop or backdrop.is_relative_to(self.cache.resolve())
                else "independent"
            )
        return workspace, backdrop, mode

    def listing(self):
        found = {}
        names = set()
        for directory in (
            self.directory,
            Path.home() / "dofs/home/dot_config/backgrounds",
        ):
            if not directory.is_dir():
                continue
            for path in sorted(directory.iterdir()):
                if (
                    path.suffix.lower() not in EXTENSIONS
                    or not path.is_file()
                    or path.name.lower() in names
                    or path.name.lower().startswith(
                        ("current", "blurry-", "generated-")
                    )
                ):
                    continue
                names.add(path.name.lower())
                resolved = path.resolve()
                found.setdefault(
                    str(resolved),
                    {
                        "name": path.stem,
                        "path": str(resolved),
                        "url": resolved.as_uri(),
                    },
                )
        return sorted(
            found.values(), key=lambda item: (item["name"].casefold(), item["path"])
        )

    @staticmethod
    def run_magick(args):
        try:
            subprocess.run(
                ["magick", *map(str, args)], check=True, capture_output=True, timeout=60
            )
        except FileNotFoundError as error:
            raise ValueError(
                "ImageMagick (magick) is required for wallpapers."
            ) from error
        except subprocess.TimeoutExpired as error:
            raise ValueError(
                "Wallpaper processing timed out; previous selections are unchanged."
            ) from error
        except subprocess.CalledProcessError as error:
            raise ValueError(
                "ImageMagick could not read or process the selected image."
            ) from error

    def validate(self, path):
        image = self.existing(path)
        if not image:
            raise ValueError("Wallpaper not found: " + str(path))
        self.run_magick(["identify", "-ping", image])
        return image

    def blurred(self, workspace):
        info = workspace.stat()
        identity = f"{workspace}\0{info.st_mtime_ns}\0{info.st_size}\0blur-v1"
        target = self.cache / (
            hashlib.sha256(identity.encode()).hexdigest() + "-blurred.jpg"
        )
        if target.is_file() and target.stat().st_size:
            return target
        self.cache.mkdir(parents=True, exist_ok=True)
        descriptor, name = tempfile.mkstemp(
            suffix=".jpg", prefix=".blur-", dir=self.cache
        )
        os.close(descriptor)
        temporary = Path(name)
        try:
            self.run_magick(
                [
                    str(workspace) + "[0]",
                    "-resize",
                    "50%",
                    "-blur",
                    "0x32",
                    "-resize",
                    "200%",
                    "-quality",
                    "88",
                    temporary,
                ]
            )
            if not temporary.stat().st_size:
                raise ValueError("ImageMagick did not produce a backdrop image.")
            temporary.replace(target)
        finally:
            temporary.unlink(missing_ok=True)
        return target

    def save(self, workspace, backdrop, mode):
        self.directory.mkdir(parents=True, exist_ok=True)
        state = {
            "version": 1,
            "workspace": str(workspace),
            "backdrop": str(backdrop),
            "workspaceUrl": workspace.as_uri(),
            "backdropUrl": backdrop.as_uri(),
            "mode": mode,
            "revision": str(time.time_ns()),
        }
        descriptor, name = tempfile.mkstemp(
            prefix=".wallpaper-", dir=self.state_file.parent
        )
        temporary = Path(name)
        try:
            with os.fdopen(descriptor, "w") as output:
                json.dump(state, output)
                output.write("\n")
                output.flush()
                os.fsync(output.fileno())
            with tempfile.TemporaryDirectory(
                prefix=".wallpaper-", dir=self.directory
            ) as staging:
                replacements = []
                for index, (target, destination) in enumerate(
                    ((workspace, self.workspace_link), (backdrop, self.backdrop_link))
                ):
                    backup = Path(staging) / f"previous-{index}"
                    try:
                        os.link(destination, backup, follow_symlinks=False)
                    except FileNotFoundError:
                        backup = None
                    candidate = Path(staging) / f"next-{index}"
                    candidate.symlink_to(target)
                    replacements.append((candidate, destination, backup))
                changed = []
                try:
                    for candidate, destination, backup in replacements:
                        candidate.replace(destination)
                        changed.append((destination, backup))
                    temporary.replace(self.state_file)
                except OSError:
                    for destination, backup in reversed(changed):
                        if backup is None:
                            destination.unlink(missing_ok=True)
                        else:
                            backup.replace(destination)
                    raise
        finally:
            temporary.unlink(missing_ok=True)
        return state

    def apply(self, args):
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        with self.state_file.with_suffix(".lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            workspace, backdrop, mode = self.selections()
            if args.images:
                workspace = self.validate(args.images[0])
                backdrop = (
                    self.validate(args.images[1])
                    if len(args.images) == 2 and args.images[1]
                    else None
                )
                mode = "independent" if backdrop else "blur"
            elif args.workspace:
                workspace = self.validate(args.workspace)
            elif args.backdrop:
                backdrop = self.validate(args.backdrop)
                mode = "independent"
            elif args.blur:
                mode = "blur"
            if not workspace:
                workspace = self.existing(self.directory / "sea.jpg")
                if not workspace:
                    images = self.listing()
                    workspace = Path(images[0]["path"]) if images else None
            if not workspace:
                raise ValueError(
                    "No workspace wallpaper available in " + str(self.directory)
                )
            if mode == "blur" or not backdrop:
                backdrop = self.blurred(workspace)
                mode = "blur"
            return self.save(workspace, backdrop, mode)


def main():
    parser = argparse.ArgumentParser(
        description="Select Quickshell workspace and Niri backdrop wallpapers."
    )
    parser.add_argument("images", nargs="*", metavar="IMAGE")
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument("--restore", action="store_true")
    actions.add_argument("--list", action="store_true")
    actions.add_argument("--workspace", metavar="IMAGE")
    actions.add_argument("--backdrop", metavar="IMAGE")
    actions.add_argument("--blur", action="store_true")
    parser.add_argument("--silent", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    if len(args.images) > 2 or (
        args.images
        and any((args.restore, args.list, args.workspace, args.backdrop, args.blur))
    ):
        parser.error("Use IMAGE [BACKDROP] or one selection option, not both.")
    if not args.images and not any(
        (args.restore, args.list, args.workspace, args.backdrop, args.blur)
    ):
        parser.error(
            "Choose IMAGE [BACKDROP], --workspace, --backdrop, --blur, --restore, or --list."
        )
    try:
        wallpapers = Wallpapers()
        result = wallpapers.listing() if args.list else wallpapers.apply(args)
        if args.json or args.list:
            print(json.dumps(result))
        if not args.silent and not args.list:
            try:
                subprocess.run(
                    [
                        "notify-send",
                        "-a",
                        "Wallpaper",
                        "-i",
                        result["workspace"],
                        "Wallpaper applied",
                        Path(result["workspace"]).name,
                    ],
                    timeout=3,
                    check=False,
                )
            except (OSError, subprocess.TimeoutExpired):
                pass
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
