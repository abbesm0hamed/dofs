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
  echo "$(date): $1" >>"$ERROR_LOG"
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
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
fi

# Install php version manager phpenv
echo_step "Installing php version manager phpenv..."
git clone https://github.com/phpenv/phpenv.git ~/.phpenv
git clone https://github.com/php-build/php-build.git ~/.phpenv/plugins/php-build
if [ -d "/tmp/php-build" ]; then
  echo "Current /tmp/php-build ownership:"
  ls -l /tmp/php-build
  sudo chown -R $USER:$USER /tmp/php-build
  chmod -R u+w /tmp/php-build
  echo_success "Phpenv build directory permissions fixed"
else
  echo_error "Phpenv build directory not found"
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
  virtualbox \
  the_silver_searcher \
  geoclue2 \
  espanso-wayland-git \
  fastfetch \
  tpm \
  tmuxifier \
  fnm-bin \
  unrar \
  cava \
  gowall \
  nwg-look-bin \
  libreoffice-fresh \
  cups \
  cups-filters \
  cups-pdf
# inkscape \
# swhkd # conky \
# woeusb \

echo_step "Installing bun..."
if ! command -v bun &>/dev/null; then
  curl -fsSL https://bun.sh/install | bash
  if ! command -v bun &>/dev/null; then
    echo "Bun installation failed!"
    exit 1
  fi
  echo "Bun installed successfully!"
else
  echo "Bun is already installed"
fi

# Install TPM if it doesn't exist
echo_step "Checking for Tmux Plugin Manager (TPM)..."
TPM_PATH="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_PATH" ]; then
  echo_step "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"
  if [ $? -eq 0 ]; then
    echo_success "TPM installed successfully"
    # Make TPM executable
    chmod +x "$TPM_PATH/tpm"
    chmod +x "$TPM_PATH/scripts/install_plugins.sh"
  else
    echo_error "Failed to install TPM"
  fi
else
  echo_success "TPM is already installed"
fi

# Install system utilities
echo_step "Installing system utilities..."
install_packages \
  networkmanager \
  trippy \
  gh-dash \
  brightnessctl \
  power-profiles-daemon \
  gparted \
  less \
  filezilla \
  pavucontrol \
  xdg-utils \
  udiskie
# balena-etcher

# Install Sway and Wayland tools
echo_step "Installing Sway and Wayland tools..."
install_packages \
  sway \
  swaylock \
  swayidle \
  swaybg \
  wofi \
  wlogout \
  mako \
  grim \
  slurp \
  wl-clipboard \
  wf-recorder \
  kanshi \
  wayshot \
  wlogout \
  fuzzel \
  wlsunset \
  hyprpicker-git \
  swaync \
  wob \
  xdg-desktop-portal-wlr

# Configure input devices for Sway
echo_step "Configuring input devices for Sway..."
mkdir -p "$HOME/.config/sway/config.d"
cp "$(dirname "$0")/input.conf" "$HOME/.config/sway/config.d/"

echo_step "Installing terminals emulators..."
install_packages \
  kitty \
  termuis
# ghostty \
# alacritty \
# wezterm \

# Install applications
echo_step "Installing applications..."
install_packages \
  zen-browser-bin \
  windsurf \
  discord \
  telegram-desktop \
  whatsapp-for-linux \
  thunderbird \
  slack-desktop \
  posting \
  postman-bin
# ladybird \
# keepassxc \
# brave-bin \
# mpv \
# calibre \
# vlc \
# insomnia \

# Install fonts
echo_step "Installing fonts..."
install_packages \
  fontconfig \
  ttf-jetbrains-mono-nerd \
  ttf-victor-mono-nerd \
  ttf-iosevka-nerd \
  ttf-font-awesome \
  ttf-commit-mono \
  ttf-nerd-fonts-symbols \
  ttf-nerd-fonts-emoji \
  ttf-material-design-iconic-font \
  ttf-feather \
  ttf-joypixels \
  ttf-lilex \
  ttf-amiri
# arabic fonts
# noto-fonts \
# ttf-cairo \

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
