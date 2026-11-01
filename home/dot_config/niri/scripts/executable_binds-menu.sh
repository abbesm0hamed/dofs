#!/bin/bash
# Keybind cheat sheet for the dofs Quickshell launcher.
# Provider: one JSON item per niri bind; activation copies it to the clipboard.
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/menu-lib.sh"

BINDS_FILE="${HOME}/.config/niri/binds.kdl"
[[ -f $BINDS_FILE ]] || { echo "missing $BINDS_FILE" >&2; exit 1; }

count=0
# Extract bind lines like:
#   Mod+Return { spawn "wezterm"; }
# and multi-line blocks like:
#   Alt+Ctrl+L {
#       spawn "sh" "-c" "~/.config/quickshell/dofs/scripts/lock-screen.sh"
#   }
while IFS=$'\t' read -r trigger action; do
    [[ -n $trigger && -n $action ]] || continue
    count=$((count + 1))
    summary=$(printf '%s  ->  %s' "$trigger" "$action")
    menu_item "$trigger" "$action" "preferences-desktop-keyboard" --copy "$summary"
done < <(
    awk '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function strip_comment(s,   i, q) {
    # Drop // comments, but never inside quotes (URLs like https://... are argv).
    q = 0
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\"") q = !q
        else if (q == 0 && substr(s, i, 2) == "//") { s = substr(s, 1, i - 1); break }
    }
    return s
}
function clean_action(s) {
    s = trim(strip_comment(s))
    sub(/^\{/, "", s)
    sub(/\}$/, "", s)
    sub(/;[ \t]*$/, "", s)
    gsub(/[ \t]+/, " ", s)
    return trim(s)
}
BEGIN { inbinds=0; inblock=0; trigger=""; action="" }
{
    line = $0
    if (line ~ /^[ \t]*\/\//) next
    if (!inbinds && line ~ /^[ \t]*binds[ \t]*\{/) { inbinds = 1; next }
    if (inbinds && !inblock && line ~ /^[ \t]*\}/) { inbinds = 0; next }
    if (!inbinds) next
    if (!inblock) {
        if (match(line, /^[ \t]*(.*?)[ \t]*\{(.*)\}[ \t]*(\/\/.*)?$/, m)) {
            t = trim(m[1]); a = clean_action(m[2])
            if (t != "" && a != "") print t "\t" a
            next
        }
        if (match(line, /^[ \t]*(.*?)[ \t]*\{[ \t]*(\/\/.*)?$/, m)) {
            inblock = 1; trigger = trim(m[1]); action = ""
            next
        }
    } else {
        if (line ~ /^[ \t]*\}[ \t]*(\/\/.*)?$/) {
            a = clean_action(action)
            if (trigger != "" && a != "") print trigger "\t" a
            inblock = 0
            next
        }
        action = action " " $0
    }
}
' "$BINDS_FILE" | sort -u
)

[[ $count -gt 0 ]] || { echo "no keybinds found in $BINDS_FILE" >&2; exit 1; }
