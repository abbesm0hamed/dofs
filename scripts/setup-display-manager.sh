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

 ensure_tuigreet_installed() {
     if pacman -Qq tuigreet &>/dev/null; then
         return 0
     fi

     if ! command -v yay &>/dev/null; then
         log_error "tuigreet is not installed and is not available via pacman on this system"
         log_error "Install yay, then run: yay -S --needed tuigreet"
         exit 1
     fi

     if [ "${EUID}" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
         sudo -u "${SUDO_USER}" yay -S --needed --noconfirm --answerclean None --answerdiff None tuigreet
     else
         yay -S --needed --noconfirm --answerclean None --answerdiff None tuigreet
     fi
 }

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
    elif systemctl is-enabled greetd.service &>/dev/null; then
        echo "greetd"
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

    if [ -f "$session_file" ]; then
        log_success "$session_file already exists"
        return 0
    fi
    
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
    
    local system_session="/usr/bin/niri-session"
    local wrapper="/usr/local/bin/niri-session"

    if [ -x "$system_session" ]; then
        if [ -e "$wrapper" ]; then
            local backup="${wrapper}.dofs.bak"
            if [ -e "$backup" ]; then
                backup="${wrapper}.dofs.bak.$(date +%s)"
            fi

            log_warning "$wrapper exists and may shadow $system_session"
            sudo mv "$wrapper" "$backup"
            log_success "Moved old wrapper to $backup"
        fi

        log_success "Using system niri-session ($system_session)"
        return 0
    fi

    if [ -f "$wrapper" ]; then
        sudo chmod +x "$wrapper"
        log_success "niri-session wrapper already exists: $wrapper"
        return 0
    fi
    
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

# Import environment into systemd user session (CRITICAL for portals)
# This allows systemd services like xdg-desktop-portal-gtk to access the display
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE

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

# Setup for greetd
setup_greetd() {
    log_step "Configuring greetd for Niri..."

    local templates_dir="${REPO_ROOT}/templates/greetd"
    local regreet_template="${templates_dir}/regreet.toml"
    local greetd_regreet_template="${templates_dir}/config-regreet.toml"
    local greetd_tuigreet_template="${templates_dir}/config-tuigreet.toml"
    local libinput_tap_quirks="${templates_dir}/libinput-tap.quirks"

    if [ ! -f "${regreet_template}" ] || [ ! -f "${greetd_regreet_template}" ] || [ ! -f "${greetd_tuigreet_template}" ] || [ ! -f "${libinput_tap_quirks}" ]; then
        log_error "Missing greetd templates under ${templates_dir}"
        log_error "Expected: regreet.toml, config-regreet.toml, config-tuigreet.toml, libinput-tap.quirks"
        exit 1
    fi

    log_step "Ensuring greetd + greeter are installed..."
    sudo pacman -S --needed --noconfirm greetd cage greetd-regreet greetd-tuigreet
    sudo systemctl enable greetd.service
    sudo systemctl set-default graphical.target >/dev/null

    sudo install -d -m 0755 /etc/greetd
    sudo install -d -m 0755 /etc/libinput

    if ! id -u greeter &>/dev/null; then
        log_step "Creating system user: greeter"
        sudo useradd -r -M -s /usr/bin/nologin greeter
        log_success "Created user: greeter"
    fi

    if getent group video >/dev/null; then
        sudo usermod -a -G video greeter
    fi

    if [ -f /etc/greetd/config.toml ]; then
        local backup="/etc/greetd/config.toml.dofs.bak"
        if [ -e "$backup" ]; then
            backup="/etc/greetd/config.toml.dofs.bak.$(date +%s)"
        fi
        sudo cp -a /etc/greetd/config.toml "$backup"
        log_warning "Existing greetd config backed up to $backup"
    fi

    local background_src="${REPO_ROOT}/.config/backgrounds/blurry-snaky.jpg"
    local background_dst="/etc/greetd/background.jpg"
    if [ -f "${background_src}" ]; then
        sudo install -m 0644 "${background_src}" "${background_dst}"
    else
        log_warning "Wallpaper not found at ${background_src}; using a solid background in ReGreet"
    fi

    # Enable tap-to-click for greetd session (applies system-wide via libinput quirk)
    sudo install -m 0644 "${libinput_tap_quirks}" /etc/libinput/local-overrides.quirks

    sudo install -d -m 0755 /var/lib/regreet
    sudo install -d -m 0755 /var/log/regreet
    sudo chown -R greeter:greeter /var/lib/regreet /var/log/regreet

    if command -v regreet &>/dev/null; then
        sudo install -m 0644 "${greetd_regreet_template}" /etc/greetd/config.toml

        if [ -f "${background_dst}" ]; then
            sed "s|@BACKGROUND@|${background_dst}|g" "${regreet_template}" | sudo tee /etc/greetd/regreet.toml > /dev/null
        else
            sed "s|@BACKGROUND@|/dev/null|g" "${regreet_template}" | sudo tee /etc/greetd/regreet.toml > /dev/null
        fi
    else
        log_warning "regreet not found; falling back to tuigreet"
        ensure_tuigreet_installed
        sudo install -m 0644 "${greetd_tuigreet_template}" /etc/greetd/config.toml
    fi

    log_success "greetd configured"
}

# Install display manager if none exists
install_display_manager() {
    log_warning "No display manager detected"

    log_step "Installing greetd (default)..."
    sudo pacman -S --needed --noconfirm greetd greetd-regreet greetd-tuigreet
    sudo systemctl enable greetd.service
    sudo systemctl set-default graphical.target >/dev/null
    log_success "greetd installed and enabled"
    echo "greetd"
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
        greetd)
            setup_greetd
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
    fi
}

main "$@"
