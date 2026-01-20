#!/bin/bash

set -euo pipefail

# Configuration
WALLPAPER_DIR="${HOME}/.config/backgrounds"
FOREGROUND_WALLPAPER="${WALLPAPER_DIR}/spiral.jpg"
BACKDROP_WALLPAPER="${WALLPAPER_DIR}/blurry-spiral.jpg"

# Logging
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-autostart.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

echo "=== Niri Autostart - $(date) ==="
echo "Display: $WAYLAND_DISPLAY"

# Helper function to start a process if not already running
run_once() {
    local cmd0="$1"
    local pname
    pname="$(basename "$cmd0")"
    if ! pgrep -x "$pname" >/dev/null; then
        echo "  → Starting $cmd0..."
        "$@" &
    else
        echo "  → $cmd0 is already running."
    fi
}

# Source env
if [ -f "$HOME/.config/niri/configs/env" ]; then
    echo "  → Sourcing env..."
    source "$HOME/.config/niri/configs/env"
fi

# Cleanup/Setup environment
echo "Syncing env vars..."

# Import environment to systemd/dbus
ENVS_TO_IMPORT=(
    DISPLAY WAYLAND_DISPLAY
    XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE
    GTK_USE_PORTAL GDK_SCALE
    QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME QT_WAYLAND_DISABLE_WINDOWDECORATION
    QT_MEDIA_BACKEND QT_FFMPEG_DECODING_HW_DEVICE_TYPES QT_FFMPEG_ENCODING_HW_DEVICE_TYPES
    CLUTTER_BACKEND ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND
    LIBVA_DRIVER_NAME MESA_LOADER_DRIVER_OVERRIDE INTEL_DEBUG
    _JAVA_AWT_WM_NONREPARENTING
    XCURSOR_THEME XCURSOR_SIZE
    STEAM_FORCE_DESKTOPUI_SCALING GAMESCOPE_WSI_MODIFIERS IRIS_MESA_DEBUG
)

systemctl --user import-environment "${ENVS_TO_IMPORT[@]}" || true
dbus-update-activation-environment --systemd "${ENVS_TO_IMPORT[@]}" || true

# Wallpapers
if [ -f "$FOREGROUND_WALLPAPER" ]; then
    bash ~/.config/niri/scripts/wallpaper.sh "$FOREGROUND_WALLPAPER" "$BACKDROP_WALLPAPER" --silent &
fi

# Core Services
run_once waybar
run_once mako

# Polkit Agent
POLKIT_AGENT="/usr/libexec/polkit-gnome-authentication-agent-1"
[ ! -f "$POLKIT_AGENT" ] && POLKIT_AGENT="/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
if [ -f "$POLKIT_AGENT" ]; then
    run_once "$POLKIT_AGENT"
fi

# Clipboard Manager
if command -v cliphist &>/dev/null && command -v wl-paste &>/dev/null; then
    if ! pgrep -f "cliphist store" >/dev/null; then
        echo "  → Starting clipboard manager..."
        wl-paste --type text --watch cliphist store &
        wl-paste --type image --watch cliphist store &
    fi
fi

# Screen Idle / Lock
if command -v swayidle &>/dev/null; then
    if ! pgrep -x "swayidle" >/dev/null; then
        echo "  → Starting swayidle..."
        swayidle -w \
            timeout 600 'niri msg action power-off-monitors' \
            resume 'niri msg action power-on-monitors' \
            timeout 900 "hyprlock" \
            before-sleep "hyprlock" \
            lock "hyprlock" &
    fi
fi

# Audio Idle Inhibitor
if command -v sway-audio-idle-inhibit &>/dev/null; then
    run_once sway-audio-idle-inhibit
fi

# Zen Browser
# if command -v flatpak &>/dev/null; then
#     sleep 1
#     echo "  → Starting Zen..."
#     flatpak run --env=MOZ_ENABLE_WAYLAND=1 app.zen_browser.zen &
# fi

echo "=== Autostart script finished ==="
exit 0
