# dofs - Fedora Workstation Dotfiles with Niri

![Niri overview](.config/screenshots/niri-overview.png)
![Neovim + fastfetch](.config/screenshots/fastfetch-floating.png)

A unified, reproducible dotfiles setup for Fedora Workstation featuring:

- **Niri** - Scrollable-tiling Wayland compositor
- **Ghostty** - Fast, native terminal emulator
- **Waybar** - Highly customizable status bar
- **Mako** - Lightweight notification daemon
- **Fish** shell with **Starship** prompt
- **Unified theme system** - Consistent theming across all applications

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/abbesm0hamed/dofs.git ~/dofs
cd ~/dofs
```

### 2. Run Installation (One Command Setup)

```bash
./install.sh
```

This will:

- Install all packages from lists (system, desktop, wayland, etc.)
- Stow all dotfiles to `~/.config`
- Apply the unified default theme
- Enable the Niri session in GDM (GNOME Display Manager)

**Time**: ~15-20 minutes

### 3. Reboot and Enjoy

```bash
reboot
```

## ⚡ Optimizations

This setup includes:

### Niri Best Practices

- ✅ **xwayland-satellite** for X11 app compatibility (Discord, Steam, etc.)
- ✅ **xdg-desktop-portal-gnome** for better screen sharing
- ✅ **GDM** (GNOME Display Manager) with Niri session support
- ✅ **Optimized autostart** with proper service ordering
- ✅ **Swaylock** with blur effects for secure screen locking

### Single-Command Installation

- ✅ One command installs everything
- ✅ Automatic validation before completion
- ✅ Declarative package management
- ✅ Reproducible setup

## What Gets Installed

### System Packages

- Base development tools, git, network manager
- Fish shell, Starship prompt
- Bluetooth, SSH, power management tools...

### Development Tools

- Node.js (fnm), Python, Rust, Go
- Docker, Kubernetes, Terraform
- Neovim, code quality tools, debuggers...

### Desktop Applications

- Chromium, Zen Browser
- Nautilus file manager
- Slack, Discord
- Zathura PDF viewer
- And many more...

### Wayland Stack

- **Niri** compositor
- **Waybar** status bar
- **Mako** notifications
- Screenshot, recording, clipboard tools

### Manage Themes

```bash
# List available themes
bash scripts/setup/theme.sh list

# Apply a theme
bash scripts/setup/theme.sh set default

# Check current theme
bash scripts/setup/theme.sh current
```

## Customization

### Add a New Package

Edit the relevant file in `packages/`:

```bash
# Add to development tools
echo "my-new-package" >> packages/development.txt

# Reinstall
./install.sh
```

### Create a New Theme

```bash
# Copy existing theme
cp -r .config/theme/default .config/theme/my-theme

# Edit theme files for each application
# Each app has its own theme file:
# - niri.conf (Niri colors)
# - mako.ini (notification colors)
# - ghostty (terminal colors)
# - waybar.css (status bar styling)
# - swaylock/theme.conf (lock screen)
# - etc.

# Apply the theme
bash scripts/setup/theme.sh set my-theme
```

### Modify Niri Config

Edit `.config/niri/config.kdl` and reload:

```bash
niri msg action reload-config
```

## Troubleshooting

### Niri won't start

- Check if Wayland is supported: `echo $WAYLAND_DISPLAY`
- Verify Niri is installed: `which niri`
- Check logs: `journalctl -u niri`

### Theme not applying

- Ensure theme files exist: `ls .config/theme/default/`
- Manually apply: `bash scripts/theme-manager.sh set default`
- Check Waybar reload: `pgrep waybar`

### Packages not installing

- Check internet connection
- Try manual install: `sudo dnf install package-name`
- For Flatpak apps: `flatpak install package-name`

## Window Management (Niri)

| Keybinding              | Action                         |
| ----------------------- | ------------------------------ |
| `Mod + h/j/k/l`         | Focus left/down/up/right       |
| `Mod + Shift + h/j/k/l` | Move window left/down/up/right |
| `Mod + f`               | Toggle maximized               |
| `Mod + equal`           | Resize window (+ width)        |
| `Mod + minus`           | Resize window (- width)        |

## Workspace Controls

| Keybinding            | Action                       |
| --------------------- | ---------------------------- |
| `Mod + (1-9)`         | Switch to workspace 1-9      |
| `Mod + Shift + (1-9)` | Move window to workspace 1-9 |
| `Mod + Tab`           | Toggle overview              |

## Application Shortcuts

| Keybinding       | Action             |
| ---------------- | ------------------ |
| `Mod + Return`   | Launch Ghostty     |
| `Mod + P`        | Launch Fuzzel      |
| `Alt + Z`        | Launch Zen Browser |
| `Alt + E`        | Launch Nautilus    |
| `Alt + Ctrl + L` | Launch Swaylock    |

## Media Controls

| Keybinding             | Action      |
| ---------------------- | ----------- |
| `XF86AudioRaiseVolume` | Volume up   |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute`        | Toggle mute |

## System Controls

| Keybinding        | Action             |
| ----------------- | ------------------ |
| `Mod + Shift + q` | Close window       |
| `Mod + Shift + e` | Quit Niri (Logout) |

## Screenshots

| Key Combination     | Action                       |
| ------------------- | ---------------------------- |
| `Super + Shift + Z` | Create Screenshots directory |
| `Alt + Super + S`   | Active window screenshot     |
| `Alt + Shift + S`   | Full screenshot              |
| `Ctrl + Alt + S`    | GUI selection tool           |

All screenshots are automatically saved to `~/Pictures/Screenshots` and copied to clipboard.

## Additional Applications

| Key Combination | Action             |
| --------------- | ------------------ |
| `Alt + Z`       | Open Zen Browser   |
| `Alt + E`       | Open Nautilus      |
| `Mod + Return`  | Launch Ghostty     |
| `Mod + P`       | Launch Fuzzel      |
| `Alt + Ctrl + L`| Lock screen (Swaylock) |

### Neovim Keybindings

The following are the custom keybindings configured for Neovim:

| Keybinding               | Mode          | Description                 |
| ------------------------ | ------------- | --------------------------- |
| `<Space>`                | All           | Leader key                  |
| `<leader>w`              | Normal        | Save file                   |
| `J`                      | Visual        | Move line down              |
| `K`                      | Visual        | Move line up                |
| `jk`                     | Insert        | Exit insert mode (ESC)      |
| `<leader>q`              | Normal        | Quit Neovim                 |
| `+`                      | Normal        | Increment number            |
| `-`                      | Normal        | Decrement number            |
| `<C-a>`                  | Normal        | Select all text             |
| `<` / `>`                | Visual        | Indent/Unindent selection   |
| `te`                     | Normal        | New tab                     |
| `<leader>sh`             | Normal        | Split window horizontally   |
| `<leader>sv`             | Normal        | Split window vertically     |
| `<C-h/j/k/l>`            | Normal        | Navigate between splits     |
| `<leader>th`             | Normal        | Change splits to horizontal |
| `<leader>tk`             | Normal        | Change splits to vertical   |
| `<C-Up/Down/Left/Right>` | Normal        | Resize window               |
| `<Tab>` / `<S-Tab>`      | Normal        | Next/Previous buffer        |
| `<leader>x`              | Normal        | Close buffer                |
| `<A-p>`                  | Normal        | Pin buffer                  |
| `<leader>co`             | Normal/Visual | Toggle comment              |
| `<leader>ff`             | Normal        | Telescope find files        |
| `<leader>fg`             | Normal        | Telescope live grep         |
| `<leader>fr`             | Normal        | Telescope recent files      |
| `<leader>fb`             | Normal        | Telescope buffers           |
| `<leader>S`              | Normal        | Toggle Spectre              |
| `<leader>sw`             | Normal/Visual | Search current word         |
| `<leader>sp`             | Normal        | Search in current file      |

#### Git Integration Keybindings

| Keybinding   | Mode            | Description               |
| ------------ | --------------- | ------------------------- |
| `ga`         | Normal          | Stage hunk                |
| `ga`         | Visual          | Stage selection           |
| `gA`         | Normal          | Stage entire buffer       |
| `<leader>gv` | Normal          | Toggle deleted lines view |
| `<leader>ua` | Normal          | Undo last stage           |
| `<leader>uh` | Normal          | Reset hunk                |
| `<leader>ub` | Normal          | Reset buffer              |
| `<leader>ob` | Normal          | Toggle git blame          |
| `gh`         | Normal          | Next hunk                 |
| `gH`         | Normal          | Previous hunk             |
| `gh`         | Visual/Operator | Select hunk               |

#### DiffView Keybindings

| Keybinding   | Mode   | Description                         |
| ------------ | ------ | ----------------------------------- |
| `<leader>q`  | Normal | Close DiffView                      |
| `<leader>ch` | Normal | Choose current version in conflict  |
| `<leader>cl` | Normal | Choose incoming version in conflict |
| `<leader>cb` | Normal | Choose base version in conflict     |
| `<leader>ca` | Normal | Choose all versions in conflict     |
| `<leader>cx` | Normal | Choose none in conflict             |
| `do`         | Normal | Get diff from other file            |
| `dp`         | Normal | Put diff to other file              |
| `j/k`        | Normal | Navigate entries in file panel      |
| `<cr>`       | Normal | Select entry in file panel          |

#### File Operations Keybindings

| Keybinding  | Mode   | Description                     |
| ----------- | ------ | ------------------------------- |
| `<C-p>`     | Normal | Copy file path (with ~)         |
| `<C-t>`     | Normal | Copy relative path              |
| `<C-n>`     | Normal | Copy filename                   |
| `<C-r>`     | Normal | Rename file                     |
| `<D-m>`     | Normal | Move file                       |
| `<leader>x` | Normal | Make file executable (chmod +x) |
| `<A-d>`     | Normal | Duplicate file                  |
| `<D-BS>`    | Normal | Move file to trash              |
| `<D-n>`     | Normal | Create new file                 |
| `X`         | Visual | Move selection to new file      |
| `-`         | Normal | Open parent directory (Oil)     |

#### Editing Support Keybindings

| Keybinding   | Mode   | Description                        |
| ------------ | ------ | ---------------------------------- |
| `gcc`        | Normal | Toggle line comment                |
| `Q`          | Normal | Comment at end of line             |
| `qO`         | Normal | Comment above                      |
| `qo`         | Normal | Comment below                      |
| `<leader>ut` | Normal | Toggle Undotree                    |
| `<leader>tp` | Normal | Toggle Puppeteer                   |
| `<leader>tj` | Normal | Toggle split/join lines            |
| `<leader>tJ` | Normal | Split line (markdown, applescript) |

#### Mini Plugins Keybindings

| Keybinding | Mode          | Description              |
| ---------- | ------------- | ------------------------ |
| `gsa`      | Normal/Visual | Add surrounding          |
| `gsd`      | Normal        | Delete surrounding       |
| `gsf`      | Normal        | Find surrounding (right) |
| `gsF`      | Normal        | Find surrounding (left)  |
| `gsh`      | Normal        | Highlight surrounding    |
| `gsr`      | Normal        | Replace surrounding      |
| `gsn`      | Normal        | Update surrounding lines |

#### Outline Navigation

| Keybinding   | Mode   | Description    |
| ------------ | ------ | -------------- |
| `<leader>ou` | Normal | Toggle outline |
| `<Esc>`, `q` | Normal | Close outline  |
| `<CR>`       | Normal | Go to location |
| `o`          | Normal | Focus location |
| `<C-space>`  | Normal | Hover symbol   |
| `K`          | Normal | Toggle preview |
| `r`          | Normal | Rename symbol  |
| `a`          | Normal | Code actions   |
| `h`          | Normal | Fold           |
| `l`          | Normal | Unfold         |
| `W`          | Normal | Fold all       |

_Note: This is not an exhaustive list. There are more keybindings available in other plugins. Check the plugin documentation for more details._

### System Mode (Exit Menu)

Press `ALT + L` to open the power menu, which provides options for:

- Logout
- Reboot
- Hibernate
- Sleep

## Additional Features

- **Keyboard Layout**: Toggle between US and Arabic layouts using `Super + Alt + Shift + Space`
- **Auto-tiling**: Dynamic tiling layout
- **Workspace Auto Back and Forth**: Enabled
- **Smooth Animations**: Advanced animation system

## Inspiration

- [The Linux Cast Dotfiles](https://gitlab.com/thelinuxcast/my-dots.git)
- [Nvim Config by Allaman](https://github.com/Allaman/nvim)
- [Chris Grieser Config](https://github.com/chrisgrieser/.config)
