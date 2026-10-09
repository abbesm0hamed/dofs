#!/bin/bash
set -euo pipefail

# Prevent race conditions with flock using a separate lock file
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/wallpaper.lock"
exec 200>"$LOCK_FILE"
flock -n 200 || {
    echo "Another instance is running"
    exit 0
}

WALL_DIR="${HOME}/.config/backgrounds"
FG_LINK="${WALL_DIR}/current.jpg"
BG_LINK="${WALL_DIR}/current-blurry.jpg"

# Wallpaper used when nothing has been picked yet (fresh machine for eg.)
DEFAULT_WALLPAPER_NAME="liftoff.png"

default_wallpaper() {
    local f
    if [ -f "$WALL_DIR/$DEFAULT_WALLPAPER_NAME" ]; then
        printf '%s\n' "$WALL_DIR/$DEFAULT_WALLPAPER_NAME"
        return 0
    fi
    shopt -s nullglob
    for f in "$WALL_DIR"/*.{jpe,jpeg,jpg,png,webp}; do
        case "$(basename "$f")" in
            current* | blurry-* | generated-*) continue ;;
        esac
        printf '%s\n' "$f"
        shopt -u nullglob
        return 0
    done
    shopt -u nullglob
    return 1
}

# Parse arguments
SILENT=false
FILES=()
for arg in "$@"; do
    if [ "$arg" == "--silent" ]; then
        SILENT=true
    else
        FILES+=("$arg")
    fi
done
set -- "${FILES[@]}"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <wallpaper_path> [backdrop_path] [--silent]"
    exit 1
fi

FG_WALL=""
BG_WALL=""

# Runtime blur cache: the blurred backdrop is generated with ImageMagick on
# demand instead of storing a second "blurry-" copy of every wallpaper.
BLUR_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-blur"
BLUR_SIGMA="${WALLPAPER_BLUR_SIGMA:-32}"

make_blurred() {
    local src="$1" key name out
    if ! command -v magick >/dev/null 2>&1; then
        echo "magick (ImageMagick) not found; cannot blur $src" >&2
        return 1
    fi
    mkdir -p "$BLUR_DIR"
    key=$(printf '%s' "$src" | md5sum | cut -c1-10)
    name="$(basename "$src")"
    out="$BLUR_DIR/${name%.*}-${key}-s${BLUR_SIGMA}.jpg"

    # Regenerate only when the source changed; drop variants generated with a
    # different sigma (or by an older version of this script).
    if [ ! -f "$out" ]; then
        rm -f "$BLUR_DIR/${name%.*}-${key}"*.jpg
    elif [ "$src" -nt "$out" ]; then
        rm -f "$out"
    fi

    if [ ! -f "$out" ]; then
        # Downscale -> blur -> upscale: much faster, and the upscale hides artifacts.
        # Effective blur at full resolution ends up around 2x BLUR_SIGMA.
        magick "$src" -resize 50% -blur 0x"$BLUR_SIGMA" -resize 200% -quality 88 "$out" ||
            {
                rm -f "$out"
                return 1
            }
    fi
    printf '%s\n' "$out"
}

# Resolve Wallpaper
if [ "${1:-}" == "--restore" ]; then
    [ -L "$FG_LINK" ] && FG_WALL=$(readlink -f "$FG_LINK")
    if [ ! -f "$FG_WALL" ]; then
        # Nothing saved yet (fresh machine) -> fall back to the default image.
        FG_WALL="$(default_wallpaper || true)"
    fi
    if [ ! -f "$FG_WALL" ]; then
        echo "Nothing to restore."
        exit 0
    fi
else
    if [ -d "$1" ]; then
        DIR_PATH="$(readlink -f "$1")"
        shopt -s nullglob
        for f in "$DIR_PATH"/default-workspace.{jpg,jpe,png,webp,jpeg,JPG,JPE,PNG,WEBP,JPEG} "$DIR_PATH"/workspace.{jpg,jpe,png,webp,jpeg,JPG,JPE,PNG,WEBP,JPEG}; do
            [ -f "$f" ] && FG_WALL="$f" && break
        done
        for f in "$DIR_PATH"/default-backdrop.{jpg,jpe,png,webp,jpeg,JPG,JPE,PNG,WEBP,JPEG} "$DIR_PATH"/backdrop.{jpg,jpe,png,webp,jpeg,JPG,JPE,PNG,WEBP,JPEG} "$DIR_PATH"/blurry-workspace.{jpg,jpe,png,webp,jpeg,JPG,JPE,PNG,WEBP,JPEG}; do
            [ -f "$f" ] && BG_WALL="$f" && break
        done
        shopt -u nullglob
        [ -z "$FG_WALL" ] && echo "No workspace image found in $DIR_PATH" && exit 1
        [ -n "$FG_WALL" ] && FG_WALL="$(readlink -f "$FG_WALL")"
        [ -n "$BG_WALL" ] && BG_WALL="$(readlink -f "$BG_WALL")"
    else
        FG_WALL="$(readlink -f "$1")"
        BG_WALL="${2:-}"
        [ -n "$BG_WALL" ] && [ -f "$BG_WALL" ] && BG_WALL="$(readlink -f "$BG_WALL")"
    fi
fi

# No usable backdrop given -> derive a blurred copy of the foreground wallpaper
if [ ! -f "${BG_WALL:-}" ]; then
    BG_WALL=""
    if [ -f "$FG_WALL" ]; then
        BG_WALL=$(make_blurred "$FG_WALL" || true)
    fi
    # Last resort: the previous backdrop link, if it still points at a real file
    if [ ! -f "${BG_WALL:-}" ] && [ -L "$BG_LINK" ]; then
        BG_WALL=$(readlink -f "$BG_LINK")
    fi
    if [ ! -f "${BG_WALL:-}" ]; then
        BG_WALL=""
        echo "No blurred backdrop for $(basename "$FG_WALL")"
    fi
fi

# Update symlinks
mkdir -p "$WALL_DIR"
[ -f "$FG_WALL" ] && ln -nsf "$FG_WALL" "$FG_LINK"
[ -n "$BG_WALL" ] && [ -f "$BG_WALL" ] && ln -nsf "$BG_WALL" "$BG_LINK"

# Foreground manager (hyprpaper)
HYPR_SOCK="${XDG_RUNTIME_DIR:-/tmp}/hypr/.hyprpaper.sock"
HYPR_LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hyprpaper.log"

hypr_start() {
    # A dead instance can leave its socket behind; it would make the -S check
    # pass immediately and every command below would go nowhere.
    rm -f "$HYPR_SOCK"
    mkdir -p "$(dirname "$HYPR_LOG")"
    # Ignore SIGPIPE so a client that disconnects early can never kill
    # hyprpaper (it used to die with exit 141 and the wallpaper vanished).
    (
        trap '' PIPE
        exec hyprpaper >>"$HYPR_LOG" 2>&1
    ) &
    local _
    for _ in {1..100}; do
        [ -S "$HYPR_SOCK" ] && break
        sleep 0.1
    done
}

hypr_send() {
    # -t 10 is essential: socat's default half-close timeout is 0.5s, and
    # decoding a large wallpaper (liftoff.png, 8192x4608) takes ~0.6s. socat
    # used to drop the socket first, hyprpaper then wrote its reply into a
    # closed socket and was killed by SIGPIPE (exit 141).
    local out
    out=$(printf '%s\n' "$1" | socat -t 10 -T 10 - UNIX-CONNECT:"$HYPR_SOCK" 2>/dev/null) || true
    if [ -n "$out" ] && [ "$out" != "ok" ]; then
        echo "hyprpaper: $out"
    fi
    return 0
}

apply_foreground() {
    [ ! -f "$FG_WALL" ] && return
    if ! command -v hyprpaper >/dev/null; then
        echo "hyprpaper not found; skipping foreground wallpaper"
        return
    fi
    if ! command -v socat >/dev/null; then
        echo "socat not found; cannot control hyprpaper"
        return
    fi

    if ! pgrep -x hyprpaper >/dev/null; then
        hypr_start
    fi

    # hyprpaper only opens the socket once it has preloaded its config.
    local _
    for _ in {1..100}; do
        [ -S "$HYPR_SOCK" ] && break
        pgrep -x hyprpaper >/dev/null || break
        sleep 0.1
    done

    if [ -S "$HYPR_SOCK" ]; then
        hypr_send "preload $FG_WALL"
        hypr_send "wallpaper ,$FG_WALL"
        hypr_send "unload unused"
    fi

    # Self-heal: if hyprpaper died anyway, start it again (hyprpaper.conf
    # preloads current.jpg, the symlink that was just updated).
    if ! pgrep -x hyprpaper >/dev/null; then
        echo "hyprpaper is not running; starting it again (see $HYPR_LOG)"
        hypr_start
    fi
}

# Backdrop manager (swaybg)
apply_backdrop() {
    [ -z "$BG_WALL" ] || [ ! -f "$BG_WALL" ] && return
    if ! command -v swaybg >/dev/null; then
        echo "swaybg not found; skipping backdrop wallpaper"
        return
    fi
    pkill -x swaybg || true
    swaybg -i "$BG_WALL" -m fill &
}

# Run
# Close the lock fd in children so they don't keep the lock alive after we exit.
apply_foreground 200>&- &
apply_backdrop 200>&- &
wait

if [ "$SILENT" = false ]; then
    notify-send -a "Wallpaper" -i "$FG_WALL" "Wallpaper Applied" "$(basename "$FG_WALL")" || true
fi
