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
    gsub(/[{};]/, "", s)
    gsub(/"/, "", s)
    gsub(/[ \t]+/, " ", s)
    return trim(s)
}
BEGIN { inblock=0; key=""; action="" }
{
    line=$0
    # Skip comments and blank lines
    if (line ~ /^[ \t]*\/\//) next
    if (line ~ /^[ \t]*$/) next

    if (!inblock) {
        # Single-line bind: Key ... { ... }
        if (match(line, /^[ \t]*([^ \t][^ {]*([+][^ {]+)*)[ \t]*\{(.*)\}[ \t]*$/, m)) {
            key=m[1]
            action=m[3]
            action=clean_action(action)
            if (action != "") print key "\t" action
            next
        }

        # Start of multi-line bind: Key ... {
        if (match(line, /^[ \t]*([^ \t][^ {]*([+][^ {]+)*)[ \t]*\{[ \t]*$/, m)) {
            inblock=1
            key=m[1]
            action=""
            next
        }

        next
    } else {
        # End of multi-line bind block
        if (line ~ /^[ \t]*\}[ \t]*$/) {
            a=clean_action(action)
            if (a != "") print key "\t" a
            inblock=0
            key=""
            action=""
            next
        }

        # Accumulate actions inside block
        action = action " " trim(line)
    }
}
' "$BINDS_FILE" |
        awk -F'\t' '{print $1 "  ->  " $2}' |
        sort -u |
        rofi -dmenu -p "󰌌 Niri Binds: " -theme-str 'window { width: 55%; height: 65%; }'
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
