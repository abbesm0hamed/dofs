import copy
import importlib.util
import json
import os
from pathlib import Path
import selectors
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

import yaml

ROOT = Path(__file__).resolve().parents[2]
SHELL = ROOT / 'home/dot_config/quickshell/dofs'
SPEC = importlib.util.spec_from_file_location('audio_backend', SHELL / 'audio/backend.py')
backend = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(backend)


def node(index, kind, name):
    return {'index': index, 'name': name, 'kind': kind, 'canVolume': True,
            'ports': [{'name': 'speaker', 'available': True}, {'name': 'unplugged', 'available': False}]}


class BackendTests(unittest.TestCase):
    def setUp(self):
        self.service = backend.Backend()
        self.data = {'sinks': [node(10, 'sink', 'speakers')],
                     'sources': [node(20, 'source', 'microphone')],
                     'playback': [node(30, 'sink-input', 'browser')],
                     'recording': [node(40, 'source-output', 'recorder')],
                     'cards': [{'index': 50, 'profiles': [{'name': 'duplex', 'available': True},
                                                        {'name': 'unavailable', 'available': False}]}]}
        self.service.snapshot = lambda: copy.deepcopy(self.data)
        self.calls = []
        self.service.run = lambda *args, **kwargs: self.calls.append(args)

    def test_volume_is_set_for_devices_and_application_streams(self):
        for kind, index in [('sink', 10), ('source', 20), ('sink-input', 30), ('source-output', 40)]:
            with self.subTest(kind=kind):
                self.service.action({'action': 'volume', 'kind': kind, 'index': index, 'value': 42.4})
                self.assertEqual(self.calls[-1], ('set-' + kind + '-volume', str(index), '42%'))

    def test_volume_rejects_invalid_or_amplified_values(self):
        for value in [-1, 101, float('nan'), float('inf'), '50', True, None]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.service.action({'action': 'volume', 'kind': 'sink', 'index': 10, 'value': value})
        self.assertEqual(self.calls, [])

    def test_volume_rejects_read_only_stream(self):
        self.data['playback'][0]['canVolume'] = False
        with self.assertRaises(ValueError):
            self.service.action({'action': 'volume', 'kind': 'sink-input', 'index': 30, 'value': 50})

    def test_mute_is_explicit_and_does_not_change_volume(self):
        self.service.action({'action': 'mute', 'kind': 'source', 'index': 20, 'value': True})
        self.assertEqual(self.calls, [('set-source-mute', '20', '1')])
        with self.assertRaises(ValueError):
            self.service.action({'action': 'mute', 'kind': 'source', 'index': 20, 'value': 'toggle'})

    def test_default_device_uses_server_name_without_moving_existing_streams(self):
        self.service.action({'action': 'default', 'kind': 'sink', 'index': 10})
        self.assertEqual(self.calls, [('set-default-sink', 'speakers')])
        with self.assertRaises(ValueError):
            self.service.action({'action': 'default', 'kind': 'sink-input', 'index': 30})

    def test_application_playback_and_recording_can_be_routed(self):
        for kind, index, target in [('sink-input', 30, 10), ('source-output', 40, 20)]:
            self.service.action({'action': 'move', 'kind': kind, 'index': index, 'target': target})
            self.assertEqual(self.calls[-1], ('move-' + kind, str(index), str(target)))

    def test_stale_stream_or_destination_is_rejected(self):
        for index, target in [(999, 10), (30, 999), (30, 20)]:
            with self.subTest(index=index, target=target), self.assertRaises(ValueError):
                self.service.action({'action': 'move', 'kind': 'sink-input', 'index': index, 'target': target})
        self.assertEqual(self.calls, [])

    def test_unknown_actions_and_kinds_are_rejected(self):
        for request in [{'action': 'exec', 'value': 'rm'}, {'action': 'mute', 'kind': 'card', 'index': 50}]:
            with self.assertRaises(ValueError):
                self.service.action(request)
        self.assertEqual(self.calls, [])

    def test_ports_and_profiles_are_validated_against_current_server_state(self):
        self.service.action({'action': 'port', 'kind': 'sink', 'index': 10, 'value': 'speaker'})
        self.service.action({'action': 'profile', 'index': 50, 'value': 'duplex'})
        self.assertEqual(self.calls, [('set-sink-port', '10', 'speaker'), ('set-card-profile', '50', 'duplex')])
        for request in [{'action': 'port', 'kind': 'sink', 'index': 10, 'value': 'unplugged'},
                        {'action': 'profile', 'index': 50, 'value': 'unavailable'},
                        {'action': 'profile', 'index': 50, 'value': '--arbitrary-option'}]:
            with self.assertRaises(ValueError):
                self.service.action(request)

    def test_volume_normalization_handles_channels_and_read_only_streams(self):
        result = backend.Backend.node({'index': 1, 'name': 'sink', 'mute': True,
                                       'volume': {'left': {'value': 32768}, 'right': {'value': 65536}}}, 'sink', 'sink')
        self.assertEqual(result['volume'], 75)
        self.assertTrue(result['default'])
        self.assertTrue(result['muted'])
        result = backend.Backend.node({'index': 2, 'properties': {'application.name': '<Browser>'}}, 'sink-input')
        self.assertEqual(result['description'], '<Browser>')
        self.assertFalse(result['canVolume'])

    def test_monitor_sources_are_marked_but_remain_available_for_routing(self):
        self.assertTrue(backend.Backend.node({'index': 1, 'monitor_of_sink': 10}, 'source')['monitor'])
        for monitor in [None, 4294967295]:
            self.assertFalse(backend.Backend.node({'index': 2, 'monitor_of_sink': monitor}, 'source')['monitor'])

    def test_choices_accept_profile_maps_and_port_arrays(self):
        profiles = backend.Backend.choices({'on': {'description': 'Duplex', 'available': True},
                                           'off': {'available': False}})
        self.assertEqual(profiles[0], {'name': 'on', 'description': 'Duplex', 'available': True})
        self.assertFalse(profiles[1]['available'])
        self.assertFalse(backend.Backend.choices([{'name': 'unplugged', 'availability': 'not available'}])[0]['available'])

    def test_snapshot_assembles_devices_streams_cards_and_defaults(self):
        service = backend.Backend()
        values = {'sinks': [{'index': 1, 'name': 'speakers'}], 'sources': [{'index': 2, 'name': 'mic'}],
                  'sink-inputs': [], 'source-outputs': [],
                  'cards': [{'index': 3, 'name': 'card', 'active_profile': 'duplex',
                             'profiles': {'duplex': {'available': True}}}]}
        service.run = lambda *args, **kwargs: ({'default_sink_name': 'speakers', 'default_source_name': 'mic'}
                                               if args == ('info',) else values[args[1]])
        result = service.snapshot()
        self.assertTrue(result['sinks'][0]['default'])
        self.assertTrue(result['sources'][0]['default'])
        self.assertEqual(result['cards'][0]['activeProfile'], 'duplex')

    def test_pactl_is_invoked_without_shell_and_with_timeout(self):
        service = backend.Backend()
        with patch.object(backend.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '{}', '')) as run:
            service.run('info', structured=True)
            self.assertEqual(run.call_args.args[0], ['pactl', '--format=json', 'info'])
            self.assertEqual(run.call_args.kwargs['timeout'], 4)
            self.assertNotIn('shell', run.call_args.kwargs)

    def test_missing_pactl_failed_server_and_timeouts_are_reported(self):
        service = backend.Backend()
        for error in [FileNotFoundError(), subprocess.TimeoutExpired('pactl', 4)]:
            with patch.object(backend.subprocess, 'run', side_effect=error), self.assertRaises(ValueError):
                service.run('info')
        with patch.object(backend.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '', 'Disconnected')):
            with self.assertRaisesRegex(ValueError, 'Disconnected'):
                service.run('info')

    def test_protocol_recovers_after_invalid_json_or_request(self):
        requests = '\n'.join(['invalid', '[]', '{"id":3,"action":"snapshot"}']) + '\n'
        process = subprocess.run([sys.executable, '-B', str(SHELL / 'audio/backend.py')], input=requests,
                                 capture_output=True, text=True, timeout=5, env=dict(os.environ, PATH=''))
        self.assertEqual(process.returncode, 0, process.stderr)
        replies = [json.loads(line) for line in process.stdout.splitlines()]
        self.assertEqual(len(replies), 3)
        self.assertTrue(all(not reply['ok'] for reply in replies))
        self.assertIn('pulseaudio-utils', replies[-1]['error'])


class IntegrationTests(unittest.TestCase):
    def test_package_and_current_entry_points_use_native_panel(self):
        packages = yaml.safe_load((ROOT / 'ansible/roles/packages/vars/main.yml').read_text())
        self.assertIn('pulseaudio-utils', packages['dnf_packages'])
        self.assertNotIn('pavucontrol', packages['dnf_packages'])
        self.assertIn('pavucontrol', packages['dnf_absent_packages'])
        for name in ['bar/StatusModule.qml', 'launcher/entries.jsonc']:
            self.assertNotIn('pavucontrol', (SHELL / name).read_text())
        shell = (SHELL / 'shell.qml').read_text()
        self.assertIn('target: "audio"', shell)
        self.assertIn('else if (entry === "audio") audio.toggle()', shell)
        self.assertIn('audio.close()', shell)

    def test_audio_controls_remain_square_and_refresh_does_not_interrupt_editing(self):
        for name in ['Panel.qml', 'Node.qml', 'Choice.qml']:
            self.assertNotRegex((SHELL / 'audio' / name).read_text(), r'radius:\s*[1-9]')
        service = (SHELL / 'audio/Service.qml').read_text()
        self.assertIn('pending >= 0 || interacting', service)
        self.assertIn('if (!interacting && !queued.length) data = reply.data', service)


@unittest.skipUnless(os.environ.get('DOFS_QML_TEST') == '1', 'requires a live Wayland session and qs')
class QmlTests(unittest.TestCase):
    def test_hidden_panel_loads_all_tabs_with_live_audio_without_mutating_it(self):
        with tempfile.TemporaryDirectory(prefix='dofs-audio-test-') as temporary:
            directory = Path(temporary)
            for name in ['audio', 'bar', 'notifications', 'services']:
                (directory / name).symlink_to(SHELL / name, target_is_directory=True)
            (directory / 'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import "audio" as Audio
import "bar"
import "notifications" as Notifications
ShellRoot {
    property var original: null
    Audio.Service { id: service; active: true }
    BarPalette { id: colors }
    Notifications.PanelHeader {
        id: header
        palette: colors
        title: "A long control center title that must not move the close button"
        subtitle: "Devices, applications and routing"
    }
    Audio.Panel {
        id: panel
        service: service
        palette: colors
        opened: false
        targetScreen: Quickshell.screens[0]
        barHeight: 24
        tab: "output"
    }
    IpcHandler {
        target: "test"
        function state(): string { return JSON.stringify({ready: service.ready, loaded: service.loaded, error: service.error,
            sinks: service.data.sinks.length, sources: service.data.sources.length, tab: panel.tab}); }
        function tab(value: string): void { panel.tab = value; }
        function headerMetrics(width: int): string {
            header.width = width;
            var button = header.children.find(child => child.objectName === "controlCenterClose");
            return JSON.stringify({width: header.width, right: button.x + button.width, label: button.text});
        }
        function fixtures(empty: bool): void {
            if (!original) original = service.data;
            service.interacting = true;
            service.data = empty ? {sinks: [], sources: [], playback: [], recording: [], cards: []} : original;
        }
    }
}''')
            process = subprocess.Popen(['qs', '-p', temporary, '--no-color'], stdout=subprocess.PIPE,
                                       stderr=subprocess.STDOUT, env=dict(os.environ, QT_QPA_PLATFORM='wayland'))
            selector = selectors.DefaultSelector()
            selector.register(process.stdout, selectors.EVENT_READ)
            logs = []
            def ipc(*args):
                result = subprocess.run(['qs', '-p', temporary, 'ipc', 'call', 'test', *args],
                                        capture_output=True, text=True, timeout=5)
                self.assertEqual(result.returncode, 0, result.stderr)
                return result.stdout.strip()
            try:
                deadline = time.monotonic() + 15
                while time.monotonic() < deadline:
                    if selector.select(timeout=1):
                        output = os.read(process.stdout.fileno(), 65536).decode()
                        logs.append(output)
                        if 'Configuration Loaded' in output:
                            break
                        if process.poll() is not None:
                            self.fail('QML exited: ' + ''.join(logs))
                else:
                    self.fail('QML did not load: ' + ''.join(logs))
                deadline = time.monotonic() + 15
                while time.monotonic() < deadline:
                    state = json.loads(ipc('state'))
                    if state['loaded'] or state['error']:
                        break
                self.assertTrue(state['loaded'], state)
                self.assertEqual(state['error'], '')
                for width in [280, 500, 800]:
                    metrics = json.loads(ipc('headerMetrics', str(width)))
                    self.assertAlmostEqual(metrics['right'], metrics['width'])
                    self.assertEqual(metrics['label'], 'Close')
                for tab in ['input', 'apps', 'profiles', 'output']:
                    ipc('tab', tab)
                    self.assertEqual(json.loads(ipc('state'))['tab'], tab)
                    ipc('fixtures', 'true')
                    ipc('fixtures', 'false')
            finally:
                process.terminate()
                try:
                    output, _ = process.communicate(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    output, _ = process.communicate()
                logs.append(output.decode())
                selector.close()
            combined = ''.join(logs)
            for marker in ['ReferenceError', 'TypeError', 'Binding loop', 'Cannot assign', 'Unable to assign', 'Failed to load configuration']:
                self.assertNotIn(marker, combined)


if __name__ == '__main__':
    unittest.main()
