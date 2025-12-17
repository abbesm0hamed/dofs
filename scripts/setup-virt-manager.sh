#!/bin/bash
# Installs and configures QEMU/KVM + virt-manager
set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_step() { printf "${BLUE}==> %s${NC}\n" "$1"; }
log_success() { printf "${GREEN}✓ %s${NC}\n" "$1"; }
log_warning() { printf "${YELLOW}⚠ %s${NC}\n" "$1"; }
log_error() { printf "${RED}✗ %s${NC}\n" "$1"; }

require_cmd() {
    if ! command -v "$1" &>/dev/null; then
        log_error "Missing required command: $1"
        exit 1
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="${SCRIPT_DIR}/../packages/virt-manager.txt"
LOG_FILE="${HOME}/virt-manager-setup.log"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

log_step "Starting virt stack install (logging to ${LOG_FILE})"

exec > >(tee -a "$LOG_FILE") 2>&1

require_cmd sudo
if command -v yay &>/dev/null; then
    PKG_INSTALL_CMD=(yay -S --needed --noconfirm --answerclean None --answerdiff None)
else
    require_cmd pacman
    PKG_INSTALL_CMD=(sudo pacman -Sy --needed --noconfirm)
fi

cpu_vendor="$(grep -m1 -oE 'GenuineIntel|AuthenticAMD' /proc/cpuinfo || true)"
if ! lscpu | grep -qi "virtualization"; then
    log_warning "CPU virtualization flag not detected; ensure virtualization is enabled in BIOS/UEFI."
fi

if [ ! -f "$PACKAGES_FILE" ]; then
    log_error "Package list not found: $PACKAGES_FILE"
    exit 1
fi

PACKAGES=()
while IFS= read -r pkg; do
    pkg="${pkg%%#*}"
    pkg="$(printf '%s' "$pkg" | xargs)"
    [ -z "$pkg" ] && continue
    PACKAGES+=("$pkg")
done < "$PACKAGES_FILE"

log_step "Installing virtualization packages..."
"${PKG_INSTALL_CMD[@]}" "${PACKAGES[@]}"
log_success "Packages installed"

modules=(kvm)
case "$cpu_vendor" in
    GenuineIntel) modules+=(kvm_intel) ;;
    AuthenticAMD) modules+=(kvm_amd) ;;
esac

log_step "Loading kernel modules: ${modules[*]}"
for mod in "${modules[@]}"; do
    if ! lsmod | grep -q "^${mod}"; then
        if ! sudo modprobe "$mod"; then
            log_warning "Could not load module $mod (it may already be built-in)"
        fi
    fi
done

log_step "Persisting module load configuration..."
sudo install -Dm644 /dev/stdin /etc/modules-load.d/virt.conf <<EOF
${modules[0]}
${modules[1]:-}
EOF

log_step "Enabling libvirt services..."
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now virtlogd.socket
sudo systemctl enable --now virtlockd.socket
log_success "Services enabled"

log_step "Adding ${TARGET_USER} to libvirt group..."
if id -nG "$TARGET_USER" | grep -qw libvirt; then
    log_success "${TARGET_USER} already in libvirt group"
else
    sudo usermod -aG libvirt "$TARGET_USER"
    log_success "Added ${TARGET_USER} to libvirt group (relog required)"
fi

log_step "Ensuring default NAT network exists..."
if sudo virsh -c qemu:///system net-info default &>/dev/null; then
    log_success "Default network already defined"
else
    tmp_net="$(mktemp)"
    cat >"$tmp_net" <<'EOF'
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF
    sudo virsh -c qemu:///system net-define "$tmp_net"
    rm -f "$tmp_net"
fi
sudo virsh -c qemu:///system net-autostart default
sudo virsh -c qemu:///system net-start default >/dev/null 2>&1 || true
log_success "Default network ready"

if [ -n "$TARGET_HOME" ]; then
    log_step "Setting default libvirt URI for ${TARGET_USER}..."
    sudo -u "$TARGET_USER" mkdir -p "$TARGET_HOME/.config/libvirt"
    sudo tee "$TARGET_HOME/.config/libvirt/libvirt.conf" >/dev/null <<'EOF'
uri_default = "qemu:///system"
EOF
    sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/libvirt/libvirt.conf"
    log_success "Default URI set to qemu:///system"
else
    log_warning "Could not determine home for ${TARGET_USER}; skipped user libvirt config"
fi

log_success "Virt-manager + QEMU/KVM setup complete."
log_warning "Log out/in (or reboot) to pick up new group membership."
