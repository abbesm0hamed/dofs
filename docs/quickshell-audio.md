# Quickshell audio panel

The `dofs` shell replaces `pavucontrol` with a square-cornered sound panel.
Open it from the bar's volume or visualizer module, **Sound settings** in the
launcher, or the system controls/settings menus. Right-click mute, middle-click
microphone mute, and scrolling volume on the bar remain unchanged.

## Controls

- **Output:** device volume/mute, default playback device, and speaker/headphone
  ports when the device offers multiple ports.
- **Input:** microphone volume/mute, default recording device, and input ports.
  Monitor sources are hidden here but remain available for application routing.
- **Applications:** separate playback and recording streams, each with mute,
  writable volume controls, and a device selector.
- **Profiles:** hardware profiles, including Bluetooth modes exposed by the
  audio server. Unavailable profiles and ports cannot be selected. Changing a
  profile can interrupt playback or remove an active microphone.

Sliders are capped at 100% and do not unmute devices. Setting a default does not
explicitly move running streams; use their selectors in **Applications**.
This is a day-to-day mixer, not a replacement for every diagnostic feature:
live peak meters, channel balance, and latency offsets are not implemented.

Escape and clicking outside close the panel. It follows Niri's focused output,
closes if that screen disappears, and excludes other shell panels when opened.
Colors follow the shell's existing watched bar palette.

## Backend and installation

The panel uses `pactl` JSON through PipeWire's existing PulseAudio-compatible
server. `pulseaudio-utils` supplies the client; no new audio daemon is started.
Python 3's standard library handles the backend. It runs only while the panel
is open and refreshes every three seconds plus after each action. Refreshes
pause while editing sliders or selectors. Bar volume remains native PipeWire.

Actions use argument arrays with timeouts, validate devices against a fresh
snapshot, and display failures in the panel. A stopped or timed-out backend
can be retried by closing and reopening the panel. The mixer lists applications
visible through the PulseAudio compatibility server, not every native PipeWire
graph node.

Ansible installs `pulseaudio-utils`, removes `pavucontrol`, and verifies the
panel files and `pactl`. `udiskie` is unchanged. Apply dotfiles and restart the
shell with `make bar-apply`; install updated packages separately through the
existing Ansible package tasks when needed.

## IPC

```sh
qs -c dofs ipc call audio ping
qs -c dofs ipc call audio open output
qs -c dofs ipc call audio open input
qs -c dofs ipc call audio open apps
qs -c dofs ipc call audio open profiles
qs -c dofs ipc call audio toggle
qs -c dofs ipc call audio status
qs -c dofs ipc call audio close
```

`quickshell-launcher.sh audio` and `launcher openEntry audio` also open the panel.

## Validation

```sh
python3 -B -m unittest discover -s scripts/tests -p 'test_quickshell_audio.py' -v
DOFS_QML_TEST=1 python3 -B -m unittest discover -s scripts/tests -p 'test_quickshell_audio.py' -v
```

The opt-in QML test loads all tabs in a hidden window and reads the live audio
server without changing volume, muting, routing, profiles, or defaults. Manual
checks should cover USB/Bluetooth hotplug, moving playback and recording streams,
keyboard slider/selector controls, and restoring a disconnected audio server.
