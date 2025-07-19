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

# Install shell and development tools
echo_step "Installing shell and development tools..."

install_packages \
  nodejs \
  npm \
  python \
  python-pip \
  rust \
  stow \
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
  fzf \
  ripgrep \
  docker \
  docker-compose \
  github-cli \
  bat \
  zoxide \
  lsd \
  neovim \
  luarocks \
  btop \
  pacman-contrib \
  virtualbox \
  the_silver_searcher \
  geoclue2 \
  fastfetch \
  tpm \
  tmuxifier \
  fnm-bin \
  unrar \
  cava \
  gowall \
  nwg-look-bin \
  libreoffice-fresh
# zed-git \
# dolphin \
# swhkd \
# woeusb # inkscape \
# conky \
# fd \
# jq \
# ncdu \
# tldr \
# nodejs-gitmoji-cli \
# neofetch \
# zsh \

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
  trippy \
  gh-dash \
  power-profiles-daemon \
  gparted \
  less \
  filezilla \
  zip \
  xdg-utils \
  udiskie
# balena-etcher

# Install Hyprland and Wayland tools
echo_step "Installing Hyprland and Wayland tools..."
install_packages \
  kanshi \
  wlogout \
  fuzzel \
  wob \
  cliphist \
  hyprshot \
  swww

echo_step "Installing terminals emulators..."
install_packages \
  kitty \
  termius
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
  teams \
  posting \
  apidog-bin \
  tableplus
# postman-bin \
# keepassxc \
# mpv \
# vlc \
# ladybird \
# brave-bin \
# calibre \
# insomnia \

# Install fonts
echo_step "Installing fonts..."
install_packages \
  fontconfig \
  ttf-jetbrains-mono-nerd \
  ttf-victor-mono \
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
echo_success "After reboot, your system will be ready with Hyprland and all the installed software."
