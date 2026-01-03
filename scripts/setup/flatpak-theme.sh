#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

log "Synchronizing system theme with Flatpak..."

# 1. Get current settings (fallbacks to defaults if not set)
GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
ICON_THEME=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
FONT_NAME=$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")

[ -z "$GTK_THEME" ] && GTK_THEME="Adwaita"
[ -z "$ICON_THEME" ] && ICON_THEME="Adwaita"

log "Detected Theme: $GTK_THEME"
log "Detected Icons: $ICON_THEME"

# 2. Grant filesystem permissions to Flatpak
log "Applying filesystem overrides..."
flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
flatpak override --user --filesystem=~/.icons:ro
flatpak override --user --filesystem=~/.themes:ro
flatpak override --user --filesystem=/usr/share/icons:ro
flatpak override --user --filesystem=/usr/share/themes:ro

# 3. Apply themes via environment variables and overrides
log "Applying theme overrides..."
flatpak override --user --env=GTK_THEME="$GTK_THEME"
flatpak override --user --env=ICON_THEME="$ICON_THEME"

# Set GSettings for Flatpak
# This is more robust for GTK4 apps
# Note: Requires xdg-desktop-portal-gtk to be running properly
dbus-send --session --dest=org.freedesktop.portal.Desktop \
    --type=method_call /org/freedesktop/portal/desktop \
    org.freedesktop.impl.portal.Settings.Read \
    string:"org.gnome.desktop.interface" string:"gtk-theme" || true

ok "Flatpak theme synchronization complete!"
