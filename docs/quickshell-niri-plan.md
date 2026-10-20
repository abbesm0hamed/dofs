# Quickshell for Niri: implementation plan

## Goal

Replace the unreliable Waybar setup with a minimal, maintainable Quickshell
bar, then add a searchable app launcher and settings/actions menu. Keep the
shell independent of Omarchy and Hyprland, use Niri's own interfaces, and keep
all source changes in this declarative dotfiles repository.

## Launcher-first implementation (main app launcher)

The launcher was implemented ahead of the bar phases below and is now the main
app launcher on `Mod+Space`. Its wrapper starts the named instance on demand,
then toggles it. Rofi's app launcher remains available on `Mod+Shift+Space` as
a fallback. The Rofi package/config, other Rofi menus, Waybar, and session
autostart are unchanged.

### Try without deploying

From the repository root, in two terminals:

```sh
qs -p "$PWD/home/dot_config/quickshell/dofs" --no-duplicate
qs -p "$PWD/home/dot_config/quickshell/dofs" ipc call launcher toggle
```

This runs the source directly; it does not modify `~/.config`. Stop with Ctrl+C,
or `qs -p "$PWD/home/dot_config/quickshell/dofs" kill`. Do not simultaneously run
the source-path instance and the deployed instance.

### Deploy when ready

Review `make dotdiff` (which may include unrelated pending dotfiles changes).
Apply **only the trial files**, without force-applying the entire home tree:

```sh
chezmoi apply --recursive --source "$PWD/home" \
  "$HOME/.config/quickshell/dofs" "$HOME/.config/niri/binds.kdl" \
  "$HOME/.config/niri/scripts/quickshell-launcher.sh"
```

Niri reloads its managed binds; `Mod+Space` toggles the Quickshell launcher.
The IPC target `launcher` also exposes `open`, `close`, and a `ping` readiness
check. The shortcut starts
the shell if necessary; nothing starts it at login. Stop it with
`qs -c dofs kill`; Rofi remains on `Mod+Shift+Space`.
The actual Makefile currently calls full apply `make dotapply`, not `make dotapp`.

After updating QML or the IPC API in an already-running deployed instance,
run `qs -c dofs kill`, then press the shortcut to start the updated shell.
Do not assume file-watch reload applied an IPC API change: the live deployment
retained its old handler during testing until explicitly restarted. Ordinary
development reloads and `entries.jsonc` edits are tested, but explicit restart
is the reliable deployment boundary, as in Omarchy's shell startup approach.

### Included interactions

- XDG application discovery through `DesktopEntries`, including Flatpak exports
  when their data directories are in the session's `XDG_DATA_DIRS`.
  A debounced visibility snapshot honors user overrides, `Hidden`, `NoDisplay`,
  `OnlyShowIn`, `NotShowIn`, and `TryExec` without scanning on search keystrokes.
- Fuzzy, multi-word search across names, descriptions, IDs and app keywords.
- When search is empty, up to five recently launched apps appear first, marked
  **Recent**, without duplicating them in the rest of the list. Typing keeps the
  normal search ranking; the Actions filter does not promote recent apps.
- **Clear history** is available beside the filters and as the searchable
  **Clear launch history** action. Only successful app-launch dispatches through
  Quickshell are recorded, including terminal apps and desktop shortcuts. Rofi
  launches, quick actions, calculator results, and open windows are not tracked.
  The five app IDs persist locally in
  `${XDG_STATE_HOME:-~/.local/state}/quickshell/dofs/launcher-history.json`
  (private directory/file permissions, atomic writes). No search queries,
  timestamps, or frequency counts are stored. Removed/hidden apps are not
  promoted, and a failed history write does not prevent an app from opening.
- All / Apps / Actions filters (Ctrl+1/2/3); ↑/↓ or Ctrl+N/P select, Enter launches.
- Tab or Ctrl+K opens the selected application's desktop shortcuts, if any.
  Escape or Backspace on an empty shortcut search returns to the main list.
- `= (12 + 3) * 4` calculates; Enter copies the result. Basic arithmetic only;
  `%` means remainder, not percentage. There is no arbitrary code execution.
- `? search terms` opens a Google search in the default browser.
- Escape or clicking outside closes. Opening targets Niri's focused output;
  failure or a 1.5-second query timeout falls back to the first available screen.
  Removing the target screen dismisses the launcher.
- Quick actions/links live in `launcher/entries.jsonc`, with live reload and
  schema validation. Comments and trailing commas are accepted. Invalid edits
  show an error and retain the last valid list.
  Commands are argument arrays, not shell strings; only `~` and `~/` expand.

Colors and fonts live in `theme/Theme.qml` and follow the existing dark Rofi
palette, with square corners throughout. The border reads Niri's active border
color from `niri/colors.kdl` and follows theme switches live. There are no
animations, usage-frequency tracking, plugins, or bar.

### Dependencies and failure behavior

Uses the declared Quickshell package, Python 3 (stdlib only), `gio` from GLib,
`xdg-open`, and `wl-copy` for calculator results. The configured action tools
are optional: missing commands produce a visible launch error. GIO handles app
desktop-file semantics (field codes, working directory and DBus activation).
`Terminal=true` entries explicitly use `wezterm start --` with Quickshell's
parsed command, rather than relying on GIO to guess a terminal. Desktop
shortcuts also use the parsed command, stripping unfilled standalone field
codes; terminal shortcuts use WezTerm. Application IDs always omit exactly one
`.desktop` suffix, including IDs that themselves end in `.desktop`.

Applications detach from the shell and survive its reload/exit. Desktop app
launch errors and command failures within the first 600 ms reopen the launcher
with an error. Later crashes are not monitored. This is not a process supervisor.
The Niri adapter only queries focused output when opening; bar event-stream
work remains in phase 3 and has not been implemented.

The shortcut wrapper serializes simultaneous invocations, waits for a positive
readiness response, bounds IPC/startup waits, and checks IPC error text even
when Quickshell exits 0. Readiness probes can retry; a possibly-executed toggle
is never retried after a timeout. It does not kill an unresponsive shell or
supervise crashes continuously; after a crash, the next shortcut starts it again.

### Validation

```sh
node scripts/tests/launcher-history.test.cjs
python3 -B -m unittest discover -s scripts/tests -p 'test_launcher_history.py'
# Optional live Wayland integration test, using synthetic desktop entries:
DOFS_QML_TEST=1 python3 -B -m unittest discover -s scripts/tests -p 'test_launcher_history.py'
```

The recent-app tests cover ordering, deduplication, five-entry limits, private
permissions, concurrent writes, corrupt-state recovery, failed/untracked
launches, persistence across process/shell restarts, unchanged typed search,
and clearing through the QML action. Tests use an isolated state directory and
synthetic apps; they do not populate the real launch history.

An earlier audit against installed Quickshell 0.3.2 used pure-JS tests and 14
Python tests, including live Wayland/QML tests. Coverage included real Qt keyboard
events (navigation, filters, shortcuts, Enter and Escape), focused-monitor
rendering, repeated opening/closing, normal and terminal desktop-file dispatch,
IDs containing spaces or `.desktop`, working directories and field codes,
clipboard/web argument dispatch, config syntax errors and atomic-file recovery,
QML reload, visible command failures, app survival after supervisor exit,
hung Niri queries, cold/warm startup, concurrent presses and IPC timeouts/errors.
Browser, terminal and clipboard commands are stubbed in the integration tests;
they do not modify the real clipboard or open real apps. GIO uses synthetic
desktop files, not a blanket test of every installed application.

Still manual/unverified: physical monitor hotplug, suspend/resume and full-login
cycles, actual Flatpak/DBus activation across installed apps, and fractional-scale
visual checks. Qt also logs SVG-buffer warnings for some installed icons; this
does not fail the launch tests, but not every app icon has been visually checked.
Later app crashes are intentionally not detected. This is a
main-app-launcher replacement only, not a migration of other Rofi menus, a bar
cutover, or an autostart change.

### Omarchy implementation comparison

Reviewed the `quattro` branch's
[AppLibrary.qml](https://github.com/omacom/omarchy/blob/quattro/shell/services/AppLibrary.qml),
[hidden-entries.sh](https://github.com/omacom/omarchy/blob/quattro/shell/services/hidden-entries.sh),
[IPC wrapper](https://github.com/omacom/omarchy/blob/quattro/bin/omarchy-shell),
and [shell startup](https://github.com/omacom/omarchy/blob/quattro/bin/omarchy-launch-shell).
The useful parallels are explicit terminal launching, preserving desktop ID
suffixes, desktop-visibility filtering, detached launches, and bounded IPC with
positive readiness/error checks. This trial deliberately does not import
Omarchy's plugin framework, UWSM/Hyprland launch scopes, OSD dependencies, or
full-shell crash supervisor. Niri remains the only compositor boundary.

## Constraints and decisions

- Edit source files under `home/`; never make hand-edited changes directly in
  the deployed `~/.config` tree. Use chezmoi to apply reviewed repo changes.
- Quickshell is already declared in
  `ansible/roles/packages/vars/main.yml`, alongside its COPR. Keep that as the
  installation source of truth.
- Start with a small shell, not a clone of Omarchy or a general-purpose plugin
  framework. Add extension points only when there is a real use case.
- Keep the visual language close to the current bar. Prefer static, clear UI;
  animations are explicitly out of scope for the first version.
- Keep Waybar available as a rollback until the Quickshell bar has passed
  session and interaction testing.

## Proposed source layout

Quickshell discovers named configurations below `~/.config/quickshell/`.
With this repo's chezmoi layout, create the source under
`home/dot_config/quickshell/dofs/`:

```text
home/dot_config/quickshell/dofs/
├── shell.qml                 # Config entry point
├── config/
│   └── bar.json              # Module order and user-facing options
├── bar/
│   ├── Bar.qml               # Per-screen panel and layout
│   └── modules/              # Small, presentational bar modules
├── services/
│   └── NiriService.qml       # Shared Niri state and action adapter
├── launcher/
│   ├── Launcher.qml          # Search UI
│   └── entries.jsonc         # Searchable actions/settings, if needed
└── theme/
    └── Theme.qml             # Colors, typography, spacing
```

Use ordinary QML components with clear inputs/outputs. Keep shared state in
services rather than letting modules shell out independently. A separate
`entries.jsonc` is only for launcher entries; don't put all shell behavior in
a large data-driven framework.

## Phases

### 1. Verify install and config discovery

- Run `make ansible-packages` to apply the existing package declaration when
  Quickshell needs installing on a machine.
- Add the starter configuration under the repo path above.
- Verify it can be launched explicitly as `qs -c dofs` after `make dotapp`.
- Confirm the default setup renders one simple `PanelWindow` before adding
  modules or replacing Waybar startup.

**Exit criteria:** the named config is discoverable, starts in the Niri Wayland
session, and QML errors are visible during development.

### 2. Implement the multi-monitor bar shell

- Use `Quickshell.screens` with `Variants` to create one bar per connected
  screen, assigning each panel to its screen.
- Keep the initial bar static and minimal. Port typography, colors, spacing,
  and module arrangement from the existing Waybar styles.
- Put module ordering and basic options in one small config file; avoid a
  plugin registry or per-module process model.
- Use `Loader`/`LazyLoader` for expensive UI that should not exist until opened.

**Exit criteria:** the bar appears on each connected monitor and responds
correctly when displays connect or disconnect.

### 3. Add a single event-driven Niri adapter

Implement `services/NiriService.qml` as the only component that communicates
with the compositor.

- Use Niri's documented `niri msg --json event-stream` interface for the
  initial state and ongoing events. Quickshell's `Process` and `SplitParser`
  are suitable for a long-lived line-oriented process.
- Parse events centrally and expose normalized workspace, window, and focus
  state to QML components. Niri notes that related state changes aren't
  guaranteed to arrive atomically; consumers must tolerate transient ordering
  differences.
- Send user actions through `niri msg action ...` initially. Use separate
  arguments rather than composing shell command strings.
- Detect process exit/disconnect, report errors, and reconnect with bounded
  backoff. Don't silently leave stale state on screen.
- Don't poll state already available through the event stream. For unrelated
  system data, prefer suitable DBus/Quickshell integrations; otherwise use a
  small number of shared, conservative timers.

Keep the Niri adapter replaceable. Quickshell doesn't currently provide a
first-party Niri service, so a custom adapter is the compositor boundary; the
rest of the bar should not depend on Niri IPC details.

**Exit criteria:** workspace/focus state follows Niri events, actions work,
and the shell recovers from the event process disconnecting.

### 4. Port bar modules incrementally

Add and test modules one at a time, in this order:

1. Workspaces and focused-window/title display
2. Clock
3. Audio and microphone
4. Network and Bluetooth
5. Battery, brightness, and system status
6. Tray and selected existing custom indicators/scripts

For every module, define its display, interactions, data source, and failure
state. Avoid duplicate polling and avoid running one external process per
widget. Do not port modules that aren't needed; preserve behavior, not legacy
complexity.

**Exit criteria:** each retained module behaves correctly under normal use,
including scroll/click interactions and unavailable-device states.

### 5. Add launcher and settings/actions menu

Only after the bar is stable:

- Build a separate searchable launcher surface.
- Discover installed applications from XDG desktop entries instead of
  maintaining a second app list.
- Keep searchable action/settings entries in a small JSONC file separate from
  QML rendering and search behavior.
- Start with apps and a small set of useful actions. Add nested menus or
  dynamic providers only when they simplify real workflows.
- Expose a small Quickshell `IpcHandler` API for opening/toggling the launcher
  and menu. Wire Niri binds to `qs -c dofs ipc call ...`.
- Make command failures visible and keep keyboard navigation usable throughout.

This borrows Omarchy's helpful data/UI separation without depending on its
shell, plugin host, commands, or compositor assumptions.

**Exit criteria:** app search and configured actions open from Niri keybindings
and work without Omarchy or Hyprland installed.

### 6. Test in parallel, then switch startup

- Test Quickshell interactively while keeping the current Waybar startup
  untouched in the repo. Avoid leaving both bars active during actual panel
  testing because they can overlap or compete for reserved screen space.
- Test multiple monitors, workspace changes, module interactions, launcher
  keyboard behavior, and event-stream recovery.
- Once behavior is acceptable, update the repo-managed startup source:
  `home/dot_config/niri/scripts/executable_autostart.sh` currently starts
  Waybar. Replace that launch with the named Quickshell config and ensure the
  startup remains idempotent.
- Review `make dotdiff` before deploying with `make dotapp`.
- Keep the Waybar config and launch path available until a full login/reboot
  test passes; rollback should be a source change followed by chezmoi apply,
  not manual edits in `~/.config`.

**Exit criteria:** exactly one bar starts at login; session startup, reload,
and rollback are documented and reliable.

## Validation checklist

- [ ] `qs -c dofs` starts the repo-managed shell without QML errors.
- [ ] Bar appears on all connected screens and handles hotplugging.
- [ ] Niri workspace/focus state updates without continuous state polling.
- [ ] Niri actions and Quickshell IPC bindings work from the Niri session.
- [ ] Niri event-stream disconnects are reported and recover automatically.
- [ ] Bluetooth/audio/network unavailable states don't freeze or hide the bar.
- [ ] Launcher remains keyboard-accessible and reports failed actions.
- [ ] Autostart launches one Quickshell instance and no longer starts Waybar
      after cutover.
- [ ] `make dotdiff` shows only intended repo-managed changes before apply.
- [ ] Waybar rollback works using repo sources and chezmoi only.

## Design references

- [Niri IPC and event stream](https://github.com/niri-wm/niri/wiki/IPC)
- [Niri startup configuration](https://github.com/niri-wm/niri/wiki/Configuration:-Miscellaneous)
- [Quickshell introduction](https://quickshell.org/docs/guide/introduction)
- [Quickshell FAQ](https://quickshell.org/docs/guide/faq)
- [Omarchy menu design](https://github.com/omacom/omarchy/blob/quattro/docs/menu.md)
- [Omarchy shell design](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md)
- [Noctalia Niri integration](https://github.com/noctalia-dev/noctalia-shell)
- [DankMaterialShell architecture](https://github.com/AvengeMedia/DankMaterialShell)
