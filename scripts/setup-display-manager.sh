#!/bin/bash
# Display Manager Setup for Niri
# Configures display manager to show Niri as a session option

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() { echo -e "${BLUE}→${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "========================================"
echo "  Niri Display Manager Setup"
echo "========================================"
echo ""

# Detect which display manager is installed
detect_display_manager() {
    if systemctl is-enabled gdm.service &>/dev/null; then
        echo "gdm"
    elif systemctl is-enabled sddm.service &>/dev/null; then
        echo "sddm"
    elif systemctl is-enabled lightdm.service &>/dev/null; then
        echo "lightdm"
    else
        echo "none"
    fi
}

# Create niri session file
create_niri_session() {
    log_step "Creating niri session file..."
    
    local session_file="/usr/share/wayland-sessions/niri.desktop"
    
    sudo tee "$session_file" > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=Scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
DesktopNames=niri
EOF
    
    log_success "Created $session_file"
}

# Create niri-session wrapper script
create_niri_session_wrapper() {
    log_step "Creating niri-session wrapper..."
    
    local wrapper="/usr/local/bin/niri-session"
    
    sudo tee "$wrapper" > /dev/null << 'EOF'
#!/bin/sh
# Niri session wrapper
# Sets up environment and starts niri

# Set XDG environment
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=niri
export XDG_CURRENT_DESKTOP=niri

# Qt Wayland support
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# Firefox Wayland
export MOZ_ENABLE_WAYLAND=1

# Electron apps
export ELECTRON_OZONE_PLATFORM_HINT=wayland

# Start niri
exec niri
EOF
    
    sudo chmod +x "$wrapper"
    log_success "Created $wrapper"
}

# Setup for GDM
setup_gdm() {
    log_step "Configuring GDM for Niri..."
    
    # GDM automatically picks up sessions from /usr/share/wayland-sessions/
    # Just need to ensure the session file exists
    
    log_success "GDM configured - Niri will appear in session list"
}

# Setup for SDDM
setup_sddm() {
    log_step "Configuring SDDM for Niri..."
    
    # SDDM also picks up from /usr/share/wayland-sessions/
    # May need to refresh session list
    
    if [ -f /etc/sddm.conf ]; then
        log_success "SDDM configured - Niri will appear in session list"
    else
        log_warning "SDDM config not found, but session should still work"
    fi
}

# Setup for LightDM
setup_lightdm() {
    log_step "Configuring LightDM for Niri..."
    
    # LightDM uses /usr/share/wayland-sessions/ for Wayland sessions
    log_success "LightDM configured - Niri will appear in session list"
}

# Install display manager if none exists
install_display_manager() {
    log_warning "No display manager detected"
    echo ""
    echo "Available options:"
    echo "  1) GDM (GNOME Display Manager) - recommended if you have GNOME"
    echo "  2) SDDM (Simple Desktop Display Manager) - lightweight"
    echo "  3) LightDM - very lightweight"
    echo "  4) Skip - I'll install one manually"
    echo ""
    read -p "Choose option [1-4]: " choice
    
    case $choice in
        1)
            log_step "Installing GDM..."
            sudo pacman -S --needed --noconfirm gdm
            sudo systemctl enable gdm.service
            log_success "GDM installed and enabled"
            echo "gdm"
            ;;
        2)
            log_step "Installing SDDM..."
            sudo pacman -S --needed --noconfirm sddm
            sudo systemctl enable sddm.service
            log_success "SDDM installed and enabled"
            echo "sddm"
            ;;
        3)
            log_step "Installing LightDM..."
            sudo pacman -S --needed --noconfirm lightdm lightdm-gtk-greeter
            sudo systemctl enable lightdm.service
            log_success "LightDM installed and enabled"
            echo "lightdm"
            ;;
        4)
            log_warning "Skipping display manager installation"
            log_warning "You'll need to start niri manually or install a DM later"
            echo "none"
            ;;
        *)
            log_error "Invalid choice"
            echo "none"
            ;;
    esac
}

# Main execution
main() {
    # Check if niri is installed
    if ! command -v niri &>/dev/null; then
        log_error "Niri is not installed yet"
        log_error "Please run the bootstrap script first"
        exit 1
    fi
    
    # Create session files
    create_niri_session
    create_niri_session_wrapper
    
    # Detect or install display manager
    DM=$(detect_display_manager)
    
    if [ "$DM" = "none" ]; then
        DM=$(install_display_manager)
    fi
    
    # Configure the detected display manager
    case $DM in
        gdm)
            setup_gdm
            ;;
        sddm)
            setup_sddm
            ;;
        lightdm)
            setup_lightdm
            ;;
        none)
            log_warning "No display manager configured"
            log_warning "To start niri manually, run: niri-session"
            ;;
    esac
    
    echo ""
    echo "========================================"
    echo "  Display Manager Setup Complete"
    echo "========================================"
    echo ""
    
    if [ "$DM" != "none" ]; then
        log_success "Niri is now available as a session option"
        log_step "Next steps:"
        echo "  1. Reboot your system"
        echo "  2. At the login screen, select 'Niri' from the session menu"
        echo "  3. Log in with your credentials"
        echo ""
        log_warning "Your existing desktop environments (e.g., GNOME) are still available"
        log_warning "You can switch between them at the login screen"
    fi
}

main "$@"
