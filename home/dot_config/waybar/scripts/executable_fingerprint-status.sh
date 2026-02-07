#!/bin/bash
set -euo pipefail

# Waybar Fingerprint Status Script
# Shows fingerprint enrollment status

# Capture status once to avoid duplicate output
# If fprintd-list fails, it usually means no device is present
if ! STATUS="$(fprintd-list "$USER" 2>/dev/null)"; then
    # No device or service error
    printf '%s\n' '{"text":"","class":"hidden"}'
    exit 1
fi

if [[ "${1:-}" == "--exec-if" ]]; then
    # Return 0 (true) only if we have a device AND no fingers are enrolled
    if grep -q "has no fingers enrolled" <<<"${STATUS}"; then
        exit 0
    fi
    exit 1
fi

# Show warning when not enrolled; hide otherwise
if grep -q "has no fingers enrolled" <<<"${STATUS}"; then
    printf '{"text":"󰈷","tooltip":"Fingerprint not enrolled\\nClick to set up","class":"warning"}\n'
else
    # Hide the module when fingerprints are enrolled or any other status
    printf '%s\n' '{"text":"","class":"hidden"}'
    exit 1
fi
