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
# the lock descriptor and holding it for the rest of the session.
if [[ ${1:-} != --locked ]]; then
    exec flock --close --wait 10 "${XDG_RUNTIME_DIR:?}/dofs-launcher.lock" bash "$0" --locked
fi

ready() {
    local reply
    reply=$(timeout --kill-after=1s 2s qs -c dofs ipc call launcher ping 2>/dev/null) \
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

# Readiness probes are safe to retry; toggle is not. A timed-out toggle may
# already have run, so never issue it again blindly. IPC errors can exit 0.
reply=$(timeout --kill-after=1s 2s qs -c dofs ipc call launcher toggle 2>&1) \
    || fail 'Quickshell launcher did not respond. Try the shortcut again.'
[[ -z $reply ]] || fail "Quickshell launcher: $reply"
