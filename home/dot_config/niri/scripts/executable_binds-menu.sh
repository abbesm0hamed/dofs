#!/bin/bash
set -euo pipefail

LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/niri/binds-menu.log"
mkdir -p "$(dirname "$LOG_FILE")"

{
    date
    echo "binds-menu invoked"
} >>"$LOG_FILE"

# niri-launched scripts sometimes have a minimal PATH
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

BINDS_FILE="${HOME}/.config/niri/binds.kdl"

if [ ! -f "$BINDS_FILE" ]; then
    notify-send "Niri" "Missing $BINDS_FILE"
    exit 1
fi

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        notify-send "Niri" "Missing command: $1"
        echo "missing command: $1" >>"$LOG_FILE"
        exit 1
    fi
}

need_cmd awk
need_cmd sort
need_cmd rofi
need_cmd wl-copy

if command -v notify-send >/dev/null 2>&1; then
    :
else
    echo "notify-send not found" >>"$LOG_FILE"
fi

# Extract bind lines like:
#   Mod+Return { spawn "wezterm"; }
# and multi-line blocks like:
#   Alt+Ctrl+L {
#       spawn "hyprlock"
#   }
SELECTION=$(
    awk '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function clean_action(s) {
    s = trim(s)
    # Remove trailing comments
    sub(/[ \t]*\/\/.*$/, "", s)
    # Remove one leading { and one trailing } if present
    sub(/^\{/, "", s)
    sub(/\}$/, "", s)
    # Remove trailing semicolon
    sub(/;[ \t]*$/, "", s)
    # Compress multiple spaces
    gsub(/[ \t]+/, " ", s)
    return trim(s)
}
BEGIN { inbinds=0; inblock=0; trigger=""; action="" }
{
    line = $0
    # Strip full-line comments early
    if (line ~ /^[ \t]*\/\//) next

    if (!inbinds && line ~ /^[ \t]*binds[ \t]*\{/) {
        inbinds = 1
        next
    }
    if (inbinds && !inblock && line ~ /^[ \t]*\}/) {
        inbinds = 0
        next
    }
    if (!inbinds) next

    if (!inblock) {
        # Single-line: trigger { action; }
        if (match(line, /^[ \t]*(.*?)[ \t]*\{(.*)\}[ \t]*(\/\/.*)?$/, m)) {
            t = trim(m[1])
            a = clean_action(m[2])
            if (t != "" && a != "") print t "\t" a
            next
        }
        # Multi-line start: trigger {
        if (match(line, /^[ \t]*(.*?)[ \t]*\{[ \t]*(\/\/.*)?$/, m)) {
            inblock = 1
            trigger = trim(m[1])
            action = ""
            next
        }
    } else {
        # Multi-line end: }
        if (line ~ /^[ \t]*\}[ \t]*(\/\/.*)?$/) {
            a = clean_action(action)
            if (trigger != "" && a != "") print trigger "\t" a
            inblock = 0
            next
        }
        action = action " " $0
    }
}
' "$BINDS_FILE" |
        awk -F'\t' '{ printf "%-35s ->  %s\n", $1, $2 }' |
        sort -u |
        rofi -dmenu -i -p "󰌌 Niri Binds" -theme-str 'window { width: 60%; height: 70%; }'
)

if [ -z "${SELECTION:-}" ]; then
    echo "no selection" >>"$LOG_FILE"
    exit 0
fi

printf '%s' "$SELECTION" | wl-copy

echo "copied: $SELECTION" >>"$LOG_FILE"

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Niri" "Bind copied to clipboard"
fi
