#!/usr/bin/env bash
set -euo pipefail

fail() {
    printf 'Screen lock unavailable: %s\n' "$1" >&2
    if command -v notify-send >/dev/null 2>&1; then
        timeout --kill-after=1s 2s notify-send --urgency=critical --app-name=dofs-lock 'Screen lock unavailable' "$1" || true
    fi
    exit 1
}

# Serialize startup/requests, not the lifetime of the independent locker.
if [[ ${1:-} != --locked ]]; then
    exec flock --close --wait 12 "${XDG_RUNTIME_DIR:?}/dofs-screen-lock.lock" \
        bash "$0" --locked "${1:-}"
fi
mode=${2:-}
[[ -z $mode || $mode == --start || $mode == --status ]] || fail 'expected --start or --status'
ipc() { timeout --kill-after=1s 2s qs -c dofs-lock ipc call lock "$@"; }

if [[ $mode == --status ]]; then
    ipc status
    exit
fi
[[ -r /etc/pam.d/dofs-lock ]] || fail 'install /etc/pam.d/dofs-lock using the Ansible desktop role before locking'

if [[ $(ipc ping 2>/dev/null || true) != ready ]]; then
    timeout --kill-after=1s 8s qs -c dofs-lock --daemonize --no-duplicate \
        || fail 'could not start the Quickshell locker'
    deadline=$((SECONDS + 5))
    until [[ $(ipc ping 2>/dev/null || true) == ready ]]; do
        (( SECONDS < deadline )) || fail 'locker did not become ready; inspect qs -c dofs-lock logs'
        sleep 0.05
    done
fi
[[ $mode != --start ]] || exit 0

ticket=$(ipc lock) || fail 'lock request failed'
[[ $ticket =~ ^[1-9][0-9]*$ ]] || fail "unexpected lock response: $ticket"
deadline=$((SECONDS + 5))
while (( SECONDS < deadline )); do
    secured=$(ipc secured) || fail 'could not confirm compositor lock'
    # Sticky acknowledgement also covers a fast fingerprint unlock before this query.
    if [[ $secured =~ ^[0-9]+$ ]] && (( secured >= ticket )); then exit 0; fi
    sleep 0.05
done
fail 'compositor did not confirm lock coverage; the locker has NOT been stopped'
