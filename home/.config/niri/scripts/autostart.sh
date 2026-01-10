#!/bin/bash

set -euo pipefail

WALLPAPER_DIR="${HOME}/.config/backgrounds"
FOREGROUND_WALLPAPER="${WALLPAPER_DIR}/fold.jpg"
BACKDROP_WALLPAPER="${WALLPAPER_DIR}/blurry-fold.jpg"
LOCK_WALLPAPER="$BACKDROP_WALLPAPER"

# Logging
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-autostart.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

echo "=== Niri Autostart - $(date) ==="
echo "Display: $WAYLAND_DISPLAY"

# Source env
if [ -f "$HOME/.config/niri/configs/env" ]; then
    echo "  → Sourcing env..."
    source "$HOME/.config/niri/configs/env"
fi

# Cleanup
pkill waybar || true
pkill mako || true
pkill swayidle || true
pkill nm-applet || true
pkill blueman-applet || true
pkill swaybg || true
pkill hyprpaper || true

echo "Syncing env vars..."
# GDK_SCALE is already set in env file, ensure it's available
export GDK_SCALE="${GDK_SCALE:-1}"
# CRITICAL: GDK_BACKEND unset for auto-detect
unset GDK_BACKEND

# Import environment to systemd/dbus
systemctl --user import-environment \
    DISPLAY WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
    GTK_USE_PORTAL GDK_SCALE \
    QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME QT_WAYLAND_DISABLE_WINDOWDECORATION \
    QT_MEDIA_BACKEND QT_FFMPEG_DECODING_HW_DEVICE_TYPES QT_FFMPEG_ENCODING_HW_DEVICE_TYPES \
    CLUTTER_BACKEND ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND \
    LIBVA_DRIVER_NAME MESA_LOADER_DRIVER_OVERRIDE INTEL_DEBUG \
    _JAVA_AWT_WM_NONREPARENTING \
    XCURSOR_THEME XCURSOR_SIZE \
    STEAM_FORCE_DESKTOPUI_SCALING GAMESCOPE_WSI_MODIFIERS IRIS_MESA_DEBUG ||
    true

dbus-update-activation-environment --systemd \
    DISPLAY WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
    GTK_USE_PORTAL GDK_SCALE \
    QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME QT_WAYLAND_DISABLE_WINDOWDECORATION \
    QT_MEDIA_BACKEND QT_FFMPEG_DECODING_HW_DEVICE_TYPES QT_FFMPEG_ENCODING_HW_DEVICE_TYPES \
    CLUTTER_BACKEND ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND \
    LIBVA_DRIVER_NAME MESA_LOADER_DRIVER_OVERRIDE INTEL_DEBUG \
    _JAVA_AWT_WM_NONREPARENTING \
    XCURSOR_THEME XCURSOR_SIZE \
    STEAM_FORCE_DESKTOPUI_SCALING GAMESCOPE_WSI_MODIFIERS IRIS_MESA_DEBUG ||
    true

# Wallpapers (Backdrop & Foreground)
sleep 0.1

if [ -f "$FOREGROUND_WALLPAPER" ]; then
    echo "  → Starting wallpapers..."
    bash ~/.config/niri/scripts/wallpaper.sh "$FOREGROUND_WALLPAPER" "$BACKDROP_WALLPAPER"
fi

# Bar (Start immediately, don't wait for wallpapers)
if command -v waybar &>/dev/null; then
    echo "  → Starting waybar..."
    waybar &
fi

# Notification Daemon (Fast, lightweight)
if command -v mako &>/dev/null; then
    echo "  → Starting mako..."
    mako &
fi

# Background Services

# Polkit Agent
{
    POLKIT_AGENT="/usr/libexec/polkit-gnome-authentication-agent-1"
    [ ! -f "$POLKIT_AGENT" ] && POLKIT_AGENT="/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"

    if [ -f "$POLKIT_AGENT" ]; then
        echo "  → Starting polkit agent..."
        "$POLKIT_AGENT" &
    fi
} &

# Clipboard Manager
{
    if command -v cliphist &>/dev/null && command -v wl-paste &>/dev/null; then
        echo "  → Starting clipboard manager..."
        wl-paste --type text --watch cliphist store &
        wl-paste --type image --watch cliphist store &
    fi
} &

# Utilities & Apps

# Screen Idle / Lock
if command -v swayidle &>/dev/null; then
    echo "  → Starting swayidle..."
    swayidle -w \
        timeout 600 'niri msg action power-off-monitors' \
        resume 'niri msg action power-on-monitors' \
        timeout 900 "hyprlock" \
        before-sleep "hyprlock" \
        lock "hyprlock" &
else
    echo "  → ERROR: swayidle not found!"
fi

# Audio Idle Inhibitor (prevents sleep during playback)
if command -v sway-audio-idle-inhibit &>/dev/null; then
    echo "  → Starting audio inhibitor..."
    sway-audio-idle-inhibit &
fi

# System Tray Apps
{
    if command -v nm-applet &>/dev/null; then
        echo "  → Starting nm-applet..."
        nm-applet --indicator &
    fi

    if command -v blueman-applet &>/dev/null; then
        echo "  → Starting blueman-applet..."
        blueman-applet &
    fi

    if command -v gromit-mpx &>/dev/null; then
        echo "  → Starting gromit-mpx..."
        gromit-mpx -k none -u none &
    fi
} &

# Zen Browser
{
    if command -v flatpak &>/dev/null; then
        sleep 1
        
        echo "  → Starting Zen..."
        flatpak run --env=MOZ_ENABLE_WAYLAND=1 app.zen_browser.zen &
    fi
} &

echo "=== Autostart script finished (background processes still loading) ==="
exit 0
