"""Exercise the logind bridge on a private bus with a fake locker, never the desktop."""

import json
import os
from pathlib import Path
import selectors
import shutil
import subprocess
import tempfile
import threading
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
BRIDGE = ROOT / 'home/dot_config/quickshell/dofs/services/session-lock.py'


def fixture():
    import dbus
    import dbus.service
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName('org.freedesktop.login1', bus)
    session_path = '/org/freedesktop/login1/session/test'
    readers = []

    class Session(dbus.service.Object):
        locked = False

        @dbus.service.method('org.freedesktop.DBus.Properties', in_signature='ss', out_signature='v')
        def Get(self, interface, prop):
            assert prop == 'LockedHint'
            return dbus.Boolean(self.locked)

        @dbus.service.signal('org.freedesktop.DBus.Properties', signature='sa{sv}as')
        def PropertiesChanged(self, interface, values, invalidated):
            pass

        @dbus.service.signal('org.freedesktop.login1.Session', signature='')
        def Lock(self):
            pass

        def set_locked(self, value):
            self.locked = value
            self.PropertiesChanged('org.freedesktop.login1.Session', {'LockedHint': dbus.Boolean(value)}, [])

    class User(dbus.service.Object):
        @dbus.service.method('org.freedesktop.DBus.Properties', in_signature='ss', out_signature='v')
        def Get(self, interface, prop):
            assert prop == 'Display'
            return dbus.Struct(('test', dbus.ObjectPath(session_path)), signature='so')

    class Manager(dbus.service.Object):
        @dbus.service.method('org.freedesktop.login1.Manager', in_signature='s', out_signature='o')
        def GetSession(self, session_id):
            return session_path

        @dbus.service.method('org.freedesktop.login1.Manager', in_signature='u', out_signature='o')
        def GetUser(self, uid):
            return '/org/freedesktop/login1/user/test'

        @dbus.service.method('org.freedesktop.login1.Manager', in_signature='ssss', out_signature='h')
        def Inhibit(self, what, who, why, mode):
            assert what == 'sleep' and mode == 'delay'
            read, write = os.pipe()
            os.set_blocking(read, False)
            readers.append(read)
            fd = dbus.types.UnixFd(write)
            os.close(write)
            return fd

        @dbus.service.method('org.freedesktop.DBus.Properties', in_signature='ss', out_signature='v')
        def Get(self, interface, prop):
            assert prop == 'PreparingForSleep'
            return dbus.Boolean(False)

        @dbus.service.signal('org.freedesktop.login1.Manager', signature='b')
        def PrepareForSleep(self, active):
            pass

    manager = Manager(name, '/org/freedesktop/login1')
    session = Session(name, session_path)
    user = User(name, '/org/freedesktop/login1/user/test')
    loop = GLib.MainLoop()
    thread = threading.Thread(target=loop.run, daemon=True)
    thread.start()

    def until(predicate):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if predicate():
                return
            time.sleep(0.01)
        raise AssertionError('Private logind fixture timed out')

    def released(read):
        try:
            return os.read(read, 1) == b''
        except BlockingIOError:
            return False

    try:
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            calls = directory / 'locks'
            config = directory / 'config'
            binary = config / 'quickshell/dofs/scripts/lock-screen.sh'
            binary.parent.mkdir(parents=True)
            binary.write_text('#!/bin/sh\nprintf "lock\\n" >> "$LOCK_CALLS"\n')
            binary.chmod(0o700)
            env = dict(os.environ, DBUS_SYSTEM_BUS_ADDRESS=os.environ['DBUS_SESSION_BUS_ADDRESS'],
                       XDG_CONFIG_HOME=str(config), LOCK_CALLS=str(calls))
            # Cover the systemd user-service path with no XDG_SESSION_ID.
            env.pop('XDG_SESSION_ID', None)
            process = subprocess.Popen(['/usr/bin/python3', '-B', '-u', str(BRIDGE)], env=env,
                                       stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            selector = selectors.DefaultSelector()
            selector.register(process.stdout, selectors.EVENT_READ)

            def event(expected):
                assert selector.select(timeout=5), 'No bridge event: ' + expected
                response = json.loads(process.stdout.readline())
                assert response['type'] == expected, response

            try:
                event('ready')
                assert len(readers) == 1
                assert not released(readers[0])
                # Explicit loginctl lock requests work without waiting for idle.
                session.Lock()
                until(lambda: calls.exists() and len(calls.read_text().splitlines()) == 1)
                session.set_locked(True)
                manager.PrepareForSleep(True)
                until(lambda: released(readers[0]))
                manager.PrepareForSleep(False)
                event('resume')
                assert len(readers) == 2 and not released(readers[1])
                session.set_locked(False)
                manager.PrepareForSleep(True)
                until(lambda: len(calls.read_text().splitlines()) == 2)
                assert not released(readers[1]), 'Starting a locker is not lock confirmation'
                session.set_locked(True)
                until(lambda: released(readers[1]))
                manager.PrepareForSleep(False)
                event('resume')
                session.set_locked(False)
                process.stdin.write(b'lock\n')
                process.stdin.flush()
                until(lambda: len(calls.read_text().splitlines()) == 3)
                process.stdin.close()  # Parent disappearance must release the delay FD.
                process.wait(timeout=5)
                assert process.returncode == 0, process.stderr.read().decode()
                until(lambda: released(readers[2]))
            finally:
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=5)
                process.stdout.close()
                process.stderr.close()
                selector.close()
    finally:
        loop.quit()
        thread.join(timeout=5)
        for read in readers:
            os.close(read)


class SessionLockTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('dbus-run-session'), 'requires dbus-run-session')
    def test_private_logind_signals_delay_fd_and_parent_lifetime(self):
        dependencies = subprocess.run(['/usr/bin/python3', '-c', 'import dbus; from gi.repository import Gio, GLib'],
                                      capture_output=True)
        if dependencies.returncode:
            self.skipTest('requires Fedora python3-dbus and python3-gobject')
        result = subprocess.run(['dbus-run-session', '--', 'env', 'DOFS_SESSION_LOCK_FIXTURE=1',
                                 '/usr/bin/python3', '-B', str(Path(__file__).resolve())],
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    if os.environ.get('DOFS_SESSION_LOCK_FIXTURE') == '1':
        fixture()
    else:
        unittest.main()
