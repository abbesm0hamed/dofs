function steam
    # -system-composer: Helps with window management under Wayland.
    # -no-cef-sandbox: Fixes black screen in Steam's browser (better than -cef-disable-gpu).
    command steam -system-composer -no-cef-sandbox $argv
end
