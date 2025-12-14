# dofs - Arch/CachyOS Dotfiles with Niri & default 

A unified, reproducible dotfiles setup for Arch Linux (CachyOS) featuring:

- **Niri** window manager (Wayland compositor)
- **default ** unified theme system
- **Mako** notification daemon
- **Waybar** status bar
- **Fish** shell with **Starship** prompt
- One-command reproducible setup via `yay` and declarative package lists

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

- Ensure `yay` is installed
- Install all packages from lists (system, desktop, wayland, etc.)
- Stow all dotfiles to `~/.config`
- Apply the unified default  theme
- Enable the Niri session in your display manager

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
- ✅ **7-phase optimized autostart** with proper service ordering
- ✅ **Live config reload** support

### CachyOS Optimizations

- ✅ **game-performance** wrapper for automatic gaming optimization
- ✅ **Flat mouse acceleration** for precise control
- ✅ **Wayland-native environment** for all apps
- ✅ **Optimized kernel** (linux-cachyos)

### Single-Command Installation

- ✅ One command installs everything
- ✅ Automatic validation before completion
- ✅ Declarative package management
- ✅ Reproducible setup

## 🎮 Gaming Setup

### Steam

Add to launch options:

```
game-performance %command%
```

### Lutris/Heroic

Use the wrapper script:

```
~/dofs/scripts/game-launcher.sh %command%
```

**Benefits:**

- Automatic performance CPU governor
- Wayland-native gaming support
- Lower latency and better FPS
- HDR support (when available)

## What Gets Installed

### System Packages

- Base development tools, git, network manager
- Fish shell, Starship prompt
- Bluetooth, SSH, power management tools

### Development Tools

- Node.js (fnm), Python, Rust, Go
- Docker, Kubernetes, Terraform
- Neovim, code quality tools, debuggers

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

## default Theme

All components use a unified **default** theme with 28 carefully selected colors:

- **Primary Background**: #1e1e2e
- **Primary Text**: #cdd6f4
- **Primary Accent**: #89b4fa (blue)
- **Alerts**: #f38ba8 (red)
- **Success**: #a6e3a1 (green)

### Themed Components

- Niri window borders
- Waybar status bar
- Mako notifications
- Terminal colors

### Manage Themes

```bash
# List available themes
dofs/scripts/theme-manager.sh list

# Apply a theme
dofs/scripts/theme-manager.sh set default

# Check current theme
dofs/scripts/theme-manager.sh current
```

## Directory Structure

```
dofs/
├── .config/                    # Configuration files (stowed to ~/.config)
│   ├── niri/                   # Niri window manager config
│   ├── waybar/                 # Status bar config
│   ├── mako/                   # Notification daemon config
│   ├── fish/                   # Fish shell config
│   ├── starship/               # Starship prompt config
│   ├── nvim/                   # Neovim config
│   ├── theme/                  # Theme system
│   │   └── default/            # Default theme
│   └── [other configs]/
├── packages/                   # Declarative package lists
│   ├── system.txt              # System packages
│   ├── development.txt         # Dev tools
│   ├── desktop.txt             # Desktop apps
│   └── wayland.txt             # Wayland stack
├── scripts/                    # Utility scripts
│   ├── setup-display-manager.sh # Niri session setup
│   ├── theme-manager.sh        # Theme management script
│   └── legacy/                 # Archived scripts
├── install.sh                  # Main installation script
└── README.md                   # This file
```

## Keybindings

### Window Management (Niri)

- `Mod+H/J/K/L` - Focus left/down/up/right
- `Mod+Shift+H/J/K/L` - Move window
- `Mod+Return` - Open terminal (Ghostty)
- `Alt+Ctrl+L` - Lock screen (Swaylock)

### Workspaces

- `Mod+1-9` - Switch to workspace
- `Mod+Shift+1-9` - Move window to workspace
- `Mod+Tab` - Toggle overview

### System

- `Alt+Space` - System controls menu
- `Alt+S` - Settings menu
- `Alt+L` - Power menu
- `Print` - Screenshot (region)
- `Shift+Print` - Screenshot (window)
- `Ctrl+Print` - Screenshot (screen)

See `.config/niri/config.kdl` for complete keybindings.

## Customization

### Add a New Package

Edit the relevant file in `packages/`:

```bash
# Add to development tools
echo "my-new-package" >> packages/development.txt

# Reinstall
bash scripts/install-development.sh
```

### Create a New Theme

```bash
# Copy existing theme
cp -r .config/theme/default .config/theme/my-theme

# Edit colors in my-theme/theme.toml
vim .config/theme/my-theme/theme.toml

# Apply the theme
bash scripts/theme-manager.sh set my-theme
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

- Ensure yay is installed: `which yay`
- Check internet connection
- Try manual install: `yay -S package-name`

## Troubleshooting

### Quick Diagnostics

```bash
# Check if everything is installed correctly
bash scripts/verify-installation.sh

# View installation log
cat ~/install.log

# Check autostart log (after logging into niri)
cat $XDG_RUNTIME_DIR/niri-autostart.log
```

### Common Issues

**Niri won't start / black screen:**

```bash
# Validate config
niri validate --config ~/.config/niri/config.kdl

# Check if niri is installed
which niri

# Re-run display manager setup
sudo bash scripts/setup-display-manager.sh
```

**Theme not applied:**

```bash
# Re-apply theme
bash scripts/theme-manager.sh set default
```

**Waybar not showing:**

```bash
# Start waybar manually
waybar &
```

**Can't switch back to Gnome:**

-  2. At login screen, select 'Niri' from session menu
  3. Log in with your credentials
  4. Press Mod+Return to open terminal
  5. Press Mod+P to open application launcher

## Inspiration & Credits

- **Catppuccin** - Beautiful color palette
- **Niri** - Modern Wayland compositor
- **Arch Linux** - Solid foundation

## Keybindings Documentation

This document provides a comprehensive list of all keyboard shortcuts configured in the system.

## Table of Contents

- [Window Management (Hyprland)](#window-management-hyprland)
- [Workspace Controls](#workspace-controls)
- [Application Shortcuts](#application-shortcuts)
- [Media Controls](#media-controls)
- [System Controls](#system-controls)
- [Screenshots](#screenshots)
- [Applications](#applications)

## Window Management (Niri)

| Keybinding                | Action                                |
| ------------------------- | ------------------------------------- |
| `Mod + h/j/k/l`           | Focus left/down/up/right              |
| `Mod + Shift + h/j/k/l`   | Move window left/down/up/right        |
| `Mod + f`                 | Toggle maximized                      |
| `Mod + equal`             | Resize window (+ width)               |
| `Mod + minus`             | Resize window (- width)               |

## Workspace Controls

| Keybinding                | Action                           |
| ------------------------- | -------------------------------- |
| `Mod + (1-9)`             | Switch to workspace 1-9          |
| `Mod + Shift + (1-9)`     | Move window to workspace 1-9     |
| `Mod + Tab`               | Toggle overview                  |

## Application Shortcuts

| Keybinding               | Action               |
| ------------------------ | -------------------- |
| `Mod + Return`           | Launch Ghostty       |
| `Mod + P`                | Launch Fuzzel        |
| `Alt + Z`                | Launch Zen Browser   |
| `Alt + E`                | Launch Nautilus      |
| `Alt + Ctrl + L`         | Launch Swaylock      |

## Media Controls

| Keybinding                           | Action                        |
| ------------------------------------ | ----------------------------- |
| `XF86AudioRaiseVolume`               | Volume up                     |
| `XF86AudioLowerVolume`               | Volume down                   |
| `XF86AudioMute`                      | Toggle mute                   |

## System Controls

| Keybinding          | Action                       |
| ------------------- | ---------------------------- |
| `Mod + Shift + q`   | Close window                 |
| `Mod + Shift + e`   | Quit Niri (Logout)           |

## Screenshots

| Key Combination     | Action                       |
| ------------------- | ---------------------------- |
| `Super + Shift + Z` | Create Screenshots directory |
| `Alt + Super + S`   | Active window screenshot     |
| `Alt + Shift + S`   | Full screenshot              |
| `Ctrl + Alt + S`    | GUI selection tool           |

All screenshots are automatically saved to `~/Pictures/Screenshots` and copied to clipboard.

## Applications

| Key Combination      | Action             |
| -------------------- | ------------------ |
| `Super + b`          | Open Brave browser |
| `Super + g`          | Open Google Chrome |
| `Super + enter`      | Kitty              |
| `Alt + enter`        | Wezterm            |
| `Alt + Ctrl + enter` | Ghostty            |
| `Alt + Ctrl + t`     | Alacritty          |

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

Press `super + alt + o` to open the power menu, which provides options for:

- Logout
- Reboot
- Hibernate
- Sleep

## Additional Features

- **Keyboard Layout**: Toggle between US and Arabic layouts using `Alt + Shift`
- **Auto-tiling**: Dynamic tiling layout
- **Workspace Auto Back and Forth**: Enabled
- **Smooth Animations**: Advanced animation system
- **Optimized for CachyOS**: Performance tweaks for the CachyOS kernel

Note: Some keybindings might be commented out in the config files. This documentation shows only the active keybindings.

## Inspiration

- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) - Base configuration (adapted for Niri)
- [The Linux Cast Dotfiles](https://gitlab.com/thelinuxcast/my-dots.git)
- [Nvim Config by Allaman](https://github.com/Allaman/nvim)
- [Chris Grieser Config](https://github.com/chrisgrieser/.config)
