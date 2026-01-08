# Force Steam to use its desktop UI scaling
set -gx STEAM_FORCE_DESKTOPUI_SCALING 1
set -gx PROTON_ENABLE_WAYLAND 0

# Enable hardware acceleration for Intel where possible (Driver only)
set -gx LIBVA_DRIVER_NAME iHD

# Workarounds for black screen in Steam CEF on Intel Meteor Lake / Arc
set -gx INTEL_DEBUG noccs
set -gx IRIS_MESA_DEBUG sync

# Fix for Intel WSI modifiers (prevents some flickering/rendering issues in gamescope)
set -gx GAMESCOPE_WSI_MODIFIERS 0
