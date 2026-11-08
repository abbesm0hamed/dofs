# Quickshell wallpapers

The main `dofs` shell replaces `swww` and `swaybg` with two background-layer
surfaces per output. The workspace surface moves and zooms with Niri workspaces;
the separate backdrop surface stays behind them in overview and between
workspaces. Both ignore exclusive zones, reserve no space, and take no input.
Niri's namespace rules in `rules.kdl` assign their roles. Do not move both
surfaces into the backdrop or make workspace backgrounds transparent.

The design follows Niri's `place-within-backdrop` model and Noctalia's legacy-v4
Quickshell `Modules/Background/Background.qml` and `Overview.qml` separation.
Unlike Noctalia's GPU overview blur, this setup keeps a cached ImageMagick blur
on disk, because the separate lockscreen also needs that file.
Animated image inputs use their first frame for the static backdrop.

## Picker

Press **Alt+Ctrl+W**, search for **Wallpaper picker** in the launcher, or run:

```sh
qs -c dofs ipc call wallpaper open
```

The wide, square-cornered panel has workspace/backdrop previews and searchable
thumbnails. Select **Workspace** or **Backdrop**, then click an image (or use
Down, arrow keys, and Enter). Escape or the right-hand Close button closes it.
Selecting a backdrop makes it independent. Changing the workspace then leaves
that image alone. **Follow workspace blur** returns to a derived backdrop.
Selections apply to all outputs; separate per-output/per-workspace selections
are not implemented. Output hotplug creates or removes the appropriate surfaces.

Images are loaded asynchronously. Each surface keeps its current image until
the replacement is ready, and keeps it on loading failure. Rendering is decoded
at output pixel size; picker thumbnails have smaller decoding bounds.

## Selection and persistence

The existing setter and theme interface remains available:

```sh
~/.config/niri/scripts/wallpaper.sh /path/workspace.jpg
~/.config/niri/scripts/wallpaper.sh /path/workspace.jpg /path/backdrop.png
~/.config/niri/scripts/wallpaper.sh --workspace /path/workspace.jpg
~/.config/niri/scripts/wallpaper.sh --backdrop /path/backdrop.png
~/.config/niri/scripts/wallpaper.sh --blur
~/.config/niri/scripts/wallpaper.sh --restore --silent
```

The positional one-image form selects workspace + generated blur, preserving
existing theme behavior. `--workspace` preserves an independent backdrop.
`workspace=` and `backdrop=` in theme `wallpapers.conf` files still work.

`~/.config/backgrounds/current.jpg` and `current-blurry.jpg` remain symlinks for
theme and lockscreen compatibility, including when the backdrop is not blurred.
State and mode live in `${XDG_STATE_HOME:-~/.local/state}/dofs/wallpaper.json`.
The shell watches atomic state-file replacements, so setters work before the
shell is running and do not depend on an available IPC connection. Restore
migrates existing links, preserves independent backdrops, and falls back to
`liftoff.png` or the first available image if the workspace selection is gone.
Blur cache keys include source path, modification time, and size to avoid
basename collisions and refresh changed files. State updates are serialized.
Failed link or state replacements roll back both compatibility links.

## Deployment and diagnostics

Apply the dotfiles and restart the main shell with `make bar-apply`. Wallpaper
surfaces share its lifecycle; restarting it briefly removes them. The separate
lockscreen is not restarted. ImageMagick and Python 3 remain required; do not
remove ImageMagick when retiring the old wallpaper daemons.
Restore and blur generation run asynchronously inside the shell rather than
blocking session startup or delaying the separate lockscreen service.

```sh
qs -c dofs ipc call wallpaper status
qs -c dofs ipc call wallpaper restore
qs -c dofs ipc call wallpaper close
niri msg layers
```

Every output should have `dofs-wallpaper-workspace` and `dofs-wallpaper-backdrop`
on the Background layer, both without keyboard interactivity. Status reports
image readiness and errors per output and role. During migration, stop the old
daemons only after both replacement images report ready. Keep their binaries
installed for the initial trial and remove them manually once satisfied. Ansible
no longer requests `swww` or `swaybg` or enables their old COPR repository.
Rolling back requires restoring the previous shell, setter, startup script,
and the old `wallpaper` namespace backdrop rule before restarting the daemons.

## Validation

```sh
python3 -B -m unittest discover -s scripts/tests -p 'test_quickshell_wallpaper.py' -v
DOFS_QML_TEST=1 python3 -B -m unittest discover -s scripts/tests -p 'test_quickshell_wallpaper.py' -v
niri validate -c home/dot_config/niri/config.kdl
```

The opt-in QML test uses isolated image/state fixtures and hidden surfaces,
checks repeated external state updates and encoded filenames, and verifies that
a failed image load retains the previous image without altering live selections.
