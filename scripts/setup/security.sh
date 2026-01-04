#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

log "Applying security hardening..."

# 1. Firewall Configuration
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

sudo firewall-cmd --set-default-zone="$ZONE"
sudo firewall-cmd --zone="$ZONE" --add-service=http --permanent
sudo firewall-cmd --zone="$ZONE" --add-service=https --permanent
sudo firewall-cmd --zone="$ZONE" --add-masquerade --permanent
sudo firewall-cmd --reload

# 2. Docker Permissions
log "Configuring Docker permissions..."
if getent group docker >/dev/null; then
    sudo usermod -aG docker "$USER"
    ok "User $USER added to docker group (logout required)"
else
    warn "Docker group not found, skipping permission fix"
fi

# 3. DNS-over-TLS (via systemd-resolved)
log "Configuring DNS-over-TLS (Cloudflare + Google)..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo tee /etc/systemd/resolved.conf.d/dot.conf >/dev/null <<EOF
[Resolve]
DNS=1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4
FallbackDNS=9.9.9.9
DNSOverTLS=yes
EOF

sudo systemctl restart systemd-resolved

ok "Security configuration applied."
