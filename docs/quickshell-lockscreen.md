# Quickshell lockscreen

`dofs-lock` is a separate, persistent Quickshell configuration. It uses
`WlSessionLock`/`WlSessionLockSurface`, not a fullscreen overlay. The compositor
covers every monitor, including newly connected outputs. The clock, blurred
wallpaper, and colors match the desktop shell. Restarting `qs -c dofs` does not
stop the locker.

## Install before locking

1. Install Quickshell 0.3.x with its Wayland and PAM modules, Fedora's PAM stack,
   and `fprintd-pam` for fingerprint authentication. Packages are declared in
   `ansible/roles/packages/vars/main.yml`.
2. Install the two root-owned PAM services through Ansible, **before** enabling
   the new lock commands:

   ```sh
   ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/playbook.yml \
     -i ansible/inventory --ask-become-pass --tags lockscreen
   ```

   `/etc/pam.d/dofs-lock` includes Fedora's `password-auth`, retaining the
   system's authselect password policy. `/etc/pam.d/dofs-lock-fingerprint`
   separately uses `pam_fprintd.so`, so password entry does not have to wait for
   fingerprint scanning. No authentication policy is loaded from dotfiles.
   Quickshell's PAM API performs authentication, not privileged account/session
   management. Fingerprint availability depends on enrollment and hardware.
3. Review and apply the dotfiles, including both configurations, the Niri
   binding/autostart, system controls, and the shell's menu scripts:

   ```sh
   chezmoi apply --recursive --source "$PWD/home" \
     "$HOME/.config/quickshell/dofs" \
     "$HOME/.config/quickshell/dofs-lock" \
     "$HOME/.config/niri/binds.kdl" \
     "$HOME/.config/niri/scripts/autostart.sh" \
     "$HOME/.config/niri/scripts/system-controls.sh"
   ```

4. Start the independent locker without locking:

   ```sh
   bash "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/dofs/scripts/lock-screen.sh" --start
   qs -c dofs-lock ipc call lock status
   ```

   Status should be `{"locked":false,"secure":false}`. The wrapper refuses to
   start/lock if the password PAM service is missing. Startup does not prove
   your actual password or fingerprint works: do the first real unlock test
   with a saved session and a known-working TTY login available.

## Usage

- `Alt+Ctrl+L`, launcher **Lock screen**, system controls, and the power menu all
  call `quickshell/dofs/scripts/lock-screen.sh`.
- Native idle locking and logind sleep/lock requests call the same script.
- Enter submits a password. Fingerprint scanning runs independently; **Retry
  fingerprint** starts a new scan. Escape cancels password entry, **not the lock**.
- Authentication is shared across outputs, while password fields remain local
  and are cleared together on submission, cancellation, failure and unlock.
  Passwords are masked without a reveal delay and are never placed in argv,
  environment variables, notification history, or IPC methods. Pending responses
  are cleared after use; QML/JavaScript strings do not provide guaranteed memory
  zeroization.
- Only a successful PAM result while the compositor lock is secure releases
  the lock. Failure, cancellation, PAM errors and maximum-attempt results keep
  the session locked. A short UI retry delay supplements the system PAM policy.

The wrapper serializes requests and waits for a sticky acknowledgement from
`WlSessionLock.secure`; launching a process alone does not count as locking. It
never kills/replaces an existing locker. The logind bridge independently waits
for Niri's `LockedHint` before releasing its sleep-delay inhibitor. Manual or
lid-close suspend still locks when the bar's keep-awake toggle is on. Logind's
maximum delay still applies if locking fails.

## Updates and recovery

Automatic **QML code** reload is disabled for this configuration. Palette JSON
can update live, but code changes require restarting the locker **while it is
unlocked**. Check `qs -c dofs-lock ipc call lock status` first. A normal bar
restart does not affect it. The locker has no unlock, password, or authentication
result IPC methods and does not honor logind `Unlock` signals as authentication.

**Never kill or reload the locker while locked.** A conforming compositor keeps
the session locked if its lock client dies; this prevents exposing the desktop,
but may leave no working unlock UI. If it fails, switch to a TTY, authenticate,
and inspect `qs -c dofs-lock` logs. If recovery is impossible, use `loginctl
list-sessions` to identify the affected graphical session and terminate that
specific session with `loginctl terminate-session SESSION_ID`. This ends the
desktop and loses unsaved work; it is not an unauthenticated unlock mechanism.

The previous locker package and generated configuration are no longer managed
by this repository; already-installed packages and old deployed files are not
automatically removed.

## Validation

```sh
python3 -B scripts/tests/test_quickshell_lock.py -v
DOFS_QML_TEST=1 python3 -B scripts/tests/test_quickshell_lock.py -v
python3 -B scripts/tests/test_session_lock.py -v
```

Default tests use mocked lock state, offscreen windows, a mock command wrapper,
and isolated PAM services (`pam_permit`, `pam_deny`, and a fixture-only secret
challenge). They never request a lock on the real desktop and do not modify
`/etc/pam.d` or test a real user's password. Test-only IPC/mocks are confined to
temporary configurations; the production locker has no test bypass.

An additional protocol test runs the actual locker inside a temporary nested
Niri compositor, without `--session`, with a private D-Bus and runtime directory:

```sh
DOFS_QML_TEST=1 DOFS_LOCK_NESTED_TEST=1 python3 -B scripts/tests/test_quickshell_lock.py \
  LiveLockTests.test_real_session_lock_and_pam_inside_nested_niri -v
```

This briefly opens a nested compositor window; only that nested session is
locked. It checks compositor-confirmed locking, PAM-controlled unlocking,
cancellation, and the absence of an unlock IPC method. Physical multi-monitor
hotplug, actual password/fingerprint authentication, and real suspend/resume
remain manual acceptance checks.

References: [Wayland lock](https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlSessionLock/),
[PAM API](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Pam/PamContext/),
[PAM configuration guidance](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Pam/).
