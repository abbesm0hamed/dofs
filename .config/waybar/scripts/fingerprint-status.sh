#!/bin/bash

# Fingerprint Status Script for Waybar
# Shows fingerprint setup indicator only when not configured

# Check if fprintd is available
if ! command -v fprintd-list &> /dev/null; then
    # fprintd not available, don't show anything
    exit 1
fi

# Check if user has enrolled fingerprints
if fprintd-list "$USER" 2>/dev/null | grep -q "finger"; then
    # Fingerprints are enrolled, don't show the module
    exit 1
else
    # No fingerprints enrolled, show setup indicator
    echo '{"text": "🔐", "tooltip": "Click to setup fingerprint authentication", "class": "fingerprint-setup"}'
    exit 0
fi
