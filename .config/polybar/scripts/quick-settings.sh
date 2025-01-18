#!/bin/bash

# Cache directory and files
CACHE_DIR="$HOME/.cache/quick-settings"
SINKS_CACHE="$CACHE_DIR/audio_sinks"
WIFI_CACHE="$CACHE_DIR/wifi_status"
BT_CACHE="$CACHE_DIR/bluetooth_status"
CACHE_TIMEOUT=5  # Cache timeout in seconds

mkdir -p "$CACHE_DIR"

# Helper function to check if cache is valid
is_cache_valid() {
    local cache_file="$1"
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    local current_time=$(date +%s)
    local file_time=$(stat -c %Y "$cache_file")
    local age=$((current_time - file_time))
    [ $age -le $CACHE_TIMEOUT ]
}

# Function to get current brightness
get_brightness() {
    current=$(brightnessctl g)
    max=$(brightnessctl m)
    echo $((current * 100 / max))
}

# Function to get volume
get_volume() {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]{1,3}(?=%)' | head -1
}

# Function to get active sink name
get_active_sink_name() {
    pactl get-default-sink | xargs -I{} pactl list sinks short | grep "^{}" | cut -f2
}

# Cache audio sinks in background
cache_audio_sinks() {
    pactl list sinks | grep -E 'Name:|Description:' > "$SINKS_CACHE" &
}

# Function to get WiFi status and SSID
get_wifi_status() {
    if is_cache_valid "$WIFI_CACHE"; then
        cat "$WIFI_CACHE"
        return
    fi

    if [[ $(nmcli radio wifi) == "enabled" ]]; then
        SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
        if [ -n "$SSID" ]; then
            echo "on ($SSID)" > "$WIFI_CACHE"
        else
            echo "on (disconnected)" > "$WIFI_CACHE"
        fi
    else
        echo "off" > "$WIFI_CACHE"
    fi
    cat "$WIFI_CACHE"
}

# Function to get bluetooth status and connected devices
get_bluetooth_status() {
    if is_cache_valid "$BT_CACHE"; then
        cat "$BT_CACHE"
        return
    fi

    if bluetoothctl show | grep -q "Powered: yes"; then
        DEVICES=$(bluetoothctl devices Connected | wc -l)
        if [ $DEVICES -gt 0 ]; then
            echo "on ($DEVICES connected)" > "$BT_CACHE"
        else
            echo "on (no devices)" > "$BT_CACHE"
        fi
    else
        echo "off" > "$BT_CACHE"
    fi
    cat "$BT_CACHE"
}

# Function to get airplane mode status
get_airplane_mode() {
    if [[ $(rfkill list all | grep -c "blocked: yes") -gt 0 ]]; then
        echo "on"
    else
        echo "off"
    fi
}

# Function to get night light status
get_night_light() {
    if [ -f "$HOME/.config/redshift/pid" ] && pgrep -x redshift >/dev/null; then
        echo "on"
    else
        echo "off"
    fi
}

# Function to toggle night light
toggle_night_light() {
    mkdir -p "$HOME/.config/redshift"
    
    if pgrep -x redshift >/dev/null; then
        pkill redshift
        # Reset screen temperature and cleanup
        redshift -x
        rm -f "$HOME/.config/redshift/pid"
    else
        # Start redshift with fixed location and temperature values for better reliability
        redshift -l 36.8:10.2 -t 6500:4200 -r -P &
        echo $! > "$HOME/.config/redshift/pid"
    fi
}

# Function to get current power profile
get_power_profile() {
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl get
    else
        echo "N/A"
    fi
}

# WiFi submenu
wifi_menu() {
    if [[ $(nmcli radio wifi) == "enabled" ]]; then
        # Only rescan if cache is invalid
        if ! is_cache_valid "$WIFI_CACHE"; then
            nmcli device wifi rescan >/dev/null 2>&1 &
        fi
        
        # Get list of networks with signal strength
        networks=$(nmcli -f SSID,SIGNAL,SECURITY device wifi list | tail -n +2 | sort -k2 -nr | awk '{print $1 " (" $2 "% " $3 ")"}')
        chosen_network=$(echo -e "󰖩 Turn Off WiFi\n---\n$networks" | rofi -dmenu -p "WiFi Networks")
        
        if [[ $chosen_network == "󰖩" ]]; then
            nmcli radio wifi off
        elif [[ -n $chosen_network ]]; then
            if nmcli -f SECURITY device wifi list | grep -q "$chosen_network.*WPA"; then
                password=$(rofi -dmenu -p "Password" -password)
                if [[ -n $password ]]; then
                    nmcli device wifi connect "$chosen_network" password "$password"
                fi
            else
                nmcli device wifi connect "$chosen_network"
            fi
        fi
    else
        nmcli radio wifi on
    fi
}

# Bluetooth submenu
bluetooth_menu() {
    if ! bluetoothctl show | grep -q "Powered: yes"; then
        bluetoothctl power on
    fi
    
    # Get list of devices
    devices=$(bluetoothctl devices | while read -r _ mac name; do
        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            echo "󰂇 $name (connected)"
        else
            echo "󰂯 $name"
        fi
    done)
    
    chosen_device=$(echo -e "󰂲 Turn Off Bluetooth\n󱑈 Scan for Devices\n---\n$devices" | rofi -dmenu -p "Bluetooth")
    
    case "$chosen_device" in
        *"Turn Off Bluetooth"*)
            bluetoothctl power off
            ;;
        *"Scan for Devices"*)
            notify-send "Bluetooth" "Scanning for devices..."
            bluetoothctl scan on &
            sleep 5
            killall bluetoothctl
            bluetooth_menu
            ;;
        *)
            device_name=$(echo "$chosen_device" | cut -d' ' -f2-)
            if echo "$chosen_device" | grep -q "connected"; then
                mac=$(bluetoothctl devices | grep "$device_name" | cut -d' ' -f2)
                bluetoothctl disconnect "$mac"
            else
                mac=$(bluetoothctl devices | grep "$device_name" | cut -d' ' -f2)
                bluetoothctl connect "$mac"
            fi
            ;;
    esac
}

# Audio submenu
audio_menu() {
    # Get list of sinks from cache if available, otherwise get fresh list
    if [ -f "$SINKS_CACHE" ]; then
        sinks=$(cat "$SINKS_CACHE")
    else
        sinks=$(pactl list sinks | grep -E 'Name:|Description:')
    fi
    current_sink=$(pactl get-default-sink)
    current_volume=$(get_volume)
    
    # Format sink list with icons
    formatted_sinks=$(echo "$sinks" | paste - - | sed 's/Name: //;s/Description: //' | while IFS=$'\t' read -r name desc; do
        if [ "$name" = "$current_sink" ]; then
            echo "󰕾 $desc (active)"
        else
            echo "󰕿 $desc"
        fi
    done)
    
    # Show sink selection menu
    chosen_sink=$(echo -e "󰕾 Volume: $current_volume%\n---\n$formatted_sinks" | rofi -dmenu -p "Audio")
    
    if [[ $chosen_sink == *"Volume"* ]]; then
        new_vol=$(echo -e "0\n10\n20\n30\n40\n50\n60\n70\n80\n90\n100" | rofi -dmenu -p "Volume")
        [[ -n $new_vol ]] && pactl set-sink-volume @DEFAULT_SINK@ ${new_vol}%
    else
        sink_name=$(echo "$sinks" | grep -B1 "${chosen_sink#* }" | head -1 | sed 's/Name: //')
        [[ -n $sink_name ]] && pactl set-default-sink "$sink_name"
    fi
}

# Brightness submenu with custom values
brightness_menu() {
    current=$(get_brightness)
    new_brightness=$(echo -e "󰃟 Current: $current%\n---\n󰃠 100%\n󰃝 90%\n󰃜 80%\n󰃛 70%\n󰃚 60%\n󰃙 50%\n󰃘 40%\n󰃗 30%\n󰃖 20%\n󰃕 10%" | \
        rofi -dmenu -p "Brightness" | grep -o '[0-9]*')
    [[ -n $new_brightness ]] && brightnessctl set "${new_brightness}%"
}

# Power profiles submenu
power_profile_menu() {
    if command -v powerprofilesctl &>/dev/null; then
        current=$(powerprofilesctl get)
        profile=$(echo -e "󰓅 Performance\n󰗑 Balanced\n󰾆 Power-saver" | rofi -dmenu -p "Power Profile ($current)")
        case "$profile" in
            *"Performance"*) powerprofilesctl set performance ;;
            *"Balanced"*) powerprofilesctl set balanced ;;
            *"Power-saver"*) powerprofilesctl set power-saver ;;
        esac
    else
        notify-send "Power Profiles" "power-profiles-daemon is not installed"
    fi
}

# Start background caching
cache_audio_sinks
# Pre-cache other statuses
get_wifi_status >/dev/null &
get_bluetooth_status >/dev/null &

# Create the main menu content
create_menu() {
    brightness=$(get_brightness)
    volume=$(get_volume)
    wifi_status=$(get_wifi_status)
    airplane_mode=$(get_airplane_mode)
    bluetooth_status=$(get_bluetooth_status)
    night_light=$(get_night_light)
    power_profile=$(get_power_profile)
    sink_name=$(get_active_sink_name)

    echo "󰃟 Brightness ($brightness%)"
    echo "󰕾 Audio ($volume%)"
    echo "󰖩 WiFi $wifi_status"
    echo "󰂯 Bluetooth $bluetooth_status"
    echo "󰀝 Airplane Mode ($airplane_mode)"
    echo "󰛨 Night Light ($night_light)"
    echo "󱐋 Power Profile ($power_profile)"
    echo "󰐥 Power"
}

# Handle selection
handle_selection() {
    case "$1" in
        *"Brightness"*)
            brightness_menu
            ;;
        *"Audio"*)
            audio_menu
            ;;
        *"WiFi"*)
            wifi_menu
            ;;
        *"Bluetooth"*)
            bluetooth_menu
            ;;
        *"Airplane Mode"*)
            if [[ $(get_airplane_mode) == "off" ]]; then
                rfkill block all
            else
                rfkill unblock all
            fi
            ;;
        *"Night Light"*)
            toggle_night_light
            ;;
        *"Power Profile"*)
            power_profile_menu
            ;;
        *"Power"*)
            action=$(echo -e "󰐥 Power Options\n---\n󰤆 Shutdown\n󰑙 Reboot\n󰍃 Logout\n󰒲 Suspend\n󰌾 Lock" | rofi -dmenu)
            case "$action" in
                *"Shutdown"*) systemctl poweroff ;;
                *"Reboot"*) systemctl reboot ;;
                *"Logout"*) i3-msg exit ;;
                *"Suspend"*) systemctl suspend ;;
                *"Lock"*) i3lock -c 000000 ;;
            esac
            ;;
    esac
}

# Show menu and handle selection
selection=$(create_menu | rofi -dmenu -p "Quick Settings" -selected-row 0)
[[ -n "$selection" ]] && handle_selection "$selection"
