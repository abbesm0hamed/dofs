#!/bin/bash
set -euo pipefail

RULES_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/rules.kdl"
MARK_BEGIN="// DOFS_TRANSPARENCY_OVERRIDE_BEGIN"
MARK_END="// DOFS_TRANSPARENCY_OVERRIDE_END"
MARK_BEGIN_HASH="# DOFS_TRANSPARENCY_OVERRIDE_BEGIN"
MARK_END_HASH="# DOFS_TRANSPARENCY_OVERRIDE_END"

if [ ! -f "$RULES_FILE" ]; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Niri" "Missing rules file: $RULES_FILE"
    fi
    exit 1
fi

has_override=0
if grep -Fq "$MARK_BEGIN" "$RULES_FILE" 2>/dev/null; then
    has_override=1
elif grep -Fq "$MARK_BEGIN_HASH" "$RULES_FILE" 2>/dev/null; then
    has_override=1
elif grep -Eq '^[[:space:]]*match[[:space:]]+app-id=.*(ghostty|wezterm|kitty)' "$RULES_FILE" 2>/dev/null && grep -Eq '^[[:space:]]*opacity[[:space:]]+1\.0[[:space:]]*$' "$RULES_FILE" 2>/dev/null; then
    has_override=1
fi

if [ "$has_override" = "1" ]; then
    awk -v begin="$MARK_BEGIN" -v end="$MARK_END" -v begin_hash="$MARK_BEGIN_HASH" -v end_hash="$MARK_END_HASH" '
    function count_braces(s,   t, opens, closes) {
        t = s
        opens = gsub(/\{/, "{", t)
        closes = gsub(/\}/, "}", t)
        return opens - closes
    }

    function block_is_legacy_injection(b) {
        if (b !~ /opacity[[:space:]]+1\.0/) return 0
        if (b ~ /open-maximized|open-floating|draw-border-with-background|shadow[[:space:]]*\{|default-column-width|tiled-state|clip-to-geometry/) return 0
        if (b ~ /match[[:space:]]+app-id=.*ghostty/ || b ~ /match[[:space:]]+app-id=.*wezterm/ || b ~ /match[[:space:]]+app-id=.*kitty/) return 1
        return 0
    }

    BEGIN {
        skipping_marked = 0
        depth = 0
        in_block = 0
        block = ""
        base_depth = 0
    }

    {
        line = $0

        if (line == begin || line == begin_hash) {
            skipping_marked = 1
            next
        }
        if (skipping_marked) {
            if (line == end || line == end_hash) skipping_marked = 0
            next
        }

        if (!in_block && line ~ /^[[:space:]]*window-rule[[:space:]]*\{[[:space:]]*$/) {
            in_block = 1
            base_depth = depth
            block = line "\n"
        } else if (in_block) {
            block = block line "\n"
        } else {
            print line
        }

        depth += count_braces(line)

        if (in_block && depth == base_depth) {
            if (!block_is_legacy_injection(block)) {
                printf "%s", block
            }
            in_block = 0
            block = ""
        }
    }
    ' "$RULES_FILE" >"$RULES_FILE.tmp"

    mv "$RULES_FILE.tmp" "$RULES_FILE"
    mode="default"
else
    if [ -n "$(tail -c 1 "$RULES_FILE" 2>/dev/null || true)" ]; then
        printf '\n' >>"$RULES_FILE"
    fi

    {
        printf '%s\n' "$MARK_BEGIN"
        cat <<'KDL'
window-rule {
    match app-id=r#"^(ghostty|Ghostty|com\.mitchellh\.ghostty(\..*)?)$"#
    opacity 1.0
}

window-rule {
    match app-id=r#"^(org\.wezfurlong\.wezterm(-nightly|-gui)?|wezterm)$"#
    opacity 1.0
}

window-rule {
    match app-id="kitty"
    opacity 1.0
}
KDL
        printf '%s\n' "$MARK_END"
    } >>"$RULES_FILE"

    mode="off"
fi

niri msg action load-config-file >/dev/null 2>&1 || true

if command -v notify-send >/dev/null 2>&1; then
    if [ "$mode" = "off" ]; then
        notify-send "Niri" "Transparency: off"
    else
        notify-send "Niri" "Transparency: default"
    fi
fi
