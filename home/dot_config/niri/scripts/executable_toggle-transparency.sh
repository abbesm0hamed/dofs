#!/bin/bash
set -euo pipefail

RULES_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/rules.kdl"

if [ ! -f "$RULES_FILE" ]; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Niri" "Missing rules file: $RULES_FILE"
    fi
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Niri" "Missing python3"
    fi
    exit 1
fi

mode=$(python3 - "$RULES_FILE" <<'PY'
import sys

path = sys.argv[1]

injected_old_escaped = """\
window-rule {
    match app-id=r#\"^(ghostty|Ghostty|com\\.mitchellh\\.ghostty)$\"#
    opacity 1.0
}

window-rule {
    match app-id=r#\"^(org\\.wezfurlong\\.wezterm|org\\.wezfurlong\\.wezterm-nightly)$\"#
    opacity 1.0
}

window-rule {
    match app-id=\"kitty\"
    opacity 1.0
}
"""

injected_new_escaped = """\
window-rule {
    match app-id=r#\"^(ghostty|Ghostty|com\\.mitchellh\\.ghostty(\\..*)?)$\"#
    opacity 1.0
}

window-rule {
    match app-id=r#\"^(org\\.wezfurlong\\.wezterm(-nightly|-gui)?|wezterm)$\"#
    opacity 1.0
}

window-rule {
    match app-id=\"kitty\"
    opacity 1.0
}
"""

injected_old = """\
window-rule {
    match app-id=r#"^(ghostty|Ghostty|com\\.mitchellh\\.ghostty)$"#
    opacity 1.0
}

window-rule {
    match app-id=r#"^(org\\.wezfurlong\\.wezterm|org\\.wezfurlong\\.wezterm-nightly)$"#
    opacity 1.0
}

window-rule {
    match app-id="kitty"
    opacity 1.0
}
"""

injected_new = """\
window-rule {
    match app-id=r#"^(ghostty|Ghostty|com\\.mitchellh\\.ghostty(\\..*)?)$"#
    opacity 1.0
}

window-rule {
    match app-id=r#"^(org\\.wezfurlong\\.wezterm(-nightly|-gui)?|wezterm)$"#
    opacity 1.0
}

window-rule {
    match app-id="kitty"
    opacity 1.0
}
"""

with open(path, "r", encoding="utf-8") as f:
    s = f.read()

found = False
for block in (injected_old_escaped, injected_new_escaped, injected_old, injected_new):
    if block in s:
        s = s.replace(block, "")
        found = True

if found:
    mode = "default"
else:
    if not s.endswith("\n"):
        s += "\n"
    s += "\n" + injected_new
    mode = "off"

with open(path, "w", encoding="utf-8") as f:
    f.write(s)

print(mode)
PY
)

niri msg action load-config-file >/dev/null 2>&1 || true

if command -v notify-send >/dev/null 2>&1; then
    if [ "$mode" = "off" ]; then
        notify-send "Niri" "Transparency: off"
    else
        notify-send "Niri" "Transparency: default"
    fi
fi
