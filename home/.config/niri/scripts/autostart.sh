#!/bin/bash

set -euo pipefail

WALLPAPER_DIR="${HOME}/.config/backgrounds"
FOREGROUND_WALLPAPER="${WALLPAPER_DIR}/fold.jpg"
BACKDROP_WALLPAPER="${WALLPAPER_DIR}/blurry-fold.jpg"
LOCK_WALLPAPER="$BACKDROP_WALLPAPER"

# Logging
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-autostart.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== Niri Autostart - $(date) ==="
echo "Display: $WAYLAND_DISPLAY"

# Source centralized environment variables
if [ -f "$HOME/.config/niri/configs/env" ]; then
    echo "  → Sourcing ~/.config/niri/configs/env..."
    source "$HOME/.config/niri/configs/env"
fi

# Cleanup existing processes
# '|| true' ensures script continues if processes aren't running
pkill waybar || true
pkill mako || true
pkill swayidle || true
pkill nm-applet || true
pkill blueman-applet || true
pkill swaybg || true
pkill hyprpaper || true

echo "Syncing environment variables..."
export GDK_SCALE="${GDK_SCALE:-1}"

# Import environment to systemd and dbus (CRITICAL for app launching and daemons)
systemctl --user import-environment \
    DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE \
    GDK_BACKEND GDK_SCALE GSK_RENDERER CLUTTER_BACKEND \
    QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME QT_WAYLAND_DISABLE_WINDOWDECORATION \
    ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND \
    GTK_USE_PORTAL XCURSOR_THEME XCURSOR_SIZE \
    STEAM_FORCE_DESKTOPUI_SCALING ||
    true
dbus-update-activation-environment --systemd \
    DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE \
    GDK_BACKEND GDK_SCALE GSK_RENDERER CLUTTER_BACKEND \
    QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME QT_WAYLAND_DISABLE_WINDOWDECORATION \
    ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND \
    GTK_USE_PORTAL XCURSOR_THEME XCURSOR_SIZE \
    STEAM_FORCE_DESKTOPUI_SCALING ||
    true

# ----------------------------------------------------------------------------
# Critical UI Components (Start ASAP)
# ----------------------------------------------------------------------------

# Wallpapers (Backdrop & Foreground)
# Small delay to ensure Wayland environment is fully initialized
sleep 0.1

if [ -f "$FOREGROUND_WALLPAPER" ]; then
    echo "  → Starting wallpapers via script..."
    # Run synchronously to ensure both daemons start properly
    bash ~/.config/niri/scripts/wallpaper.sh "$FOREGROUND_WALLPAPER" "$BACKDROP_WALLPAPER"
    echo "  → Wallpapers initialized"
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

# ----------------------------------------------------------------------------
# Background Services (Parallel Execution)
# ----------------------------------------------------------------------------

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

# ----------------------------------------------------------------------------
# Utilities & Apps
# ----------------------------------------------------------------------------

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
