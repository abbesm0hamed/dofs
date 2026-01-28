#!/bin/bash

# waybar-switcher.sh - Switch between waybar configurations
# Similar to theme-picker.sh

set -euo pipefail

WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
VARIANTS_DIR="$WAYBAR_DIR/variants"
CURRENT_CONFIG="$WAYBAR_DIR/config.jsonc"
CURRENT_STYLE="$WAYBAR_DIR/style.css"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
STATE_FILE="$STATE_DIR/current_variant"

LEGACY_STATE_FILE="$WAYBAR_DIR/.current-variant"
if [ -f "$LEGACY_STATE_FILE" ] && [ ! -f "$STATE_FILE" ]; then
    mkdir -p "$STATE_DIR"
    mv "$LEGACY_STATE_FILE" "$STATE_FILE"
fi

DEFAULT_VARIANT="default"
DEFAULT_LABEL="Default"

VARIANT_KEYS=()
VARIANT_LABELS=()

load_variants() {
    VARIANT_KEYS=()
    VARIANT_LABELS=()
    VARIANT_KEYS+=("$DEFAULT_VARIANT")
    VARIANT_LABELS+=("$DEFAULT_LABEL")

    if [ ! -d "$VARIANTS_DIR" ]; then
        return 0
    fi

    for dir in "$VARIANTS_DIR"/*; do
        [ -d "$dir" ] || continue
        local key
        local label
        key="$(basename "$dir")"
        label="$key"

        if [ -f "$dir/label" ]; then
            label="$(head -n 1 "$dir/label")"
        fi

        if [ "$key" = "$DEFAULT_VARIANT" ]; then
            VARIANT_LABELS[0]="$label"
            continue
        fi

        VARIANT_KEYS+=("$key")
        VARIANT_LABELS+=("$label")
    done
}

get_current_variant() {
    if [ -f "$CURRENT_CONFIG" ] && [ -d "$VARIANTS_DIR" ]; then
        for dir in "$VARIANTS_DIR"/*; do
            [ -d "$dir" ] || continue
            local key
            local config_file
            key="$(basename "$dir")"
            config_file="$dir/config.jsonc"

            if [ -f "$config_file" ] && cmp -s "$config_file" "$CURRENT_CONFIG"; then
                echo "$key"
                return 0
            fi
        done
    fi

    if [ -f "$STATE_FILE" ]; then
        local state
        state="$(cat "$STATE_FILE")"

        if [ -n "$state" ] && { [ -d "$VARIANTS_DIR/$state" ] || [ "$state" = "$DEFAULT_VARIANT" ]; }; then
            echo "$state"
            return 0
        fi
    fi

    echo "$DEFAULT_VARIANT"
}

switch_variant() {
    local variant=$1
    local config_file="$VARIANTS_DIR/$variant/config.jsonc"
    local style_file="$VARIANTS_DIR/$variant/style.css"

    if [ "$variant" = "$DEFAULT_VARIANT" ]; then
        if [ -f "$VARIANTS_DIR/$DEFAULT_VARIANT/config.jsonc" ]; then
            cp "$VARIANTS_DIR/$DEFAULT_VARIANT/config.jsonc" "$CURRENT_CONFIG"
        elif [ ! -f "$CURRENT_CONFIG" ]; then
            notify-send "Waybar Switcher" "Default config missing in $CURRENT_CONFIG" -u critical
            return 1
        fi

        if [ -f "$VARIANTS_DIR/$DEFAULT_VARIANT/style.css" ]; then
            cp "$VARIANTS_DIR/$DEFAULT_VARIANT/style.css" "$CURRENT_STYLE"
        fi
    else
        if [ ! -f "$config_file" ]; then
            notify-send "Waybar Switcher" "Variant '$variant' not found" -u critical
            return 1
        fi

        if [ -f "$CURRENT_CONFIG" ] && [ ! -f "$VARIANTS_DIR/$DEFAULT_VARIANT/config.jsonc" ]; then
            mkdir -p "$VARIANTS_DIR/$DEFAULT_VARIANT"
            cp "$CURRENT_CONFIG" "$VARIANTS_DIR/$DEFAULT_VARIANT/config.jsonc"
        fi

        if [ -f "$CURRENT_STYLE" ] && [ ! -f "$VARIANTS_DIR/$DEFAULT_VARIANT/style.css" ]; then
            mkdir -p "$VARIANTS_DIR/$DEFAULT_VARIANT"
            cp "$CURRENT_STYLE" "$VARIANTS_DIR/$DEFAULT_VARIANT/style.css"
        fi

        cp "$config_file" "$CURRENT_CONFIG"

        if [ -f "$style_file" ]; then
            cp "$style_file" "$CURRENT_STYLE"
        fi
    fi

    # Save current variant
    echo "$variant" >"$STATE_FILE"

    # Reload waybar
    pkill -SIGUSR2 waybar || {
        pkill waybar
        sleep 0.2
        waybar &
        disown
    }

    notify-send "Waybar Switcher" "Switched to $variant variant" -t 2000
}

show_picker() {
    load_variants
    local current=$(get_current_variant)
    local options=()

    for i in "${!VARIANT_KEYS[@]}"; do
        local key="${VARIANT_KEYS[$i]}"
        local label="${VARIANT_LABELS[$i]}"
        local prefix="  "

        if [ "$key" = "$current" ]; then
            prefix="✓ "
        fi

        options+=("$prefix$label")
    done

    local selected
    selected=$(printf '%s\n' "${options[@]}" | rofi -dmenu -i -p "Waybar Variant" -theme-str 'window {width: 30%;}')

    if [ -n "$selected" ]; then
        # Extract variant key from selection
        local variant_label="${selected#* }" # Remove checkmark
        variant_label="${variant_label# }"   # Remove leading space

        for i in "${!VARIANT_KEYS[@]}"; do
            local key="${VARIANT_KEYS[$i]}"
            local label="${VARIANT_LABELS[$i]}"

            if [ "$label" = "$variant_label" ]; then
                switch_variant "$key"
                return 0
            fi
        done
    fi
}

# Main
case "${1:-picker}" in
    "picker")
        show_picker
        ;;
    "current")
        get_current_variant
        ;;
    *)
        if [ -d "$VARIANTS_DIR/$1" ]; then
            switch_variant "$1"
            exit 0
        fi

        echo "Usage: $0 [picker|current|<variant>]"
        exit 1
        ;;
esac
