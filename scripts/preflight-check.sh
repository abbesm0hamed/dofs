#!/bin/bash
# Pre-flight checks for niri installation
# Validates system compatibility and readiness

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

log_step() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS+=1))
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS+=1))
}

echo "========================================"
echo "  Niri Setup - Pre-flight Checks"
echo "========================================"
echo ""

# Check 1: OS Compatibility
log_step "Checking OS compatibility..."
if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [[ "$ID" == "cachyos" ]] || [[ "$ID" == "arch" ]] || [[ "$ID_LIKE" == *"arch"* ]]; then
        log_success "Running on Arch-based system: $PRETTY_NAME"
    else
        log_error "Not running on Arch-based system (detected: $PRETTY_NAME)"
        log_error "This setup is designed for Arch/CachyOS"
    fi
else
    log_error "Cannot detect OS (missing /etc/os-release)"
fi

# Check 2: Internet connectivity
log_step "Checking internet connectivity..."
if ping -c 1 -W 2 archlinux.org &>/dev/null; then
    log_success "Internet connection available"
else
    log_error "No internet connection - required for package installation"
fi

# Check 3: Disk space
log_step "Checking available disk space..."
AVAILABLE_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_GB" -ge 10 ]; then
    log_success "Sufficient disk space available (${AVAILABLE_GB}GB)"
else
    log_warning "Low disk space (${AVAILABLE_GB}GB) - recommend at least 10GB free"
fi

# Check 4: Running as non-root
log_step "Checking user privileges..."
if [ "$EUID" -eq 0 ]; then
    log_error "Running as root - please run as normal user (sudo will be used when needed)"
else
    log_success "Running as non-root user"
fi

# Check 5: Sudo access
log_step "Checking sudo access..."
if sudo -n true 2>/dev/null; then
    log_success "Sudo access available (passwordless)"
elif sudo -v 2>/dev/null; then
    log_success "Sudo access available"
else
    log_error "No sudo access - required for system package installation"
fi

# Check 6: Existing desktop environments
log_step "Checking for existing desktop environments..."
EXISTING_DES=()

# Check for common DEs
if pacman -Qq gnome-shell &>/dev/null; then
    EXISTING_DES+=("GNOME")
fi
if pacman -Qq plasma-desktop &>/dev/null; then
    EXISTING_DES+=("KDE Plasma")
fi
if pacman -Qq xfce4-session &>/dev/null; then
    EXISTING_DES+=("XFCE")
fi
if pacman -Qq hyprland &>/dev/null; then
    EXISTING_DES+=("Hyprland")
fi

if [ ${#EXISTING_DES[@]} -eq 0 ]; then
    log_success "No existing desktop environments detected"
else
    log_success "Existing desktop environments detected: ${EXISTING_DES[*]}"
    echo "    These will be kept as backup options - you can switch at login"
fi

# Check 7: Display manager
log_step "Checking display manager..."
DM_DETECTED=""
if systemctl is-enabled gdm.service &>/dev/null; then
    DM_DETECTED="GDM"
elif systemctl is-enabled sddm.service &>/dev/null; then
    DM_DETECTED="SDDM"
elif systemctl is-enabled greetd.service &>/dev/null; then
    DM_DETECTED="greetd"
elif systemctl is-enabled lightdm.service &>/dev/null; then
    DM_DETECTED="LightDM"
fi

if [ -n "$DM_DETECTED" ]; then
    log_success "Display manager detected: $DM_DETECTED"
else
    log_warning "No display manager detected - will need to install one"
fi

# Check 8: Package manager (pacman/yay)
log_step "Checking package managers..."
if command -v pacman &>/dev/null; then
    log_success "pacman available"
else
    log_error "pacman not found - critical error"
fi

if command -v yay &>/dev/null; then
    log_success "yay already installed"
else
    log_warning "yay not installed - will be installed during bootstrap"
fi

# Check 9: Git
log_step "Checking git installation..."
if command -v git &>/dev/null; then
    log_success "git available"
else
    log_warning "git not installed - will be installed for yay"
fi

# Check 10: Base-devel
log_step "Checking base-devel group..."
if pacman -Qq base-devel &>/dev/null; then
    log_success "base-devel installed"
else
    log_warning "base-devel not installed - will be installed for AUR packages"
fi

# Check 11: Wayland support
log_step "Checking Wayland support..."
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    log_success "Currently running on Wayland"
elif [ -n "${DISPLAY:-}" ]; then
    log_warning "Currently running on X11 - Niri requires Wayland"
    log_warning "Niri will work after reboot/re-login"
else
    log_success "Running in TTY - Niri will work after installation"
fi

# Summary
echo ""
echo "========================================"
echo "  Pre-flight Check Summary"
echo "========================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo "System is ready for niri installation."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo "Installation can proceed, but please review warnings above."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo "Please fix the errors above before proceeding."
    exit 1
fi
