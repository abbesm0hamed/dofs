#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

log "Setting up Docker..."
if ! systemctl is-active --quiet docker; then
    if command -v docker &>/dev/null; then
        sudo systemctl enable --now docker 2>/dev/null || true
        # Add current user to docker group if it exists
        if getent group docker >/dev/null && ! groups "$USER" | grep -qw docker; then
            sudo usermod -aG docker "$USER"
            ok "Added $USER to docker group (re-login required)"
        fi
        ok "Docker enabled and started"
    else
        warn "Docker not found, skipping setup."
    fi
else
    ok "Docker already running"
fi

setup_libvirt() {
    log "Setting up libvirt / virt-manager..."
    if ! systemctl list-unit-files | grep -q '^libvirtd\.service'; then
        warn "libvirtd.service not found, skipping libvirt setup."
        return
    fi

    # Ensure service is running before we make changes
    sudo systemctl enable --now libvirtd 2>/dev/null || warn "Failed to enable libvirtd"

    local config_changed=false

    # Fix for libvirt networking on recent Fedora: force iptables backend
    local LIBVIRT_NET_CONF="/etc/libvirt/network.conf"
    if [ -f "$LIBVIRT_NET_CONF" ] && ! grep -q '^\s*firewall_backend = "iptables"' "$LIBVIRT_NET_CONF"; then
        log "Forcing libvirt to use iptables firewall backend..."
        if sudo sed -i 's/^#*\s*firewall_backend = .*/firewall_backend = "iptables"/' "$LIBVIRT_NET_CONF"; then
            ok "Set libvirt firewall_backend to iptables"
            config_changed=true
        else
            warn "Failed to update $LIBVIRT_NET_CONF"
        fi
    fi

    # Restart libvirtd if needed before proceeding
    if [ "$config_changed" = true ]; then
        if sudo systemctl restart libvirtd; then
            ok "Restarted libvirtd service to apply config changes."
        else
            warn "Failed to restart libvirtd service; network setup may fail."
        fi
    fi

    # Add current user to libvirt and kvm groups
    for group in libvirt kvm; do
        if ! groups "$USER" | grep -qw "$group"; then
            if sudo usermod -aG "$group" "$USER"; then
                ok "Added $USER to $group group (re-login required)"
            else
                warn "Failed to add $USER to $group group"
            fi
        else
            ok "User already in $group group"
        fi
    done

    # Ensure default libvirt network is defined, active, and autostarted
    if ! sudo virsh net-info default >/dev/null 2>&1; then
        log "Defining default libvirt network..."
        if [ -f /usr/share/libvirt/networks/default.xml ]; then
            sudo virsh net-define /usr/share/libvirt/networks/default.xml >/dev/null 2>&1 || warn "Failed to define default network"
        else
            warn "default.xml for libvirt network not found; skipping network setup"
            return
        fi
    fi

    if ! sudo virsh net-info default 2>/dev/null | grep -q "Active:.*yes"; then
        log "Starting default libvirt network..."
        sudo virsh net-start default >/dev/null 2>&1 || warn "Failed to start default network"
    fi

    if ! sudo virsh net-list --all | grep -q 'default\s*active\s*yes'; then
        warn "Default network is not active or not set to autostart."
    else
        ok "Default libvirt network is active and configured."
    fi
}

setup_libvirt