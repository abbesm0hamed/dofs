"""NetworkManager/BlueZ bridge. JSON on stdin/stdout; secrets never enter argv.

Only read status automatically. Radio, discovery, pairing, and connection changes
require explicit UI actions. Runs while the connectivity panel is open.
"""
import concurrent.futures
import json
from pathlib import Path
import subprocess
import sys
import threading
import time
import re
import uuid

from gi.repository import Gio, GLib

NM = 'org.freedesktop.NetworkManager'
NP = '/org/freedesktop/NetworkManager'
BLUEZ = 'org.bluez'
lock = threading.Lock()


def emit(value):
    with lock:
        print(json.dumps(value), flush=True)


class Backend:
    def __init__(self):
        self.bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        self.pending = {}
        self.scanning = set()
        self.agent_registered = False
        self.agent_owner = None

    def call(self, path, interface, method, signature=None, args=(), service=NM, timeout=15000):
        result = self.bus.call_sync(service, path, interface, method,
                                    GLib.Variant(signature, args) if signature else None,
                                    None, Gio.DBusCallFlags.NONE, timeout, None)
        return result.unpack() if result else ()

    def props(self, path, interface, service=NM):
        return self.call(path, 'org.freedesktop.DBus.Properties', 'GetAll', '(s)', (interface,), service)[0]

    def set_property(self, path, interface, name, value, service=NM):
        self.call(path, 'org.freedesktop.DBus.Properties', 'Set', '(ssv)', (interface, name, value), service)

    def settings_variants(self, path):
        """Preserve types and user settings when updating one saved secret."""
        reply = self.bus.call_sync(NM, path, NM + '.Settings.Connection', 'GetSettings',
                                   None, None, Gio.DBusCallFlags.NONE, 15000, None)
        return self.variant_settings(reply.get_child_value(0))

    @staticmethod
    def variant_settings(value):
        sections = {}
        for i in range(value.n_children()):
            entry = value.get_child_value(i)
            name = entry.get_child_value(0).get_string()
            properties = entry.get_child_value(1)
            sections[name] = {}
            for j in range(properties.n_children()):
                item = properties.get_child_value(j)
                sections[name][item.get_child_value(0).get_string()] = item.get_child_value(1).get_variant()
        return sections

    def wifi_devices(self):
        paths = self.call(NP, NM, 'GetDevices')[0]
        return [(p, self.props(p, NM + '.Device')) for p in paths
                if self.props(p, NM + '.Device').get('DeviceType') == 2]

    @staticmethod
    def ssid(value):
        return bytes(value).decode('utf-8', errors='replace')

    def network_snapshot(self):
        manager = self.props(NP, NM)
        result = {'enabled': manager.get('WirelessEnabled', False), 'devices': [], 'networks': [], 'hotspots': []}
        for path, device in self.wifi_devices():
            wifi = self.props(path, NM + '.Device.Wireless')
            interface = device['Interface']
            active_ap = wifi.get('ActiveAccessPoint', '/')
            states = {10: 'Unmanaged', 20: 'Unavailable', 30: 'Disconnected', 40: 'Preparing',
                      50: 'Connecting', 60: 'Credentials required', 70: 'Getting an address',
                      80: 'Checking connectivity', 90: 'Starting', 100: 'Connected',
                      110: 'Disconnecting', 120: 'Connection failed'}
            info = {'path': path, 'interface': interface, 'state': device['State'],
                    'status': states.get(device['State'], 'Unknown'),
                    'canHotspot': bool(wifi.get('WirelessCapabilities', 0) & 0x40), 'address': '', 'connection': ''}
            ip4 = device.get('Ip4Config', '/')
            if ip4 != '/':
                addresses = self.props(ip4, NM + '.IP4Config').get('AddressData', [])
                info['address'] = ', '.join(f"{a['address']}/{a['prefix']}" for a in addresses)
            active = device.get('ActiveConnection', '/')
            if active != '/':
                connection = self.props(active, NM + '.Connection.Active')
                info['connection'] = connection.get('Id', '')
                profile = connection.get('Connection', '/')
                if profile != '/':
                    settings = self.call(profile, NM + '.Settings.Connection', 'GetSettings')[0]
                    wireless = settings.get('802-11-wireless', {})
                    if wireless.get('mode') == 'ap':
                        result['hotspots'].append({'interface': interface, 'active': active, 'profile': profile,
                            'ssid': self.ssid(wireless.get('ssid', [])), 'address': info['address']})
            result['devices'].append(info)
            strongest = {}
            for ap in self.call(path, NM + '.Device.Wireless', 'GetAllAccessPoints')[0]:
                props = self.props(ap, NM + '.AccessPoint')
                name = self.ssid(props.get('Ssid', []))
                if not name:
                    continue
                flags = props.get('WpaFlags', 0) | props.get('RsnFlags', 0)
                # PSK is supported; SAE-only/enterprise/WEP require advanced settings.
                security = 'WPA personal' if flags & 0x100 else 'Open' if not props.get('Flags', 0) & 1 else 'Advanced security'
                item = {'path': ap, 'device': path, 'ssid': name, 'signal': props.get('Strength', 0),
                        'security': security, 'active': ap == active_ap, 'interface': interface}
                key = (name, security)
                old = strongest.get(key)
                if not old or (item['active'], item['signal']) > (old['active'], old['signal']):
                    strongest[key] = item
            result['networks'].extend(sorted(strongest.values(), key=lambda a: (not a['active'], -a['signal'])))
        return result

    def bluetooth_snapshot(self):
        objects = self.call('/', 'org.freedesktop.DBus.ObjectManager', 'GetManagedObjects', service=BLUEZ)[0]
        adapters, devices = [], []
        for path, interfaces in objects.items():
            if BLUEZ + '.Adapter1' in interfaces:
                p = interfaces[BLUEZ + '.Adapter1']
                adapters.append({'path': path, 'name': p.get('Alias', 'Bluetooth'), 'enabled': p.get('Powered', False),
                                 'discovering': path in self.scanning})
            if BLUEZ + '.Device1' in interfaces:
                p = interfaces[BLUEZ + '.Device1']
                devices.append({'path': path, 'name': p.get('Alias', p.get('Address', 'Device')),
                                'address': p.get('Address', ''), 'paired': p.get('Paired', False),
                                'connected': p.get('Connected', False), 'adapter': p.get('Adapter', ''),
                                'battery': interfaces.get(BLUEZ + '.Battery1', {}).get('Percentage')})
        radios = []
        for radio in Path('/sys/class/rfkill').glob('rfkill*'):
            try:
                if (radio / 'type').read_text().strip() == 'bluetooth':
                    radios.append({'soft': (radio / 'soft').read_text().strip() == '1',
                                   'hard': (radio / 'hard').read_text().strip() == '1'})
            except OSError:
                continue
        return {'radios': radios, 'adapters': adapters, 'devices': sorted(devices, key=lambda d: (not d['connected'], not d['paired'], d['name']))}

    def snapshot(self):
        result = {}
        for key, function in [('network', self.network_snapshot), ('bluetooth', self.bluetooth_snapshot)]:
            try:
                result[key] = function()
            except GLib.Error as error:
                result[key] = {'error': error.message}
        return result

    def register_agent(self):
        if self.agent_registered:
            return
        methods = '''<node><interface name="org.bluez.Agent1">
        <method name="Release"/><method name="Cancel"/>
        <method name="RequestPinCode"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
        <method name="RequestPasskey"><arg type="o" direction="in"/><arg type="u" direction="out"/></method>
        <method name="DisplayPinCode"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
        <method name="DisplayPasskey"><arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/></method>
        <method name="RequestConfirmation"><arg type="o" direction="in"/><arg type="u" direction="in"/></method>
        <method name="RequestAuthorization"><arg type="o" direction="in"/></method>
        <method name="AuthorizeService"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
        </interface></node>'''
        self.agent_owner = self.call('/org/freedesktop/DBus', 'org.freedesktop.DBus', 'GetNameOwner', '(s)',
                                     (BLUEZ,), 'org.freedesktop.DBus')[0]
        self.bus.register_object('/dofs/bluetooth_agent', Gio.DBusNodeInfo.new_for_xml(methods).interfaces[0], self.agent_call, None, None)
        self.call('/org/bluez', BLUEZ + '.AgentManager1', 'RegisterAgent', '(os)',
                  ('/dofs/bluetooth_agent', 'KeyboardDisplay'), BLUEZ)
        self.agent_registered = True

    def agent_call(self, bus, sender, path, interface, method, parameters, invocation):
        if sender != self.agent_owner:
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'Only BlueZ may request pairing authorization')
            return
        args = parameters.unpack()
        name = 'Bluetooth device'
        if args:
            try:
                props = self.props(args[0], BLUEZ + '.Device1', BLUEZ)
                name = props.get('Alias', props.get('Address', name))
            except GLib.Error:
                pass
        if method in ('Cancel', 'Release'):
            for pending, _ in self.pending.values():
                pending.return_dbus_error('org.bluez.Error.Canceled', 'Pairing canceled')
            self.pending.clear()
            emit({'pairing': None})
            invocation.return_value(None)
        elif method.startswith('Display'):
            emit({'pairing': {'id': '', 'method': method, 'device': args[0], 'name': name, 'code': str(args[1]).zfill(6) if method == 'DisplayPasskey' else args[1]}})
            invocation.return_value(None)
        else:
            key = str(uuid.uuid4())
            self.pending[key] = (invocation, method)
            emit({'pairing': {'id': key, 'method': method, 'device': args[0], 'name': name,
                              'code': str(args[1]).zfill(6) if method == 'RequestConfirmation' else ''}})

    def respond(self, request):
        pending = self.pending.pop(request.get('token', ''), None)
        if not pending:
            return
        invocation, method = pending
        if not request.get('accept'):
            invocation.return_dbus_error('org.bluez.Error.Rejected', 'Pairing rejected')
        elif method == 'RequestPinCode':
            invocation.return_value(GLib.Variant('(s)', (request.get('value', ''),)))
        elif method == 'RequestPasskey':
            value = request.get('value', '')
            if not value.isdigit() or len(value) > 6:
                invocation.return_dbus_error('org.bluez.Error.Rejected', 'Expected a six digit passkey')
            else:
                invocation.return_value(GLib.Variant('(u)', (int(value),)))
        else:
            invocation.return_value(None)
        emit({'pairing': None})

    @staticmethod
    def wireless_settings(ssid, password, hotspot=False):
        raw = ssid.encode('utf-8')
        if not 1 <= len(raw) <= 32:
            raise ValueError('Wi-Fi name must contain 1–32 bytes')
        if password and not (8 <= len(password) <= 63 and password.isascii() or
                             len(password) == 64 and all(c in '0123456789abcdefABCDEF' for c in password)):
            raise ValueError('Wi-Fi password must be 8–63 ASCII characters or 64 hexadecimal digits')
        if hotspot and not password:
            raise ValueError('A password is required for your hotspot')
        settings = {
            'connection': {'id': GLib.Variant('s', 'dofs-hotspot' if hotspot else ssid),
                           'uuid': GLib.Variant('s', str(uuid.uuid4())),
                           'type': GLib.Variant('s', '802-11-wireless'),
                           'autoconnect': GLib.Variant('b', not hotspot)},
            '802-11-wireless': {'ssid': GLib.Variant('ay', raw),
                               'mode': GLib.Variant('s', 'ap' if hotspot else 'infrastructure')},
            'ipv4': {'method': GLib.Variant('s', 'shared' if hotspot else 'auto')},
            'ipv6': {'method': GLib.Variant('s', 'disabled' if hotspot else 'auto')},
        }
        if password:
            settings['802-11-wireless-security'] = {'key-mgmt': GLib.Variant('s', 'wpa-psk'),
                                                    'psk': GLib.Variant('s', password)}
            if hotspot:
                settings['802-11-wireless-security']['proto'] = GLib.Variant('as', ['rsn'])
        return settings

    def sharing_device(self, path, preserve):
        """Prepare a second interface only on an explicit hotspot start request."""
        device = self.props(path, NM + '.Device')
        wifi = self.props(path, NM + '.Device.Wireless')
        if not preserve or device['State'] != 100 or wifi.get('ActiveAccessPoint', '/') == '/':
            return path, device, None
        interface = device['Interface']
        phy = (Path('/sys/class/net') / interface / 'phy80211').resolve()
        if not phy.exists():
            raise ValueError('Cannot identify the Wi-Fi hardware for simultaneous sharing')
        details = subprocess.run(['/usr/bin/iw', 'phy', phy.name, 'info'],
                                 capture_output=True, text=True, check=True, timeout=10).stdout
        combos = details.split('valid interface combinations:', 1)[-1].split('HT Capability', 1)[0]
        if not any('managed' in group and re.search(r'\bAP\b', group) for group in combos.split('*')):
            raise ValueError('This adapter cannot receive and share Wi-Fi at the same time. Use Ethernet, USB tethering, or another adapter.')
        ap = self.props(wifi['ActiveAccessPoint'], NM + '.AccessPoint')
        frequency = ap.get('Frequency', 0)
        if frequency == 2484:
            band, channel = 'bg', 14
        elif 2412 <= frequency <= 2472:
            band, channel = 'bg', (frequency - 2407) // 5
        elif 5000 < frequency < 5925:
            band, channel = 'a', (frequency - 5000) // 5
        else:
            raise ValueError('Simultaneous sharing is supported here on 2.4 GHz and 5 GHz Wi-Fi. Use another internet source for this band.')
        name = None
        for index in range(10):
            candidate = f'dofs-ap{index}'
            node = Path('/sys/class/net') / candidate
            if not node.exists():
                result = subprocess.run(['pkexec', '/usr/bin/iw', 'dev', interface, 'interface', 'add', candidate, 'type', '__ap'],
                                        capture_output=True, text=True, timeout=65)
                if result.returncode:
                    raise ValueError('Could not prepare Wi-Fi sharing. ' + (result.stderr.strip() or 'Administrator authentication was canceled.'))
                name = candidate
                break
            if candidate != interface and (node / 'phy80211').resolve() == phy:
                existing = self.call(NP, NM, 'GetDeviceByIpIface', '(s)', (candidate,))[0]
                info = self.props(existing, NM + '.Device')
                if info.get('ActiveConnection', '/') == '/':
                    name = candidate
                    break
        if not name:
            raise ValueError('No free Wi-Fi sharing interface is available')
        for _ in range(50):
            try:
                virtual = self.call(NP, NM, 'GetDeviceByIpIface', '(s)', (name,))[0]
                info = self.props(virtual, NM + '.Device')
                return virtual, info, (band, channel)
            except GLib.Error:
                time.sleep(0.1)
        raise ValueError('NetworkManager did not detect the sharing adapter. Retry after a few seconds.')

    def action(self, r):
        action = r['action']
        if action == 'snapshot':
            return self.snapshot()
        if action == 'wifi-power':
            self.set_property(NP, NM, 'WirelessEnabled', GLib.Variant('b', bool(r['enabled'])))
        elif action == 'scan-wifi':
            for path, _ in self.wifi_devices():
                try:
                    self.call(path, NM + '.Device.Wireless', 'RequestScan', '(a{sv})', ({},))
                except GLib.Error as error:
                    if 'Scanning not allowed' not in error.message and 'already scanning' not in error.message.lower():
                        raise
        elif action == 'connect-wifi':
            ap = self.props(r['ap'], NM + '.AccessPoint')
            ssid = self.ssid(ap['Ssid'])
            # Use a matching saved profile first, preserving enterprise credentials.
            available = self.props(r['device'], NM + '.Device').get('AvailableConnections', [])
            for profile in available:
                saved = self.call(profile, NM + '.Settings.Connection', 'GetSettings')[0]
                wireless = saved.get('802-11-wireless', {})
                if wireless.get('mode', 'infrastructure') != 'infrastructure' or bytes(wireless.get('ssid', [])) != bytes(ap['Ssid']):
                    continue
                password = r.get('password', '')
                security = saved.get('802-11-wireless-security', {})
                if password:
                    # Only update PSK profiles here; preserve enterprise and SAE settings.
                    if security.get('key-mgmt') != 'wpa-psk':
                        continue
                    self.wireless_settings(ssid, password)  # Validate before changing a profile.
                    settings = self.settings_variants(profile)
                    settings['802-11-wireless-security']['psk'] = GLib.Variant('s', password)
                    settings['802-11-wireless-security']['psk-flags'] = GLib.Variant('u', 0)
                    self.call(profile, NM + '.Settings.Connection', 'Update', '(a{sa{sv}})', (settings,))
                elif security.get('key-mgmt') == 'wpa-psk':
                    try:
                        secrets = self.call(profile, NM + '.Settings.Connection', 'GetSecrets', '(s)', ('802-11-wireless-security',))[0]
                    except GLib.Error:
                        secrets = {}
                    if not secrets.get('802-11-wireless-security', {}).get('psk'):
                        raise ValueError('The saved Wi-Fi password is unavailable. Enter it in this panel to reconnect.')
                self.call(NP, NM, 'ActivateConnection', '(ooo)', (profile, r['device'], r['ap']))
                return self.snapshot()
            flags = ap.get('WpaFlags', 0) | ap.get('RsnFlags', 0)
            if flags & 0x100:
                if not r.get('password'):
                    raise ValueError('Enter the Wi-Fi password, or leave it blank to use a saved connection')
            elif ap.get('Flags', 0) & 1:
                raise ValueError('This security type needs advanced connection settings')
            settings = self.wireless_settings(ssid, r.get('password', ''))
            self.call(NP, NM, 'AddAndActivateConnection', '(a{sa{sv}}oo)', (settings, r['device'], r['ap']))
        elif action == 'start-hotspot':
            device = self.props(r['device'], NM + '.Device')
            wifi = self.props(r['device'], NM + '.Device.Wireless')
            if not wifi.get('WirelessCapabilities', 0) & 0x40:
                raise ValueError('This Wi-Fi adapter does not support hotspot mode')
            # Validate before prompting or creating an interface.
            settings = self.wireless_settings(r['ssid'], r['password'], True)
            path, device, channel = self.sharing_device(r['device'], r.get('keepConnection', False))
            if channel:
                settings['802-11-wireless']['band'] = GLib.Variant('s', channel[0])
                settings['802-11-wireless']['channel'] = GLib.Variant('u', channel[1])
            settings['connection']['interface-name'] = GLib.Variant('s', device['Interface'])
            profiles = self.call(NP + '/Settings', NM + '.Settings', 'ListConnections')[0]
            for profile in profiles:
                old = self.call(profile, NM + '.Settings.Connection', 'GetSettings')[0]
                connection = old.get('connection', {})
                if (connection.get('id') == 'dofs-hotspot' and
                    connection.get('interface-name') == device['Interface'] and
                    old.get('802-11-wireless', {}).get('mode') == 'ap'):
                    settings['connection']['uuid'] = GLib.Variant('s', connection['uuid'])
                    self.call(profile, NM + '.Settings.Connection', 'Update', '(a{sa{sv}})', (settings,))
                    self.call(NP, NM, 'ActivateConnection', '(ooo)', (profile, path, '/'))
                    return self.snapshot()
            self.call(NP, NM, 'AddAndActivateConnection', '(a{sa{sv}}oo)', (settings, path, '/'))
        elif action == 'stop-hotspot':
            # Verify the selected active connection is actually an AP before stopping.
            props = self.props(r['active'], NM + '.Connection.Active')
            settings = self.call(props['Connection'], NM + '.Settings.Connection', 'GetSettings')[0]
            if settings.get('802-11-wireless', {}).get('mode') != 'ap':
                raise ValueError('Selected connection is not a hotspot')
            self.call(NP, NM, 'DeactivateConnection', '(o)', (r['active'],))
        elif action == 'hotspot-password':
            settings = self.call(r['profile'], NM + '.Settings.Connection', 'GetSettings')[0]
            if settings.get('802-11-wireless', {}).get('mode') != 'ap':
                raise ValueError('Selected connection is not a hotspot')
            secrets = self.call(r['profile'], NM + '.Settings.Connection', 'GetSecrets', '(s)', ('802-11-wireless-security',))[0]
            return {'hotspotPassword': secrets.get('802-11-wireless-security', {}).get('psk', '')}
        elif action == 'unblock-bluetooth':
            result = subprocess.run(['rfkill', 'unblock', 'bluetooth'], capture_output=True, text=True, timeout=10)
            if result.returncode:
                raise ValueError(result.stderr.strip() or 'Could not unblock the Bluetooth radio')
        elif action == 'forget-bluetooth':
            device = self.props(r['device'], BLUEZ + '.Device1', BLUEZ)
            self.call(device['Adapter'], BLUEZ + '.Adapter1', 'RemoveDevice', '(o)', (r['device'],), BLUEZ)
        elif action == 'bluetooth-power':
            self.set_property(r['adapter'], BLUEZ + '.Adapter1', 'Powered', GLib.Variant('b', bool(r['enabled'])), BLUEZ)
        elif action == 'scan-bluetooth':
            self.call(r['adapter'], BLUEZ + '.Adapter1', 'StartDiscovery', service=BLUEZ)
            self.scanning.add(r['adapter'])
        elif action == 'stop-bluetooth-scan':
            if r['adapter'] in self.scanning:
                self.call(r['adapter'], BLUEZ + '.Adapter1', 'StopDiscovery', service=BLUEZ)
                self.scanning.discard(r['adapter'])
        elif action in ('pair-bluetooth', 'connect-bluetooth', 'disconnect-bluetooth', 'cancel-pairing'):
            method = {'pair-bluetooth': 'Pair', 'connect-bluetooth': 'Connect',
                      'disconnect-bluetooth': 'Disconnect', 'cancel-pairing': 'CancelPairing'}[action]
            self.call(r['device'], BLUEZ + '.Device1', method, service=BLUEZ, timeout=90000)
            if action == 'pair-bluetooth':
                emit({'pairing': None})
        else:
            raise ValueError('Unknown connectivity action')
        return self.snapshot()


def main():
    backend = Backend()
    loop = GLib.MainLoop()
    pool = concurrent.futures.ThreadPoolExecutor(max_workers=3)

    def run(request):
        try:
            emit({'id': request.get('id'), 'ok': True, 'data': backend.action(request)})
        except Exception as error:
            if request.get('action') == 'pair-bluetooth':
                emit({'pairing': None})
            # Do not include request data: it can contain a network password.
            emit({'id': request.get('id'), 'ok': False, 'error': str(error)})

    def dispatch(request):
        if request.get('action') == 'pairing-response':
            backend.respond(request)
        else:
            if request.get('action') in ('pair-bluetooth', 'connect-bluetooth'):
                try:
                    backend.register_agent()
                except Exception as error:
                    emit({'id': request.get('id'), 'ok': False, 'error': str(error)})
                    return False
            pool.submit(run, request)
        return False

    def reader():
        for line in sys.stdin:
            try:
                request = json.loads(line)
                if not isinstance(request, dict):
                    raise ValueError('Expected an object')
                GLib.idle_add(dispatch, request)
            except ValueError:
                emit({'ok': False, 'error': 'Invalid connectivity request'})
        GLib.idle_add(loop.quit)

    threading.Thread(target=reader, daemon=True).start()
    try:
        loop.run()
    finally:
        for path in backend.scanning:
            try:
                backend.call(path, BLUEZ + '.Adapter1', 'StopDiscovery', service=BLUEZ)
            except GLib.Error:
                pass
        pool.shutdown(wait=False, cancel_futures=True)


if __name__ == '__main__':
    main()
