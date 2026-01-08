# Steam and Gaming Environment Variables
# Force Steam to use its desktop UI scaling and stable XWayland behavior
set -gx STEAM_FORCE_DESKTOPUI_SCALING 1
set -gx GDK_BACKEND x11
set -gx PROTON_ENABLE_WAYLAND 0

# Enable hardware acceleration for Intel where possible
set -gx SDL_VIDEODRIVER x11
set -gx LIBVA_DRIVER_NAME iHD

# Workaround for black screen in Steam CEF on some Intel chips
# set -gx INTEL_DEBUG noccs # Uncomment if you still see rendering glitches
