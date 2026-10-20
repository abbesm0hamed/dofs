"""Resolve XDG desktop IDs and launch detached commands with early error checks.

GIO handles ordinary desktop files; QML explicitly wraps terminal entries.
No shell parsing, extra Python packages, or second maintained application list.
Later application crashes are not monitored.
"""

import json
import configparser
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import shutil


def data_roots():
    roots = [os.environ.get("XDG_DATA_HOME") or str(Path.home() / ".local/share")]
    roots += (os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share").split(":")
    return [Path(root) / "applications" for root in roots if root and Path(root).is_absolute()]


def desktop_file(app_id):
    if not app_id or "/" in app_id or app_id in (".", ".."):
        raise ValueError("Invalid desktop ID")
    # Quickshell IDs omit exactly one suffix. org.telegram.desktop is an ID
    # whose filename is org.telegram.desktop.desktop, not org.telegram.desktop.
    filename = app_id + ".desktop"
    for applications in data_roots():
        direct = applications / filename
        if direct.is_file():
            return direct
        for candidate in sorted(applications.rglob("*.desktop")):
            if str(candidate.relative_to(applications)).replace("/", "-") == filename:
                return candidate
    raise FileNotFoundError(f"Desktop entry not found: {app_id}")


def hidden_entries():
    """One snapshot per application-list change, never one scan per keystroke."""
    desktops = set(filter(None, os.environ.get("XDG_CURRENT_DESKTOP", "").split(":")))
    seen, hidden = set(), []
    for applications in data_roots():
        for candidate in sorted(applications.rglob("*.desktop")):
            app_id = str(candidate.relative_to(applications))[:-8].replace("/", "-")
            if app_id in seen:
                continue
            seen.add(app_id)
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                parser.read(candidate, encoding="utf-8")
                entry = parser["Desktop Entry"]
                only = set(filter(None, entry.get("OnlyShowIn", "").split(";")))
                exclude = set(filter(None, entry.get("NotShowIn", "").split(";")))
                executable = entry.get("TryExec", "")
                if (entry.get("Hidden", "false").lower() == "true"
                    or entry.get("NoDisplay", "false").lower() == "true"
                    or (only and not only.intersection(desktops))
                    or exclude.intersection(desktops)
                    or (executable and not shutil.which(executable))):
                    hidden.append(app_id)
            except (OSError, UnicodeError, configparser.Error, KeyError):
                hidden.append(app_id)
    return hidden


def launch_command(command, cwd=None):
    """Detach launched programs from Quickshell, but catch early failures.

    Avoid PIPEs: a long-lived GUI must not retain a pipe to a dead supervisor.
    The anonymous stderr file disappears once the child closes its descriptor.
    """
    if not isinstance(command, list) or not command or not all(isinstance(arg, str) for arg in command):
        raise ValueError("Expected a nonempty argument array")
    with tempfile.TemporaryFile() as errors:
        child = subprocess.Popen(command, cwd=cwd or None, start_new_session=True,
                                 stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=errors)
        try:
            code = child.wait(timeout=0.6)
        except subprocess.TimeoutExpired:
            return 0
        if code:
            errors.seek(0)
            print(errors.read(4096).decode(errors="replace"), file=sys.stderr)
        return code if code >= 0 else 128 - code


if __name__ == "__main__":
    try:
        if sys.argv[1] == "app":
            # GIO exits before the app does. Do not let the app inherit QML's
            # short-lived stdout/stderr pipes: later writes can cause SIGPIPE
            # (notably Foot's startup diagnostics).
            sys.exit(launch_command(["gio", "launch", str(desktop_file(sys.argv[2]))]))
        elif sys.argv[1] == "command":
            sys.exit(launch_command(json.loads(sys.argv[2]), sys.argv[3] if len(sys.argv) > 3 else None))
        elif sys.argv[1] == "hidden":
            print(json.dumps(hidden_entries()))
        else:
            raise ValueError("Expected app, command or hidden mode")
    except (OSError, ValueError, IndexError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
