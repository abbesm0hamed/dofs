#!/bin/bash
# Verify Niri Installation
# Comprehensive post-installation validation

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_step() { echo -e "${BLUE}→${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS+=1))
}
log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS+=1))
}

echo "========================================"
echo "  Niri Installation Verification"
echo "========================================"
echo ""

# Check 1: Critical binaries
log_step "Checking critical binaries..."
CRITICAL_BINS=(
    "niri"
    "waybar"
    "mako"
    "fuzzel"
    "swaylock"
    "fish"
    "starship"
)

for bin in "${CRITICAL_BINS[@]}"; do
    if command -v "$bin" &>/dev/null; then
        log_success "$bin installed"
    else
        log_error "$bin not found"
    fi
done

# Check 2: Optional binaries
log_step "Checking optional binaries..."
OPTIONAL_BINS=(
    "ghostty"
    "swww"
    "grim"
    "slurp"
    "satty"
    "cliphist"
    "xwayland-satellite"
)

for bin in "${OPTIONAL_BINS[@]}"; do
    if command -v "$bin" &>/dev/null; then
        log_success "$bin installed"
    else
        log_warning "$bin not found (optional)"
    fi
done

# Check 3: Symlinks
log_step "Checking configuration symlinks..."
CONFIG_DIRS=(
    "niri"
    "waybar"
    "mako"
    "fuzzel"
    "fish"
)

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -L "$HOME/.config/$dir" ]; then
        target=$(readlink "$HOME/.config/$dir")
        if [ -d "$target" ]; then
            log_success "$dir → $target"
        else
            log_error "$dir symlink broken (points to non-existent: $target)"
        fi
    elif [ "$dir" = "fish" ] && [ -d "$HOME/.config/$dir" ]; then
        # fish files are stowed individually, so the directory itself is not a symlink
        log_success "fish directory present (files stowed individually)"
    elif [ -d "$HOME/.config/$dir" ]; then
        log_warning "$dir exists but is not a symlink"
    else
        log_error "$dir not found"
    fi
done

log_step "Checking Starship configuration..."
if [ -L "$HOME/.config/starship.toml" ]; then
    target=$(readlink "$HOME/.config/starship.toml")
    if [ -f "$target" ]; then
        log_success "starship.toml → $target"
    else
        log_error "starship.toml symlink broken (points to non-existent: $target)"
    fi
elif [ -f "$HOME/.config/starship.toml" ]; then
    log_warning "starship.toml exists but is not a symlink"
else
    log_warning "starship.toml not found"
fi

# Check 4: Niri config validation
log_step "Validating niri configuration..."
if command -v niri &>/dev/null; then
    if [ -f "$HOME/.config/niri/config.kdl" ]; then
        if niri validate --config "$HOME/.config/niri/config.kdl" &>/dev/null; then
            log_success "Niri config is valid"
        else
            log_error "Niri config has syntax errors"
            log_error "Run: niri validate --config ~/.config/niri/config.kdl"
        fi
    else
        log_error "Niri config file not found"
    fi
else
    log_warning "Cannot validate config (niri not installed)"
fi

# Check 5: Theme files
log_step "Checking theme files..."
THEME_FILES=(
    "$HOME/.config/niri/theme.conf"
    "$HOME/.config/theme-current/waybar.css"
    "$HOME/.config/mako/config"
)

for file in "${THEME_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_success "$(basename "$file") exists"
    else
        log_warning "$(basename "$file") not found"
    fi
done

# Check 6: Autostart script
log_step "Checking autostart script..."
if [ -f "$HOME/.config/niri/scripts/autostart.sh" ]; then
    if [ -x "$HOME/.config/niri/scripts/autostart.sh" ]; then
        log_success "Autostart script exists and is executable"
    else
        log_warning "Autostart script not executable"
        chmod +x "$HOME/.config/niri/scripts/autostart.sh"
        log_success "Made autostart script executable"
    fi
else
    log_error "Autostart script not found"
fi

# Check 7: Display manager session
log_step "Checking display manager session..."
if [ -f "/usr/share/wayland-sessions/niri.desktop" ]; then
    log_success "Niri session file exists"
else
    log_warning "Niri session file not found"
    log_warning "Run: sudo bash scripts/setup-display-manager.sh"
fi

if [ -x "/usr/bin/niri-session" ]; then
    log_success "niri-session exists: /usr/bin/niri-session"
elif [ -x "/usr/local/bin/niri-session" ]; then
    log_success "niri-session exists: /usr/local/bin/niri-session"
elif [ -f "/usr/bin/niri-session" ] || [ -f "/usr/local/bin/niri-session" ]; then
    log_warning "niri-session exists but is not executable"
else
    log_warning "niri-session not found"
fi

# Check 8: XDG portals
log_step "Checking XDG desktop portals..."
if pacman -Qq xdg-desktop-portal &> /dev/null; then
    log_success "xdg-desktop-portal installed"
else
    log_error "xdg-desktop-portal not installed"
fi

if pacman -Qq xdg-desktop-portal-gtk &> /dev/null; then
    log_success "xdg-desktop-portal-gtk installed"
else
    log_warning "xdg-desktop-portal-gtk not installed"
fi

if pacman -Qq xdg-desktop-portal-gnome &> /dev/null; then
    log_success "xdg-desktop-portal-gnome installed"
else
    log_warning "xdg-desktop-portal-gnome not installed (optional)"
fi

# Check portal configuration
if [ -f "$HOME/.config/xdg-desktop-portal/niri-portals.conf" ]; then
    log_success "Portal configuration exists"
else
    log_warning "Portal configuration not found"
fi

# Runtime check (only if in a session)
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    log_step "Checking portal services (runtime)..."
    
    if systemctl --user is-active xdg-desktop-portal.service &> /dev/null; then
        log_success "xdg-desktop-portal service is running"
    else
        log_warning "xdg-desktop-portal service not running"
    fi
    
    if systemctl --user is-active xdg-desktop-portal-gtk.service &> /dev/null; then
        log_success "xdg-desktop-portal-gtk service is running"
    else
        log_warning "xdg-desktop-portal-gtk service not running"
        log_warning "File pickers may not work - check: systemctl --user status xdg-desktop-portal-gtk"
    fi
fi

# Check 9: Audio system
log_step "Checking audio system..."
if pacman -Qq pipewire &>/dev/null; then
    log_success "PipeWire installed"
else
    log_error "PipeWire not installed"
fi

if pacman -Qq wireplumber &>/dev/null; then
    log_success "WirePlumber installed"
else
    log_error "WirePlumber not installed"
fi

# Check 10: Wallpaper
log_step "Checking wallpaper..."
WALLPAPER="$HOME/.config/backgrounds/snaky.jpg"
if [ -f "$WALLPAPER" ]; then
    log_success "Default wallpaper exists"
else
    log_warning "Default wallpaper not found: $WALLPAPER"
fi

# Summary
echo ""
echo "========================================"
echo "  Verification Summary"
echo "========================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your niri setup is complete and ready to use."
    echo ""
    echo "Next steps:"
    echo "  1. Reboot your system: sudo reboot"
    echo "  2. At login screen, select 'Niri' session"
    echo "  3. Press Mod+Return to open terminal"
    echo "  4. Press Alt+P to open application launcher"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Installation mostly complete, but some optional components are missing."
    echo "Review warnings above."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Installation incomplete. Please fix errors above."
    echo ""
    echo "Common fixes:"
    echo "  - Re-run installer: bash install.sh"
    echo "  - Check logs: cat ~/install.log"
    echo "  - Manual package install: yay -S <package-name>"
    exit 1
fi
