# This wrapper ensures Steam always launches with settings for maximum stability on Niri.
# It forces the X11 backend and applies workarounds for common rendering issues.
function steam
    # Force X11 backend for compatibility.
    set -lx GDK_BACKEND x11
    set -lx SDL_VIDEODRIVER x11

    # -system-composer: Helps with window management under Wayland.
    # -cef-disable-gpu: Fixes black screen in Steam's browser on some Intel GPUs.
    command steam -system-composer -cef-disable-gpu $argv
end
