# Own your DOtFileS with dofs - Fedora Workstation + Niri

### Themes & Screenshots

This setup comes with 3 built-in themes: **dofs** (default), **Kanagawa**, and **Zen**.

#### dofs Theme

![Niri Overview](home/dot_config/screenshots/dofs-niri-overview.png)
*Niri Overview*

![Niri Binds](home/dot_config/screenshots/dofs-niri-binds.png)
*Niri Keybindings*

![Yazi Floating](home/dot_config/screenshots/dofs-yazi-floating.png)
*Yazi Floating*

#### Kanagawa Theme

![Kanagawa Theme](home/dot_config/screenshots/kanagawa-decoration-apps.png)
*Modern professional aesthetics*

![Kanagawa Variant Switcher](home/dot_config/screenshots/kanagawa-waybar-variant-switcher.png)
*Unified variant switcher*

#### Zen Theme

![Zen Theme Overview](home/dot_config/screenshots/zen-theme-niri-overview.png)
*Minimalist focus*

![Zen Theme Switcher](home/dot_config/screenshots/zen-theme-switcher.png)
*Unified theme switcher*

#### Gruvbox Theme

![Gruvbox Theme Overview](home/dot_config/screenshots/gruvbox-overview.png)
*Retro warm aesthetics*

A unified, reproducible dotfiles setup for Fedora Workstation featuring:

- **Niri** - Scrollable-tiling Wayland compositor
- **WezTerm** - GPU-accelerated terminal emulator
- **Rofi** - Highly customizable application launcher
- **Waybar** - Highly customizable status bar
- **Mako** - Lightweight notification daemon
- **Fish** shell with **Hydro** prompt

## Quick Start

Run this command in your terminal:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/abbesm0hamed/dofs/migrate/chezmoi/bootstrap.sh)"
```

This will:

- Clone the repository to `~/dofs`
- Install Ansible and chezmoi
- Apply dotfiles to your home directory using **chezmoi**
- Install all packages and configure the system using **Ansible**
- Apply the unified default theme

## Manual Installation

If you prefer to clone the repository manually, follow these steps:

```bash
# Clone the repository
git clone --branch fedora-niri https://github.com/abbesm0hamed/dofs.git ~/dofs
cd ~/dofs

# Run the bootstrap script
./bootstrap.sh

# Or with flags for specific operations:
./bootstrap.sh --dotfiles-only  # Only apply dotfiles
./bootstrap.sh --ansible-only   # Only run Ansible
./bootstrap.sh --update         # Update existing installation
```

**Bootstrap Options:**

- `--dotfiles-only` - Only apply dotfiles (skip Ansible)
- `--ansible-only` - Only run Ansible (skip dotfiles)
- `--update` - Update existing installation
- `--skip-pull` - Don't pull latest changes from git
- `-h, --help` - Show help message

## Reboot

```bash
reboot
```

## ⚡ Optimizations

This setup includes:

### Niri Best Practices

- **xwayland-satellite** for X11 app compatibility (Discord, Steam, etc.)
- **xdg-desktop-portal-gnome** for better screen sharing
- **GDM** (GNOME Display Manager) with Niri session support
- **Optimized autostart** with proper service ordering
- **Hyprlock** with blur effects for secure screen locking

### Single-Command Installation

- One command installs everything
- Automatic validation before completion
- Declarative package management
- Reproducible setup

## What Gets Installed

### System Packages

- Base development tools, git, network manager
- Fish shell, Hydro prompt
- Bluetooth, SSH, power management tools...

### Development Tools

- Node.js (fnm), Python, Rust, Go
- Docker, Kubernetes, Terraform
- Neovim, code quality tools, debuggers...

### Desktop Applications

- Chromium, Zen Browser
- Nautilus file manager
- Slack, Discord
- Evince PDF viewer
- And many more...

### Wayland Stack

- **Niri** compositor
- **Waybar** status bar
- **Mako** notifications
- Screenshot, recording, clipboard tools

### Gaming

- **Steam** with Wayland optimizations
- **Gamescope** for compositing and scaling
- **MangoHUD** for performance overlays
- **Proton** for Windows game compatibility

**Steam Wayland Fix**: Steam is configured with `-system-composer -no-cef-sandbox` flags in `~/.local/share/applications/steam.desktop` to fix black screen issues on Wayland. The `gaming.sh` setup script automatically applies these flags to the Steam desktop entry and all its actions (Store, Community, Library, etc.).

### Unified Management

This setup includes a central manager script `dofs` (symlinked to `~/.local/bin/dofs`) to simplify everyday tasks:

```bash
# Run the full installation (supports all bootstrap.sh flags)
dofs install
dofs install --dotfiles-only  # Only apply dotfiles
dofs install --ansible-only   # Only run Ansible config setup
dofs install --update         # Update existing installation
# Update everything (DNF, Flatpak, Nvim, Fish plugins)
dofs update
# Run a comprehensive health check (binaries, services, configs, etc.)
dofs doctor
# Verify your configuration and installation
dofs verify
# Generate keybindings documentation
dofs docs
# Uninstall configurations and symlinks managed by dofs
dofs uninstall
```

## Folder Structure

```
dofs/
├── ansible/              # System configuration (Ansible)
│   ├── roles/           # Ansible roles (packages, desktop, dotfiles, etc.)
│   ├── playbook.yml     # Main playbook
│   └── inventory        # Inventory file
├── home/                # Dotfiles managed by chezmoi
│   ├── .chezmoi.yaml.tmpl
│   ├── .chezmoiignore
│   └── dot_config/      # ~/.config contents
├── scripts/             # Utility scripts
│   ├── maintenance/     # update-all, doctor, etc.
│   └── setup/          # verify, etc.
├── system/              # System-level configs (optional)
├── bootstrap.sh        # Main entry point
└── dofs               # CLI management tool
```

**Key Principles:**

- **Ansible** handles system configuration and package installation
- **chezmoi** manages user dotfiles in `home/`
- **Scripts** provide standalone maintenance utilities

## Customization

### Add a New Package

Edit the relevant file in `packages/`:

```bash
# Add to development tools
echo "my-new-package" >> packages/development.txt

# Reinstall
./install.sh
```

## Troubleshooting

### Niri won't start

- Check if Wayland is supported: `echo $WAYLAND_DISPLAY`
- Verify Niri is installed: `which niri`
- Check logs: `journalctl -u niri`

### Packages not installing

- Check internet connection
- Try manual install: `sudo dnf install package-name`
- For Flatpak apps: `flatpak install package-name`

## Keybindings

For a detailed and auto-generated list of all keybindings for Niri and Neovim, please see the [KEYBINDINGS.md](KEYBINDINGS.md) file.

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

## 📓 Obsidian Google Drive Sync

This setup uses **rclone bisync** to keep a local copy of your notes synchronized bidirectionally with Google Drive.

1. **Authenticate**: Run `rclone config` and create a remote named `gdrive`. For best results, create your own **Google OAuth Client ID** in the Google Cloud Console to avoid rate limiting. (Path: _APIs & Services > Credentials > Create Credentials > OAuth client ID_).
2. **Enable API**: Ensure the **Google Drive API** is enabled in your [Google Cloud Console](https://console.developers.google.com/apis/api/drive.googleapis.com/overview).
3. **Setup**: Run `bash ~/dofs/scripts/setup/obsidian.sh`. This initializes the vault and enables background sync.
4. **Use**:
   - **Manual Sync**: Press `<leader>oz` in Neovim to trigger an immediate sync.
   - **Search**: Use `<leader>os` to search your notes using the Snacks picker.
   - **Quick Note**: Use `<leader>on` to create a new note from anywhere.
5. **Performance**: Since notes are stored locally in `~/vaults/google-drive`, the picker is instant. Background sync runs every 30 minutes via a systemd timer.
6. **Reliability**: Uses `rclone bisync` with `size` and `modtime` comparison for fast, reliable updates.
