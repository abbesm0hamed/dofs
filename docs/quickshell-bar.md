# Quickshell status bar

The `dofs` Quickshell instance hosts the launcher, menus and a top bar on every
connected output.

## Deployment

Run the following from the repository root. Development tests use isolated
configurations and do not deploy to `~/.config`.

1. Check dependencies. Quickshell 0.3.2 was used for testing. `quickshell` and
   `upower` are declared in `ansible/roles/packages/vars/main.yml`; apply the
   package role with `make install-packages` if needed. The existing Python,
   coreutils, PipeWire, BlueZ, power-profiles-daemon, brightnessctl, nmcli, Cava,
   libnotify and Nerd Font packages are also used. Native idle support requires
   Quickshell 0.3.x; the sleep/lock bridge uses Fedora's `python3-dbus` and
   `python3-gobject` packages.
2. Review `make dotdiff`. Apply only the relevant shell/session files, not the
   entire home tree with `--force`:

   ```sh
   chezmoi apply --recursive --source "$PWD/home" \
     "$HOME/.config/quickshell/dofs" \
     "$HOME/.config/quickshell/dofs-lock" \
     "$HOME/.config/niri/binds.kdl" \
     "$HOME/.config/niri/scripts/autostart.sh" \
     "$HOME/.config/niri/scripts/quickshell-launcher.sh" \
     "$HOME/.config/niri/scripts/toggle-bar.sh" \
     "$HOME/.config/niri/scripts/set-theme.sh" \
     "$HOME/.config/niri/scripts/system-controls.sh" \
     "$HOME/.config/niri/scripts/screencast.sh" \
     "$HOME/.config/themes" \
     "$HOME/.config/matugen/config.toml" \
     "$HOME/.config/matugen/templates/quickshell.json"
   ```

3. Restart the shell:

   ```sh
   qs -c dofs kill || true
   bash "$HOME/.config/niri/scripts/quickshell-launcher.sh" --start
   ```

    Launcher, bar, notification and idle IPC readiness must succeed. This same idempotent wrapper
   runs at login. Restart the instance after a QML/IPC update; do not rely on
   hot reload to replace a live IPC API. `make bar-reload` also restarts it.

## Configuration and shortcuts

Edit `home/dot_config/quickshell/dofs/bar/config.json`, then apply that file
with chezmoi. For a local trial, edit a **copy** and run `qs -p /path/to/copy`.
Never run the source and deployed instances simultaneously during normal use.

- `outputs: []`: every screen; otherwise an explicit connector-name allowlist.
- `height`, `font`, `fontSize`: logical pixels and font family.
- `iconSize`: shared icon size for modules and tray (13 px by default); falls
  back to `fontSize` when omitted. Font icons are centered by their visible
  glyph bounds and scaled to the capital-letter height at this size using
  the configured font. Hover changes foreground colors only.
- `showTitle`: show the active window title in the remaining middle space.
- `modules`: ordered right-hand modules; remove an entry to disable it.

Changes reload live. Invalid options retain the last valid configuration and
show an error in the left button's tooltip. A narrow screen clips the module
row rather than overlapping workspaces; drag the row horizontally to see more.
Remove optional modules or reduce font size if you want everything visible.

| Shortcut | Action |
| --- | --- |
| `Mod+Alt+B` | Hide/show bars without stopping the launcher |
| `Mod+Alt+Shift+B` | Open bar options in Ghostty/Neovim |
| `Mod+Space` | Open the launcher |

IPC: `qs -c dofs ipc call bar ping`, `show`, `hide`, `toggle`, `refresh`,
or `status`. `status` includes Niri connection state, workspaces, system stats,
current options and configuration errors. `refresh` refreshes update/history
indicators; `dofs update` calls it after updating.

## Modules and interactions

- Left button: keybinding menu; right click opens the launcher. Workspaces are
  local to each output, sorted by index, with active/urgent styling. Clicking
  sends a stable workspace **ID**, not a potentially ambiguous monitor index.
- Visualizer: shared five-bar Cava stream at 15 fps;
  click for mixer, right click for Cava terminal. Remove `visualizer` to disable.
- Media: native MPRIS; click play/pause, right next, middle previous, scroll
  player volume. Uses a playing player first and checks supported operations.
- Fingerprint enrollment warning and updates: shell-owned status scripts; click
  to enroll or run `dofs update` in Ghostty.
- Tray: native StatusNotifier icons, activation, right-click menus, middle
  clicks and scroll; ignores nm-applet/blueman-applet.
- Monitoring: Docker containers, home-filesystem usage, memory and CPU. Click
  the left chevron to slide the metrics out to its left, pushing the preceding
  modules aside; click the right chevron to collapse them again. Starts collapsed
  on each output. Click Docker for lazydocker; other metrics open btop.
- Brightness: scroll ±5%, with a 5% lower bound.
- Audio: native PipeWire, tracks default-device changes; click mixer, right
  mute output, middle mute microphone, scroll output volume (capped at 100%).
- Connectivity: native Bluetooth; click manager, right click adapter power.
  Network uses one shared, bounded nmcli snapshot every 10 seconds; click opens
  the connection editor. Device/connection details are in its tooltip.
- Battery: native UPower, only shown for a present laptop battery; warning and
  charging colors, time/power tooltip. Click opens system controls.
- Power profile: native daemon integration; click cycles supported profiles.
- Notifications: native unread count; click to toggle the notification center,
  right-click to toggle do not disturb. See [notifications](quickshell-notifications.md)
  for persistent history, privacy rules and migration from the previous daemon.
- Idle: click to toggle keep-awake using native Wayland inhibition. The icon
  changes immediately and a notification confirms automatic idle locking is
  enabled/disabled. All outputs and the system-controls menu share this state.
- Power: the built-in launcher menu for lock, logout, suspend, reboot and shutdown;
  also available with `Alt+L`. No separate logout-menu application is needed.
  Clock: minute-resolution local time and full-date tooltip.
  Prayer: location-aware calculation with cached results, five-minute alerts
  and external API requests.

Configure modules in `bar/config.json`. Scripts and menu providers live under
`quickshell/dofs/scripts/`.

## Architecture and validation

`BarHost.qml` owns settings, palette and **one** `BarService`. `Variants` owns
one `PanelWindow` per eligible screen, including hotplug/removal. Panels use
the top layer, reserve only their height and do not request keyboard focus.
Theme colors watch `quickshell/dofs/bar/theme.json`. Each built-in theme has a
dedicated `quickshell-theme.json`, copied by `set-theme.sh`; Matugen also writes
the shell's JSON palette. Invalid palettes retain the last valid colors.
Theme changes update the bar without restarting the shell.

Niri supplies its initial snapshot and subsequent updates through one
`niri msg --json event-stream`. A pure reducer tolerates transient event
ordering and ignores unknown events. Disconnect clears stale state, marks the
bar offline and reconnects with 0.5–30 second backoff; a healthy connection
resets backoff. Workspace actions use a separate bounded Unix socket. The
launcher's bounded focused-output query remains unchanged.

Audio, media, battery, profiles, Bluetooth and tray use native APIs. One
Python stdlib helper samples `/proc`, filesystem and backlight state every
three seconds. Status commands are shared across outputs, skip overlapping
runs and have process-group timeouts; failed commands clear stale indicators.
Removing modules stops their optional command sources. A shell-wide native
Quickshell notification server handles popups and persistent history independently
of bar visibility and the notifications module.

Idle handling uses Quickshell's `IdleMonitor`: monitors turn off after 10 minutes
and the native Quickshell locker starts after 15 minutes, matching the session's
previous defaults.
Activity restores the monitors. The bar's `IdleInhibitor` also advertises
keep-awake to other Wayland clients; the shell disables its own timers directly,
so inhibition remains effective even with the bar hidden. Other applications'
Wayland inhibitors are respected. Removing the idle **button** does not disable
automatic locking. Keep-awake resets to off when the shell restarts.

`session-lock.py` only handles logind `Lock` and `PrepareForSleep` signals. It
keeps a sleep-delay inhibitor until Niri confirms `LockedHint`, then releases it;
it reacquires the inhibitor on resume. Manual/lid-close sleep still locks even
when keep-awake is on. Logind's maximum delay still applies if the locker fails.
This bridge is independent of the idle timers and never polls for processes.

When migrating an existing session, stop the previously configured external idle
daemon (or log out after applying) to avoid duplicate idle actions. Its package
is no longer installed by Ansible; existing installations are not automatically
uninstalled. The retired idle launch/toggle scripts have been removed from the
source tree. Screen locking is now handled by the separate `dofs-lock` Quickshell
instance; see [lockscreen setup and recovery](quickshell-lockscreen.md) before
deploying the new lock commands. Install its PAM services first.

Idle IPC: `qs -c dofs ipc call idle toggle`, `inhibited`, or `status`. The system
controls menu uses this same API; toggling never starts or stops a daemon.

The update cache lives at
`${XDG_CACHE_HOME:-~/.cache}/quickshell/dofs/updates`.

```sh
node scripts/tests/niri-state.test.cjs
python3 -B -m unittest discover -s scripts/tests -p 'test_quickshell_bar.py' -v
python3 -B scripts/tests/test_session_lock.py -v
# Optional live Wayland tests: copied config, hidden panels, scripts disabled.
DOFS_QML_TEST=1 python3 -B -m unittest discover -s scripts/tests -p 'test_quickshell_bar.py' -v
```

Tested: package configuration, stats, stable-ID action protocol, wrapper startup and
IPC error handling, command JSON/Pango decoding and hard timeout of a process
that ignores SIGTERM, real QML loading on Quickshell 0.3.2, launcher/bar readiness,
hide/toggle, initial Niri state, event-stream reconnect, valid/invalid settings
and palette reload, built-in theme outputs and dependency boundaries. Native
idle tests cover immediate cross-output icon updates and notifications, hidden
panel inhibition, mocked monitor/lock actions, and a private-logind test of
sleep-delay FD lifetime, lock confirmation, resume and parent exit. No test
locks or suspends the real desktop.
The bar was visually checked on the
1920×1200 eDP-1 output at 1× scale. Tests do not click hardware controls or run
the update/prayer scripts. Still manual: fractional scaling, tray app interactions, physical
monitor hotplug, suspend/resume and a complete fresh login.

## References

- Native [idle monitoring](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/IdleMonitor/)
  and [idle inhibition](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/IdleInhibitor/).

- [Quickshell panels](https://quickshell.org/docs/v0.2.1/types/Quickshell/PanelWindow/),
  [popup anchors](https://quickshell.org/docs/v0.2.1/types/Quickshell/PopupAnchor/),
  [process lifecycle](https://quickshell.org/docs/v0.2.1/types/Quickshell.Io/Process/),
  [file watching](https://quickshell.org/docs/v0.2.1/types/Quickshell.Io/FileView/).
- Native service documentation for [PipeWire tracking](https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.Pipewire/PwObjectTracker/),
  [UPower](https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.UPower/UPower/),
  [power profiles](https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.UPower/PowerProfiles/),
  [Bluetooth](https://quickshell.org/docs/v0.2.1/types/Quickshell.Bluetooth/Bluetooth/),
  [MPRIS](https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.Mpris/MprisPlayer/),
  [tray items](https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.SystemTray/SystemTrayItem/).
- [Niri IPC protocol and event definitions](https://github.com/niri-wm/niri/blob/main/niri-ipc/src/lib.rs):
  event-stream initial state, non-atomic ordering and workspace-ID actions.
- [Omarchy's Quattro shell](https://github.com/omacom/omarchy/blob/quattro/shell/shell.qml)
  and [shell design/custom modules](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md).
