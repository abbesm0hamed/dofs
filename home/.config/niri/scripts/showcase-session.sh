#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

WORKSPACE_PREFIX="${SHOWCASE_WORKSPACE_PREFIX:-showcase}"
URL="${SHOWCASE_URL:-https://www.reddit.com/r/unixporn/}"

launch_terminal() {
    local app_id="$1"
    shift

    if command -v wezterm >/dev/null 2>&1; then
        wezterm start --class "$app_id" -- "$@" &
        return 0
    fi

    if command -v ghostty >/dev/null 2>&1; then
        ghostty --class="$app_id" -e "$@" &
        return 0
    fi

    if command -v kitty >/dev/null 2>&1; then
        kitty "--class=$app_id" -e "$@" &
        return 0
    fi

    if command -v foot >/dev/null 2>&1; then
        foot -a "$app_id" -e "$@" &
        return 0
    fi

    if command -v alacritty >/dev/null 2>&1; then
        alacritty --class "$app_id" -e "$@" &
        return 0
    fi

    return 1
}

launch_browser() {
    if [ -n "${SHOWCASE_BROWSER_CMD:-}" ]; then
        bash -lc "$SHOWCASE_BROWSER_CMD" &
        return 0
    fi

    if command -v flatpak >/dev/null 2>&1 && flatpak info app.zen_browser.zen >/dev/null 2>&1; then
        flatpak run app.zen_browser.zen "$URL" &
        return 0
    fi

    if command -v chromium-browser >/dev/null 2>&1; then
        chromium-browser --new-window "$URL" &
        return 0
    fi

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$URL" >/dev/null 2>&1 &
        return 0
    fi

    return 1
}

niri_action() {
    local action="$1"

    if command -v niri >/dev/null 2>&1; then
        niri msg action "$action" >/dev/null 2>&1 || true
    fi
}

niri_rename_workspace() {
    local name="$1"

    if command -v niri >/dev/null 2>&1; then
        niri msg action set-workspace-name "$name" >/dev/null 2>&1 || true
    fi
}

open_files_workspace() {
    niri_action focus-workspace-down
    sleep 0.1
    niri_rename_workspace "[${WORKSPACE_PREFIX}-files]"

    if command -v nautilus >/dev/null 2>&1; then
        nautilus "$HOME" >/dev/null 2>&1 &
    fi

    launch_browser || true
}

open_matrix_workspace() {
    niri_action focus-workspace-down
    sleep 0.1
    niri_rename_workspace "[${WORKSPACE_PREFIX}-matrix]"

    launch_terminal showcase-matrix bash -lc '
clear
printf "\n\e[1;36m%s\e[0m\n" "==== $(hostname) | $(date "+%A, %Y-%m-%d %H:%M:%S") ===="
echo
fastfetch 2>/dev/null || neofetch 2>/dev/null || uname -a
echo
if command -v cmatrix >/dev/null 2>&1; then
  cmatrix -b
else
  while true; do
    clear
    printf "\n\e[1;32m%s\e[0m\n\n" "cmatrix not installed"
    date
    sleep 1
  done
fi
' || true
}

open_binds_workspace() {
    niri_action focus-workspace-down
    sleep 0.1
    niri_rename_workspace "[${WORKSPACE_PREFIX}-binds]"

    if [ -x "$HOME/.config/niri/scripts/binds-menu.sh" ] && command -v rofi >/dev/null 2>&1; then
        "$HOME/.config/niri/scripts/binds-menu.sh" &
    else
        launch_terminal showcase-binds bash -lc 'sed -n "1,200p" "$HOME/.config/niri/binds.kdl" 2>/dev/null || true; exec bash -l' || true
    fi
}

open_files_workspace
open_matrix_workspace
open_binds_workspace

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Showcase session" "Opened showcase workspaces" >/dev/null 2>&1 || true
fi
