import importlib.util
from pathlib import Path
import unittest
import sys
import contextlib
import io
import os
import shutil
import subprocess
import tempfile
from unittest.mock import patch

import yaml
sys.dont_write_bytecode = True

from gi.repository import GLib

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('connectivity', ROOT / 'home/dot_config/quickshell/dofs/connectivity/backend.py')
backend = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(backend)


class ConfigurationTests(unittest.TestCase):
    def test_hotspot_shares_ipv4_without_autoconnecting_or_open_security(self):
        settings = backend.Backend.wireless_settings('My hotspot', 'correct horse', True)
        # Verify the actual D-Bus payload, not only its Python representation.
        unpacked = GLib.Variant('a{sa{sv}}', settings).unpack()
        self.assertEqual(unpacked['802-11-wireless']['mode'], 'ap')
        self.assertEqual(unpacked['ipv4']['method'], 'shared')
        self.assertFalse(unpacked['connection']['autoconnect'])
        self.assertEqual(unpacked['802-11-wireless-security']['key-mgmt'], 'wpa-psk')
        self.assertEqual(unpacked['802-11-wireless-security']['proto'], ['rsn'])

    def test_open_network_does_not_gain_a_password_setting(self):
        settings = backend.Backend.wireless_settings('Guest', '')
        self.assertNotIn('802-11-wireless-security', settings)
        self.assertEqual(settings['ipv4']['method'].unpack(), 'auto')

    def test_ssid_validation_counts_utf8_bytes(self):
        with self.assertRaises(ValueError):
            backend.Backend.wireless_settings('é' * 17, 'password123')
        backend.Backend.wireless_settings('é' * 16, 'password123')

    def test_hotspot_rejects_missing_or_invalid_password(self):
        for password in ['', 'short', 'x' * 64, 'é' * 8]:
            with self.subTest(password_length=len(password)), self.assertRaises(ValueError):
                backend.Backend.wireless_settings('Share', password, True)

    def test_we_can_represent_hex_psk_and_special_characters_without_shell_parsing(self):
        for password in ['a' * 64, 'abc:def"$`123']:
            settings = backend.Backend.wireless_settings('Wi-Fi: "home"', password)
            self.assertEqual(settings['802-11-wireless-security']['psk'].unpack(), password)


class ActionTests(unittest.TestCase):
    def make_backend(self):
        service = backend.Backend.__new__(backend.Backend)
        service.calls = []
        service.snapshot = lambda: {'snapshot': True}
        service.sharing_device = lambda path, preserve: (path, {'Interface': 'wlan0'}, None)
        def call(*args, **kwargs):
            service.calls.append((args, kwargs))
            return ()
        service.call = call
        return service

    def test_stop_hotspot_refuses_to_disconnect_an_ordinary_wifi_connection(self):
        service = self.make_backend()
        service.props = lambda *args: {'Connection': '/profile'}
        service.call = lambda *args, **kwargs: ({'802-11-wireless': {'mode': 'infrastructure'}},)
        with self.assertRaisesRegex(ValueError, 'not a hotspot'):
            service.action({'action': 'stop-hotspot', 'active': '/active'})

    def test_hotspot_reuses_its_profile_and_retains_uuid(self):
        service = self.make_backend()
        service.props = lambda path, interface: {'Interface': 'wlan0'} if interface.endswith('.Device') else {'WirelessCapabilities': 0x40}
        old = {'connection': {'id': 'dofs-hotspot', 'interface-name': 'wlan0', 'uuid': 'existing'},
               '802-11-wireless': {'mode': 'ap'}}
        def call(*args, **kwargs):
            service.calls.append((args, kwargs))
            if args[2] == 'ListConnections':
                return (['/profile'],)
            if args[2] == 'GetSettings':
                return (old,)
            return ()
        service.call = call
        service.action({'action': 'start-hotspot', 'device': '/wifi', 'ssid': 'Share', 'password': 'password123'})
        methods = [args[2] for args, kwargs in service.calls]
        self.assertIn('Update', methods)
        self.assertIn('ActivateConnection', methods)
        self.assertNotIn('AddAndActivateConnection', methods)
        update = next(args for args, kwargs in service.calls if args[2] == 'Update')
        self.assertEqual(update[4][0]['connection']['uuid'].unpack(), 'existing')

    def test_concurrent_hotspot_activates_virtual_interface_on_upstream_channel(self):
        service = self.make_backend()
        service.props = lambda path, interface: {'Interface': 'wlan0'} if interface.endswith('.Device') else {'WirelessCapabilities': 0x40}
        preserve_values = []
        def sharing(path, preserve):
            preserve_values.append(preserve)
            return '/virtual', {'Interface': 'dofs-ap0'}, ('a', 36)
        service.sharing_device = sharing
        def call(*args, **kwargs):
            service.calls.append((args, kwargs))
            return ([],) if args[2] == 'ListConnections' else ()
        service.call = call
        service.action({'action': 'start-hotspot', 'device': '/wifi', 'ssid': 'Share',
                        'password': 'password123', 'keepConnection': True})
        self.assertEqual(preserve_values, [True])
        activate = service.calls[-1][0]
        settings, device, ap = activate[4]
        self.assertEqual(device, '/virtual')
        self.assertEqual(settings['802-11-wireless']['band'].unpack(), 'a')
        self.assertEqual(settings['802-11-wireless']['channel'].unpack(), 36)
        self.assertEqual(settings['connection']['interface-name'].unpack(), 'dofs-ap0')

    def test_saved_network_activates_without_requesting_password_or_creating_profile(self):
        service = self.make_backend()
        service.props = lambda path, interface: {'Ssid': list(b'Home')} if path == '/ap' else {'AvailableConnections': ['/saved']}
        def call(*args, **kwargs):
            service.calls.append((args, kwargs))
            if args[2] == 'GetSettings':
                return ({'802-11-wireless': {'ssid': list(b'Home')}},)
            return ()
        service.call = call
        service.action({'action': 'connect-wifi', 'ap': '/ap', 'device': '/wifi', 'password': ''})
        self.assertEqual(service.calls[-1][0][2], 'ActivateConnection')

    def test_enterprise_security_requires_advanced_settings(self):
        service = self.make_backend()
        service.props = lambda path, interface: {'Ssid': list(b'Office'), 'Flags': 1, 'RsnFlags': 0x200} if path == '/ap' else {'AvailableConnections': []}
        with self.assertRaisesRegex(ValueError, 'advanced'):
            service.action({'action': 'connect-wifi', 'ap': '/ap', 'device': '/wifi', 'password': 'password123'})
        self.assertFalse(service.calls)

    def test_pairing_rejection_does_not_silently_authorize_device(self):
        service = self.make_backend()
        class Invocation:
            error = None
            def return_dbus_error(self, name, text):
                self.error = name
        invocation = Invocation()
        service.pending = {'token': (invocation, 'RequestConfirmation')}
        service.respond({'token': 'token', 'accept': False})
        self.assertEqual(invocation.error, 'org.bluez.Error.Rejected')
        self.assertFalse(service.pending)


class ReviewRegressionTests(unittest.TestCase):
    make_backend = ActionTests.make_backend

    def test_saved_password_update_preserves_static_ip_and_profile_uuid(self):
        service = self.make_backend()
        service.props = lambda path, interface: {'Ssid': list(b'Home')} if path == '/ap' else {'AvailableConnections': ['/saved']}
        settings = {'connection': {'uuid': GLib.Variant('s', 'existing')},
                    'ipv4': {'method': GLib.Variant('s', 'manual')},
                    '802-11-wireless-security': {'key-mgmt': GLib.Variant('s', 'wpa-psk')}}
        service.settings_variants = lambda profile: settings
        def call(*args, **kwargs):
            service.calls.append((args, kwargs))
            if args[2] == 'GetSettings':
                return ({'802-11-wireless': {'ssid': list(b'Home')},
                         '802-11-wireless-security': {'key-mgmt': 'wpa-psk'}},)
            return ()
        service.call = call
        service.action({'action': 'connect-wifi', 'ap': '/ap', 'device': '/wifi', 'password': 'newpassword'})
        methods = [args[2] for args, _ in service.calls]
        self.assertEqual(methods, ['GetSettings', 'Update', 'ActivateConnection'])
        payload = service.calls[1][0][4][0]
        self.assertEqual(payload['connection']['uuid'].unpack(), 'existing')
        self.assertEqual(payload['ipv4']['method'].unpack(), 'manual')
        self.assertEqual(payload['802-11-wireless-security']['psk'].unpack(), 'newpassword')
        self.assertEqual(payload['802-11-wireless-security']['psk-flags'].unpack(), 0)

    def test_saved_password_missing_from_removed_applet_prompts_in_panel(self):
        service = self.make_backend()
        service.props = lambda path, interface: {'Ssid': list(b'Home')} if path == '/ap' else {'AvailableConnections': ['/saved']}
        def call(*args, **kwargs):
            service.calls.append((args, kwargs))
            if args[2] == 'GetSettings':
                return ({'802-11-wireless': {'ssid': list(b'Home')},
                         '802-11-wireless-security': {'key-mgmt': 'wpa-psk'}},)
            return ({},)
        service.call = call
        with self.assertRaisesRegex(ValueError, 'Enter it in this panel'):
            service.action({'action': 'connect-wifi', 'ap': '/ap', 'device': '/wifi', 'password': ''})
        self.assertNotIn('ActivateConnection', [args[2] for args, _ in service.calls])

    def test_typed_settings_preserve_complex_variant_types(self):
        original = {'connection': {'uuid': GLib.Variant('s', 'keep')},
                    'ipv4': {'method': GLib.Variant('s', 'manual'),
                             'address-data': GLib.Variant('aa{sv}', [{'address': GLib.Variant('s', '192.0.2.4'), 'prefix': GLib.Variant('u', 24)}])}}
        encoded = GLib.Variant('a{sa{sv}}', original)
        decoded = backend.Backend.variant_settings(encoded)
        self.assertEqual(GLib.Variant('a{sa{sv}}', decoded), encoded)
        self.assertEqual(decoded['ipv4']['address-data'].get_type_string(), 'aa{sv}')

    def test_pairing_prompt_identifies_device_and_rejects_non_bluez_senders(self):
        service = self.make_backend()
        service.agent_owner = ':1.bluez'
        service.pending = {}
        service.props = lambda *args: {'Alias': 'My keyboard'}
        class Invocation:
            error = None
            def return_dbus_error(self, name, text):
                self.error = name
        attacker = Invocation()
        args = GLib.Variant('(ou)', ('/device', 123456))
        service.agent_call(None, ':1.other', '', '', 'RequestConfirmation', args, attacker)
        self.assertEqual(attacker.error, 'org.bluez.Error.Rejected')
        self.assertFalse(service.pending)
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            service.agent_call(None, ':1.bluez', '', '', 'RequestConfirmation', args, Invocation())
        self.assertIn('My keyboard', output.getvalue())
        self.assertEqual(len(service.pending), 1)

    def test_sharing_never_reuses_the_uplink_or_another_active_interface(self):
        service = self.make_backend()
        def props(path, interface):
            if path == '/ap':
                return {'Frequency': 5180}
            if interface.endswith('.Wireless'):
                return {'ActiveAccessPoint': '/ap'}
            return {'Interface': 'dofs-ap0', 'State': 100,
                    'ActiveConnection': '/' if path == '/spare' else '/uplink'}
        service.props = props
        def call(*args, **kwargs):
            service.calls.append((args, kwargs))
            return ('/spare' if args[4][0] == 'dofs-ap2' else '/occupied',)
        service.call = call
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            net, phy = base / 'net', base / 'phy0'
            net.mkdir(); phy.mkdir()
            for name in ('dofs-ap0', 'dofs-ap1', 'dofs-ap2'):
                (net / name).mkdir()
                (net / name / 'phy80211').symlink_to(phy)
            def path(value):
                return net if value == '/sys/class/net' else Path(value)
            iw = subprocess.CompletedProcess([], 0, stdout='valid interface combinations: * #{ managed } <= 2, #{ AP } <= 1')
            with patch.object(backend, 'Path', side_effect=path), patch.object(backend.subprocess, 'run', return_value=iw) as run:
                result = backend.Backend.sharing_device(service, '/source', True)
            self.assertEqual(result[0], '/spare')
            self.assertEqual(run.call_count, 1)  # Only read iw capabilities; no interface mutation.
            self.assertEqual(run.call_args.args[0][:2], ['/usr/bin/iw', 'phy'])
            queried = [args[4][0] for args, _ in service.calls]
            self.assertNotIn('dofs-ap0', queried)


class PackagePolicyTests(unittest.TestCase):
    def test_old_desktop_uis_are_not_installed_and_core_backends_remain(self):
        values = yaml.safe_load((ROOT / 'ansible/roles/packages/vars/main.yml').read_text())
        removed = set(values['dnf_absent_packages'])
        installed = set(values['dnf_packages'])
        self.assertFalse({'blueman', 'network-manager-applet', 'crystal-dock'} & installed)
        self.assertFalse(installed & removed)
        self.assertTrue({'NetworkManager', 'bluez', 'polkit', 'iw', 'nm-connection-editor'} <= installed)


@unittest.skipUnless(os.environ.get('DOFS_QML_TEST') == '1', 'requires qs')
class LiveConnectivityTests(unittest.TestCase):
    def test_hidden_password_is_not_restored_by_late_backend_reply(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            shutil.copy2(ROOT / 'home/dot_config/quickshell/dofs/connectivity/Service.qml', directory / 'Service.qml')
            # An inert bridge exercises QML lifecycle without touching the real radios.
            (directory / 'backend.py').write_text('import sys\nfor line in sys.stdin: pass\n')
            (directory / 'shell.qml').write_text('''import QtQuick
import Quickshell
ShellRoot {
 Service { id: service }
 Timer { interval: 100; running: true; onTriggered: {
  service.active = true;
  service.allowPasswordReply = true;
  var reply = JSON.stringify({ok:true, data:{hotspotPassword:"test-password"}});
  service.receive(reply);
  if (service.hotspotPassword !== "test-password") throw new Error("visible password missing");
  service.hideHotspotPassword();
  service.receive(reply);
  if (service.hotspotPassword) throw new Error("hidden password restored");
  service.active = false;
  service.allowPasswordReply = true;
  service.receive(reply);
  if (service.hotspotPassword) throw new Error("closed panel received a password");
  console.warn("PASSWORD_LIFECYCLE_PASS");
  Qt.quit();
 } }
}
''')
            result = subprocess.run(['qs', '-p', str(directory)], capture_output=True, text=True, timeout=6)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('PASSWORD_LIFECYCLE_PASS', result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
