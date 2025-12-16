#!/bin/bash

set -euo pipefail

# Logging
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-autostart.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== Niri Autostart - $(date) ==="

pkill -9 waybar || true
pkill -9 mako || true
pkill -9 swayidle || true
pkill -9 nm-applet || true
pkill -9 blueman-applet || true
pkill -9 xwayland-satellite || true
pkill -9 swaybg || true
pkill -9 swww-daemon || true

echo "Loading wallpapers immediately..."

# Start backdrop wallpaper FIRST (instant visual feedback)
if command -v swaybg &>/dev/null; then
    BACKDROP_WALLPAPER="${HOME}/.config/backgrounds/blurry-snaky.jpg"
    if [ -f "$BACKDROP_WALLPAPER" ]; then
        echo "  → Starting swaybg backdrop: $BACKDROP_WALLPAPER"
        swaybg -i "$BACKDROP_WALLPAPER" -m fill &
    else
        echo "  → Using solid color backdrop"
        swaybg -c '#1e1e2e' &
    fi
fi

# Start swww daemon immediately (parallel with swaybg)
if command -v swww &>/dev/null; then
    echo "  → Starting swww daemon..."
    swww-daemon --format xrgb &
    SWWW_PID=$!

    # Wait briefly until daemon responds
    for _ in {1..15}; do
        if swww query &>/dev/null; then
            break
        fi
        sleep 0.1
    done

    # Load foreground wallpaper
    FOREGROUND_WALLPAPER="${HOME}/.config/backgrounds/snaky.jpg"
    if [ -f "$FOREGROUND_WALLPAPER" ]; then
        echo "  → Loading foreground wallpaper: $FOREGROUND_WALLPAPER"
        swww img "$FOREGROUND_WALLPAPER" --transition-type none &
    elif [ -f "${HOME}/.config/backgrounds/snaky.jpg" ]; then
        swww img "${HOME}/.config/backgrounds/blurry-snaky.jpg" --transition-type none &
    fi
fi

echo "Starting critical background services..."

# Launch all critical services in parallel (they don't need to be sequential)
{
    # XWayland support
    if command -v xwayland-satellite &>/dev/null; then
        echo "  → Starting xwayland-satellite..."
        xwayland-satellite &
    fi
} &

{
    # Polkit authentication agent
    if [ -f /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then
        echo "  → Starting polkit agent..."
        /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
    fi
} &

{
    # Import environment to systemd
    echo "  → Importing environment to systemd..."
    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP || true
    sleep 0.5
} &

{
    # Clipboard manager (start early, runs in background)
    if command -v cliphist &>/dev/null && command -v wl-paste &>/dev/null; then
        echo "  → Starting clipboard manager..."
        wl-paste --type text --watch cliphist store &
        wl-paste --type image --watch cliphist store &
    fi
} &

# Wait for background services to initialize
sleep 0.3

echo "Starting UI components..."

# Start notification daemon first (lightweight, fast)
if command -v mako &>/dev/null; then
    echo "  → Starting mako..."
    mako &
fi

# Brief delay for mako to initialize
sleep 0.15

# Start Waybar (now wallpaper is visible, so loading bar looks good)
if command -v waybar &>/dev/null; then
    echo "  → Starting waybar..."
    waybar &
fi

echo "Starting system tray apps..."

# Launch tray apps in parallel (they're independent)
{
    if command -v nm-applet &>/dev/null; then
        echo "  → Starting nm-applet..."
        nm-applet --indicator &
    fi
} &

{
    if command -v blueman-applet &>/dev/null; then
        echo "  → Starting blueman-applet..."
        blueman-applet &
    fi
} &

# Small delay to let tray populate
sleep 0.2

echo "Starting power management and utilities..."

# Idle manager (non-critical, can start later)
if command -v swayidle &>/dev/null; then
    echo "  → Starting swayidle..."
    swayidle -w \
        timeout 600 'niri msg action power-off-monitors' \
        resume 'niri msg action power-on-monitors' \
        timeout 900 'swaylock -f' \
        before-sleep 'swaylock -f' &
fi

# Gammastep (blue light filter - lowest priority)
if command -v gammastep &>/dev/null; then
    echo "  → Starting gammastep..."
    gammastep -l 0:0 &
fi

echo "Starting optional services..."

if command -v zen-browser &>/dev/null; then
    echo "  → Starting zen-browser..."
    zen-browser &
fi

# ============================================================================
# Completion & Verification
# ============================================================================

echo "=== Niri autostart completed ==="

# Verify critical services (non-blocking check)
{
    sleep 1
    echo ""
    echo "Service status check:"
    pgrep -a xwayland-satellite && echo "  ✓ xwayland-satellite running" || echo "  ✗ xwayland-satellite not running"
    pgrep -a waybar && echo "  ✓ waybar running" || echo "  ✗ waybar not running"
    pgrep -a mako && echo "  ✓ mako running" || echo "  ✗ mako not running"
    pgrep -a swaybg && echo "  ✓ swaybg running" || echo "  ✗ swaybg not running"
    pgrep -a swww && echo "  ✓ swww running" || echo "  ✗ swww not running"
    pgrep -a swayidle && echo "  ✓ swayidle running" || echo "  ✗ swayidle not running"
    echo ""
    echo "Autostart complete! Log: $LOG_FILE"
} &

exit 0