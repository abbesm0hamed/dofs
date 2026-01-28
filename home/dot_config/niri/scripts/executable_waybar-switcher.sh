#!/bin/bash

# waybar-switcher.sh - Switch between waybar configurations
# Similar to theme-picker.sh

set -euo pipefail

WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
CURRENT_CONFIG="$WAYBAR_DIR/config.jsonc"
CURRENT_STYLE="$WAYBAR_DIR/style.css"
STATE_FILE="$WAYBAR_DIR/.current-variant"

# Available variants
VARIANTS=(
    "default:Default (Full)"
    "minimal:Minimal (Workspaces + Essentials)"
)

get_current_variant() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "default"
    fi
}

switch_variant() {
    local variant=$1
    local config_file="$WAYBAR_DIR/config-${variant}.jsonc"
    local style_file="$WAYBAR_DIR/style-${variant}.css"
    
    # For default, use config.jsonc directly
    if [ "$variant" = "default" ]; then
        # Backup current if it's a symlink
        if [ -L "$CURRENT_CONFIG" ]; then
            rm "$CURRENT_CONFIG"
        fi
        
        # Restore original config if it was backed up
        if [ -f "$WAYBAR_DIR/config-default.jsonc" ]; then
            cp "$WAYBAR_DIR/config-default.jsonc" "$CURRENT_CONFIG"
        fi

        # Restore original style if it was backed up
        if [ -f "$WAYBAR_DIR/style-default.css" ]; then
            cp "$WAYBAR_DIR/style-default.css" "$CURRENT_STYLE"
        fi
    else
        # Check if variant exists
        if [ ! -f "$config_file" ]; then
            notify-send "Waybar Switcher" "Variant '$variant' not found" -u critical
            return 1
        fi
        
        # Backup default config if not already done
        if [ ! -f "$WAYBAR_DIR/config-default.jsonc" ] && [ ! -L "$CURRENT_CONFIG" ]; then
            cp "$CURRENT_CONFIG" "$WAYBAR_DIR/config-default.jsonc"
        fi

        # Backup default style if not already done
        if [ ! -f "$WAYBAR_DIR/style-default.css" ] && [ -f "$CURRENT_STYLE" ] && [ ! -L "$CURRENT_STYLE" ]; then
            cp "$CURRENT_STYLE" "$WAYBAR_DIR/style-default.css"
        fi
        
        # Copy variant to active config
        cp "$config_file" "$CURRENT_CONFIG"

        if [ -f "$style_file" ]; then
            cp "$style_file" "$CURRENT_STYLE"
        fi
    fi
    
    # Save current variant
    echo "$variant" > "$STATE_FILE"
    
    # Reload waybar
    pkill -SIGUSR2 waybar || {
        pkill waybar
        sleep 0.2
        waybar & disown
    }
    
    notify-send "Waybar Switcher" "Switched to $variant variant" -t 2000
}

show_picker() {
    local current=$(get_current_variant)
    local options=""
    
    for variant in "${VARIANTS[@]}"; do
        local key="${variant%%:*}"
        local label="${variant##*:}"
        
        if [ "$key" = "$current" ]; then
            options+="✓ $label\n"
        else
            options+="  $label\n"
        fi
    done
    
    local selected=$(echo -e "$options" | rofi -dmenu -i -p "Waybar Variant" -theme-str 'window {width: 400px;}')
    
    if [ -n "$selected" ]; then
        # Extract variant key from selection
        local variant_label="${selected#* }"  # Remove checkmark
        variant_label="${variant_label# }"    # Remove leading space
        
        for variant in "${VARIANTS[@]}"; do
            local key="${variant%%:*}"
            local label="${variant##*:}"
            
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
    "default"|"minimal")
        switch_variant "$1"
        ;;
    "current")
        get_current_variant
        ;;
    *)
        echo "Usage: $0 [picker|default|minimal|current]"
        exit 1
        ;;
esac
