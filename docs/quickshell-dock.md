# Quickshell dock

Quickshell 0.3.2 and later ship `Quickshell.Wayland.ToplevelManager`, which
exposes every mapped window through niri's `wlr-foreign-toplevel-management`
implementation. That made a complete dock possible without the discontinued
crystal-dock daemon: the same file hosts the pinned launchers and the grouped
task manager.

Niri 26.04 or later is required for the dock background blur rule. The dock
uses a compact surface so blur stays behind the container.

## Deployment

1. When upgrading, apply the new shell directory and the toggle script:

   ```sh
   chezmoi apply --recursive --source "$PWD/home" \
     "$HOME/.config/quickshell/dofs/dock" \
     "$HOME/.config/niri/scripts/toggle-dock.sh" \
     "$HOME/.config/niri/rules.kdl"
   rm -rf "$HOME/.crystal-dock-2"  # chezmoi no longer manages this
   ```

2. Uninstall the old package: `make install-packages` runs
   `ansible/roles/packages`, where `crystal-dock` moved to
   `dnf_absent_packages`.
3. Restart the shell (`qs -c dofs kill; bash ~/.config/niri/scripts/quickshell-launcher.sh --start`).
   The dock starts with the instance; `Mod+Shift+D` still toggles visibility.

## Behavior

- Pinned launchers come from `config.json`, in the same order crystal-dock
  used. `separator` entries separate groups. Pins with no matching desktop
  file use a generic icon; launching requires the desktop file to be installed.
- Open windows group under their application. Modal dialogs attach to their
  main window instead of gaining their own tile.
- Indicators: no dot = not running; narrow dot = running; accent-colored dot =
  the application's window is active on any output; dimmed icon = all its
  windows are minimized.
- Interactions:
  - Left click: launch, or focus the first unminimized window (on this output
    before the others). Clicking the active application minimizes it.
  - Right click: cycle through the application's windows.
  - Middle click: close the active window (or the first window).
- Launching reuses `launcher/launch.py app <id>` so desktop ids, terminal
  wrappers and launch history behave exactly like the launcher.

## Configuration

Edit `home/dot_config/quickshell/dofs/dock/config.json`, then apply it with
chezmoi.

- `launchers`: desktop entry ids with `"separator"` keys; grouping matches
  window appIds against these ids heuristically (exact, heuristic and
  last-dotted-segment lookups).
- `showRunning`: append tiles for running applications that have no pin.
- `iconSize`, `padding`, `spacing`: tile sizing in logical pixels.
- `margin`: gap between the pill and the screen bottom.
- `outputs`: connector-name allowlist, empty for every screen.
