#!/bin/bash
set -euo pipefail

if command -v curl >/dev/null 2>&1; then
    FETCH_CMD=(curl -fsSL)
elif command -v wget >/dev/null 2>&1; then
    FETCH_CMD=(wget -qO-)
else
    echo "Missing dependency: curl or wget" >&2
    read -r -n 1 -s
    exit 1
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/niri"
LOCATION_FILE="${CONFIG_DIR}/weather-location"

mkdir -p "$CONFIG_DIR"

LOCATION="${*:-}"
if [[ -z "$LOCATION" ]]; then
    LOCATION="${WEATHER_LOCATION:-}"
fi
if [[ -z "$LOCATION" ]] && [[ -f "$LOCATION_FILE" ]]; then
    LOCATION="$(cat "$LOCATION_FILE" 2>/dev/null || true)"
fi
if [[ -z "$LOCATION" ]]; then
    clear
    echo "Enter location for weather (example: Paris,FR or 48.8566,2.3522)."
    echo "Leave empty to use IP-based location (may be inaccurate)."
    printf "> "
    IFS= read -r LOCATION || true
    if [[ -n "$LOCATION" ]]; then
        printf '%s' "$LOCATION" > "$LOCATION_FILE"
    fi
fi

location_to_url_path() {
    local s="$1"
    s="${s// /+}"
    printf '%s' "$s"
}

fetch_weather() {
    local loc="$1"
    local loc_path
    local url
    local tmp

    loc_path="$(location_to_url_path "$loc")"
    url="https://wttr.in/${loc_path}"

    tmp="$(mktemp)"

    ( "${FETCH_CMD[@]}" "$url" >"$tmp" ) &
    local pid=$!

    local spin='|/-\\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\rLoading weather... %c" "${spin:i%4:1}"
        sleep 0.1
        i=$((i + 1))
    done
    printf "\r\033[K"

    if wait "$pid"; then
        clear
        cat "$tmp"
    else
        clear
        echo "Failed to fetch weather from $url"
        echo
        echo "Press 'r' to retry, 'l' to change location, 'q' to close."
        rm -f "$tmp"
        return 1
    fi

    rm -f "$tmp"
    return 0
}

fetch_weather "$LOCATION" || true

echo
echo "Location: ${LOCATION:-auto}" 
echo "Press 'r' to refresh, 'l' to set location, 'q' to close."

while true; do
    IFS= read -r -n 1 -s key || true
    case "$key" in
        q)
            exit 0
            ;;
        r)
            fetch_weather "$LOCATION" || true
            echo
            echo "Location: ${LOCATION:-auto}" 
            echo "Press 'r' to refresh, 'l' to set location, 'q' to close."
            ;;
        l)
            clear
            echo "Enter location (example: Paris,FR or 48.8566,2.3522)."
            echo "Leave empty to use IP-based location (may be inaccurate)."
            printf "> "
            IFS= read -r new_location || true
            LOCATION="$new_location"
            if [[ -n "$LOCATION" ]]; then
                printf '%s' "$LOCATION" > "$LOCATION_FILE"
            else
                rm -f "$LOCATION_FILE" 2>/dev/null || true
            fi

            fetch_weather "$LOCATION" || true
            echo
            echo "Location: ${LOCATION:-auto}" 
            echo "Press 'r' to refresh, 'l' to set location, 'q' to close."
            ;;
    esac
done
