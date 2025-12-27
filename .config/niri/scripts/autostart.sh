#!/bin/bash

set -euo pipefail

WALLPAPER_DIR="${HOME}/.config/backgrounds"
FOREGROUND_WALLPAPER="${WALLPAPER_DIR}/spiderman.jpg"
BACKDROP_WALLPAPER="${WALLPAPER_DIR}/blurry-spiderman.jpg"
LOCK_WALLPAPER="$BACKDROP_WALLPAPER"

# Logging
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-autostart.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== Niri Autostart - $(date) ==="

# Cleanup existing processes
# '|| true' ensures script continues if processes aren't running
pkill waybar || true
pkill mako || true
pkill swayidle || true
pkill nm-applet || true
pkill blueman-applet || true
pkill xwayland-satellite || true
pkill swaybg || true
pkill swww-daemon || true

echo "Syncing environment variables..."
# Import environment to systemd and dbus (CRITICAL for app launching and daemons)
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP || true
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP || true

# ----------------------------------------------------------------------------
# Critical UI Components (Start ASAP)
# ----------------------------------------------------------------------------

# 1. Background (Backdrop)
if [ -f "$BACKDROP_WALLPAPER" ]; then
    swaybg -i "$BACKDROP_WALLPAPER" -m fill &
fi

# 2. Notification Daemon (Fast, lightweight)
if command -v mako &>/dev/null; then
    echo "  → Starting mako..."
    mako &
fi

# 3. Bar (Start immediately, don't wait for wallpapers)
if command -v waybar &>/dev/null; then
    echo "  → Starting waybar..."
    waybar &
fi

# ----------------------------------------------------------------------------
# Background Services (Parallel Execution)
# ----------------------------------------------------------------------------

# Wallpaper Daemon (Complex logic moved to background)
{
    if command -v swww &>/dev/null && command -v swww-daemon &>/dev/null; then
        echo "  → Starting swww daemon..."
        swww-daemon --format xrgb &

        # Wait for daemon to be ready (internal loop)
        for _ in {1..30}; do
            if swww query &>/dev/null; then
                break
            fi
            sleep 0.1
        done

        # Load foreground wallpaper
        if [ -f "$FOREGROUND_WALLPAPER" ]; then
            echo "  → Loading wallpaper: $FOREGROUND_WALLPAPER"
            swww img "$FOREGROUND_WALLPAPER" --transition-type none
        fi
    fi
} &

# XWayland Satellite
{
    if command -v xwayland-satellite &>/dev/null; then
        echo "  → Starting xwayland-satellite..."
        xwayland-satellite &
    fi
} &

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

# System Tray Apps
{
    # Check if we need to wait a tiny bit for tray to be ready,
    # though usually nm-applet handles this well.
    sleep 0.5

    if command -v nm-applet &>/dev/null; then
        echo "  → Starting nm-applet..."
        nm-applet --indicator &
    fi

    if command -v blueman-applet &>/dev/null; then
        echo "  → Starting blueman-applet..."
        blueman-applet &
    fi
} &

# ----------------------------------------------------------------------------
# Utilities & Idle
# ----------------------------------------------------------------------------

if command -v swayidle &>/dev/null; then
    echo "  → Starting swayidle..."
    swayidle -w \
        timeout 600 'niri msg action power-off-monitors' \
        resume 'niri msg action power-on-monitors' \
        timeout 900 "swaylock -f -i '$LOCK_WALLPAPER'" \
        before-sleep "swaylock -f -i '$LOCK_WALLPAPER'" &
fi

# Optional: Zen Browser
if flatpak info app.zen_browser.zen &>/dev/null; then
    echo "  → Starting zen-browser..."
    flatpak run app.zen_browser.zen &
fi

echo "=== Autostart script finished (background processes still loading) ==="
exit 0
