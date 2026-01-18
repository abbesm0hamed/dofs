#!/bin/bash

# Settings Menu for Niri + Arch Linux
# Usage: settings-menu.sh

# Function to show audio settings
audio_menu() {
    local options=(
        "  Volume Control (pavucontrol)" # nf-fa-volume_up
        "  Audio Devices"                # nf-fa-headphones
        "󰝟  Toggle Mute"                  # nf-mdi-volume_off
        "  Increase Volume (+5%)"        # nf-fa-microphone
        "  Decrease Volume (-5%)"        # nf-fa-volume_down
    )

    local choice
    choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "󰓃 Audio Settings: ")

    case "$choice" in
        *"Volume Control"*) pavucontrol & ;;
        *"Audio Devices"*)
            pactl list sinks short | rofi -dmenu -p "󰓃 Audio Devices: "
            ;;
        *"Toggle Mute"*)
            pactl set-sink-mute @DEFAULT_SINK@ toggle
            notify-send "Audio" "Audio mute toggled" -i "audio-volume-muted"
            ;;
        *"Increase Volume"*)
            pactl set-sink-volume @DEFAULT_SINK@ +5%
            notify-send "Audio" "Volume increased" -i "audio-volume-high"
            ;;
        *"Decrease Volume"*)
            pactl set-sink-volume @DEFAULT_SINK@ -5%
            notify-send "Audio" "Volume decreased" -i "audio-volume-low"
            ;;
    esac
}

# Function to show display settings
display_menu() {
    local options=(
        "  Display Configuration"      # nf-fa-desktop
        "  Brightness Control"         # nf-fa-lightbulb_o
        "  Night Light Settings"       # nf-fa-moon_o
        "  Increase Brightness (+10%)" # nf-fa-adjust
        "  Decrease Brightness (-10%)" # nf-fa-tint
    )

    local choice
    choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "󰔊 Display Settings: ")

    case "$choice" in
        *"Display Configuration"*)
            notify-send "Settings" "Edit ~/.config/niri/config.kdl for display settings" -i "preferences-desktop-display"
            wezterm start -- nvim ~/.config/niri/config.kdl &
            ;;
        *"Brightness Control"*)
            local current=$(brightnessctl get)
            local max=$(brightnessctl max)
            local percent=$((current * 100 / max))
            notify-send "Brightness" "Current: ${percent}%" -i "display-brightness"
            ;;
        *"Night Light Settings"*) ~/.config/niri/scripts/system-controls.sh ;;
        *"Increase Brightness"*)
            brightnessctl set +10%
            notify-send "Brightness" "Brightness increased" -i "display-brightness"
            ;;
        *"Decrease Brightness"*)
            brightnessctl set 10%-
            notify-send "Brightness" "Brightness decreased" -i "display-brightness"
            ;;
    esac
}

# Function to show network settings
network_menu() {
    local options=(
        "  WiFi Networks"     # nf-fa-wifi
        "  Bluetooth Devices" # nf-fa-bluetooth
        "  Network Manager"   # nf-fa-sitemap (or globe)
        "  Toggle WiFi"       # nf-fa-wifi
        "  Toggle Bluetooth"  # nf-fa-bluetooth
    )

    local choice
    choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "󰤨 Network Settings: ")

    case "$choice" in
        *"WiFi Networks"*)
            nmcli device wifi list | rofi -dmenu -p "󰤨 WiFi Networks: "
            ;;
        *"Bluetooth Devices"*)
            bluetoothctl devices | rofi -dmenu -p "󰂯 Bluetooth Devices: "
            ;;
        *"Network Manager"*) nm-connection-editor & ;;
        *"Toggle WiFi"*) ~/.config/niri/scripts/system-controls.sh ;;
        *"Toggle Bluetooth"*) ~/.config/niri/scripts/system-controls.sh ;;
    esac
}

# Function to show system info
system_info() {
    local info=(
        "  $(uname -n)"  # nf-fa-laptop
        "  $(uname -r)"  # nf-fa-linux
        "  $(uptime -p)" # nf-fa-bolt
        "  $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
        "  $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
        "  $(sensors 2>/dev/null | grep -E 'Core|temp' | head -1 | awk '{print $3}' || echo 'N/A')"
    )

    printf '%s\n' "${info[@]}" | rofi -dmenu -p "󰋇 System Info: "
}

# Main settings menu
main_menu() {
    local options=(
        "  Audio Settings"        # nf-fa-volume_up
        "  Display Settings"      # nf-fa-desktop
        "  Network Settings"      # nf-fa-wifi
        "  Input Settings"        # nf-fa-keyboard_o
        "  Notification Settings" # nf-fa-bell
        "  System Information"    # nf-fa-info_circle
        "  Edit Niri Config"      # nf-fa-cogs
        "  Edit Home Config"      # nf-fa-home
        "  System Settings (GUI)" # nf-fa-wrench
    )

    local line_count=${#options[@]}
    local theme_str="
window { height: 0px; }
listview { lines: ${line_count}; fixed-height: false; }
"

    local choice
    choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "󰒓 Settings: " -l "$line_count" -theme-str "$theme_str")

    case "$choice" in
        *"Audio Settings"*) audio_menu ;;
        *"Display Settings"*) display_menu ;;
        *"Network Settings"*) network_menu ;;
        *"Input Settings"*)
            notify-send "Settings" "Configure input in Niri config" -i "preferences-desktop-keyboard"
            wezterm start -- nvim ~/.config/niri/config.kdl &
            ;;
        *"Notification Settings"*)
            wezterm start -- nvim ~/.config/mako/config &
            ;;
        *"System Information"*) system_info ;;
        *"Edit Niri Config"*) wezterm start -- nvim ~/.config/niri/config.kdl & ;;
        *"Edit Home Config"*) wezterm start -- nvim ~/.config/fish/config.fish & ;;
        *"System Settings"*)
            if command -v gnome-control-center >/dev/null; then
                gnome-control-center &
            else
                notify-send "Settings" "No GUI settings app available" -i "dialog-information"
            fi
            ;;
    esac
}

# Run the main menu
main_menu
