# Native Quickshell notifications

The `dofs` shell now owns `org.freedesktop.Notifications`. It replaces Mako and
the script-generated launcher history menu; `notify-send` and application
notifications continue to use the standard desktop notification protocol.

## Features and controls

- Compact, square-edged popup cards with the active shell palette, app icons,
  images, action buttons and an unread indicator. Popups never take keyboard focus.
- New popups follow Niri's focused workspace output and stay pinned there;
  disconnected outputs fall back to the first available screen.
- Hover pauses the popup timer. Normal popups use the configured timeout unless
  the application requests one. A timeout of zero keeps the popup visible;
  critical notifications default to this persistent behavior.
- The bell and **Mod+N** toggle the right-side center on the focused output.
  Opening it marks history read and hides current popups. Escape or an outside
  click closes it. The launcher also has a **Notification center** action.
- Search titles, application names and messages. History is grouped by day and
  application, with expandable long messages, per-entry/group deletion and a
  two-click **Clear all** confirmation.
- Right-click the bell, use the center's DND button, or use the existing system
  controls menu to toggle do not disturb. DND is saved across shell restarts.
- Actions remain usable while the sending application's notification is live,
  even after its popup disappears. Inline replies are available in the center
  when the sender supports them. Archived entries never pretend that expired
  actions are still usable.
- In the history list, arrow keys navigate, Enter invokes the selected live
  notification's default action, and Delete removes it. Tab reaches controls.

Hiding a popup is **not** deleting its history or marking it read. Applications
can withdraw their notifications; their saved text remains, marked read. Transient
notifications are popup-only and never enter history. Under a burst, older popups
move to history rather than covering the entire desktop.

## Configuration

Edit `home/dot_config/quickshell/dofs/notifications/config.json` and apply that
file with chezmoi. Valid changes reload live; invalid changes retain the last
valid options and display an error in the center and bell tooltip.

| Option | Default | Meaning |
| --- | --- | --- |
| `historyEnabled` | `true` | Persist history to disk; disabling clears the stored history but keeps this session's in-memory entries |
| `historyLimit` | `200` | Maximum in-memory and saved entries, 1–500 |
| `retentionDays` | `7` | Remove old entries, 1–365 days |
| `popupTimeout` | `6000` | Default normal popup lifetime in milliseconds, 1000–60000 |
| `maxVisible` | `3` | Maximum visible popup cards, 1–5 |
| `toastWidth` | `380` | Popup width in logical pixels, 280–600 |
| `padding` | `15` | Shared inner padding for popup and history cards in logical pixels, 0–32; changes reload live |
| `criticalBypassDnd` | `false` | Allow critical popups while DND is enabled |
| `mutedApps` | `[]` | Case-insensitive exact app names or desktop-entry IDs; keep history, suppress popups |
| `privateApps` | `[]` | App names/IDs whose history stays in memory only, never written to disk |

For example, `"mutedApps": ["Spotify"]` silences that application's popups.
`"privateApps": ["org.signal.Signal"]` excludes matching messages from disk.
Use the sender's actual application name or `desktop-entry` hint; no substring
matching is performed. Muting also suppresses critical popups from that sender.

The center and popups watch `bar/theme.json`, so built-in themes and Matugen
recolor them without restarting. No separate notification theme is needed.
Cards, the center, inputs, buttons, unread markers and scrollbar thumbs all
use zero corner radius, matching the rest of dofs.
Popups and the center use the same 8 px screen margin. History cards run flush
to the center panel's edge rather than adding a second inset around the list.
Both popup and history cards use the same global `padding` option, defaulting
to Mako's previous 15 px inner padding, and identical internal row spacing.
Center headings and controls align to that same inset. For a tighter layout,
set `"padding": 8`; both surfaces update together.
Existing configs without this key default to 15. Text-only cards never reserve
an empty image-preview area.
The history scrollbar lives outside the list viewport in a dedicated 4 px track
with a 6 px gap; cards and group controls cannot extend beneath it. The gutter
stays reserved when the scrollbar is hidden to avoid text reflow.

### Application icons

Icons resolve from the sender's icon, its desktop-entry ID (with or without
`.desktop`), its application name, and its icon-theme ID. This includes Flatpak
exports in `XDG_DATA_DIRS`. Absolute paths and properly encoded local file URLs
are supported, including paths containing spaces or `#`. If an icon is missing,
deleted, or fails to decode, the next candidate is tried; a bundled application
icon is the final fallback, so the header never depends on an installed generic
theme icon. Network URLs are rejected before loading.

Application logos stay in the header, not in a large empty message-preview
slot. Only actual notification images become message previews. Saved history
resolves application icons again after restarting the shell.

## Storage and privacy

History and DND state are stored at:

```
${XDG_STATE_HOME:-~/.local/state}/quickshell/dofs/notifications/history.json
```

The directory is mode **0700**, and the history file is **0600**. A small Python
stdlib helper performs serialized, atomic writes and holds an exclusive writer
lock. It is a storage helper, not another notification daemon. If storage fails,
notifications continue in memory and the center displays the error. The helper
reconnects without resurrecting notifications deleted during the interruption.
Damaged history is preserved as `history.corrupt-*.json`, not silently overwritten.

**History is plaintext, not encrypted.** It can contain message previews and is
accessible to your account, root, and backups. Use `privateApps`, disable history,
or rely on encrypted home storage if that is inappropriate. Lowering retention,
deleting entries, or changing privacy rules rewrites the active file; it cannot
erase copies already in backups or guarantee secure erasure on SSDs.

Only bounded text, app identity/icon, urgency, timestamps and read status are
stored. Action objects, reply drafts, notification image data and in-process image
URLs are not persisted. Restarted history therefore has no old action/reply
buttons or saved image previews. Bodies are plain text and remote images are
never fetched. Normal shutdown/reload can lose changes from the last 100 ms write
debounce; this is not a transactional message inbox.

## Switch from Mako

Development does not change your running desktop. Review the diff, then apply
the relevant files from the repository root (not the entire home tree):

```sh
chezmoi apply --recursive --source "$PWD/home" \
  "$HOME/.config/quickshell/dofs" \
  "$HOME/.config/niri/scripts/autostart.sh" \
  "$HOME/.config/niri/scripts/quickshell-launcher.sh" \
  "$HOME/.config/niri/scripts/system-controls.sh" \
  "$HOME/.config/niri/scripts/settings-menu.sh" \
  "$HOME/.config/niri/scripts/set-theme.sh" \
  "$HOME/.config/matugen/config.toml"
```

Only one notification daemon can own the D-Bus service. Stop the old daemon once
before starting the updated shell:

```sh
systemctl --user disable --now mako.service 2>/dev/null || true
pkill -x mako || true
qs -c dofs kill || true
bash "$HOME/.config/niri/scripts/quickshell-launcher.sh" --start
notify-send -a "Quickshell test" "Notifications ready" "Open Mod+N to see the saved message."
```

The autostart script no longer starts Mako, the package role no longer installs
it, and theme changes no longer generate/reload its configuration. Existing Mako
configuration/theme assets are retained as historical files; `.config/mako/` is
excluded from new chezmoi deployments. If Mako is still installed, its D-Bus
activation may start it when Quickshell is absent. You can uninstall it separately
if you no longer need it. The old in-memory Mako history is not imported.

## IPC and testing

```sh
qs -c dofs ipc call notifications status
qs -c dofs ipc call notifications toggle
qs -c dofs ipc call notifications toggleDnd
qs -c dofs ipc call notifications dismissPopups
qs -c dofs ipc call notifications markRead
# Destructive: deletes saved notification history too.
qs -c dofs ipc call notifications clear
```

`status` reports counts/state/errors, not message contents. Notification handling
continues if the bar is hidden or its notifications module is removed.

```sh
node scripts/tests/notification-history.test.cjs
python3 -B -m unittest discover -s scripts/tests -p 'test_quickshell*.py' -v
DOFS_QML_TEST=1 python3 -B -m unittest discover -s scripts/tests -p 'test_quickshell*.py' -v
```

Live notification tests use copied configuration, hidden surfaces, a temporary
state directory and a **private D-Bus session**. They exercise real notification
delivery, replacement, expiry, transient hints, DND, action/reply signals,
withdrawal, persistence/restart, storage failure recovery, privacy rules,
history limits, burst handling and deletion. They never claim your real desktop's
notification service. Icon tests require actual Qt `Image.Ready` decoding and
nonzero painted dimensions for themed icons, desktop-entry lookup, exported
Flatpak entries, local files, fallbacks, changing sources and archived history.
On the current workstation, Firefox, Ghostty, Discord, Slack, Obsidian and Zen
Browser icons are also checked directly, without accepting a generic fallback.
An offscreen-rendered layout test covers long notifications at multiple widths,
scrolling to the end, group controls, and hiding the scrollbar when history fits.
Live tests also check that changing `padding` updates the actual content inset
of both popup and history cards, that invalid values retain the last valid option,
and that older configs without `padding` still load.
The assembled center panel is rendered offscreen alongside an equal-width popup:
effective content positions, all four insets, row spacing and total heights must
match at 0, 4, 15 and 24 px padding. This includes the center's surrounding layout,
not just the card's padding property.
Manual checks still needed: visual/fractional-scale layout,
real application reply support, accessibility, and monitor hotplug.
