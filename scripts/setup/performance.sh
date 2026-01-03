#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

log "Optimizing system performance..."

# 1. ZRAM Optimization (Fedora way)
log "Configuring Zram..."
if ! rpm -q zram-generator &>/dev/null; then
    sudo dnf install -y zram-generator
fi

sudo tee /etc/systemd/zram-generator.conf >/dev/null <<EOF
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

sudo systemctl daemon-reload
sudo systemctl start /dev/zram0 || true

# 2. SSD Trimming
log "Enabling SSD fstrim timer..."
sudo systemctl enable --now fstrim.timer

# 3. Power Management optimizations
log "Configuring power-profiles-daemon..."
if systemctl is-active --quiet power-profiles-daemon; then
    # Set balanced as default if not set
    sudo powerprofilesctl set balanced || true
fi

ok "Performance tweaks applied. (Reboot recommended for Zram changes)"
