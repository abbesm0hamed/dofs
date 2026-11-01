"""Locker tests never acquire a lock on the real desktop."""

import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
LOCK = ROOT / 'home/dot_config/quickshell/dofs-lock'
SHELL = LOCK.parent / 'dofs'
WRAPPER = SHELL / 'scripts/executable_lock-screen.sh'


class LockTests(unittest.TestCase):
    def test_authentication_is_the_only_unlock_path(self):
        controller = (LOCK / 'AuthController.qml').read_text()
        self.assertEqual(controller.count('session.locked = false'), 1)
        self.assertIn('result === PamResult.Success && session.locked && session.secure', controller)
        shell = (LOCK / 'shell.qml').read_text()
        self.assertIn('WlSessionLock {', shell)
        self.assertIn('WlSessionLockSurface {', shell)
        self.assertIn('Quickshell.watchFiles = false', shell)
        ipc = shell.split('IpcHandler {')[1]
        for name in ('unlock', 'submit', 'completed', 'respond'):
            self.assertNotIn('function ' + name, ipc)
        self.assertIn('configDirectory: "/etc/pam.d"', shell)
        self.assertNotIn('DOFS_LOCK_TEST', shell)

    def test_pam_uses_system_password_policy_and_separate_fingerprint_service(self):
        files = ROOT / 'ansible/roles/desktop/files'
        self.assertIn('auth        include       password-auth', (files / 'dofs-lock.pam').read_text())
        self.assertIn('auth        required      pam_fprintd.so', (files / 'dofs-lock-fingerprint.pam').read_text())
        self.assertIn('/etc/pam.d/dofs-lock', WRAPPER.read_text())
        field = (LOCK / 'LockView.qml').read_text()
        self.assertIn('TextInput.Password', field)
        self.assertIn('passwordMaskDelay: 0', field)
        self.assertIn('Qt.ImhSensitiveData', field)

    def test_wrapper_start_lock_fast_unlock_and_bad_ipc(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            pam = directory / 'pam-service'
            pam.write_text('fixture')
            wrapper = directory / 'lock-screen.sh'
            wrapper.write_text(WRAPPER.read_text().replace('/etc/pam.d/dofs-lock', str(pam)))
            binary = directory / 'qs'
            binary.write_text(r'''#!/usr/bin/env python3
import json, os, pathlib, sys
path = pathlib.Path(os.environ['QS_STATE'])
state = json.loads(path.read_text()) if path.exists() else {'running': False, 'ticket': 0, 'secure': 0}
args = sys.argv[1:]
with open(os.environ['QS_CALLS'], 'a') as log: log.write(json.dumps(args) + '\n')
if '--daemonize' in args: state['running'] = True
elif args[-1] == 'ping': print('ready' if state['running'] else 'Target not found.')
elif args[-1] == 'lock':
    if os.environ.get('BAD_IPC'): print('Target not found.')
    else:
        state['ticket'] += 1
        state['secure'] = 0 if os.environ.get('NO_CONFIRM') else state['ticket']
        print(state['ticket'])
elif args[-1] == 'secured': print(state['secure'])
path.write_text(json.dumps(state))
''')
            binary.chmod(0o700)
            notify = directory / 'notify-send'
            notify.write_text('#!/bin/sh\nexit 0\n')
            notify.chmod(0o700)
            env = dict(os.environ, XDG_RUNTIME_DIR=str(directory), PATH=str(directory) + ':' + os.environ['PATH'],
                       QS_STATE=str(directory / 'state'), QS_CALLS=str(directory / 'calls'))

            def run(*args, **extra):
                return subprocess.run(['bash', str(wrapper), *args], env=dict(env, **extra),
                                      capture_output=True, text=True, timeout=15)

            self.assertEqual(run('--start').returncode, 0)
            calls = [json.loads(line) for line in (directory / 'calls').read_text().splitlines()]
            self.assertFalse(any(args[-1] == 'lock' for args in calls), '--start must never lock')
            result = run()
            self.assertEqual(result.returncode, 0, result.stderr)
            # The wrapper relies on a sticky secure acknowledgement, not a currently locked flag.
            self.assertEqual(json.loads((directory / 'state').read_text())['secure'], 1)
            bad = run(BAD_IPC='1')
            self.assertNotEqual(bad.returncode, 0)
            self.assertIn('unexpected lock response', bad.stderr)
            unconfirmed = run(NO_CONFIRM='1')
            self.assertNotEqual(unconfirmed.returncode, 0)
            self.assertIn('compositor did not confirm', unconfirmed.stderr)
            self.assertTrue(json.loads((directory / 'state').read_text())['running'])
            calls = [json.loads(line) for line in (directory / 'calls').read_text().splitlines()]
            self.assertFalse(any('kill' in args for args in calls), 'never kill an unconfirmed/locked instance')
            pam.unlink()
            self.assertNotEqual(run().returncode, 0, 'missing PAM must fail before requesting a lock')


@unittest.skipUnless(os.environ.get('DOFS_QML_TEST') == '1', 'requires qs; uses offscreen mock locks')
class LiveLockTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get('DOFS_LOCK_NESTED_TEST') == '1', 'optional nested-Niri protocol test')
    def test_real_session_lock_and_pam_inside_nested_niri(self):
        if not shutil.which('niri') or not os.environ.get('WAYLAND_DISPLAY'):
            self.skipTest('requires Niri and an outer Wayland session')
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            runtime = directory / 'runtime'
            runtime.mkdir(mode=0o700)
            outer_socket = Path(os.environ['WAYLAND_DISPLAY'])
            if not outer_socket.is_absolute():
                outer_socket = Path(os.environ['XDG_RUNTIME_DIR']) / outer_socket
            config = directory / 'niri.kdl'
            config.write_text('')  # No startup commands, exported environment or host-session services.
            env = dict(os.environ, XDG_RUNTIME_DIR=str(runtime), WAYLAND_DISPLAY=str(outer_socket),
                       XDG_SESSION_ID='', QT_QPA_PLATFORM='wayland', QT_QUICK_BACKEND='software')
            env.pop('DISPLAY', None)
            nested_log = directory / 'nested.log'
            with nested_log.open('w') as stream:
                compositor = subprocess.Popen(['dbus-run-session', '--', 'niri', '-c', str(config)], env=env,
                                              stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
            locker = None
            try:
                deadline = time.monotonic() + 15
                inner = None
                while time.monotonic() < deadline:
                    sockets = [path for path in runtime.glob('wayland-*') if path.is_socket()]
                    if sockets:
                        inner = sockets[0]
                        break
                    if compositor.poll() is not None:
                        self.skipTest('Nested compositor unavailable: ' + nested_log.read_text())
                    time.sleep(0.05)
                self.assertIsNotNone(inner, nested_log.read_text())
                # Only the nested socket is passed to the test locker. Never request
                # a session lock with the outer desktop's WAYLAND_DISPLAY.
                env['WAYLAND_DISPLAY'] = str(inner)
                env['XDG_CONFIG_HOME'] = str(directory / 'config')
                copied = directory / 'dofs-lock'
                shutil.copytree(LOCK, copied)
                pam = directory / 'pam'
                pam.mkdir()
                (pam / 'dofs-lock').write_text('auth required pam_permit.so\n')
                (pam / 'dofs-lock-fingerprint').write_text('auth required pam_deny.so\n')
                source = (copied / 'shell.qml').read_text().replace('configDirectory: "/etc/pam.d"',
                                                                 'configDirectory: "' + str(pam) + '"')
                source = '\n'.join('                wallpaper: ""' if line.strip().startswith('wallpaper:') else line
                                   for line in source.splitlines())
                source = source.rsplit('}', 1)[0] + '''
    IpcHandler {
        target: "fixture"
        function authenticate(): void { auth.submit("fixture-only"); }
        function cancel(): void { auth.cancelPassword(); }
    }
}'''
                (copied / 'shell.qml').write_text(source)
                log = directory / 'locker.log'
                with log.open('w') as stream:
                    locker = subprocess.Popen(['qs', '-p', str(copied), '--no-color'], env=env,
                                              stdout=stream, stderr=subprocess.STDOUT)

                def ipc(target, method):
                    result = subprocess.run(['qs', '-p', str(copied), 'ipc', 'call', target, method],
                                            env=env, capture_output=True, text=True, timeout=3)
                    return result.stdout.strip()

                def wait_status(predicate):
                    deadline = time.monotonic() + 10
                    while time.monotonic() < deadline:
                        reply = ipc('lock', 'status')
                        if reply.startswith('{'):
                            status = json.loads(reply)
                            if predicate(status):
                                return
                        if locker.poll() is not None:
                            self.fail(log.read_text())
                    self.fail('Nested lock state did not converge: ' + log.read_text())

                wait_status(lambda status: not status['locked'])
                self.assertEqual(ipc('lock', 'lock'), '1')
                wait_status(lambda status: status['secure'])
                self.assertEqual(ipc('lock', 'lock'), '1', 'repeated requests must not reset authentication')
                self.assertEqual(ipc('lock', 'secured'), '1')
                ipc('fixture', 'cancel')
                self.assertTrue(json.loads(ipc('lock', 'status'))['locked'])
                self.assertNotEqual(ipc('lock', 'unlock'), '')
                self.assertTrue(json.loads(ipc('lock', 'status'))['locked'])
                ipc('fixture', 'authenticate')
                wait_status(lambda status: not status['locked'])
                self.assertEqual(ipc('lock', 'secured'), '1', 'secure acknowledgement survives a quick unlock')
                self.assertNotIn('WARN scene:', log.read_text(), log.read_text())
                self.assertNotIn('ERROR:', log.read_text(), log.read_text())
            finally:
                if locker is not None:
                    locker.terminate()
                    locker.wait(timeout=8)
                if compositor.poll() is None:
                    os.killpg(compositor.pid, signal.SIGTERM)
                compositor.wait(timeout=8)

    def test_production_entrypoint_loads_unlocked_without_authentication(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            shutil.copytree(LOCK, directory / 'dofs-lock')
            shutil.copytree(SHELL / 'bar', directory / 'dofs/bar')
            env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
            env.pop('WAYLAND_DISPLAY', None)
            log = directory / 'entrypoint.log'
            with log.open('w') as stream:
                process = subprocess.Popen(['qs', '-p', str(directory / 'dofs-lock'), '--no-color'], env=env,
                                           stdout=stream, stderr=subprocess.STDOUT)
            try:
                deadline = time.monotonic() + 8
                while time.monotonic() < deadline:
                    result = subprocess.run(['qs', '-p', str(directory / 'dofs-lock'), 'ipc', 'call', 'lock', 'status'],
                                            env=env, capture_output=True, text=True, timeout=3)
                    if result.stdout.startswith('{'):
                        break
                    if process.poll() is not None:
                        self.fail(log.read_text())
                else:
                    self.fail(log.read_text())
                self.assertEqual(json.loads(result.stdout), {'locked': False, 'secure': False})
            finally:
                process.terminate()
                process.wait(timeout=8)
            self.assertNotIn('WARN scene:', log.read_text(), log.read_text())

    def launch(self, directory, qml):
        directory = Path(directory)
        shutil.copytree(LOCK, directory / 'lock')
        (directory / 'shell.qml').write_text(qml.replace('ShellRoot {', 'ShellRoot {\n    Component.onCompleted: Quickshell.watchFiles = false', 1))
        env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
        env.pop('WAYLAND_DISPLAY', None)
        env.pop('DISPLAY', None)
        log = directory / 'qs.log'
        with log.open('w') as stream:
            process = subprocess.Popen(['qs', '-p', str(directory), '--no-color'], env=env,
                                       stdout=stream, stderr=subprocess.STDOUT)
        self.addCleanup(self.stop, process, log.open())

        def ipc(method, *args):
            result = subprocess.run(['qs', '-p', str(directory), 'ipc', 'call', 'test', method, *map(str, args)],
                                    env=env, capture_output=True, text=True, timeout=4)
            return result.stdout.strip()

        def wait(predicate):
            deadline = time.monotonic() + 8
            while time.monotonic() < deadline:
                reply = ipc('state')
                if reply.startswith('{'):
                    state = json.loads(reply)
                    if predicate(state):
                        return state
                if process.poll() is not None:
                    self.fail(log.read_text())
            self.fail('Locker fixture timed out: ' + log.read_text())

        wait(lambda state: state['ready'])
        return ipc, wait

    def stop(self, process, log):
        process.terminate()
        process.wait(timeout=8)
        log.seek(0)
        logs = log.read()
        log.close()
        self.assertNotIn('WARN scene:', logs, logs)
        self.assertNotIn('ERROR:', logs, logs)

    def test_controller_cancellation_prompts_failures_and_success(self):
        with tempfile.TemporaryDirectory() as directory:
            ipc, wait = self.launch(directory, '''import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import "lock"
ShellRoot {
    function field(view) {
        var todo = [view];
        while (todo.length) {
            var item = todo.pop();
            if (item.objectName === "lockPassword") return item;
            for (var i = 0; i < item.children.length; i++) todo.push(item.children[i]);
        }
        return null;
    }
    component MockPam: QtObject {
        property bool active: false
        property bool responseRequired: false
        property bool responseVisible: false
        property string message: ""
        property bool allowStart: true
        property int responses: 0
        signal pamMessage()
        signal completed(int result)
        function start() { active = allowStart; return allowStart; }
        function abort() { active = false; responseRequired = false; }
        function respond(value) { responses++; responseRequired = false; }
        function prompt(visible) { responseRequired = true; responseVisible = visible; message = "Prompt"; pamMessage(); }
        function finish(result) { active = false; responseRequired = false; completed(result); }
    }
    QtObject { id: session; property bool locked: false; property bool secure: false }
    MockPam { id: password }
    MockPam { id: fingerprint }
    AuthController { id: auth; session: session; passwordPam: password; fingerprintPam: fingerprint }
    QtObject {
        id: palette
        property color background: "#111111"
        property color surface: "#222222"
        property color text: "#eeeeee"
        property color muted: "#999999"
        property color accent: "#abcdef"
        property color border: "#333333"
    }
    Window {
        width: 800; height: 600; visible: true
        LockView { id: first; anchors.fill: parent; auth: auth; palette: palette }
        LockView { id: second; anchors.fill: parent; auth: auth; palette: palette; visible: false }
    }
    IpcHandler {
        target: "test"
        function begin(): void { session.locked = false; session.secure = false; session.locked = true; session.secure = true; }
        function submit(): void { auth.submit("fixture-secret"); }
        function fill(): void { field(first).text = "fixture-only"; field(second).text = "fixture-only"; }
        function secretPrompt(): void { password.prompt(false); }
        function visiblePrompt(): void { password.prompt(true); }
        function cancel(): void { auth.cancelPassword(); }
        function insecure(): void { session.secure = false; }
        function reject(): void { password.finish(PamResult.Failed); }
        function error(): void { password.finish(PamResult.Error); }
        function maxTries(): void { password.finish(PamResult.MaxTries); }
        function succeed(): void { password.finish(PamResult.Success); }
        function fingerprintSuccess(): void { fingerprint.finish(PamResult.Success); }
        function failStart(): void { password.allowStart = false; }
        function state(): string {
            return JSON.stringify({ready: true, locked: session.locked, pending: auth.pendingResponse.length,
                responses: password.responses, password: password.active, fingerprint: fingerprint.active,
                typed: field(first).text.length + field(second).text.length,
                canType: auth.canType, message: auth.message});
        }
    }
}''')
            ipc('begin')
            self.assertTrue(json.loads(ipc('state'))['fingerprint'])
            ipc('fill')
            ipc('submit')
            self.assertEqual(json.loads(ipc('state'))['typed'], 0, 'clear input on every output when submitting')
            self.assertGreater(json.loads(ipc('state'))['pending'], 0)
            ipc('visiblePrompt')
            state = json.loads(ipc('state'))
            self.assertEqual(state['pending'], 0)
            self.assertEqual(state['responses'], 0, 'never send a password to an echo-on prompt')
            ipc('submit')
            self.assertEqual(json.loads(ipc('state'))['responses'], 1)
            ipc('secretPrompt')
            self.assertEqual(json.loads(ipc('state'))['responses'], 1, 'do not reuse a secret for later prompts')
            ipc('submit')
            self.assertEqual(json.loads(ipc('state'))['responses'], 2)
            ipc('cancel')
            ipc('succeed')
            self.assertTrue(json.loads(ipc('state'))['locked'], 'stale success after abort cannot unlock')
            for failure in ('reject', 'error', 'maxTries'):
                ipc('begin')
                ipc('submit')
                ipc(failure)
                state = json.loads(ipc('state'))
                self.assertTrue(state['locked'])
                self.assertFalse(state['canType'])
                self.assertEqual(state['pending'], 0)
            ipc('begin')
            ipc('submit')
            ipc('insecure')
            ipc('succeed')
            self.assertTrue(json.loads(ipc('state'))['locked'], 'success before lock coverage cannot unlock')
            ipc('begin')
            ipc('submit')
            ipc('secretPrompt')
            ipc('succeed')
            self.assertFalse(json.loads(ipc('state'))['locked'])
            self.assertFalse(json.loads(ipc('state'))['fingerprint'])
            ipc('begin')
            ipc('fingerprintSuccess')
            self.assertFalse(json.loads(ipc('state'))['locked'])
            ipc('begin')
            ipc('failStart')
            ipc('submit')
            state = json.loads(ipc('state'))
            self.assertTrue(state['locked'])
            self.assertEqual(state['pending'], 0)

    def test_real_pam_success_failure_and_secret_prompt_with_mock_session(self):
        for module, unlocks in (('pam_permit.so', True), ('pam_deny.so', False), ('pam_exec.so', True)):
            with self.subTest(module=module), tempfile.TemporaryDirectory() as directory:
                directory = Path(directory)
                pam_dir = directory / 'pam'
                pam_dir.mkdir()
                rule = module
                if module == 'pam_exec.so':
                    checker = directory / 'check-response'
                    checker.write_text('#!/usr/bin/python3\nimport os, sys\nsys.exit(0 if os.read(0, 512).rstrip(b"\\0") == b"fixture-only" else 1)\n')
                    checker.chmod(0o700)
                    rule += ' expose_authtok quiet ' + str(checker)
                (pam_dir / 'password').write_text('auth required ' + rule + '\n')
                (pam_dir / 'fingerprint').write_text('auth required pam_deny.so\n')
                ipc, wait = self.launch(directory, '''import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import "lock"
ShellRoot {
    QtObject { id: session; property bool locked: false; property bool secure: false }
    PamContext { id: password; config: "password"; configDirectory: "PAM_DIR" }
    PamContext { id: fingerprint; config: "fingerprint"; configDirectory: "PAM_DIR" }
    AuthController { id: auth; session: session; passwordPam: password; fingerprintPam: fingerprint }
    IpcHandler {
        target: "test"
        function begin(): void { session.locked = true; session.secure = true; auth.submit("fixture-only"); }
        function state(): string {
            return JSON.stringify({ready: true, locked: session.locked, active: password.active,
                pending: auth.pendingResponse.length, attempted: auth.passwordAttempt});
        }
    }
}'''.replace('PAM_DIR', str(pam_dir)))
                ipc('begin')
                state = wait(lambda state: not state['active'] and not state['attempted'])
                self.assertEqual(state['locked'], not unlocks)
                self.assertEqual(state['pending'], 0)


if __name__ == '__main__':
    unittest.main()
