#!/usr/bin/env bash
set -euo pipefail

fail() {
    local message="$1"
    printf '%s\n' "$message" >&2
    if command -v notify-send >/dev/null 2>&1; then
        notify-send --urgency=critical 'Launcher unavailable' "$message" || true
    fi
    exit 1
}

# Serialize simultaneous key presses. --close prevents the daemon inheriting
# the lock descriptor and holding it for the rest of the session. The id is
# forwarded: bash "$0" --locked <entry-id>.
if [[ ${1:-} != --locked ]]; then
    exec flock --close --wait 10 "${XDG_RUNTIME_DIR:?}/dofs-launcher.lock" \
        bash "$0" --locked "${1:-}"
fi

# After re-exec: --locked [entry-id]
entry=${2:-}

ipc() {
    timeout --kill-after=1s 2s qs -c dofs ipc call launcher "$@"
}

ready() {
    local reply
    reply=$(ipc ping 2>/dev/null) \
        && [[ $reply == ready ]]
}

if ! ready; then
    timeout --kill-after=1s 8s qs -c dofs --daemonize --no-duplicate \
        || fail 'Could not start Quickshell. Check: qs -c dofs'
    deadline=$((SECONDS + 5))
    until ready; do
        (( SECONDS < deadline )) || fail 'Quickshell launcher did not become ready. After an update, restart it with: qs -c dofs kill'
        sleep 0.1
    done
fi

# Readiness probes are safe to retry; toggle is not. openEntry (with an id) is
# idempotent, so it may be issued again. IPC errors can exit 0. Note: quickshell
# IPC does not map kebab-case from the CLI — call functions in camelCase.
if [[ -n $entry ]]; then
    reply=$(ipc openEntry "$entry" 2>&1) \
        || fail 'Quickshell launcher did not respond. Try the shortcut again.'
else
    reply=$(ipc toggle 2>&1) \
        || fail 'Quickshell launcher did not respond. Try the shortcut again.'
fi
[[ -z $reply ]] || fail "Quickshell launcher: $reply"
