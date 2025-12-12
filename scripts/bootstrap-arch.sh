#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACKAGES_DIR="${REPO_ROOT}/packages"
LOG_FILE="/tmp/niri-bootstrap.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() { printf "${BLUE}==> %s${NC}\n" "$1" | tee -a "$LOG_FILE"; }
log_info() { printf "${BLUE}--> %s${NC}\n" "$1" | tee -a "$LOG_FILE"; }
log_done() { printf "${GREEN}==> %s${NC}\n" "$1" | tee -a "$LOG_FILE"; }
log_error() { printf "${RED}==> ERROR: %s${NC}\n" "$1" | tee -a "$LOG_FILE"; }
log_warning() { printf "${YELLOW}==> WARNING: %s${NC}\n" "$1" | tee -a "$LOG_FILE"; }

# Parse arguments
SKIP_PREFLIGHT=false
SKIP_INSTALLED=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-preflight)
      SKIP_PREFLIGHT=true
      shift
      ;;
    --skip-installed)
      SKIP_INSTALLED=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--skip-preflight] [--skip-installed]"
      exit 1
      ;;
  esac
done

# Initialize log
echo "========================================" >"$LOG_FILE"
echo "  Niri Bootstrap - $(date)" >>"$LOG_FILE"
echo "========================================" >>"$LOG_FILE"
echo "" >>"$LOG_FILE"

echo ""
echo "=========================================="
echo "  Niri Setup Bootstrap"
echo "=========================================="
echo ""
log_info "Log file: $LOG_FILE"
echo ""

# Phase 0: Pre-flight checks
if [ "$SKIP_PREFLIGHT" = false ]; then
  log_step "Phase 0: Running pre-flight checks..."
  if bash "${SCRIPT_DIR}/preflight-check.sh"; then
    log_done "Pre-flight checks passed"
  else
    log_error "Pre-flight checks failed"
    log_error "Fix the errors above or run with --skip-preflight to continue anyway"
    exit 1
  fi
  echo ""
else
  log_warning "Skipping pre-flight checks (--skip-preflight)"
  echo ""
fi

# Phase 1: Ensure yay is available
ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    log_info "yay already installed"
    return
  fi

  log_step "Phase 1: Installing yay (requires sudo for base-devel/git)"
  sudo pacman -Syu --needed --noconfirm git base-devel

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' EXIT
  git clone https://aur.archlinux.org/yay.git "${tmpdir}/yay"
  pushd "${tmpdir}/yay" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  log_done "yay installed"
}

log_step "Phase 1: Ensuring yay is available"
ensure_yay
echo ""

# Phase 2: Source package installers
source_installers() {
  source "${SCRIPT_DIR}/install-system.sh"
  source "${SCRIPT_DIR}/install-development.sh"
  source "${SCRIPT_DIR}/install-desktop.sh"
  source "${SCRIPT_DIR}/install-wayland.sh"
}

source_installers

# Phase 3: Install packages
log_step "Phase 2: Installing packages..."
echo ""

install_system
echo ""
install_development
echo ""
install_desktop
echo ""
install_wayland
echo ""

log_done "All packages installed"
echo ""

# Phase 4: Setup symlinks
setup_symlinks() {
  log_step "Phase 3: Setting up dotfiles symlinks"

  # Create .config directory if it doesn't exist
  mkdir -p "${HOME}/.config"

  # List of config directories to symlink
  local configs=(
    "niri"
    "waybar"
    "mako"
    "fuzzel"
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
      elif [ -d "$dst" ] || [ -f "$dst" ]; then
        log_warning "Backing up existing: $config"
        mv "$dst" "${dst}.bak.$(date +%s)"
        ln -s "$src" "$dst"
        log_done "Symlinked: $config"
      else
        ln -s "$src" "$dst"
        log_done "Symlinked: $config"
      fi
    else
      log_warning "Source not found, skipping: $config"
    fi
  done
}

setup_symlinks
echo ""

# Phase 5: Apply theme (after symlinks are verified)
apply_theme() {
  log_step "Phase 4: Applying unified Catppuccin Mocha theme"

  # Verify symlinks exist before applying theme
  if [ ! -L "${HOME}/.config/niri" ]; then
    log_error "Niri config symlink not found, skipping theme"
    return 1
  fi

  bash "${SCRIPT_DIR}/theme-manager.sh" set catppuccin-mocha || {
    log_warning "Theme application had issues (this is OK during initial setup)"
  }
  log_done "Theme applied"
}

apply_theme
echo ""

# Phase 6: Setup display manager
log_step "Phase 5: Setting up display manager"
if bash "${SCRIPT_DIR}/setup-display-manager.sh"; then
  log_done "Display manager configured"
else
  log_warning "Display manager setup had issues"
fi
echo ""

# Phase 7: Final validation
log_step "Phase 6: Validating installation"
if bash "${SCRIPT_DIR}/verify-installation.sh"; then
  log_done "Validation passed"
else
  log_warning "Validation found some issues - review above"
fi
echo ""

# Success!
echo "=========================================="
echo "  Bootstrap Complete!"
echo "=========================================="
echo ""
log_done "Your niri setup is ready!"
echo ""
log_info "Next steps:"
echo "  1. Reboot your system: sudo reboot"
echo "  2. At login screen, select 'Niri' from session menu"
echo "  3. Log in with your credentials"
echo "  4. Press Mod+Return to open terminal"
echo "  5. Press Alt+P to open application launcher"
echo ""
log_info "Troubleshooting:"
echo "  - View log: cat $LOG_FILE"
echo "  - Re-run verification: bash scripts/verify-installation.sh"
echo "  - Check autostart log: cat \$XDG_RUNTIME_DIR/niri-autostart.log"
echo ""
log_warning "Your existing desktop environments (e.g., GNOME) are still available"
log_warning "You can switch between them at the login screen"
echo ""
