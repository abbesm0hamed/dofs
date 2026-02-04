#!/bin/bash
set -euo pipefail

# Waybar Fingerprint Status Script
# Shows fingerprint enrollment status

if [[ "${1:-}" == "--exec-if" ]]; then
    command -v fprintd-list >/dev/null 2>&1 || exit 1
    STATUS="$(fprintd-list "$USER" 2>/dev/null || true)"
    [[ -n "${STATUS}" ]] || exit 1
    grep -q "has no fingers enrolled" <<<"${STATUS}" || exit 1
    exit 0
fi

# Quietly check for fprintd
if ! command -v fprintd-list >/dev/null 2>&1; then
    printf '%s\n' '{"text":"","class":"hidden"}'
    exit 0
fi

# Capture status once to avoid duplicate output
STATUS="$(fprintd-list "$USER" 2>/dev/null || true)"

# No device detected or no output from fprintd
if [[ -z "${STATUS}" ]]; then
    printf '%s\n' '{"text":"","class":"hidden"}'
    exit 0
fi

# Show warning when not enrolled; hide otherwise
if grep -q "has no fingers enrolled" <<<"${STATUS}"; then
    printf '{"text":"󰈷","tooltip":"Fingerprint not enrolled\\nClick to set up","class":"warning"}\n'
else
    # Hide the module when fingerprints are enrolled
    printf '%s\n' '{"text":"","class":"hidden"}'
    exit 0
fi
