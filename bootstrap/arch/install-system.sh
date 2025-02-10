#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Error log file
ERROR_LOG="installation_errors.log"

echo_step() {
    echo -e "${BLUE}==> ${1}${NC}"
}

echo_success() {
    echo -e "${GREEN}==> ${1}${NC}"
}

echo_error() {
    echo -e "${RED}==> ERROR: ${1}${NC}"
    echo "$(date): $1" >> "$ERROR_LOG"
}

# Function to install packages with error handling
install_packages() {
    local failed_packages=()
    for package in "$@"; do
        if ! yay -S --needed --noconfirm "$package"; then
            echo_error "Failed to install: $package"
            failed_packages+=("$package")
        fi
    done
    
    if [ ${#failed_packages[@]} -ne 0 ]; then
        echo_error "The following packages failed to install:"
        printf '%s\n' "${failed_packages[@]}" | tee -a "$ERROR_LOG"
    fi
}

# Update the system
echo_step "Updating the system..."
sudo pacman -Syu --noconfirm

# Install base development tools
echo_step "Installing base development tools..."
sudo pacman -S --needed base-devel git --noconfirm

# Install yay AUR helper
echo_step "Installing yay AUR helper..."
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# Configure touchpad for tap-to-click
echo_step "Configuring touchpad..."
sudo pacman -S xf86-input-libinput --noconfirm
sudo mkdir -p /etc/X11/xorg.conf.d/
echo 'Section "InputClass"
    Identifier "touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "ClickMethod" "clickfinger"
EndSection' | sudo tee /etc/X11/xorg.conf.d/40-libinput.conf >/dev/null

# Install i3ass (i3 assistance scripts)
echo_step "Installing i3ass..."
cd "$HOME"
if [ ! -d "i3ass" ]; then
    git clone https://github.com/budlabs/i3ass.git
    cd i3ass
    make
    sudo make install
    cd ..
fi

# Install shell and development tools
echo_step "Installing shell and development tools..."
install_packages \
    zsh \
    nodejs \
    npm \
    python \
    python-pip \
    rust \
    stow \
    neofetch \
    pokemon-colorscripts-git \
    sqlite \
    yazi \
    pipes.sh \
    ranger \
    imagemagick \
    python-ueberzug \
    tmux \
    gitmux \
    lazygit \
    lazydocker \
    nodejs-gitmoji-cli \
    fzf \
    ripgrep \
    docker \
    docker-compose \
    github-cli \
    bat \
    tldr \
    zoxide \
    lsd \
    neovim \
    luarocks \
    btop \
    fd \
    jq \
    ncdu \
    pacman-contrib \
    # inkscape \
    # woeusb \
    virtualbox \
    the_silver_searcher \
    xrandr \
    geoclue2 \
    espanso-x11-git \
    conky \
    fastfetch \
    tpm \
    tmuxifier \
    fnm-bin \
    unrar \
    cava \
    lxappearance

# Install system utilities
echo_step "Installing system utilities..."
install_packages \
    networkmanager \
    brightnessctl \
    power-profiles-daemon \
    gparted \
    pavucontrol \
    xdg-utils \
    udiskie \
    # balena-etcher

# Install window manager and desktop tools
echo_step "Installing window manager and desktop tools..."
install_packages \
    i3-wm \
    sxhkd \
    autotiling \
    rofi \
    # polybar \
    i3status-rust \
    dunst \
    picom-simpleanims-git \
    flameshot \
    feh \
    gammastep \
    xcolor \
    autorandr \
    arandr \
    kvantum

# Install applications
echo_step "Installing applications..."
install_packages \
    ladybrid \
    brave-bin \
    # visual-studio-code-bin \
    windsurf \
    # postman-bin \
    # keepassxc \
    # mpv \
    # vlc \
    # calibre \
    discord \
    slack-desktop \
    telegram-desktop

# Install fonts
echo_step "Installing fonts..."
install_packages \
    ttf-jetbrains-mono-nerd \
    ttf-victormono-nerd \
    ttf-iosevka-nerd \
    ttf-font-awesome \
    ttf-commit-mono \
    ttf-nerd-fonts-symbols \
    ttf-nerd-fonts-emoji \
    ttf-material-design-iconic-font \
    ttf-feather \
    ttf-joypixels \
    ttf-lilex \
    noto-fonts \

# Change default shell to zsh
echo_step "Changing default shell to zsh..."
if [[ $SHELL != "/usr/bin/zsh" ]]; then
    chsh -s /usr/bin/zsh
fi

# Enable and start services
echo_step "Enabling system services..."
sudo systemctl enable --now docker.service
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now power-profiles-daemon.service

# Add user to docker group
echo_step "Adding user to docker group..."
sudo usermod -aG docker $USER

if [ -s "$ERROR_LOG" ]; then
    echo_error "Installation completed with some errors. Check $ERROR_LOG for details."
    echo_success "You can try to manually install failed packages later."
else
    echo_success "Installation completed successfully!"
fi

echo_success "Please reboot your system to apply all changes."
echo_success "After reboot, your system will be ready with all the installed software."
