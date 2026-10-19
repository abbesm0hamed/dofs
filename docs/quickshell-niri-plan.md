# Quickshell for Niri: implementation plan

## Goal

Replace the unreliable Waybar setup with a minimal, maintainable Quickshell
bar, then add a searchable app launcher and settings/actions menu. Keep the
shell independent of Omarchy and Hyprland, use Niri's own interfaces, and keep
all source changes in this declarative dotfiles repository.

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
