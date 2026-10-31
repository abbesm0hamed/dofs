import importlib.util
import json
import os
import re
from pathlib import Path
import selectors
import shutil
import socket
import subprocess
import tempfile
import threading
import time
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[2]
SHELL = ROOT / 'home/dot_config/quickshell/dofs'
WRAPPER = ROOT / 'home/dot_config/niri/scripts/executable_quickshell-launcher.sh'


class BarTests(unittest.TestCase):
    def test_sampler(self):
        spec = importlib.util.spec_from_file_location('stats', SHELL / 'services/system-stats.py')
        stats = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(stats)
        first, previous = stats.snapshot()
        self.assertIsNone(first['cpu'])
        for key in ('storage', 'memory'):
            self.assertGreaterEqual(first[key], 0)
            self.assertLessEqual(first[key], 100)
        second, _ = stats.snapshot((previous[0] - 100, previous[1] - 25))
        self.assertGreaterEqual(second['cpu'], 0)
        self.assertLessEqual(second['cpu'], 100)

    def test_workspace_action_uses_id_and_reads_reply(self):
        with tempfile.TemporaryDirectory() as directory:
            address = str(Path(directory) / 'niri.sock')
            requests = []
            with socket.socket(socket.AF_UNIX) as server:
                server.bind(address)
                server.listen(1)

                def serve():
                    client, _ = server.accept()
                    with client, client.makefile('rb') as stream:
                        requests.append(json.loads(stream.readline()))
                        client.sendall(b'{"Ok":"Handled"}\n')

                thread = threading.Thread(target=serve, daemon=True)
                thread.start()
                result = subprocess.run(['python3', '-B', str(SHELL / 'services/niri-action.py'), '42'],
                                        env=dict(os.environ, NIRI_SOCKET=address), capture_output=True, timeout=5)
                thread.join(timeout=5)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(requests, [{'Action': {'FocusWorkspace': {'reference': {'Id': 42}}}}])

    def test_package_cutover(self):
        packages = (ROOT / 'ansible/roles/packages/vars/main.yml').read_text()
        installed = packages.split('dnf_packages:', 1)[1].split('dnf_absent_packages:', 1)[0]
        self.assertNotIn('  - waybar\n', installed)
        self.assertIn('  - quickshell\n', installed)
        self.assertTrue((ROOT / 'home/dot_config/waybar/config.jsonc').is_file())
        self.assertNotIn('run_once waybar', (ROOT / 'home/dot_config/niri/scripts/executable_autostart.sh').read_text())

    def test_active_shell_has_no_legacy_bar_dependencies(self):
        files = [p for p in SHELL.rglob('*') if p.is_file()]
        files += [ROOT / p for p in (
            'home/dot_config/niri/scripts/executable_set-theme.sh',
            'home/dot_config/niri/scripts/executable_system-controls.sh',
            'home/dot_config/niri/scripts/executable_screencast.sh',
            'home/dot_config/matugen/config.toml',
            'scripts/maintenance/doctor.sh', 'ansible/roles/verify/tasks/main.yml', 'dofs')]
        for file in files:
            with self.subTest(file=file):
                self.assertNotRegex(file.read_text(), re.compile('waybar', re.IGNORECASE))

    def test_theme_palettes_and_generation(self):
        mapping = {'background': 'bar_bg', 'surface': 'surface0', 'text': 'text',
                   'muted': 'ws_fg', 'accent': 'blue', 'border': 'bar_border',
                   'red': 'red', 'yellow': 'yellow', 'green': 'green'}
        themes = ROOT / 'home/dot_config/themes'
        for palette in themes.glob('*/quickshell-theme.json'):
            colors = json.loads(palette.read_text())
            self.assertEqual(set(colors), set(mapping))
            legacy = dict(re.findall(r'@define-color\s+(\w+)\s+(#[0-9a-fA-F]{6});', (palette.parent / 'waybar-theme.css').read_text()))
            for key, legacy_key in mapping.items():
                self.assertEqual(colors[key], legacy[legacy_key], (palette, key))
        matugen = tomllib.loads((ROOT / 'home/dot_config/matugen/config.toml').read_text())
        self.assertIn('quickshell', matugen['templates'])
        self.assertNotIn('waybar', matugen['templates'])
        self.assertEqual(matugen['templates']['quickshell']['output_path'], '~/.config/quickshell/dofs/bar/theme.json')
        # Run the real theme script against isolated fixtures: no GTK, wallpaper
        # or real notification changes, and preserve the archived CSS sentinel.
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            config = home / '.config'
            (config / 'waybar').mkdir(parents=True)
            old_palette = config / 'waybar/theme.css'
            old_palette.write_text('archived palette')
            bin_dir = home / 'bin'
            bin_dir.mkdir()
            mako = bin_dir / 'makoctl'
            mako.write_text('#!/bin/sh\nexit 0\n')
            mako.chmod(0o700)
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(config),
                       XDG_STATE_HOME=str(home / '.state'), PATH=str(bin_dir) + ':' + os.environ['PATH'])
            for palette in themes.glob('*/quickshell-theme.json'):
                destination = config / 'themes' / palette.parent.name
                destination.mkdir(parents=True)
                shutil.copy2(palette, destination / palette.name)
                result = subprocess.run(['bash', str(ROOT / 'home/dot_config/niri/scripts/executable_set-theme.sh'),
                                         palette.parent.name, '--skip-wallpaper', '--silent'],
                                        env=env, capture_output=True, text=True, timeout=5)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads((config / 'quickshell/dofs/bar/theme.json').read_text()), json.loads(palette.read_text()))
                self.assertEqual(old_palette.read_text(), 'archived palette')

    def test_wrapper_start_toggle_and_ipc_error(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            binary = directory / 'qs'
            binary.write_text('''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['CALLS'], 'a') as log: log.write(json.dumps(sys.argv[1:]) + '\\n')
if sys.argv[-1] == 'ping': print('ready')
elif os.environ.get('FAIL_IPC') == '1': print('error: handler unavailable')
''')
            binary.chmod(0o700)
            # Avoid desktop notifications during deliberate error cases.
            notify = directory / 'notify-send'
            notify.write_text('#!/bin/sh\nexit 0\n')
            notify.chmod(0o700)
            log = directory / 'calls'
            env = dict(os.environ, PATH=str(directory) + ':' + os.environ['PATH'],
                       CALLS=str(log), XDG_RUNTIME_DIR=str(directory))
            start = subprocess.run(['bash', str(WRAPPER), '--start'], env=env, capture_output=True, timeout=10)
            self.assertEqual(start.returncode, 0, start.stderr)
            self.assertTrue(all(json.loads(line)[-1] == 'ping' for line in log.read_text().splitlines()))
            toggle = subprocess.run(['bash', str(WRAPPER), '--bar-toggle'], env=env, capture_output=True, timeout=10)
            self.assertEqual(toggle.returncode, 0, toggle.stderr)
            self.assertEqual(json.loads(log.read_text().splitlines()[-1])[-2:], ['bar', 'toggle'])
            failed = subprocess.run(['bash', str(WRAPPER), '--bar-toggle'],
                                    env=dict(env, FAIL_IPC='1'), capture_output=True, timeout=10)
            self.assertNotEqual(failed.returncode, 0, 'IPC error text must fail even if qs exits zero')


@unittest.skipUnless(os.environ.get('DOFS_QML_TEST') == '1', 'requires a live Wayland session and qs')
class LiveBarTests(unittest.TestCase):
    def test_command_output_and_hard_timeout(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            shutil.copytree(SHELL / 'services', directory / 'services')
            (directory / 'shell.qml').write_text('''import Quickshell
import Quickshell.Io
import "services"
ShellRoot {
    CommandStatus {
        id: healthy
        command: ["printf", "{\\"text\\":\\"<span>ready</span>\\"}"]
        interval: 0
    }
    CommandStatus {
        id: hung
        command: ["python3", "-c", "import signal,time; signal.signal(signal.SIGTERM, signal.SIG_IGN); time.sleep(30)"]
        timeout: 200
        interval: 0
    }
    IpcHandler {
        target: "test"
        function status(): string { return JSON.stringify({text: healthy.plain(healthy.value.text), healthyError: healthy.error, hungError: hung.error}); }
    }
}''')
            process = subprocess.Popen(['qs', '-p', str(directory), '--no-color'],
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            logs = []
            selector = selectors.DefaultSelector()
            selector.register(process.stdout, selectors.EVENT_READ)
            try:
                deadline = time.monotonic() + 10
                while time.monotonic() < deadline:
                    if not selector.select(timeout=1):
                        continue
                    line = os.read(process.stdout.fileno(), 65536).decode(errors='replace')
                    logs.append(line)
                    if 'Configuration Loaded' in line:
                        break
                    if process.poll() is not None:
                        self.fail('Quickshell exited: ' + ''.join(logs))
                else:
                    self.fail('No QML readiness: ' + ''.join(logs))
                while time.monotonic() < deadline:
                    result = subprocess.run(['qs', '-p', str(directory), 'ipc', 'call', 'test', 'status'],
                                            capture_output=True, text=True, timeout=3)
                    status = json.loads(result.stdout)
                    if status['hungError']:
                        break
                else:
                    self.fail('Command was not bounded by its hard timeout')
                self.assertEqual(status['text'], 'ready')
                self.assertEqual(status['healthyError'], '')
                self.assertEqual(status['hungError'], 'Command timed out')
            finally:
                process.terminate()
                remaining, _ = process.communicate(timeout=8)
                logs.append(remaining.decode(errors='replace'))
                selector.close()
            self.assertNotIn('WARN scene:', ''.join(logs), ''.join(logs))

    def test_hidden_shell_ipc_and_event_reconnect(self):
        # Copy the config to give this test its own Quickshell instance identity.
        # Never deploy files, show surfaces, run legacy scripts, or change focus.
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / 'dofs-test'
            shutil.copytree(SHELL, config)
            entrypoint = config / 'shell.qml'
            entrypoint.write_text('import QtQuick\n' + entrypoint.read_text().rsplit('}', 1)[0] + '''
    TextMetrics {
        id: labelMetrics
        text: "M"
        font.family: "Lilex Nerd Font Mono"
        font.pixelSize: 13
        renderType: Text.QtRendering
    }
    Item {
        Repeater {
            id: iconSamples
            model: ["󰁹", "󰐊", "", "", "", "󰤨", ""]
            BarIcon { required property string modelData; glyph: modelData; size: 13; height: 23 }
        }
    }
    IpcHandler {
        target: "iconTest"
        function metrics(): string {
            var result = [];
            for (var i = 0; i < iconSamples.count; i++) {
                var icon = iconSamples.itemAt(i);
                var glyph = icon.children[0];
                result.push({width: icon.inkBounds.width * icon.glyphScale,
                    height: icon.inkBounds.height * icon.glyphScale,
                    target: labelMetrics.tightBoundingRect.height,
                    centerX: glyph.x + (icon.inkBounds.x + icon.inkBounds.width / 2) * glyph.scale,
                    centerY: glyph.y + (glyph.baselineOffset + icon.inkBounds.y + icon.inkBounds.height / 2) * glyph.scale,
                    boxWidth: icon.width, boxHeight: icon.height});
            }
            return JSON.stringify(result);
        }
    }
}''')
            env = dict(os.environ, DOFS_BAR_TEST='1', QT_QPA_PLATFORM='wayland', PYTHONDONTWRITEBYTECODE='1')
            process = subprocess.Popen(['qs', '-p', str(config), '--no-color'], env=env,
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            logs = []
            selector = selectors.DefaultSelector()
            selector.register(process.stdout, selectors.EVENT_READ)

            def ipc(*args):
                result = subprocess.run(['qs', '-p', str(config), 'ipc', 'call', *args],
                                        env=env, capture_output=True, text=True, timeout=4)
                self.assertEqual(result.returncode, 0, result.stderr)
                return result.stdout.strip()

            def wait_status(predicate):
                deadline = time.monotonic() + 12
                while time.monotonic() < deadline:
                    reply = ipc('bar', 'status')
                    if reply.startswith('{'):
                        status = json.loads(reply)
                        if predicate(status):
                            return status
                self.fail('Bar state did not converge')

            try:
                deadline = time.monotonic() + 15
                while time.monotonic() < deadline:
                    if not selector.select(timeout=1):
                        continue
                    line = os.read(process.stdout.fileno(), 65536).decode(errors='replace')
                    logs.append(line)
                    if 'Configuration Loaded' in line:
                        break
                    if process.poll() is not None:
                        self.fail('Quickshell exited: ' + ''.join(logs))
                else:
                    self.fail('No QML readiness: ' + ''.join(logs))
                self.assertEqual(ipc('launcher', 'ping'), 'ready')
                self.assertEqual(ipc('bar', 'ping'), 'ready')
                first = wait_status(lambda s: s['niri'] and s['workspaces'] and s['stats'].get('cpu') is not None)
                samples = json.loads(ipc('iconTest', 'metrics'))
                self.assertEqual(len(samples), 7)
                for sample in samples:
                    self.assertGreater(sample['width'], 0)
                    self.assertGreater(sample['height'], 0)
                    self.assertAlmostEqual(max(sample['width'], sample['height']), sample['target'], places=5)
                    self.assertAlmostEqual(sample['centerX'], sample['boxWidth'] / 2, places=5)
                    self.assertAlmostEqual(sample['centerY'], sample['boxHeight'] / 2, places=5)
                ipc('bar', 'hide')
                self.assertFalse(json.loads(ipc('bar', 'status'))['shown'])
                ipc('bar', 'toggle')
                self.assertTrue(json.loads(ipc('bar', 'status'))['shown'])
                self.assertEqual(ipc('launcher', 'ping'), 'ready', 'hiding bar must not stop launcher')
                # Exercise live JSON reads and last-known-good recovery. Only
                # change the copied test config, never the user's config.
                options_path = config / 'bar/config.json'
                options = json.loads(options_path.read_text())
                options['height'] = 28
                options['modules'] = ['clock', 'audio']
                options_path.write_text(json.dumps(options))
                wait_status(lambda s: s['options']['height'] == 28 and s['options']['modules'] == ['clock', 'audio'])
                options_path.write_text('{ invalid json')
                invalid = wait_status(lambda s: bool(s['configError']))
                self.assertEqual(invalid['options']['height'], 28)
                options_path.write_text(json.dumps(options))
                wait_status(lambda s: not s['configError'])
                theme_path = config / 'bar/theme.json'
                theme = json.loads(theme_path.read_text())
                theme['background'] = '#123456'
                theme_path.write_text(json.dumps(theme))
                wait_status(lambda s: s['theme'].get('background') == '#123456')
                theme_path.write_text('{ invalid palette')
                invalid_theme = wait_status(lambda s: bool(s['configError']))
                self.assertEqual(invalid_theme['theme']['background'], '#123456')
                theme_path.write_text(json.dumps(theme))
                wait_status(lambda s: not s['configError'])
                # Kill only this test shell's event-stream child, never Niri itself.
                children = Path(f'/proc/{process.pid}/task/{process.pid}/children').read_text().split()
                event_pid = next(int(pid) for pid in children if b'event-stream' in Path(f'/proc/{pid}/cmdline').read_bytes())
                os.kill(event_pid, 15)
                wait_status(lambda s: not s['niri'])
                restored = wait_status(lambda s: s['niri'] and bool(s['workspaces']))
                self.assertEqual({w['id'] for w in first['workspaces']}, {w['id'] for w in restored['workspaces']})
            finally:
                process.terminate()
                remaining, _ = process.communicate(timeout=8)
                logs.append(remaining.decode(errors='replace'))
                selector.close()
            output = ''.join(logs)
            self.assertNotIn('ERROR:', output, output)
            self.assertNotIn('WARN scene:', output, output)


if __name__ == '__main__':
    unittest.main()
