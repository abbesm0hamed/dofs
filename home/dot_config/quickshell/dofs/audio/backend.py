import json
import math
import os
import subprocess
import sys


class Backend:
    kinds = {'sink': 'sinks', 'source': 'sources',
             'sink-input': 'playback', 'source-output': 'recording'}

    def run(self, *arguments, structured=False):
        command = ['pactl'] + (['--format=json'] if structured else []) + list(arguments)
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=4,
                                    env=dict(os.environ, LC_ALL='C'))
        except FileNotFoundError:
            raise ValueError('pactl is missing. Install pulseaudio-utils.') from None
        except subprocess.TimeoutExpired:
            raise ValueError('The audio server did not respond in time.') from None
        if result.returncode:
            raise ValueError(result.stderr.strip()[:240] or 'The audio server rejected this request.')
        return json.loads(result.stdout) if structured else None

    @staticmethod
    def choices(raw):
        if isinstance(raw, dict):
            raw = [dict(value, name=name) for name, value in raw.items()]
        return [{'name': item['name'], 'description': item.get('description') or item['name'],
                 'available': item.get('available', item.get('availability'))
                 not in (False, 'no', 'not available')} for item in (raw or [])]

    @staticmethod
    def node(raw, kind, default=''):
        properties = raw.get('properties') or {}
        channels = list((raw.get('volume') or {}).values())
        volume = round(sum(channel['value'] / 65536 * 100 for channel in channels) / len(channels)) if channels else 0
        stream = kind in ('sink-input', 'source-output')
        application = properties.get('application.name') or properties.get('application.process.binary')
        return {'index': raw['index'], 'name': raw.get('name', ''), 'kind': kind,
                'description': (application or raw.get('name') or 'Audio stream') if stream
                else raw.get('description') or raw.get('name') or 'Audio device',
                'detail': properties.get('media.name', '') if stream else raw.get('state', '').lower(),
                'muted': bool(raw.get('mute')), 'volume': volume,
                'canVolume': bool(channels) and raw.get('volume_writable', True),
                'default': not stream and raw.get('name') == default,
                'target': raw.get('sink' if kind == 'sink-input' else 'source'),
                'ports': Backend.choices(raw.get('ports')), 'activePort': raw.get('active_port', ''),
                'monitor': kind == 'source' and raw.get('monitor_of_sink') not in (None, 4294967295)}

    def snapshot(self):
        info = self.run('info', structured=True)
        data = {'server': info.get('server_name', '')}
        for kind, key in self.kinds.items():
            default = info.get('default_sink_name' if kind == 'sink' else 'default_source_name', '')
            data[key] = [self.node(item, kind, default) for item in
                         self.run('list', kind + 's', structured=True)]
        data['cards'] = [{'index': item['index'], 'name': item['name'],
                          'description': item.get('properties', {}).get('device.description') or item['name'],
                          'profiles': self.choices(item.get('profiles')),
                          'activeProfile': item.get('active_profile', '')}
                         for item in self.run('list', 'cards', structured=True)]
        return data

    def action(self, request):
        action = request.get('action')
        if action == 'snapshot':
            return self.snapshot()
        if action not in ('volume', 'mute', 'default', 'move', 'port', 'profile'):
            raise ValueError('Unknown audio action.')
        data = self.snapshot()
        kind = request.get('kind')
        key = 'cards' if action == 'profile' else self.kinds.get(kind)
        if key is None:
            raise ValueError('Unknown audio device type.')
        entry = next((item for item in data[key] if item['index'] == request.get('index')), None)
        if entry is None:
            raise ValueError('This audio device or stream is no longer available.')
        target = str(entry['index'])
        if action == 'volume':
            value = request.get('value')
            if (not entry['canVolume'] or isinstance(value, bool) or not isinstance(value, (int, float))
                    or not math.isfinite(value) or not 0 <= value <= 100):
                raise ValueError('Volume must be between 0 and 100%.')
            self.run('set-' + kind + '-volume', target, str(round(value)) + '%')
        elif action == 'mute':
            if not isinstance(request.get('value'), bool):
                raise ValueError('Mute must be true or false.')
            self.run('set-' + kind + '-mute', target, '1' if request['value'] else '0')
        elif action == 'default':
            if kind not in ('sink', 'source'):
                raise ValueError('Only devices can be set as the default.')
            self.run('set-default-' + kind, entry['name'])
        elif action == 'move':
            if kind not in ('sink-input', 'source-output'):
                raise ValueError('Only application streams can be moved.')
            devices = data['sinks' if kind == 'sink-input' else 'sources']
            destination = next((item for item in devices if item['index'] == request.get('target')), None)
            if destination is None:
                raise ValueError('The selected audio device is no longer available.')
            self.run('move-' + kind, target, str(destination['index']))
        elif action in ('port', 'profile'):
            if action == 'port' and kind not in ('sink', 'source'):
                raise ValueError('Only devices have ports.')
            options = entry['profiles' if action == 'profile' else 'ports']
            choice = next((item for item in options if item['name'] == request.get('value')), None)
            if not choice or not choice['available']:
                raise ValueError('The selected audio ' + action + ' is unavailable.')
            self.run('set-card-profile' if action == 'profile' else 'set-' + kind + '-port',
                     target, choice['name'])
        return self.snapshot()


def main():
    backend = Backend()
    for line in sys.stdin:
        request = {}
        try:
            request = json.loads(line)
            if not isinstance(request, dict):
                request = {}
                raise ValueError('Expected an audio request object.')
            reply = {'id': request.get('id'), 'ok': True, 'data': backend.action(request)}
        except (ValueError, KeyError, TypeError, OSError) as error:
            reply = {'id': request.get('id'), 'ok': False, 'error': str(error)}
        print(json.dumps(reply), flush=True)


if __name__ == '__main__':
    main()
