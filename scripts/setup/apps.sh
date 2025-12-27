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

log "Setting up libvirt / virt-manager..."
if command -v virt-manager &>/dev/null; then
    # Ensure libvirt service is running (Fedora uses modular daemons behind libvirtd)
    if systemctl list-unit-files | grep -q '^libvirtd\.service'; then
        sudo systemctl enable --now libvirtd 2>/dev/null || warn "Failed to enable libvirtd"
    fi

    # Add current user to libvirt and kvm groups for qemu:///system access
    if ! groups "$USER" | grep -qw libvirt; then
        if sudo usermod -aG libvirt "$USER"; then
            ok "Added $USER to libvirt group (re-login required)"
        else
            warn "Failed to add $USER to libvirt group"
        fi
    else
        ok "User already in libvirt group"
    fi

    if ! groups "$USER" | grep -qw kvm; then
        if sudo usermod -aG kvm "$USER"; then
            ok "Added $USER to kvm group (re-login required)"
        else
            warn "Failed to add $USER to kvm group"
        fi
    else
        ok "User already in kvm group"
    fi

    # Ensure default libvirt network exists and is set to autostart
    if sudo virsh net-info default >/dev/null 2>&1; then
        sudo virsh net-autostart default >/dev/null 2>&1 || warn "Failed to set default network to autostart"
    else
        if [ -f /usr/share/libvirt/networks/default.xml ]; then
            sudo virsh net-define /usr/share/libvirt/networks/default.xml >/dev/null 2>&1 || warn "Failed to define default network"
            sudo virsh net-start default >/dev/null 2>&1 || warn "Failed to start default network"
            sudo virsh net-autostart default >/dev/null 2>&1 || warn "Failed to autostart default network"
        else
            warn "default.xml for libvirt network not found; skipping network setup"
        fi
    fi
else
    warn "virt-manager not found; skipping libvirt setup."
fi
