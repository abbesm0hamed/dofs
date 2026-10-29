# Quickshell for Niri

The `dofs` shell provides an application launcher, searchable action menus and
a multi-monitor status bar. See [bar configuration](quickshell-bar.md) for panel
settings, modules, deployment and validation.

## Source layout

```text
home/dot_config/quickshell/dofs/
├── shell.qml                 # Entry point and IPC handlers
├── bar/                      # Per-screen panels, options and palette
├── launcher/                 # Search UI, actions and application dispatch
├── scripts/                  # Status commands and menu providers
├── services/                 # Shared compositor and system state
└── theme/                    # Launcher colors and typography
```

Edit source files under `home/` and use chezmoi to apply reviewed changes.
Package declarations live in `ansible/roles/packages/vars/main.yml`.

## Launcher

`Mod+Space` toggles the launcher. The shortcut wrapper starts the named shell
instance if necessary, serializes concurrent invocations and checks readiness
with bounded waits. Session autostart uses the same wrapper with `--start`.

### Interactions

- XDG application discovery through `DesktopEntries`, including Flatpak exports
  present in `XDG_DATA_DIRS`. A debounced visibility snapshot honors user
  overrides, `Hidden`, `NoDisplay`, `OnlyShowIn`, `NotShowIn` and `TryExec`.
- Fuzzy, multi-word search across names, descriptions, IDs and keywords.
- All / Apps / Actions filters with Ctrl+1/2/3. Arrow keys or Ctrl+N/P select;
  Enter launches.
- Tab or Ctrl+K opens the selected application's desktop shortcuts. Escape or
  Backspace on an empty shortcut search returns to the main list.
- `= (12 + 3) * 4` calculates; Enter copies the result. Basic arithmetic only;
  `%` means remainder. Expressions do not execute arbitrary code.
- `? search terms` opens a Google search in the default browser.
- Escape or clicking outside closes the launcher.
- Opening targets Niri's focused output. A failed query or 1.5-second timeout
  falls back to the first available screen. Removing the target screen closes
  the launcher.

### Recent applications

An empty search promotes up to five recently launched applications without
duplicating them. Typed searches keep their normal ranking; the Actions filter
does not promote recent apps. Clear history is available beside the filters
and as a searchable action.

Only successful application dispatches through this launcher are recorded,
including terminal apps and desktop shortcuts. Quick actions, calculations,
searches and open windows are not tracked. The five IDs persist in
`${XDG_STATE_HOME:-~/.local/state}/quickshell/dofs/launcher-history.json` with
private permissions and atomic writes. No queries, timestamps or frequency
counts are stored. A failed history write does not prevent an app from opening.

### Actions and menus

`launcher/entries.jsonc` defines searchable actions and menu providers. Comments
and trailing commas are accepted. Changes reload live; invalid edits display an
error and retain the last valid list.

Commands are argument arrays, not shell strings. Only `~` and `~/` expand.
Menu providers print one JSON item per line and live under `scripts/`.

### Application dispatch

GIO handles ordinary desktop-file semantics, including field codes, working
directories and DBus activation. Terminal entries use `ghostty -e` with parsed
arguments. Desktop shortcuts use parsed arguments with unfilled standalone
field codes removed. Application IDs omit exactly one `.desktop` suffix.

Applications detach from the shell and survive its reload or exit. Desktop
dispatch errors and command failures within the first 600 ms reopen the
launcher with an error. Later application crashes are not monitored.

Dependencies include Quickshell, Python 3, GIO, Ghostty, `xdg-open` and `wl-copy`.
Optional action tools report a visible error when unavailable.

## IPC and development

```sh
qs -c dofs ipc call launcher ping
qs -c dofs ipc call launcher toggle
qs -c dofs ipc call launcher openEntry themes
qs -c dofs ipc call launcher close
```

The launcher target also provides `open`. IPC errors can be returned as text
even when the CLI exits zero; the wrapper checks both. Readiness probes can
retry, but a possibly executed toggle is never retried after a timeout.

For an isolated trial, copy the configuration and run `qs -p /path/to/copy`.
Do not run source and deployed instances simultaneously during normal use.
After changing QML or IPC, restart with `make bar-reload`.

Launcher colors and fonts live in `theme/Theme.qml`. Its border follows Niri's
active border color from `niri/colors.kdl`. The bar uses its own watched JSON
palette. Both surfaces use square corners.

## Validation

```sh
node scripts/tests/niri-state.test.cjs
python3 -B -m unittest discover -s scripts/tests -p 'test_quickshell_bar.py' -v
DOFS_QML_TEST=1 python3 -B -m unittest discover -s scripts/tests -p 'test_quickshell_bar.py' -v
```

Manual checks include keyboard navigation, desktop shortcuts, terminal apps,
Flatpak/DBus activation, fractional scaling, physical monitor hotplug,
suspend/resume and a full login cycle.
