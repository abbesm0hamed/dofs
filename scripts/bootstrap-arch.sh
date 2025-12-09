#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACKAGES_DIR="${REPO_ROOT}/packages"

log_step()   { printf '\e[34m==> %s\e[0m\n' "$1"; }
log_info()   { printf '\e[36m--> %s\e[0m\n' "$1"; }
log_done()   { printf '\e[32m==> %s\e[0m\n' "$1"; }
log_error()  { printf '\e[31m==> ERROR: %s\e[0m\n' "$1"; }

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    log_info "yay already installed"
    return
  fi

  log_step "Installing yay (requires sudo for base-devel/git)"
  sudo pacman -Syu --needed --noconfirm git base-devel

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' EXIT
  git clone https://aur.archlinux.org/yay.git "${tmpdir}/yay"
  pushd "${tmpdir}/yay" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  log_done "yay installed"
}

source_installers() {
  source "${SCRIPT_DIR}/install-system.sh"
  source "${SCRIPT_DIR}/install-development.sh"
  source "${SCRIPT_DIR}/install-desktop.sh"
  source "${SCRIPT_DIR}/install-wayland.sh"
}

apply_theme() {
  log_step "Applying unified Catppuccin Mocha theme"
  bash "${SCRIPT_DIR}/theme-manager.sh" set catppuccin-mocha
  log_done "Theme applied"
}

setup_symlinks() {
  log_step "Setting up dotfiles symlinks"
  
  # Create .config directory if it doesn't exist
  mkdir -p "${HOME}/.config"
  
  # List of config directories to symlink
  local configs=(
    "niri"
    "waybar"
    "mako"
    "walker"
    "fish"
    "starship"
    "ghostty"
    "nvim"
    "lazygit"
    "ranger"
    "swaylock"
    "backgrounds"
  )
  
  for config in "${configs[@]}"; do
    local src="${REPO_ROOT}/.config/${config}"
    local dst="${HOME}/.config/${config}"
    
    if [ -d "$src" ]; then
      if [ -L "$dst" ]; then
        log_info "Symlink already exists: $config"
      elif [ -d "$dst" ]; then
        log_info "Directory exists (backing up): $config"
        mv "$dst" "${dst}.bak.$(date +%s)"
        ln -s "$src" "$dst"
        log_done "Symlinked: $config"
      else
        ln -s "$src" "$dst"
        log_done "Symlinked: $config"
      fi
    fi
  done
}

main() {
  log_step "Bootstrap starting (Arch/CachyOS)"
  log_step "Ensuring yay is available"
  ensure_yay

  source_installers

  install_system
  install_development
  install_desktop
  install_wayland

  setup_symlinks
  apply_theme

  log_done "Bootstrap finished - your Arch setup is ready!"
}

main "$@"
