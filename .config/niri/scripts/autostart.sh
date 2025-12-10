#!/usr/bin/env bash
# Optimized Niri Autostart Script
# Follows Niri best practices with proper service ordering

set -euo pipefail

# Logging
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-autostart.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== Niri Autostart - $(date) ==="

# Kill any existing instances to prevent duplicates
pkill -9 waybar || true
pkill -9 mako || true
pkill -9 swayidle || true
pkill -9 nm-applet || true
pkill -9 blueman-applet || true
pkill -9 xwayland-satellite || true

# Wait for Niri to be fully ready
sleep 1

# ============================================================================
# Phase 1: Critical System Services
# ============================================================================

echo "[Phase 1] Starting critical system services..."

# XWayland support (CRITICAL - must start before X11 apps)
if command -v xwayland-satellite &> /dev/null; then
    echo "  → Starting xwayland-satellite..."
    xwayland-satellite &
    sleep 0.5
else
    echo "  ⚠ xwayland-satellite not found - X11 apps won't work"
fi

# Polkit authentication agent (CRITICAL - needed for GUI sudo)
if [ -f /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then
    echo "  → Starting polkit agent..."
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
else
    echo "  ⚠ Polkit agent not found"
fi

sleep 0.5

# ============================================================================
# Phase 2: XDG Desktop Portals
# ============================================================================

echo "[Phase 2] Starting XDG desktop portals..."

# Kill existing portals
pkill -9 xdg-desktop-portal-gnome || true
pkill -9 xdg-desktop-portal || true

sleep 0.5

# Start portals (for screen sharing, file pickers, etc.)
if command -v xdg-desktop-portal-gnome &> /dev/null; then
    echo "  → Starting xdg-desktop-portal-gnome..."
    /usr/lib/xdg-desktop-portal-gnome &
    sleep 0.5
fi

echo "  → Starting xdg-desktop-portal..."
/usr/lib/xdg-desktop-portal -r &
sleep 1

# ============================================================================
# Phase 3: User Interface Components
# ============================================================================

echo "[Phase 3] Starting UI components..."

# Notification daemon
if command -v mako &> /dev/null; then
    echo "  → Starting mako..."
    mako &
    sleep 0.3
fi

# Status bar
if command -v waybar &> /dev/null; then
    echo "  → Starting waybar..."
    waybar &
    sleep 0.3
fi

# ============================================================================
# Phase 4: System Tray Applications
# ============================================================================

echo "[Phase 4] Starting system tray apps..."

# Network manager
if command -v nm-applet &> /dev/null; then
    echo "  → Starting nm-applet..."
    nm-applet --indicator &
    sleep 0.2
fi

# Bluetooth
if command -v blueman-applet &> /dev/null; then
    echo "  → Starting blueman-applet..."
    blueman-applet &
    sleep 0.2
fi

# ============================================================================
# Phase 5: Wallpaper
# ============================================================================

echo "[Phase 5] Setting wallpaper..."

# Initialize swww daemon
if command -v swww &> /dev/null; then
    echo "  → Starting swww daemon..."
    swww init &
    sleep 1
    
    # Set wallpaper if it exists
    WALLPAPER="${HOME}/.config/backgrounds/default.jpg"
    if [ -f "$WALLPAPER" ]; then
        echo "  → Loading wallpaper: $WALLPAPER"
        swww img "$WALLPAPER" --transition-type fade --transition-fps 60 --transition-duration 1 &
    else
        echo "  ⚠ Wallpaper not found: $WALLPAPER"
        # Fallback to solid color
        swww img <(convert -size 1920x1080 xc:'#1e1e2e' png:-) &
    fi
fi

# ============================================================================
# Phase 6: Utilities
# ============================================================================

echo "[Phase 6] Starting utilities..."

# Clipboard manager
if command -v cliphist &> /dev/null && command -v wl-paste &> /dev/null; then
    echo "  → Starting clipboard manager..."
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &
    sleep 0.2
fi

# Idle manager (screen timeout and lock)
if command -v swayidle &> /dev/null; then
    echo "  → Starting swayidle..."
    swayidle -w \
        timeout 600 'niri msg action power-off-monitors' \
        resume 'niri msg action power-on-monitors' \
        timeout 900 'swaylock -f' \
        before-sleep 'swaylock -f' &
fi

# ============================================================================
# Phase 7: Optional Services
# ============================================================================

echo "[Phase 7] Starting optional services..."

# Gammastep (blue light filter)
if command -v gammastep &> /dev/null; then
    echo "  → Starting gammastep..."
    gammastep -l 0:0 &  # Auto-detect location or set your coords
fi

# ============================================================================
# Completion
# ============================================================================

echo "=== Niri autostart completed successfully ==="
echo "Log file: $LOG_FILE"

# Wait a moment to ensure all services are stable
sleep 1

# Verify critical services
echo ""
echo "Service status:"
pgrep -a xwayland-satellite && echo "  ✓ xwayland-satellite running" || echo "  ✗ xwayland-satellite not running"
pgrep -a waybar && echo "  ✓ waybar running" || echo "  ✗ waybar not running"
pgrep -a mako && echo "  ✓ mako running" || echo "  ✗ mako not running"
pgrep -a swayidle && echo "  ✓ swayidle running" || echo "  ✗ swayidle not running"

echo ""
echo "Autostart complete!"
