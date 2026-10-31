"""Private, atomic, single-writer notification history. JSON-lines over stdio.

The notification daemon is Quickshell; this helper only handles disk I/O.
No notification content is placed on argv or logged to stderr.
"""
import fcntl
import json
import os
from pathlib import Path
import stat
import sys
import tempfile
import time


def clean(data):
    if not isinstance(data, dict) or not isinstance(data.get('entries'), list) or data.get('version', 1) != 1:
        raise ValueError('Invalid notification history')
    entries = []
    for item in data['entries'][:500]:
        if not isinstance(item, dict) or not isinstance(item.get('id'), str):
            raise ValueError('Invalid history entry')
        timestamp = item.get('timestamp')
        if type(timestamp) not in (int, float) or not 0 < timestamp <= time.time() * 1000 + 60000:
            raise ValueError('Invalid history timestamp')
        entry = {key: str(item.get(key, ''))[:limit] for key, limit in
                 (('id', 160), ('appId', 256), ('appName', 256), ('summary', 2048),
                  ('body', 12000), ('appIcon', 1024))}
        # Never load remote content or stale in-process image providers.
        if '://' in entry['appIcon'] and not entry['appIcon'].startswith('file://'):
            entry['appIcon'] = ''
        entry.update(timestamp=timestamp, read=bool(item.get('read')), urgency=item.get('urgency', 1))
        if type(entry['urgency']) is not int or entry['urgency'] not in (0, 1, 2):
            entry['urgency'] = 1
        entries.append(entry)
    return {'version': 1, 'entries': entries, 'dnd': data.get('dnd') is True}


class Store:
    def __init__(self, directory):
        self.directory = Path(directory)
        if self.directory.is_symlink():
            raise ValueError('History directory must not be a symlink')
        self.directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        self.directory.chmod(0o700)
        self.path = self.directory / 'history.json'
        fd = os.open(self.directory / 'history.lock', os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        self.lock = os.fdopen(fd, 'w')
        try:
            fcntl.flock(self.lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            self.lock.close()
            raise

    def load(self):
        try:
            fd = os.open(self.path, os.O_RDONLY | os.O_NOFOLLOW)
        except FileNotFoundError:
            return {'version': 1, 'entries': [], 'dnd': False}, ''
        try:
            with os.fdopen(fd) as stream:
                if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode) or os.fstat(stream.fileno()).st_size > 8_000_000:
                    raise ValueError('Invalid history file')
                os.fchmod(stream.fileno(), 0o600)
                data = clean(json.load(stream))
            return data, ''
        except (ValueError, UnicodeError):
            backup = self.path.with_name(f'history.corrupt-{time.time_ns()}.json')
            self.path.rename(backup)
            return {'version': 1, 'entries': [], 'dnd': False}, 'Damaged history was preserved in ' + backup.name

    def save(self, data):
        data = clean(data)
        fd, name = tempfile.mkstemp(prefix='.history-', dir=self.directory)
        try:
            with os.fdopen(fd, 'w') as stream:
                json.dump(data, stream, ensure_ascii=False)
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(name, self.path)
            directory_fd = os.open(self.directory, os.O_RDONLY | os.O_DIRECTORY)
            try:
                os.fsync(directory_fd)
            finally:
                os.close(directory_fd)
        finally:
            if os.path.exists(name):
                os.unlink(name)


def emit(value):
    print(json.dumps(value, ensure_ascii=False), flush=True)


def main():
    state = Path(os.environ.get('XDG_STATE_HOME') or Path.home() / '.local/state')
    store = Store(state / 'quickshell/dofs/notifications')
    data, warning = store.load()
    emit(dict(data, type='ready', warning=warning))
    for line in sys.stdin:
        try:
            if len(line) > 8_000_000:
                raise ValueError('History snapshot is too large')
            data = json.loads(line)
            store.save(data)
            emit({'type': 'saved'})
        except (OSError, ValueError):
            emit({'type': 'error', 'error': 'Could not save notification history; changes remain in memory'})


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError):
        emit({'type': 'error', 'error': 'History storage unavailable; check permissions or another running shell'})
        sys.exit(1)
