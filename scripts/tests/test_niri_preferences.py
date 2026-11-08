"""Exercise the real chezmoi templates and toggles without changing the desktop."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi is required")
class NiriPreferencesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.home = root / "home"
        self.source = root / "source"
        self.config = self.home / "custom-config"
        self.state = self.home / "custom-state"
        self.niri = self.config / "niri"
        self.niri.mkdir(parents=True)
        source_niri = self.source / "custom-config/niri"
        source_niri.mkdir(parents=True)
        for name in ("layout.kdl.tmpl", "rules.kdl.tmpl"):
            shutil.copy(REPO / "home/dot_config/niri" / name, source_niri / name)
        mock_bin = root / "bin"
        mock_bin.mkdir()
        for name in ("niri", "notify-send"):
            mock = mock_bin / name
            mock.write_text("#!/bin/sh\nexit 0\n")
            mock.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_CONFIG_HOME=str(self.config), XDG_STATE_HOME=str(self.state),
                        XDG_CACHE_HOME=str(root / "cache"),
                        PATH=f"{mock_bin}:{os.environ['PATH']}")
        self.chezmoi_config = root / "chezmoi.toml"
        self.chezmoi_config.write_text("")

    def apply(self):
        subprocess.run(["chezmoi", "apply", "--source", str(self.source),
                        "--destination", str(self.home), "--config",
                        str(self.chezmoi_config), "--force"],
                       env=self.env, check=True, capture_output=True, text=True)

    def toggle(self, name):
        subprocess.run(["bash", str(REPO / "home/dot_config/niri/scripts" /
                                   f"executable_toggle-{name}.sh")],
                       env=self.env, check=True, capture_output=True, text=True)

    def assert_preferences(self, gaps, transparent):
        self.assertIn(f"    gaps {gaps}\n", (self.niri / "layout.kdl").read_text())
        rules = (self.niri / "rules.kdl").read_text()
        self.assertEqual(rules.count("// DOFS_TRANSPARENCY_OVERRIDE_BEGIN"),
                         int(transparent))
        self.assertEqual("    opacity 0.96\n" in rules, transparent)
        self.assertEqual("    opacity 0.93\n" in rules, transparent)
        self.assertIn("    opacity 1.0\n", rules)

    def test_toggles_survive_repeated_applies_in_both_directions(self):
        self.apply()
        self.assert_preferences(0, False)
        for gaps, transparent in ((8, True), (0, False)):
            self.toggle("gaps")
            self.toggle("transparency")
            self.assert_preferences(gaps, transparent)
            before = (self.niri / "rules.kdl").read_text()
            for name in ("layout.kdl", "rules.kdl"):
                with (self.niri / name).open("a") as target:
                    target.write("// obsolete local configuration\n")
            self.apply()
            self.apply()
            self.assert_preferences(gaps, transparent)
            self.assertEqual(before, (self.niri / "rules.kdl").read_text())
            self.assertNotIn("obsolete", (self.niri / "layout.kdl").read_text())

    def test_existing_choices_migrate_without_state_files(self):
        self.apply()
        self.toggle("gaps")
        self.toggle("transparency")
        shutil.rmtree(self.state)
        self.apply()
        self.assert_preferences(8, True)

    def test_default_xdg_paths(self):
        (self.source / "custom-config").rename(self.source / "dot_config")
        self.config = self.home / ".config"
        self.state = self.home / ".local/state"
        self.niri = self.config / "niri"
        del self.env["XDG_CONFIG_HOME"]
        del self.env["XDG_STATE_HOME"]
        self.apply()
        self.toggle("gaps")
        self.toggle("transparency")
        self.apply()
        self.assert_preferences(8, True)

    def test_saved_choices_restore_missing_configs(self):
        (self.state / "niri").mkdir(parents=True)
        (self.state / "niri/gaps-state").write_text("8\n")
        (self.state / "niri/transparency-state").write_text("on\n")
        self.apply()
        self.assert_preferences(8, True)

    def test_invalid_state_cannot_inject_configuration(self):
        (self.state / "niri").mkdir(parents=True)
        (self.state / "niri/gaps-state").write_text("8; invalid-node\n")
        (self.state / "niri/transparency-state").write_text("invalid\n")
        self.apply()
        self.assert_preferences(0, False)


if __name__ == "__main__":
    unittest.main()
