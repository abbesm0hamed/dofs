#!/bin/bash

# Auto-generates KEYBINDINGS.md from configuration files.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_FILE="${REPO_ROOT}/KEYBINDINGS.md"

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }

# Clear the output file
> "$OUTPUT_FILE"

log "Generating KEYBINDINGS.md..."

# --- Niri Keybindings ---
log "Parsing Niri keybindings..."
NIRI_BINDS_FILE="${REPO_ROOT}/home/.config/niri/binds.kdl"
NIRI_CONFIG_FILE="${REPO_ROOT}/home/.config/niri/config.kdl"

if [ -f "$NIRI_BINDS_FILE" ]; then
    NIRI_CONFIG="$NIRI_BINDS_FILE"
else
    NIRI_CONFIG="$NIRI_CONFIG_FILE"
fi

if [ -f "$NIRI_CONFIG" ]; then
    echo "# Niri Keybindings" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "| Keybinding | Action |" >> "$OUTPUT_FILE"
    echo "|------------|--------|" >> "$OUTPUT_FILE"

    awk '
        function trim(s) {
            gsub(/^[ \t]+|[ \t]+$/, "", s)
            return s
        }
        function clean_key(s) {
            s = trim(s)
            gsub(/ allow-when-locked=true/, "", s)
            gsub(/ repeat=false/, "", s)
            gsub(/ cooldown-ms=[0-9]+/, "", s)
            return trim(s)
        }
        function clean_action(s) {
            s = trim(s)
            gsub(/;$/, "", s)
            s = trim(s)
            sub(/^spawn[ \t]+/, "", s)
            gsub(/"/, "", s)
            return trim(s)
        }
        /binds[ \t]*\{/ { in_binds = 1; next }
        in_binds {
            if ($0 ~ /^(\s*$|\s*\/\/)/) next

            # End of binds block
            if (!in_block && $0 ~ /^\s*\}/) { in_binds = 0; next }

            # Start of a bind entry (single-line or multi-line)
            if (!in_block && match($0, /^\s*([^\/\s][^\{]*?)\s*\{(.*)$/, m)) {
                key_part = clean_key(m[1])
                rest = m[2]

                # Single-line: key { action; }
                if (match(rest, /([^}]*)\}/, a)) {
                    action_part = clean_action(a[1])
                    if (key_part != "" && action_part != "") {
                        printf "| `%-25s` | `%-60s` |\n", key_part, action_part
                    }
                    key_part = ""; action_part = ""; in_block = 0
                    next
                }

                action_part = ""
                in_block = 1
                next
            }

            # Inside a multi-line bind block: capture the first meaningful action line
            if (in_block) {
                if ($0 ~ /^\s*\}/) {
                    if (key_part != "" && action_part != "") {
                        printf "| `%-25s` | `%-60s` |\n", key_part, action_part
                    }
                    key_part = ""; action_part = ""; in_block = 0
                    next
                }
                if ($0 ~ /^(\s*$|\s*\/\/)/) next
                if (action_part == "") {
                    action_part = clean_action($0)
                }
            }
        }
    ' "$NIRI_CONFIG" | sort >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
else
    log "Niri config not found at $NIRI_CONFIG"
fi

# --- Neovim Keybindings ---
log "Parsing Neovim keybindings..."
NVIM_LUA_DIR="${REPO_ROOT}/home/.config/nvim/lua"
NVIM_PLUGINS_DIR="$(find "$NVIM_LUA_DIR" -maxdepth 2 -type d -name plugins 2>/dev/null | head -n 1 || true)"

if [ -n "$NVIM_PLUGINS_DIR" ] && [ -d "$NVIM_PLUGINS_DIR" ]; then
    echo "# Neovim Keybindings" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "| Keybinding | Description |" >> "$OUTPUT_FILE"
    echo "|------------|-------------|" >> "$OUTPUT_FILE"

    # Use find and awk to parse all lua files in the plugins directory
    find "$NVIM_PLUGINS_DIR" -name "*.lua" -print0 | xargs -0 awk '
        BEGIN { key = ""; desc = ""; in_keys = 0; brace_level = 0 }
        /keys\s*=\s*{/ { in_keys = 1; next }
        in_keys {
            if (/{/) brace_level++
            if (/}/) brace_level--

            if (match($0, /^\s*"([^"]+)"/, k)) {
                key = k[1]
            }
            if (match($0, /desc\s*=\s*"([^"]+)"/, d)) {
                desc = d[1]
            }

            if (brace_level == 0 && key != "" && desc != "") {
                printf "| `%-20s` | %-50s |\n", key, desc
                key = ""; desc = ""
            }

            if (brace_level < 0) {
                in_keys = 0
                brace_level = 0
            }
        }
    ' | sort -u >> "$OUTPUT_FILE"

    echo "" >> "$OUTPUT_FILE"
else
    log "Neovim plugins directory not found at $NVIM_PLUGINS_DIR"
fi

# Helper for awk script - this is a bit of a hack to define the function
# The awk script will be called with this prepended.
awk_getline_func="function getline_buffer(n) { ARGC = 2; ARGV[1] = FILENAME; while (getline > 0) { if (NR==n) { return \$0 } }; close(FILENAME) }"

log "KEYBINDINGS.md generated successfully at ${OUTPUT_FILE}"
