#!/bin/bash

# System controls for the dofs Quickshell launcher.
# No arguments: provider that prints one JSON item per line.
# --run NAME: executes a toggle directly (shared with the settings menus).

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/menu-lib.sh"

SELF="$HOME/.config/niri/scripts/system-controls.sh"

is_user_unit_active() {
    systemctl --user is-active --quiet "$1" 2>/dev/null
}

night_light_is_on() {
    pgrep -x gammastep >/dev/null 2>&1 \
        || pgrep -x gammastep-indicator >/dev/null 2>&1 \
        || pgrep -x redshift >/dev/null 2>&1
}

idle_desc() {
    if is_user_unit_active swayidle.service || pgrep -x swayidle >/dev/null 2>&1; then
        echo "Idle mode is ON - turn OFF"
    else
        echo "Idle mode is OFF - turn ON"
    fi
}

night_light_desc() {
    if night_light_is_on; then echo "Night light is ON - turn OFF"; else echo "Night light is OFF - turn ON"; fi
}

notifications_desc() {
    if [[ $(timeout 2s qs -c dofs ipc call notifications dnd 2>/dev/null) == true ]]; then
        echo "Notifications are OFF - turn ON"
    else
        echo "Notifications are ON - turn OFF"
    fi
}

wifi_desc() {
    if nmcli radio wifi 2>/dev/null | grep -q "enabled"; then echo "WiFi is ON - turn OFF"; else echo "WiFi is OFF - turn ON"; fi
}

bluetooth_desc() {
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then echo "Bluetooth is ON - turn OFF"; else echo "Bluetooth is OFF - turn ON"; fi
}

toggle_idle_mode() {
    if is_user_unit_active swayidle.service; then
        systemctl --user stop swayidle.service
        notify-send "System Controls" "Idle mode disabled" -i "system-suspend"
    elif pgrep -x swayidle >/dev/null 2>&1; then
        pkill -x swayidle
        notify-send "System Controls" "Idle mode disabled" -i "system-suspend"
    else
        if systemctl --user list-unit-files swayidle.service >/dev/null 2>&1; then
            systemctl --user start swayidle.service
        else
            swayidle -w \
                timeout 600 'niri msg action power-off-monitors' \
                resume 'niri msg action power-on-monitors' \
                timeout 300 'hyprlock' \
                before-sleep 'hyprlock' &
        fi
        notify-send "System Controls" "Idle mode enabled" -i "system-suspend"
    fi
}

toggle_night_light() {
    if night_light_is_on; then
        pkill -x gammastep 2>/dev/null || true
        pkill -x gammastep-indicator 2>/dev/null || true
        pkill -x redshift 2>/dev/null || true
        notify-send "System Controls" "Night light disabled" -i "weather-clear-night"
    else
        gammastep -O 4700 &
        notify-send "System Controls" "Night light enabled" -i "weather-clear-night"
    fi
}

toggle_notifications() {
    local reply
    reply=$(timeout 2s qs -c dofs ipc call notifications toggleDnd 2>&1) || return 1
    [[ -z $reply ]] || { printf '%s\n' "$reply" >&2; return 1; }
}

toggle_wifi() {
    if nmcli radio wifi 2>/dev/null | grep -q "enabled"; then
        nmcli radio wifi off
        notify-send "System Controls" "WiFi disabled" -i "network-wireless-disabled"
    else
        nmcli radio wifi on
        notify-send "System Controls" "WiFi enabled" -i "network-wireless"
    fi
}

toggle_bluetooth() {
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        bluetoothctl power off
        notify-send "System Controls" "Bluetooth disabled" -i "bluetooth-disabled"
    else
        bluetoothctl power on
        notify-send "System Controls" "Bluetooth enabled" -i "bluetooth"
    fi
}

if [[ ${1:-} == --run ]]; then
    [[ $# -eq 2 ]] || { echo "expected --run NAME" >&2; exit 1; }
    case "$2" in
        toggle-idle) toggle_idle_mode ;;
        toggle-night-light) toggle_night_light ;;
        toggle-notifications) toggle_notifications ;;
        toggle-wifi) toggle_wifi ;;
        toggle-bluetooth) toggle_bluetooth ;;
        *) echo "unknown toggle: $2" >&2; exit 1 ;;
    esac
    exit 0
fi
if [[ $# -ne 0 ]]; then
    echo "usage: $0 [--run NAME]" >&2
    exit 1
fi

menu_item "Idle mode" "$(idle_desc)" "system-suspend" -- bash "$SELF" --run toggle-idle
menu_item "Night light" "$(night_light_desc)" "weather-clear-night" -- bash "$SELF" --run toggle-night-light
menu_item "Notifications" "$(notifications_desc)" "preferences-system-notifications" -- bash "$SELF" --run toggle-notifications
if command -v nmcli >/dev/null 2>&1; then
    menu_item "WiFi radio" "$(wifi_desc)" "network-wireless" -- bash "$SELF" --run toggle-wifi
fi
if command -v bluetoothctl >/dev/null 2>&1; then
    menu_item "Bluetooth radio" "$(bluetooth_desc)" "preferences-system-bluetooth" -- bash "$SELF" --run toggle-bluetooth
fi
if command -v pavucontrol >/dev/null 2>&1; then
    menu_item "Volume mixer" "Open pavucontrol" "audio-volume-high" -- pavucontrol
fi
menu_item "Settings" "Audio, display, network, info" "preferences-system" --menu "$HOME/.config/niri/scripts/settings-menu.sh"
menu_item "Lock screen" "Lock this session" "system-lock-screen" -- hyprlock
menu_item "Power menu" "Lock, logout, suspend, reboot" "system-shutdown" --menu "$HOME/.config/quickshell/dofs/scripts/power-menu.sh"
