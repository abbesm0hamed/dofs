#!/usr/bin/env python3
"""Bridge logind sleep/lock requests, not inactivity timers, to the shell locker."""

import json
import os
import signal
import sys


class SleepGuard:
    """Keep logind's delay FD until the compositor confirms LockedHint."""

    def __init__(self, acquire_delay, is_locked, lock, emit):
        self.acquire_delay = acquire_delay
        self.is_locked = is_locked
        self.lock = lock
        self.emit = emit
        self.fd = None
        self.sleeping = False

    def acquire(self):
        if self.fd is None:
            self.fd = self.acquire_delay()

    def release(self):
        if self.fd is not None:
            os.close(self.fd)
            self.fd = None

    def prepare_sleep(self, sleeping):
        self.sleeping = bool(sleeping)
        if self.sleeping:
            if self.is_locked():
                self.release()
            else:
                self.lock()
        else:
            self.acquire()
            self.emit({'type': 'resume'})

    def locked_changed(self, locked):
        if self.sleeping and locked:
            self.release()


def main():
    # Use Fedora's system Python; dbus/GObject are RPM dependencies, not pip ones.
    import dbus
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import Gio, GLib

    def emit(event):
        print(json.dumps(event), flush=True)

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    manager_object = bus.get_object('org.freedesktop.login1', '/org/freedesktop/login1')
    manager = dbus.Interface(manager_object, 'org.freedesktop.login1.Manager')
    properties = 'org.freedesktop.DBus.Properties'
    session_interface = 'org.freedesktop.login1.Session'
    session_id = os.environ.get('XDG_SESSION_ID')
    if session_id:
        session_path = manager.GetSession(session_id)
    else:
        # A shell launched as a systemd user service has no logind session PID.
        user = bus.get_object('org.freedesktop.login1', manager.GetUser(os.getuid()))
        _, session_path = user.Get('org.freedesktop.login1.User', 'Display', dbus_interface=properties)
        if session_path == '/':
            raise RuntimeError('No graphical logind session')
    session = bus.get_object('org.freedesktop.login1', session_path)
    loop = GLib.MainLoop()
    locker = None

    def is_locked():
        return bool(session.Get(session_interface, 'LockedHint', dbus_interface=properties))

    def lock():
        nonlocal locker
        if is_locked() or locker is not None:
            return
        try:
            locker = Gio.Subprocess.new(['hyprlock', '--immediate-render', '--no-fade-in'],
                                        Gio.SubprocessFlags.STDIN_PIPE | Gio.SubprocessFlags.STDOUT_SILENCE
                                        | Gio.SubprocessFlags.STDERR_SILENCE)
            locker.get_stdin_pipe().close(None)
            locker.wait_async(None, lock_finished)
        except GLib.Error as error:
            locker = None
            emit({'type': 'error', 'message': 'Could not start screen lock: ' + str(error)})

    def lock_finished(process, result):
        nonlocal locker
        try:
            process.wait_finish(result)
            if not process.get_successful():
                emit({'type': 'error', 'message': 'Screen locker exited unsuccessfully'})
        finally:
            locker = None

    guard = SleepGuard(lambda: manager.Inhibit('sleep', 'dofs', 'Lock session before sleep', 'delay').take(),
                       is_locked, lock, emit)

    def changed(interface, values, invalidated):
        if interface == session_interface and 'LockedHint' in values:
            guard.locked_changed(bool(values['LockedHint']))

    bus.add_signal_receiver(guard.prepare_sleep, signal_name='PrepareForSleep',
                            dbus_interface='org.freedesktop.login1.Manager',
                            bus_name='org.freedesktop.login1', path='/org/freedesktop/login1')
    bus.add_signal_receiver(lock, signal_name='Lock', dbus_interface=session_interface,
                            bus_name='org.freedesktop.login1', path=str(session_path))
    bus.add_signal_receiver(changed, signal_name='PropertiesChanged', dbus_interface=properties,
                            bus_name='org.freedesktop.login1', path=str(session_path))
    bus.call_on_disconnection(lambda _: loop.quit())
    buffer = b''

    def read_commands(fd, condition):
        nonlocal buffer
        data = os.read(fd, 4096)
        if not data:
            loop.quit()
            return False
        buffer += data
        while b'\n' in buffer:
            line, buffer = buffer.split(b'\n', 1)
            if line == b'lock':
                lock()
        if len(buffer) > 4096:
            raise ValueError('Session lock command too long')
        return True

    GLib.io_add_watch(sys.stdin.fileno(), GLib.IO_IN | GLib.IO_HUP, read_commands)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, lambda: (loop.quit(), False)[1])
    try:
        guard.acquire()
        emit({'type': 'ready'})
        if manager_object.Get('org.freedesktop.login1.Manager', 'PreparingForSleep', dbus_interface=properties):
            guard.prepare_sleep(True)
        loop.run()
    finally:
        guard.release()


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(json.dumps({'type': 'error', 'message': str(error)}), flush=True)
        sys.exit(1)
