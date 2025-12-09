#!/usr/bin/env bash

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
    choice=$(printf '%s\n' "${options[@]}" | walker --dmenu --prompt="Audio Settings: " --width=40 --lines=6)

    case "$choice" in
        *"Volume Control"*) pavucontrol & ;;
        *"Audio Devices"*)
            pactl list sinks short | walker --dmenu --prompt="Audio Devices: " --width=60
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
    choice=$(printf '%s\n' "${options[@]}" | walker --dmenu --prompt="Display Settings: " --width=40 --lines=6)

    case "$choice" in
        *"Display Configuration"*)
            notify-send "Settings" "Edit ~/.config/niri/config.kdl for display settings" -i "preferences-desktop-display"
            ghostty -e nvim ~/.config/niri/config.kdl &
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
    choice=$(printf '%s\n' "${options[@]}" | walker --dmenu --prompt="Network Settings: " --width=40 --lines=6)

    case "$choice" in
        *"WiFi Networks"*)
            nmcli device wifi list | walker --dmenu --prompt="WiFi Networks: " --width=60
            ;;
        *"Bluetooth Devices"*)
            bluetoothctl devices | walker --dmenu --prompt="Bluetooth Devices: " --width=60
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

    printf '%s\n' "${info[@]}" | walker --dmenu --prompt="System Info: " --width=50 --lines=8
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

    local choice
    choice=$(printf '%s\n' "${options[@]}" | walker --dmenu --prompt="Settings: " --width=40 --lines=10)

    case "$choice" in
        *"Audio Settings"*) audio_menu ;;
        *"Display Settings"*) display_menu ;;
        *"Network Settings"*) network_menu ;;
        *"Input Settings"*)
            notify-send "Settings" "Configure input in Niri config" -i "preferences-desktop-keyboard"
            ghostty -e nvim ~/.config/niri/config.kdl &
            ;;
        *"Notification Settings"*)
            ghostty -e nvim ~/.config/mako/config &
            ;;
        *"System Information"*) system_info ;;
        *"Edit Niri Config"*) ghostty -e nvim ~/.config/niri/config.kdl & ;;
        *"Edit Home Config"*) ghostty -e nvim ~/.config/fish/config.fish & ;;
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
