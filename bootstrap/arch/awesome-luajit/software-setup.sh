#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_msg() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check for required commands
check_command() {
    if ! command -v "$1" &>/dev/null; then
        print_error "$1 is not installed."
        exit 1
    fi
}

# Function to install packages using the detected package manager
install_packages() {
    if [[ -n $AUR_HELPER ]]; then
        print_msg "Installing packages using $AUR_HELPER..."
        $AUR_HELPER -S --needed --noconfirm "$@"
    else
        print_error "No AUR helper found. Please install yay or paru first."
        exit 1
    fi
}

# System initialization
print_msg "Updating system and installing base packages..."
sudo pacman -Syu --noconfirm || { print_error "Failed to update system"; exit 1; }
sudo pacman -S --needed base-devel git --noconfirm || { print_error "Failed to install base packages"; exit 1; }

# Install yay if not present
if ! command -v yay &>/dev/null; then
    print_msg "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm) || { print_error "Failed to install yay"; exit 1; }
    rm -rf /tmp/yay
    print_success "yay installation complete"
    AUR_HELPER="yay"
else
    AUR_HELPER="yay"
    print_msg "yay is already installed"
fi

# Configure touchpad
print_msg "Configuring touchpad for tap-to-click..."
sudo pacman -S --needed xf86-input-libinput --noconfirm
sudo mkdir -p /etc/X11/xorg.conf.d/
echo 'Section "InputClass"
    Identifier "touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "ClickMethod" "clickfinger"
EndSection' | sudo tee /etc/X11/xorg.conf.d/40-libinput.conf >/dev/null

# Set yay as AUR helper
AUR_HELPER="yay"

# Window Manager and Desktop Environment
WM_PACKAGES=(
    "awesome-luajit-git"     # Window Manager
    "picom"                  # Lightweight compositor for transparency and blur
    "sxhkd"                  # Hotkey daemon
    "autotiling"             # Automatic tiling
    "rofi"                   # Application launcher
    "dunst"                  # Notification daemon
    "gammastep"              # Color temperature adjustment
    "xcolor"                 # Color picker
)

# Terminal and Shell
TERMINAL_PACKAGES=(
    "kitty"                 # Terminal emulator
    "zsh"                   # Shell
    "tmux"                  # Terminal multiplexer
    "gitmux"                # Git info for tmux
    "tpm"                   # Tmux plugin manager
    "tmuxifier"             # Tmux layout manager
)

# Development Tools
DEV_PACKAGES=(
    "base-devel"            # Development tools
    "git"                   # Version control
    "github-cli"            # GitHub CLI
    # "visual-studio-code-bin" # VS Code
    "neovim"                # Text editor
    "luarocks"              # Lua package manager
    "nodejs"                # Node.js
    "npm"                   # Node package manager
    "fnm-bin"               # Node version manager
    "python"                # Python
    "python-pip"            # Python package manager
    "rust"                  # Rust
    "sqlite"                # SQLite database
    "docker"                # Containerization
    "docker-compose"        # Container orchestration
    "lazygit"               # Git TUI
    "lazydocker"            # Docker TUI
    "postman-bin"           # API testing
    "virtualbox"            # Virtualization
)

# File Management and System Tools
SYSTEM_PACKAGES=(
    "yazi"                  # Modern terminal file manager
    # "udiskie"               # Auto-mount USB drives
    # "gparted"               # Partition editor
    # "ncdu"                  # Disk usage analyzer
    "btop"                  # System monitor
    "power-profiles-daemon" # Power management
    "pacman-contrib"        # Pacman utilities
    # "woeusb"               # Windows USB creator
    # "balena-etcher"        # USB image writer
)

# CLI Tools and Utilities
CLI_PACKAGES=(
    "fzf"                   # Fuzzy finder
    "ripgrep"               # Fast grep
    "bat"                   # Cat clone with syntax highlighting
    "lsd"                   # Modern ls replacement
    "fd"                    # Find alternative
    "jq"                    # JSON processor
    "tldr"                  # Command examples
    "zoxide"                # Smart directory jumper
    "the_silver_searcher"   # Code searching
)

# Fonts and Appearance
FONT_PACKAGES=(
    "ttf-jetbrains-mono-nerd"
    "ttf-victormono-nerd"
    "ttf-iosevka-nerd"
    "ttf-font-awesome"
    "ttf-material-design-iconic-font"
    "ttf-feather"
    "ttf-joypixels"
    "ttf-lilex"
)

# Network and Communication
NETWORK_PACKAGES=(
    "networkmanager"        # Network management
    "net-tools"             # Network utilities
    # "discord"               # Chat
    # "telegram-desktop"      # Messaging
    # "whatsapp-nativefier"   # WhatsApp
    # "slack-desktop"         # Team communication
    # "anydesk"               # Remote desktop
)

# Multimedia and Graphics
MULTIMEDIA_PACKAGES=(
    "pipewire"              # Audio/video handler
    "pipewire-pulse"        # PulseAudio replacement
    "pipewire-alsa"         # ALSA support
    "pipewire-jack"         # JACK support
    "wireplumber"           # Session manager
    "pavucontrol"           # Audio control
    # "mpv"                   # Media player
    # "vlc"                   # Media player
    # "calibre"               # E-book management
    # "inkscape"              # Vector graphics
    # "cheese"                # Webcam tool
    "flameshot"             # Screenshot tool
    "imagemagick"           # Image manipulation
    "python-ueberzug"       # Image previews in terminal
)

# Monitor Management
MONITOR_PACKAGES=(
    "arandr"                # Monitor layout GUI
    "autorandr"             # Auto monitor profile
    "ddcutil"               # Monitor control
    "xrandr"                # Screen management
)

# Fun and Customization
EXTRA_PACKAGES=(
    "fastfetch"             # System info (faster than neofetch)
    "pokemon-colorscripts-git"
    "pipes.sh"              # Terminal animation
    "cava"                  # Audio visualizer
)

# Browser and Web
BROWSER_PACKAGES=(
    # "brave-bin"             # Browser
    "xdg-utils"             # Open default applications
)

# Install all packages by category
categories=(
    "WM_PACKAGES[@]"
    "TERMINAL_PACKAGES[@]"
    "DEV_PACKAGES[@]"
    "SYSTEM_PACKAGES[@]"
    "CLI_PACKAGES[@]"
    "FONT_PACKAGES[@]"
    "NETWORK_PACKAGES[@]"
    "MULTIMEDIA_PACKAGES[@]"
    "MONITOR_PACKAGES[@]"
    "EXTRA_PACKAGES[@]"
    "BROWSER_PACKAGES[@]"
)

for category in "${categories[@]}"; do
    print_msg "Installing ${category%[@]} packages..."
    install_packages "${!category}"
done

# Post-installation setup
print_msg "Setting up services and configurations..."

# Enable system services
sudo systemctl enable --now docker
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# Set up ZSH
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    print_msg "Setting up Zsh as default shell..."
    chsh -s /usr/bin/zsh
fi

# Install Zinit
if [ ! -d "$HOME/.zinit" ]; then
    print_msg "Installing Zinit..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/master/scripts/install.sh)"
fi

# Set up Tmux Plugin Manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    print_msg "Setting up Tmux Plugin Manager..."
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Create Awesome config directory if it doesn't exist
AWESOME_CONFIG_DIR="$HOME/.config/awesome"
if [ ! -d "$AWESOME_CONFIG_DIR" ]; then
    print_msg "Creating Awesome config directory..."
    mkdir -p "$AWESOME_CONFIG_DIR"
fi

# Copy default config if it doesn't exist
if [ ! -f "$AWESOME_CONFIG_DIR/rc.lua" ]; then
    print_msg "Copying default Awesome config..."
    cp /etc/xdg/awesome/rc.lua "$AWESOME_CONFIG_DIR/"
fi

# Set up autostart directory and entries
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

# Create autostart entries
cat > "$AUTOSTART_DIR/picom.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Picom
Exec=picom -b --experimental-backends
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

# Set up monitor hot-plug rules
sudo tee /etc/udev/rules.d/95-monitor-hotplug.rules << EOF
ACTION=="change", SUBSYSTEM=="drm", RUN+="/usr/bin/autorandr --change --default default"
EOF

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

print_success "Setup completed successfully!"
print_msg "Please log out and log back in to start using your new setup."
print_msg "You may want to customize your Awesome config at: $AWESOME_CONFIG_DIR/rc.lua"
