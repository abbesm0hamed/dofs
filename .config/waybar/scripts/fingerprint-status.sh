#!/bin/bash
set -euo pipefail

# Waybar Fingerprint Status Script
# Shows fingerprint enrollment status

# Quietly check for fprintd
command -v fprintd-list >/dev/null 2>&1 || exit 0

# Capture status once to avoid duplicate output
STATUS="$(fprintd-list "$USER" 2>/dev/null || true)"

# No device detected or no output from fprintd
[[ -z "${STATUS}" ]] && exit 0

# Show warning when not enrolled; hide otherwise
if grep -q "has no fingers enrolled" <<<"${STATUS}"; then
    printf '{"text":"󰈷","tooltip":"Fingerprint not enrolled\\nClick to set up","class":"warning"}\n'
else
    # Hide the module when fingerprints are enrolled
    exit 0
fi
