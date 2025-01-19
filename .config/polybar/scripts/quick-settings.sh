#!/bin/bash

# Cache directory and files
CACHE_DIR="${HOME}/.cache/quick-settings"
SINKS_CACHE="${CACHE_DIR}/audio_sinks"
WIFI_CACHE="${CACHE_DIR}/wifi_status"
BT_CACHE="${CACHE_DIR}/bluetooth_status"
CACHE_TIMEOUT=5  # Cache timeout in seconds

mkdir -p "${CACHE_DIR}"

# Helper function to check if cache is valid
is_cache_valid() {
    [[ -f "$1" ]] && [[ $(($(date +%s) - $(stat -c %Y "$1"))) -le ${CACHE_TIMEOUT} ]]
}

# Function to get current brightness
get_brightness() {
    local current max
    read -r current < <(brightnessctl g)
    read -r max < <(brightnessctl m)
    echo $((current * 100 / max))
}

# Function to get volume
get_volume() {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]{1,3}(?=%)' | head -1
}

# Function to get active sink name
get_active_sink_name() {
    local current_sink
    current_sink=$(pactl get-default-sink)
    pactl list sinks | awk -v sink="$current_sink" '
        $0 ~ "^Sink #" {in_sink=0}
        $0 ~ "Name: "sink"$" {in_sink=1; next}
        in_sink && $0 ~ "Description: " {sub("^.*: ", ""); print; exit}
    '
}

# Cache audio sinks in background
cache_audio_sinks() {
    pactl list sinks | awk '/Name:|Description:/' > "${SINKS_CACHE}" &
}

# Function to get WiFi status and SSID
get_wifi_status() {
    if is_cache_valid "${WIFI_CACHE}"; then
        cat "${WIFI_CACHE}"
        return
    fi

    local status output
    status=$(nmcli -t radio wifi)
    if [[ ${status} == "enabled" ]]; then
        read -r output < <(nmcli -t -f active,ssid dev wifi | awk -F: '/^yes/ {print $2}')
        echo "on (${output:-disconnected})" > "${WIFI_CACHE}"
    else
        echo "off" > "${WIFI_CACHE}"
    fi
    cat "${WIFI_CACHE}"
}

# Function to get bluetooth status and connected devices
get_bluetooth_status() {
    if is_cache_valid "${BT_CACHE}"; then
        cat "${BT_CACHE}"
        return
    fi

    if bluetoothctl show | grep -q "Powered: yes"; then
        local devices
        devices=$(bluetoothctl devices Connected | wc -l)
        echo "on (${devices:-no} device${devices:+s} connected)" > "${BT_CACHE}"
    else
        echo "off" > "${BT_CACHE}"
    fi
    cat "${BT_CACHE}"
}

# Function to get airplane mode status
get_airplane_mode() {
    [[ $(rfkill list all | grep -c "blocked: yes") -gt 0 ]] && echo "on" || echo "off"
}

# Function to get night light status
get_night_light() {
    pgrep -x gammastep >/dev/null && echo "on" || echo "off"
}

# Function to toggle night light
toggle_night_light() {
    if pgrep -x gammastep >/dev/null; then
        pkill gammastep && gammastep -x
    else
        gammastep -l 36.8:10.2 -t 6500:3500 -P &
    fi
}

# Function to get current power profile
get_power_profile() {
    command -v powerprofilesctl &>/dev/null && powerprofilesctl get || echo "N/A"
}

# Show loading notification
show_loading() {
    notify-send -t 1000 "Quick Settings" "Loading..." &
}

# WiFi submenu
wifi_menu() {
    show_loading
    local status networks chosen_network password
    status=$(nmcli radio wifi)
    
    if [[ ${status} == "enabled" ]]; then
        # Only rescan if cache is invalid
        is_cache_valid "${WIFI_CACHE}" || nmcli device wifi rescan >/dev/null 2>&1 &
        
        # Get list of networks with signal strength
        networks=$(nmcli -f SSID,SIGNAL,SECURITY device wifi list | tail -n +2 | sort -k2 -nr | 
                  awk '{print $1 " (" $2 "% " $3 ")"}')
        chosen_network=$(printf "󰖩 Turn Off WiFi\n---\n%s" "${networks}" | rofi -dmenu -p "WiFi Networks")
        
        case "${chosen_network}" in
            "󰖩 Turn Off WiFi")
                nmcli radio wifi off
                ;;
            "")
                return
                ;;
            *)
                if nmcli -f SECURITY device wifi list | grep -q "${chosen_network}.*WPA"; then
                    password=$(rofi -dmenu -p "Password" -password)
                    [[ -n ${password} ]] && nmcli device wifi connect "${chosen_network}" password "${password}"
                else
                    nmcli device wifi connect "${chosen_network}"
                fi
                ;;
        esac
    else
        nmcli radio wifi on
    fi
}

# Bluetooth submenu
bluetooth_menu() {
    show_loading
    local devices chosen_device device_name mac
    
    if ! bluetoothctl show | grep -q "Powered: yes"; then
        bluetoothctl power on
    fi
    
    # Get list of devices
    devices=$(bluetoothctl devices | while read -r _ mac name; do
        if bluetoothctl info "${mac}" | grep -q "Connected: yes"; then
            printf "󰂇 %s (connected)\n" "${name}"
        else
            printf "󰂯 %s\n" "${name}"
        fi
    done)
    
    chosen_device=$(printf "󰂲 Turn Off Bluetooth\n󱑈 Scan for Devices\n---\n%s" "${devices}" | rofi -dmenu -p "Bluetooth")
    
    case "${chosen_device}" in
        *"Turn Off Bluetooth"*)
            bluetoothctl power off
            ;;
        *"Scan for Devices"*)
            notify-send "Bluetooth" "Scanning for devices..."
            timeout 5 bluetoothctl scan on
            bluetooth_menu
            ;;
        "")
            return
            ;;
        *)
            device_name=${chosen_device#* }
            device_name=${device_name% (*}
            mac=$(bluetoothctl devices | awk -v name="${device_name}" '$0 ~ name {print $2}')
            if [[ ${chosen_device} == *"connected"* ]]; then
                bluetoothctl disconnect "${mac}"
            else
                bluetoothctl connect "${mac}"
            fi
            ;;
    esac
}

# Audio submenu
audio_menu() {
    show_loading
    local sinks chosen_sink sink_name
    
    # Get list of sinks from cache if available, otherwise get fresh list
    if [[ -f "${SINKS_CACHE}" ]]; then
        sinks=$(cat "${SINKS_CACHE}")
    else
        sinks=$(pactl list sinks | awk '/Name:|Description:/')
        echo "${sinks}" > "${SINKS_CACHE}"
    fi
    
    chosen_sink=$(echo "${sinks}" | awk -F': ' '
        /Name:/ {name=$2}
        /Description:/ {print name " | " $2}
    ' | rofi -dmenu -p "Audio Output")
    
    [[ -n ${chosen_sink} ]] && pactl set-default-sink "${chosen_sink%% |*}"
}

# Brightness submenu with custom values
brightness_menu() {
    show_loading
    local value
    value=$(printf "100%%\n75%%\n50%%\n25%%\n10%%" | rofi -dmenu -p "Brightness")
    [[ -n ${value} ]] && brightnessctl s "${value}"
}

# Power profiles submenu
power_profile_menu() {
    show_loading
    local profile
    if command -v powerprofilesctl &>/dev/null; then
        profile=$(printf "performance\nbalanced\npower-saver" | rofi -dmenu -p "Power Profile")
        [[ -n ${profile} ]] && powerprofilesctl set "${profile}"
    else
        notify-send "Power Profiles" "Power profiles daemon not available"
    fi
}

# Create menu
create_menu() {
    local wifi_status bt_status airplane_status night_light_status power_profile
    wifi_status=$(get_wifi_status)
    bt_status=$(get_bluetooth_status)
    airplane_status=$(get_airplane_mode)
    night_light_status=$(get_night_light)
    power_profile=$(get_power_profile)
    
    cat << EOF
󰤨 WiFi (${wifi_status})
󰂯 Bluetooth (${bt_status})
󰀝 Airplane Mode (${airplane_status})
󰛨 Night Light (${night_light_status})
󰃟 Audio Output ($(get_active_sink_name))
󰃞 Volume ($(get_volume)%)
󰃠 Brightness ($(get_brightness)%)
󰈐 Power Profile (${power_profile})
󰐥 Power
EOF
}

# Handle selection
handle_selection() {
    case "$1" in
        *"WiFi"*) wifi_menu ;;
        *"Bluetooth"*) bluetooth_menu ;;
        *"Airplane Mode"*)
            if [[ $(get_airplane_mode) == "on" ]]; then
                rfkill unblock all
            else
                rfkill block all
            fi
            ;;
        *"Night Light"*) toggle_night_light ;;
        *"Audio Output"*) audio_menu ;;
        *"Volume"*) pavucontrol ;;
        *"Brightness"*) brightness_menu ;;
        *"Power Profile"*) power_profile_menu ;;
        *"Power"*)
            action=$(printf "󰐥 Power Options\n---\n󰤆 Shutdown\n󰑙 Reboot\n󰍃 Logout\n󰒲 Suspend\n󰌾 Lock" | rofi -dmenu -p "Power")
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

# Start background caching and show menu
cache_audio_sinks
get_wifi_status >/dev/null &
get_bluetooth_status >/dev/null &

show_loading
selection=$(create_menu | rofi -dmenu -p "Quick Settings" -selected-row 0)
[[ -n "${selection}" ]] && handle_selection "${selection}"
