#!/bin/bash
# Settings menu for the dofs Quickshell launcher.
# No argument: main settings list provider.
# SECTION: prints the JSON items for one section (audio|devices|display|
# network|wifi|bluetooth|sysinfo). Sections are wired from the main list via
# "menu" items, so each call prints exactly one flat list.
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/menu-lib.sh"

SELF="$HOME/.config/niri/scripts/settings-menu.sh"
CONTROLS="$HOME/.config/niri/scripts/system-controls.sh"

section=${1:-main}

case "$section" in
    main)
        menu_item "Audio" "Mixer, devices, mute, volume" "audio-volume-high" --menu "$SELF audio"
        menu_item "Display" "Configuration, brightness, night light" "video-display" --menu "$SELF display"
        menu_item "Network" "WiFi, bluetooth, connections" "network-wireless" --menu "$SELF network"
        menu_item "System info" "Host, kernel, memory, disk" "dialog-information" --menu "$SELF sysinfo"
        menu_item "Input and display config" "Edit the niri config" "preferences-desktop-keyboard" -- ghostty -e nvim ~/.config/niri/config.kdl
        menu_item "Notification config" "History, privacy and popup settings" "preferences-system-notifications" -- ghostty -e nvim ~/.config/quickshell/dofs/notifications/config.json
        menu_item "Edit niri config" "Open config.kdl in nvim" "utilities-editor" -- ghostty -e nvim ~/.config/niri/config.kdl
        menu_item "Edit fish config" "Open config.fish in nvim" "utilities-editor" -- ghostty -e nvim ~/.config/fish/config.fish
        if command -v gnome-control-center >/dev/null 2>&1; then
            menu_item "Desktop settings" "Open the GUI settings app" "preferences-system" -- gnome-control-center
        fi
        ;;
    audio)
        if command -v pavucontrol >/dev/null 2>&1; then
            menu_item "Volume mixer" "Open pavucontrol" "audio-volume-high" -- pavucontrol
        fi
        menu_item "Audio devices" "Pick the default output" "audio-card" --menu "$SELF devices"
        menu_item "Toggle mute" "Default audio output" "audio-volume-muted" -- pactl set-sink-mute @DEFAULT_SINK@ toggle
        menu_item "Increase volume" "Default audio output +5%" "audio-volume-high" -- pactl set-sink-volume @DEFAULT_SINK@ +5%
        menu_item "Decrease volume" "Default audio output -5%" "audio-volume-low" -- pactl set-sink-volume @DEFAULT_SINK@ -5%
        ;;
    devices)
        count=0
        while IFS=$'\t' read -r _ name rest; do
            [[ -n $name ]] || continue
            count=$((count + 1))
            menu_item "$name" "Set as default audio output" "audio-card" -- pactl set-default-sink "$name"
        done < <(pactl list sinks short 2>/dev/null)
        [[ $count -gt 0 ]] || { echo "no audio outputs found" >&2; exit 1; }
        ;;
    display)
        menu_item "Display configuration" "Edit the niri config" "video-display" -- ghostty -e nvim ~/.config/niri/config.kdl
        if command -v brightnessctl >/dev/null 2>&1; then
            if current=$(brightnessctl get 2>/dev/null) && max=$(brightnessctl max 2>/dev/null); then
                percent=$((current * 100 / max))
                menu_item "Brightness" "${percent}% of maximum" "display-brightness" --copy "${percent}%"
            fi
            menu_item "Increase brightness" "Set +10%" "display-brightness" -- brightnessctl set +10%
            menu_item "Decrease brightness" "Set 10% down" "display-brightness" -- brightnessctl set 10%-
        fi
        menu_item "Night light" "Toggle the 4700K overlay" "weather-clear-night" -- bash "$CONTROLS" --run toggle-night-light
        ;;
    network)
        menu_item "Connection editor" "Manage known connections" "preferences-system-network" -- nm-connection-editor
        menu_item "WiFi networks" "Pick a network nearby" "network-wireless" --menu "$SELF wifi"
        menu_item "Bluetooth devices" "Connect a known device" "preferences-system-bluetooth" --menu "$SELF bluetooth"
        menu_item "Toggle WiFi" "Radio power for this adapter" "network-wireless" -- bash "$CONTROLS" --run toggle-wifi
        menu_item "Toggle Bluetooth" "Radio power for this controller" "preferences-system-bluetooth" -- bash "$CONTROLS" --run toggle-bluetooth
        ;;
    wifi)
        count=0
        while IFS=: read -r active signal security ssid; do
            [[ -n $ssid ]] || continue
            count=$((count + 1))
            description="$signal% $security"
            if [[ $active == "yes" || $active == "*" ]]; then
                description="$signal% $security · connected"
            fi
            menu_item "$ssid" "$description" "network-wireless" \
                -- bash "$HOME/.config/niri/scripts/wifi-connect.sh" "$ssid" "$security"
        done < <(nmcli -t -f ACTIVE,SIGNAL,SECURITY,SSID device wifi list 2>/dev/null | awk -F: '!seen[$4]++')
        [[ $count -gt 0 ]] || { echo "no WiFi networks found" >&2; exit 1; }
        ;;
    bluetooth)
        count=0
        while read -r _ mac name; do
            [[ -n ${name:-} ]] || continue
            count=$((count + 1))
            menu_item "$name" "Connect with bluetoothctl" "bluetooth" -- bluetoothctl connect "$mac"
        done < <(bluetoothctl devices 2>/dev/null)
        [[ $count -gt 0 ]] || { echo "no known Bluetooth devices" >&2; exit 1; }
        ;;
    sysinfo)
        menu_item "Hostname" "$(uname -n)" "computer" --copy "$(uname -n)"
        menu_item "Kernel" "$(uname -r)" "computer" --copy "$(uname -r)"
        menu_item "Uptime" "$(uptime -p)" "dialog-information" --copy "$(uptime -p)"
        menu_item "Memory" "$(free -h | awk '/^Mem:/ {print $3 " / " $2}')" "dialog-information" \
            --copy "$(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
        menu_item "Disk (/)" "$(df -h / | awk 'NR==2 {print $3 " / " $2}')" "dialog-information" \
            --copy "$(df -h / | awk 'NR==2 {print $3 " / " $2}')"
        if command -v sensors >/dev/null 2>&1; then
            temp=$(sensors 2>/dev/null | grep -E 'Core|temp' | head -1 | awk '{print $2}' | tr -d '+')
            menu_item "Temperature" "${temp:-N/A}" "dialog-information" --copy "${temp:-N/A}"
        fi
        ;;
    *)
        echo "unknown section: $section" >&2
        exit 1
        ;;
esac
