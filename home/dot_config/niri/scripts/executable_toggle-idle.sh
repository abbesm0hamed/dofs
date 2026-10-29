#!/usr/bin/env bash
# Toggle the shell's swayidle locking behavior.
set -euo pipefail
if systemctl --user is-active --quiet swayidle.service 2>/dev/null; then
    systemctl --user stop swayidle.service
elif pgrep -x swayidle >/dev/null 2>&1; then
    pkill -x swayidle
elif systemctl --user list-unit-files --no-legend swayidle.service 2>/dev/null | grep -q '^swayidle.service'; then
    systemctl --user start swayidle.service
else
    swayidle -w \
        timeout 1200 'niri msg action power-off-monitors' \
        resume 'niri msg action power-on-monitors' \
        timeout 1800 hyprlock before-sleep hyprlock &
fi
