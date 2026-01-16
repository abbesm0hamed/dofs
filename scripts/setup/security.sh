#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

log "Applying security hardening..."

# Firewall Configuration
log "Configuring Firewalld..."
if ! systemctl is-active --quiet firewalld; then
    sudo dnf install -y firewalld
    sudo systemctl enable --now firewalld
fi

# Basic workstation lockdown
ZONE="public"
if sudo firewall-cmd --get-zones | grep -q "FedoraWorkstation"; then
    ZONE="FedoraWorkstation"
fi

if [ "$(sudo firewall-cmd --get-default-zone)" != "$ZONE" ]; then
    sudo firewall-cmd --set-default-zone="$ZONE"
    firewall_changed=true
fi

for service in http https; do
    if ! sudo firewall-cmd --zone="$ZONE" --query-service=$service --permanent; then
        sudo firewall-cmd --zone="$ZONE" --add-service=$service --permanent
        firewall_changed=true
    fi
done

if ! sudo firewall-cmd --zone="$ZONE" --query-masquerade --permanent; then
    sudo firewall-cmd --zone="$ZONE" --add-masquerade --permanent
    firewall_changed=true
fi

if [ "${firewall_changed:-false}" = true ]; then
    log "Reloading firewall configuration..."
    sudo firewall-cmd --reload
else
    ok "Firewall rules are already up to date."
fi

# Docker Permissions
log "Configuring Docker permissions..."
if getent group docker >/dev/null; then
    sudo usermod -aG docker "$USER"
    ok "User $USER added to docker group (logout required)"
else
    warn "Docker group not found, skipping permission fix"
fi

# DNS-over-TLS (via systemd-resolved)
log "Configuring DNS-over-TLS (Cloudflare + Google)..."
DOT_CONF_CONTENT='[Resolve]
DNS=1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4
FallbackDNS=9.9.9.9
DNSOverTLS=yes'

if [ -f /etc/systemd/resolved.conf.d/dot.conf ] && grep -q "DNSOverTLS=yes" /etc/systemd/resolved.conf.d/dot.conf; then
    ok "DNS-over-TLS is already configured."
else
    sudo mkdir -p /etc/systemd/resolved.conf.d/
    echo "$DOT_CONF_CONTENT" | sudo tee /etc/systemd/resolved.conf.d/dot.conf >/dev/null
    sudo systemctl restart systemd-resolved
    ok "DNS-over-TLS configured."
fi

ok "Security configuration applied."
