#!/bin/bash
set -euo pipefail

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { printf "${BLUE}==> %s${NC}\n" "$1"; }
success() { printf "${GREEN}==> %s${NC}\n" "$1"; }
error() { printf "${RED}==> %s${NC}\n" "$1"; }

TEMP_DIR=$(mktemp -d)
DRIVER_URL="http://dell.archive.canonical.com/updates/pool/public/libf/libfprint-2-tod1-broadcom-cv3plus/libfprint-2-tod1-broadcom-cv3plus_6.3.299-6.3.040.0.orig.tar.gz"
TARGET_DIR="/usr/lib64/libfprint-2/tod-1"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Check for Broadcom 58200 hardware
if ! lsusb | grep -q "0a5c:5865"; then
    log "Broadcom 58200 fingerprint sensor (0a5c:5865) not found. Skipping driver installation."
    exit 0
fi

# Check if driver is already installed
if [[ -f "$TARGET_DIR/libfprint-2-tod-1-broadcom-cv3plus.so" ]]; then
    success "Broadcom fingerprint driver already installed. Skipping download."
    # We still ensure Polkit rule and service status
else
    log "Downloading Broadcom CV3Plus fingerprint driver..."
    curl -L --fail -o "$TEMP_DIR/driver.tar.gz" "$DRIVER_URL" || { error "Failed to download driver"; exit 1; }

    log "Extracting driver..."
    tar -xzf "$TEMP_DIR/driver.tar.gz" -C "$TEMP_DIR"

    # Locate the .so file
    SO_FILE=$(find "$TEMP_DIR" -name "libfprint-2-tod-1-broadcom-cv3plus.so" | head -n 1)

    if [[ -z "$SO_FILE" ]]; then
        error "Could not find driver shared object file."
        exit 1
    fi

    log "Installing driver to $TARGET_DIR..."
    sudo mkdir -p "$TARGET_DIR"
    sudo cp "$SO_FILE" "$TARGET_DIR/"
    sudo chmod 755 "$TARGET_DIR/libfprint-2-tod-1-broadcom-cv3plus.so"

    log "Installing firmware to /var/lib/fprint/..."
    FIRMWARE_SOURCE=$(find "$TEMP_DIR" -type d -name ".broadcomCv3plusFW" | head -n 1)
    if [[ -n "$FIRMWARE_SOURCE" ]]; then
        sudo mkdir -p /var/lib/fprint
        sudo cp -r "$FIRMWARE_SOURCE" /var/lib/fprint/
        sudo find /var/lib/fprint/.broadcomCv3plusFW -type d -exec chmod 755 {} \;
        sudo find /var/lib/fprint/.broadcomCv3plusFW -type f -exec chmod 644 {} \;
    else
        error "Could not find firmware directory."
        exit 1
    fi
fi

log "Installing PolicyKit rule for fingerprint enrollment..."
sudo tee /etc/polkit-1/rules.d/90-fingerprint-enroll.rules > /dev/null << 'EOF'
/* Allow users to enroll fingerprints */
polkit.addRule(function (action, subject) {
    if (action.id == "net.reactivated.fprint.device.enroll") {
        return polkit.Result.YES;
    }
});
EOF
sudo chmod 644 /etc/polkit-1/rules.d/90-fingerprint-enroll.rules

log "Restarting fprintd service..."
sudo systemctl restart fprintd

success "Broadcom CV3Plus driver installed successfully!"
