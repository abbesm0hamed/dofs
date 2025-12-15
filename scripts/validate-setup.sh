#!/bin/bash
# Niri Setup Validation Script
# Checks that everything is properly configured before first boot

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ERRORS=0
WARNINGS=0

echo "=== Niri Setup Validation ==="
echo ""

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
    ((ERRORS+=1))
}

warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
    ((WARNINGS+=1))
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# ============================================================================
# Check Critical Packages
# ============================================================================

echo "[1/7] Checking critical packages..."

check_package() {
    if command -v "$1" &>/dev/null || pacman -Q "$1" &>/dev/null 2>&1; then
        success "$1 installed"
        return 0
    else
        error "$1 not installed"
        return 1
    fi
}

check_package "niri"
check_package "waybar"
check_package "mako"
check_package "fuzzel"
check_package "xwayland-satellite"
check_package "swaylock"
check_package "swayidle"
check_package "ghostty" || warning "ghostty not found - terminal keybindings may not work"

echo ""

# ============================================================================
# Check Niri Configuration
# ============================================================================

echo "[2/7] Validating Niri configuration..."

if [ -f ~/.config/niri/config.kdl ]; then
    if command -v niri &>/dev/null; then
        if niri validate ~/.config/niri/config.kdl 2>&1; then
            success "Niri config is valid"
        else
            error "Niri config has errors"
        fi
    else
        warning "Cannot validate config - niri not installed yet"
    fi
else
    error "Niri config not found at ~/.config/niri/config.kdl"
fi

echo ""

# ============================================================================
# Check Scripts
# ============================================================================

echo "[3/7] Checking scripts..."

check_script() {
    if [ -f "$1" ]; then
        if [ -x "$1" ]; then
            success "$(basename "$1") is executable"
        else
            error "$(basename "$1") is not executable - run: chmod +x $1"
        fi

        # Check for bash syntax errors
        if bash -n "$1" 2>&1; then
            success "$(basename "$1") has no syntax errors"
        else
            error "$(basename "$1") has syntax errors"
        fi
    else
        error "Script not found: $1"
    fi
}

check_script ~/.config/niri/scripts/autostart.sh
check_script "${REPO_ROOT}/install.sh"
check_script "${REPO_ROOT}/scripts/theme-manager.sh"

echo ""

# ============================================================================
# Check Symlinks
# ============================================================================

echo "[4/7] Checking symlinks..."

check_symlink() {
    if [ -L "$1" ]; then
        if [ -e "$1" ]; then
            success "$(basename "$1") symlink is valid"
        else
            error "$(basename "$1") symlink is broken"
        fi
    elif [ -d "$1" ] || [ -f "$1" ]; then
        warning "$(basename "$1") exists but is not a symlink"
    else
        warning "$(basename "$1") not found"
    fi
}

check_symlink ~/.config/niri
check_symlink ~/.config/waybar
check_symlink ~/.config/mako
check_symlink ~/.config/fuzzel

echo ""

# ============================================================================
# Check Theme Files
# ============================================================================

echo "[5/7] Checking theme files..."

if [ -f ~/.config/niri/theme.conf ]; then
    success "Niri theme config exists"
else
    error "Niri theme config not found"
fi

if [ -d ~/.config/theme/default ]; then
    success "Default theme exists"
else
    warning "Default theme directory not found"
fi

echo ""

# ============================================================================
# Check Wallpaper
# ============================================================================

echo "[6/7] Checking wallpaper..."

if [ -f ~/.config/backgrounds/snaky.jpg ] || [ -f ~/.config/backgrounds/default.png ]; then
    success "Default wallpaper exists"
else
    warning "Default wallpaper not found - autostart may fail to set wallpaper"
    echo "  Place your wallpaper at: ~/.config/backgrounds/blurry-snaky.jpg"
fi

echo ""

# ============================================================================
# Check Services
# ============================================================================

echo "[7/7] Checking system services..."

if systemctl --user is-enabled pipewire &>/dev/null; then
    success "PipeWire is enabled"
else
    warning "PipeWire is not enabled - run: systemctl --user enable pipewire pipewire-pulse wireplumber"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================

echo "=== Validation Summary ==="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Your setup is ready.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Reboot: reboot"
    echo "  2. Niri should start automatically"
    echo "  3. Press Mod+K to see all keybindings"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation completed with $WARNINGS warning(s)${NC}"
    echo "Your setup should work, but review warnings above."
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo "Please fix the errors above before proceeding."
    exit 1
fi
