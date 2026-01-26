#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

log "Optimizing system performance..."

log "Configuring Zram..."
rpm -q zram-generator &>/dev/null || sudo dnf install -y zram-generator

ZRAM_CONF_CONTENT='[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap'

if [ -f /etc/systemd/zram-generator.conf ] \
    && grep -q "zram-size = min(ram / 2, 4096)" /etc/systemd/zram-generator.conf \
    && grep -q "compression-algorithm = zstd" /etc/systemd/zram-generator.conf; then
    log "Zram configuration already applied."
else
    echo "$ZRAM_CONF_CONTENT" | sudo tee /etc/systemd/zram-generator.conf >/dev/null
    sudo systemctl daemon-reload
    sudo systemctl start /dev/zram0 || true
fi

# SSD Trimming
log "Enabling SSD fstrim timer..."
sudo systemctl enable --now fstrim.timer

# Power Management optimizations
log "Configuring power-profiles-daemon..."
if systemctl is-active --quiet power-profiles-daemon; then
    # Set balanced as default if not set
    sudo powerprofilesctl set balanced || true
fi

ok "Performance tweaks applied. (Reboot recommended for Zram changes)"
