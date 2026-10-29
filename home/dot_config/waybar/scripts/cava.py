"""Run the shell visualizer."""
import os
from pathlib import Path
import runpy

config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
runpy.run_path(str(config / "quickshell/dofs/scripts/cava.py"), run_name="__main__")
