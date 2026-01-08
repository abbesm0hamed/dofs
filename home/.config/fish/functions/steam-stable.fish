function steam-stable
    gamescope -W 1920 -H 1080 -f -e -- \
    env GDK_BACKEND=x11 SDL_VIDEODRIVER=x11 \
    steam -no-cef-sandbox -system-composer -cef-disable-gpu $argv
end
