#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

error() { echo -e "${RED}✗ ERROR: $1${NC}"; ((ERRORS+=1)); }
warning() { echo -e "${YELLOW}⚠ WARNING: $1${NC}"; ((WARNINGS+=1)); }
success() { echo -e "${GREEN}✓ $1${NC}"; }

echo "=== System Validation ==="

# 1. Packages
echo -e "\nChecking packages..."
check_pkg() {
    if command -v "$1" &>/dev/null; then success "$1 installed"; else error "$1 missing"; fi
}

PACKAGES=(niri waybar mako fuzzel xwayland-satellite swaylock swayidle ghostty)
for pkg in "${PACKAGES[@]}"; do check_pkg "$pkg"; done

# 2. Config & Symlinks
echo -e "\nChecking configuration..."
[ -f ~/.config/niri/config.kdl ] && success "Niri config found" || error "Niri config missing"

check_link() {
    if [ -L "$1" ] && [ -e "$1" ]; then success "$(basename "$1") link valid"; else warning "$(basename "$1") link invalid or missing"; fi
}

LINKS=(~/.config/niri ~/.config/waybar ~/.config/mako ~/.config/fuzzel)
for link in "${LINKS[@]}"; do check_link "$link"; done

# 3. Scripts
echo -e "\nChecking scripts..."
check_script() {
    if [ -x "$1" ] && bash -n "$1" 2>/dev/null; then success "$(basename "$1") OK"; else error "$(basename "$1") failed checks"; fi
}

check_script ~/.config/niri/scripts/autostart.sh
check_script "${REPO_ROOT}/install.sh"

for script in "${REPO_ROOT}/scripts/setup/"*.sh; do
    check_script "$script"
done

# Summary
echo -e "\n=== Summary ==="
if [ $ERRORS -eq 0 ]; then
    success "Validation passed ($WARNINGS warnings)"
    exit 0
else
    error "Validation failed with $ERRORS errors"
    exit 1
fi
