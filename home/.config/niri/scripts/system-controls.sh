#!/bin/bash

# System Controls Menu for Niri
# Usage: system-controls.sh

is_user_unit_active() {
    local unit="$1"
    systemctl --user is-active --quiet "$unit" 2>/dev/null
}

is_proc_running() {
    local exe="$1"
    pgrep -x "$exe" >/dev/null 2>&1
}

night_light_is_on() {
    is_proc_running gammastep || is_proc_running gammastep-indicator || is_proc_running redshift
}

# Function to check if a service/feature is active
check_idle_mode() {
    if is_user_unit_active swayidle.service; then
        echo "  Idle Mode: ON" # nf-fa-moon_o
    elif is_proc_running swayidle; then
        echo "  Idle Mode: ON" # nf-fa-moon_o
    else
        echo "  Idle Mode: OFF" # nf-fa-eye (awake)
    fi
}

check_night_light() {
    if night_light_is_on; then
        echo "  Night Light: ON" # nf-fa-lightbulb_o
    else
        echo "  Night Light: OFF" # nf-fa-circle (dark)
    fi
}

check_notifications() {
    if command -v makoctl >/dev/null 2>&1; then
        if makoctl mode 2>/dev/null | grep -qx "do-not-disturb"; then
            echo "  Notifications: OFF" # nf-fa-bell_slash
        else
            echo "  Notifications: ON" # nf-fa-bell
        fi
    else
        if pgrep -x mako >/dev/null 2>&1; then
            echo "  Notifications: ON" # nf-fa-bell
        else
            echo "  Notifications: OFF" # nf-fa-bell_slash
        fi
    fi
}

check_wifi() {
    if nmcli radio wifi | grep -q "enabled"; then
        echo "  WiFi: ON" # nf-fa-wifi
    else
        echo "󰖪  WiFi: OFF" # nf-fa-ban
    fi
}

check_bluetooth() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        echo "  Bluetooth: ON" # nf-fa-bluetooth
    else
        echo "󰂲  Bluetooth: OFF" # nf-fa-ban
    fi
}

# Function to toggle idle mode
toggle_idle_mode() {
    if is_user_unit_active swayidle.service; then
        systemctl --user stop swayidle.service
        notify-send "System Controls" "Idle mode disabled" -i "system-suspend"
    elif is_proc_running swayidle; then
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

# Function to toggle night light
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

# Function to toggle notifications
toggle_notifications() {
    if ! command -v makoctl >/dev/null 2>&1; then
        notify-send "System Controls" "makoctl not found"
        return 0
    fi

    makoctl mode -t do-not-disturb

    if makoctl mode 2>/dev/null | grep -qx "do-not-disturb"; then
        notify-send "System Controls" "Notifications disabled"
    else
        notify-send "System Controls" "Notifications enabled"
    fi
}

# Function to toggle WiFi
toggle_wifi() {
    if nmcli radio wifi | grep -q "enabled"; then
        nmcli radio wifi off
        notify-send "System Controls" "WiFi disabled" -i "network-wireless-disabled"
    else
        nmcli radio wifi on
        notify-send "System Controls" "WiFi enabled" -i "network-wireless"
    fi
}

# Function to toggle Bluetooth
toggle_bluetooth() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        bluetoothctl power off
        notify-send "System Controls" "Bluetooth disabled" -i "bluetooth-disabled"
    else
        bluetoothctl power on
        notify-send "System Controls" "Bluetooth enabled" -i "bluetooth"
    fi
}

# Main menu
main_menu() {
    local options=(
        "$(check_idle_mode)"
        "$(check_night_light)"
        "$(check_notifications)"
        "$(check_wifi)"
        "$(check_bluetooth)"
        "  Settings"    # nf-fa-cogs
        "  Lock Screen" # nf-fa-lock
        "  Power Menu"  # nf-fa-power_off
    )

    local choice
    choice=$(printf '%s\n' "${options[@]}" | fuzzel --dmenu --prompt="System Controls: " --width=40 --lines=10)

    case "$choice" in
        *"Idle Mode"*) toggle_idle_mode ;;
        *"Night Light"*) toggle_night_light ;;
        *"Notifications"*) toggle_notifications ;;
        *"WiFi"*) toggle_wifi ;;
        *"Bluetooth"*) toggle_bluetooth ;;
        *"Settings") ~/.config/niri/scripts/settings-menu.sh ;;
        *"Lock Screen") hyprlock ;;
        *"Power Menu") ~/.config/waybar/scripts/power-menu.sh ;;
    esac
}

# Run the main menu
main_menu
