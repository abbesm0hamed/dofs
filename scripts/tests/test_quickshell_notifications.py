import importlib.util
import json
import os
from pathlib import Path
import re
import selectors
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[2]
SHELL = ROOT / 'home/dot_config/quickshell/dofs'
NOTIFICATIONS = SHELL / 'notifications'
spec = importlib.util.spec_from_file_location('notification_store', NOTIFICATIONS / 'history-store.py')
store_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(store_module)


class HistoryTests(unittest.TestCase):
    def entry(self, **extra):
        return dict(id='test', timestamp=time.time() * 1000, appName='Chat', summary='Hello', body='Private text', **extra)

    def test_atomic_private_storage_and_restart(self):
        with tempfile.TemporaryDirectory() as directory:
            store = store_module.Store(Path(directory) / 'notifications')
            self.assertEqual(store.load()[0]['entries'], [])
            store.save({'entries': [self.entry()], 'dnd': True})
            self.assertEqual(store.path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(store.directory.stat().st_mode & 0o777, 0o700)
            self.assertTrue(store.load()[0]['dnd'])
            self.assertEqual(store.load()[0]['entries'][0]['body'], 'Private text')
            store.save({'entries': [], 'dnd': False})
            self.assertEqual(store.load()[0]['entries'], [])
            self.assertEqual(list(store.directory.glob('.history-*')), [])
            store.lock.close()

    def test_corrupt_history_is_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            store = store_module.Store(directory)
            store.path.write_text('{ damaged')
            data, warning = store.load()
            self.assertEqual(data['entries'], [])
            self.assertIn('preserved', warning)
            self.assertEqual(next(store.directory.glob('history.corrupt-*')).read_text(), '{ damaged')
            store.lock.close()

    def test_single_writer_and_symlink_safety(self):
        with tempfile.TemporaryDirectory() as directory:
            store = store_module.Store(Path(directory) / 'notifications')
            with self.assertRaises(BlockingIOError):
                store_module.Store(store.directory)
            target = Path(directory) / 'target'
            target.write_text('do not touch')
            store.path.symlink_to(target)
            with self.assertRaises(OSError):
                store.load()
            self.assertEqual(target.read_text(), 'do not touch')
            store.lock.close()

    def test_remote_images_and_invalid_data(self):
        cleaned = store_module.clean({'entries': [self.entry(appIcon='https://example.com/tracker.png')], 'dnd': False})
        self.assertEqual(cleaned['entries'][0]['appIcon'], '')
        for invalid in ({}, {'entries': [None]}, {'entries': [{'id': 'bad', 'timestamp': 'yesterday'}]}):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                store_module.clean(invalid)

    def test_active_integration_has_no_old_daemon_dependency(self):
        files = list(SHELL.rglob('*.qml')) + list(SHELL.rglob('*.sh'))
        files += [ROOT / p for p in (
            'home/dot_config/niri/scripts/executable_autostart.sh',
            'home/dot_config/niri/scripts/executable_system-controls.sh',
            'home/dot_config/niri/scripts/executable_settings-menu.sh',
            'home/dot_config/niri/scripts/executable_set-theme.sh',
            'home/dot_config/matugen/config.toml')]
        for file in files:
            with self.subTest(file=file):
                self.assertNotRegex(file.read_text(), re.compile(r'makoctl|run_once mako'))

    def test_notification_surfaces_have_square_corners(self):
        for file in NOTIFICATIONS.glob('*.qml'):
            with self.subTest(file=file):
                self.assertTrue(all(float(value) == 0 for value in re.findall(r'\bradius:\s*([\d.]+)', file.read_text())))


@unittest.skipUnless(os.environ.get('DOFS_QML_TEST') == '1', 'requires qs, gdbus, dbus-run-session and Wayland')
class LiveNotificationTests(unittest.TestCase):
    def private_bus(self):
        if os.environ.get('DOFS_NOTIFICATION_BUS') == '1':
            return False
        result = subprocess.run(['dbus-run-session', '--', 'env', 'DOFS_NOTIFICATION_BUS=1',
                                 sys.executable, '-B', str(Path(__file__).resolve()),
                                 type(self).__name__ + '.' + self._testMethodName, '-v'],
                                capture_output=True, text=True, timeout=90)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return True

    def test_popup_and_center_effective_content_insets_match(self):
        if self.private_bus():
            return
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / 'shell'
            shutil.copytree(SHELL, config)
            (config / 'shell.qml').write_text('''import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import "notifications" as Notifications
ShellRoot {
    id: root
    function findItem(item, name) {
        if (item.objectName === name) return item;
        for (var i = 0; i < item.children.length; i++) {
            var result = findItem(item.children[i], name);
            if (result) return result;
        }
        return null;
    }
    Window {
        id: render
        width: 960; height: 720; visible: true
        Notifications.Card {
            id: popup
            width: 430; height: implicitHeight
            toast: true
            service: dummy; palette: colors; entry: dummy.entries[0]
        }
        Notifications.CenterPanel {
            id: center
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 440
            opened: false
            service: dummy; palette: colors
        }
    }
    QtObject {
        id: fixtureSettings
        property var options: ({padding: 15, retentionDays: 7})
    }
    QtObject {
        id: dummy
        property var settings: fixtureSettings
        property var entries: [{id: "test", appName: "Fixture", summary: "Same notification title",
            body: "Identical short message body.", timestamp: Date.now(), read: true, urgency: 1}]
        property bool dnd: false
        property string error: ""
        function find(key) { return null; }
    }
    QtObject {
        id: colors
        property color background: "#0d0e11"
        property color surface: "#313244"
        property color text: "#e7e3ff"
        property color muted: "#879099"
        property color accent: "#7e9cd8"
        property color border: "#383850"
        property color red: "#f38ba8"
        property color yellow: "#f9e2af"
    }
    IpcHandler {
        target: "insets"
        function padding(value: int): void { fixtureSettings.options = {padding: value, retentionDays: 7}; }
        function state(): string {
            var panel = center;
            var history = root.findItem(center, "notificationCenterHistory");
            history.view.forceLayout();
            var card = history.view.itemAtIndex(0);
            if (!card) return JSON.stringify({ready: false});
            popup.width = card.width;
            var content = card.children[0], popupContent = popup.children[0];
            return JSON.stringify({ready: true, padding: fixtureSettings.options.padding,
                centerLeft: content.mapToItem(panel, 0, 0).x,
                popupLeft: popupContent.mapToItem(popup, 0, 0).x,
                centerTop: content.y, popupTop: popupContent.y,
                centerRight: card.width - content.x - content.width,
                popupRight: popup.width - popupContent.x - popupContent.width,
                centerBottom: card.height - content.y - content.height,
                popupBottom: popup.height - popupContent.y - popupContent.height,
                centerHeight: card.height, popupHeight: popup.height,
                centerSpacing: content.spacing, popupSpacing: popupContent.spacing,
                centerIcon: root.findItem(card, "notificationApplicationIcon").status,
                popupIcon: root.findItem(popup, "notificationApplicationIcon").status});
        }
    }
}''')
            env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', PYTHONDONTWRITEBYTECODE='1')
            env.pop('WAYLAND_DISPLAY', None)
            env.pop('DISPLAY', None)
            log = Path(directory) / 'insets.log'
            with log.open('w') as stream:
                process = subprocess.Popen(['qs', '-p', str(config), '--no-color'], env=env, stdout=stream, stderr=subprocess.STDOUT)
            try:
                def ipc(method, *args):
                    result = subprocess.run(['qs', '-p', str(config), 'ipc', 'call', 'insets', method, *map(str, args)],
                                            env=env, capture_output=True, text=True, timeout=4)
                    return result.stdout.strip()

                for padding in (15, 4, 0, 24):
                    deadline = time.monotonic() + 10
                    last = None
                    applied = False
                    while time.monotonic() < deadline:
                        reply = ipc('state')
                        last = json.loads(reply) if reply.startswith('{') else None
                        if last and not applied:
                            ipc('padding', padding)
                            applied = True
                        if last and last.get('ready') and last['padding'] == padding:
                            insets = ('centerLeft', 'popupLeft', 'centerTop', 'popupTop', 'centerRight', 'popupRight', 'centerBottom', 'popupBottom')
                            if (all(abs(last[key] - padding) < 0.01 for key in insets)
                                    and abs(last['centerHeight'] - last['popupHeight']) < 0.01
                                    and last['centerIcon'] == last['popupIcon'] == 1
                                    and last['centerSpacing'] == last['popupSpacing']):
                                break
                        if process.poll() is not None:
                            self.fail(log.read_text())
                    else:
                        self.fail('Assembled popup/center insets differ: ' + str(last) + '\n' + log.read_text())
            finally:
                process.terminate()
                process.wait(timeout=8)
            logs = log.read_text()
            self.assertNotIn('WARN scene:', logs, logs)
            self.assertNotIn('Binding loop', logs, logs)
            self.assertNotIn('ERROR:', logs, logs)

    def test_history_scrollbar_has_a_separate_gutter(self):
        if self.private_bus():
            return
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / 'shell'
            shutil.copytree(SHELL, config)
            (config / 'shell.qml').write_text('''import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import "notifications" as Notifications
ShellRoot {
    id: root
    property string cleared: ""
    function findItems(item, name) {
        var result = item.objectName === name ? [item] : [];
        for (var i = 0; i < item.children.length; i++) result = result.concat(findItems(item.children[i], name));
        return result;
    }
    ListModel { id: entries; dynamicRoles: true }
    Component.onCompleted: {
        for (var i = 0; i < 30; i++) entries.append({section: "Today · App " + Math.floor(i / 3),
            record: {id: String(i), appName: "Long application name " + i, summary: "A notification title that wraps on narrow outputs " + i,
                body: "Message text that should wrap inside the card, never under the scrollbar. ".repeat(6),
                timestamp: Date.now(), read: true, urgency: 1}});
    }
    Window {
        width: 440; height: 240; visible: true
        Notifications.HistoryList {
            id: history
            width: 424; height: 220
            model: entries; service: dummy; palette: colors
            onClearSection: section => root.cleared = section
        }
    }
    QtObject {
        id: dummy
        property var settings: ({options: {padding: 15}})
        function find(key) { return null; }
    }
    QtObject {
        id: colors
        property color background: "#0d0e11"
        property color surface: "#313244"
        property color text: "#e7e3ff"
        property color muted: "#879099"
        property color accent: "#7e9cd8"
        property color border: "#383850"
        property color red: "#f38ba8"
    }
    IpcHandler {
        target: "layout"
        function state(): string {
            history.view.forceLayout();
            var bar = root.findItems(history, "notificationHistoryScroll")[0];
            var cards = [];
            for (var i = 0; i < history.view.count; i++) {
                var card = history.view.itemAtIndex(i);
                if (card) cards.push({right: card.mapToItem(history, card.width, 0).x,
                    width: card.width, height: card.height, padding: card.padding, entry: card.entry.id, bodyLength: card.entry.body.length});
            }
            var controls = root.findItems(history.view.contentItem, "notificationHistoryClear").map(button =>
                ({right: button.mapToItem(history, button.width, 0).x, width: button.width}));
            return JSON.stringify({viewportWidth: history.view.width, viewportHeight: history.view.height,
                contentHeight: history.view.contentHeight, contentY: history.view.contentY, originY: history.view.originY,
                count: history.view.count, cards: cards, controls: controls, cleared: root.cleared,
                scrollbar: {x: bar.x, y: bar.y, width: bar.width, height: bar.height, visible: bar.visible,
                    external: bar.parent === history, size: bar.size, position: bar.position}});
        }
        function resize(width: int, height: int): void { history.width = width; history.height = height; }
        function scroll(): void { history.view.positionViewAtEnd(); }
        function clearGroup(): void { root.findItems(history.view.contentItem, "notificationHistoryClear")[0].clicked(); }
        function one(): void {
            entries.clear();
            entries.append({section: "Today · App", record: {id: "one", appName: "App", summary: "Short message", body: "",
                timestamp: Date.now(), read: true, urgency: 1}});
            history.view.positionViewAtBeginning();
        }
    }
}''')
            # Render real Qt layout frames offscreen, without opening a surface
            # or taking keyboard focus on the user's Wayland desktop.
            env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', PYTHONDONTWRITEBYTECODE='1')
            env.pop('WAYLAND_DISPLAY', None)
            env.pop('DISPLAY', None)
            log = Path(directory) / 'layout.log'
            with log.open('w') as stream:
                process = subprocess.Popen(['qs', '-p', str(config), '--no-color'], env=env, stdout=stream, stderr=subprocess.STDOUT)
            try:
                def ipc(method, *args):
                    result = subprocess.run(['qs', '-p', str(config), 'ipc', 'call', 'layout', method, *map(str, args)],
                                            env=env, capture_output=True, text=True, timeout=4)
                    return result.stdout.strip()

                def wait(predicate):
                    deadline = time.monotonic() + 10
                    last = None
                    while time.monotonic() < deadline:
                        reply = ipc('state')
                        last = json.loads(reply) if reply.startswith('{') else None
                        if last and predicate(last):
                            return last
                        if process.poll() is not None:
                            self.fail(log.read_text())
                    self.fail('History layout did not settle: ' + str(last) + '\n' + log.read_text())

                def check_bounds(state):
                    bar = state['scrollbar']
                    self.assertTrue(bar['external'])
                    self.assertAlmostEqual(bar['x'] - state['viewportWidth'], 6)
                    self.assertAlmostEqual(bar['height'], state['viewportHeight'])
                    self.assertEqual(bar['y'], 0)
                    self.assertEqual(bar['width'], 4)
                    self.assertTrue(state['cards'])
                    self.assertTrue(state['controls'])
                    for card in state['cards']:
                        self.assertAlmostEqual(card['width'], state['viewportWidth'])
                        self.assertLessEqual(card['right'], bar['x'] - 6)
                        self.assertGreater(card['height'], 0)
                        self.assertEqual(card['padding'], 15, 'history cards must use the shared notification padding')
                    for control in state['controls']:
                        self.assertLessEqual(control['right'], bar['x'] - 6)
                        self.assertGreater(control['width'], 0)

                overflowing = wait(lambda s: s['count'] == 30 and s['cards'] and s['controls'] and s['scrollbar']['visible'])
                self.assertGreater(overflowing['contentHeight'], overflowing['viewportHeight'])
                check_bounds(overflowing)
                for width, height in ((320, 220), (240, 160), (424, 220)):
                    ipc('resize', width, height)
                    resized = wait(lambda s: abs(s['viewportWidth'] - (width - 10)) < 0.01 and s['cards'] and s['controls'])
                    check_bounds(resized)
                ipc('scroll')
                scrolled = wait(lambda s: s['contentY'] > 0 and s['cards'] and s['controls'])
                check_bounds(scrolled)
                ipc('clearGroup')
                wait(lambda s: bool(s['cleared']))
                ipc('one')
                short = wait(lambda s: s['count'] == 1 and not s['scrollbar']['visible'] and s['cards'] and s['controls'])
                check_bounds(short)
                self.assertLess(short['cards'][0]['height'], 100, 'text-only cards must not reserve an empty image preview')
            finally:
                process.terminate()
                process.wait(timeout=8)
            logs = log.read_text()
            self.assertNotIn('WARN scene:', logs, logs)
            self.assertNotIn('Binding loop', logs, logs)
            self.assertNotIn('ERROR:', logs, logs)

    def test_application_icons_decode_and_fall_back(self):
        if self.private_bus():
            return
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            config = directory / 'shell'
            config.mkdir()
            shutil.copytree(SHELL, config, dirs_exist_ok=True)
            data = directory / 'data'
            applications = data / 'applications'
            applications.mkdir(parents=True)
            logo = directory / 'application logo #1.svg'
            logo.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><path fill="#7e9cd8" d="M0 0h32v32H0z"/></svg>')
            broken = directory / 'broken.svg'
            broken.write_text('not an image')
            missing = directory / 'deleted.svg'
            (applications / 'org.dofs.IconFixture.desktop').write_text(
                '[Desktop Entry]\nType=Application\nName=Dofs Icon Fixture\nExec=true\nIcon=' + str(logo) + '\n')
            theme = data / 'icons/hicolor'
            (theme / '32x32/apps').mkdir(parents=True)
            (theme / 'index.theme').write_text('[Icon Theme]\nName=Test hicolor\nDirectories=32x32/apps,scalable/apps,128x128/apps,256x256/apps,512x512/apps\n\n[32x32/apps]\nSize=32\nType=Fixed\nContext=Applications\n\n[scalable/apps]\nSize=48\nType=Scalable\nMinSize=1\nMaxSize=512\nContext=Applications\n' + ''.join(f'\n[{size}x{size}/apps]\nSize={size}\nType=Fixed\nContext=Applications\n' for size in (128, 256, 512)))
            shutil.copy2(logo, theme / '32x32/apps/dofs-fixture-themed.svg')
            exports = directory / 'flatpak/exports/share'
            (exports / 'applications').mkdir(parents=True)
            (exports / 'applications/org.dofs.FlatpakFixture.desktop').write_text(
                '[Desktop Entry]\nType=Application\nName=Flatpak Fixture\nExec=true\nIcon=dofs-fixture-themed\n')

            cases = [
                {'name': 'theme name', 'appIcon': 'dofs-fixture-themed', 'contains': 'dofs-fixture-themed'},
                {'name': 'theme filename', 'appIcon': 'dofs-fixture-themed.svg', 'contains': 'dofs-fixture-themed'},
                {'name': 'theme provider', 'appIcon': 'image://icon/dofs-fixture-themed', 'contains': 'dofs-fixture-themed'},
                {'name': 'absolute file with spaces and hash', 'appIcon': str(logo), 'file': str(logo)},
                {'name': 'encoded file URL', 'appIcon': logo.as_uri(), 'file': str(logo)},
                {'name': 'desktop-entry hint', 'appId': 'org.dofs.IconFixture', 'file': str(logo)},
                {'name': 'desktop-entry filename', 'appId': 'org.dofs.IconFixture.desktop', 'file': str(logo)},
                {'name': 'application display name', 'appName': 'Dofs Icon Fixture', 'file': str(logo)},
                {'name': 'Flatpak exported entry', 'appId': 'org.dofs.FlatpakFixture', 'contains': 'dofs-fixture-themed'},
                {'name': 'missing theme to desktop fallback', 'appIcon': 'dofs-nonexistent-icon', 'appId': 'org.dofs.IconFixture', 'file': str(logo)},
                {'name': 'broken file to desktop fallback', 'appIcon': str(broken), 'appId': 'org.dofs.IconFixture', 'file': str(logo)},
                {'name': 'deleted file to bundled fallback', 'appIcon': str(missing), 'fallback': True},
                {'name': 'remote URL blocked', 'appIcon': 'https://127.0.0.1:9/tracker.png', 'fallback': True},
                {'name': 'unknown application', 'appName': 'Dofs Unknown App', 'fallback': True},
                {'name': 'empty metadata', 'fallback': True},
            ]
            real_apps = [('/usr/share/applications/org.mozilla.firefox.desktop', 'Firefox'),
                         ('/usr/share/applications/com.mitchellh.ghostty.desktop', 'Ghostty'),
                         ('/var/lib/flatpak/exports/share/applications/com.discordapp.Discord.desktop', 'Discord'),
                         ('/var/lib/flatpak/exports/share/applications/com.slack.Slack.desktop', 'Slack'),
                         ('/var/lib/flatpak/exports/share/applications/md.obsidian.Obsidian.desktop', 'Obsidian'),
                         ('/var/lib/flatpak/exports/share/applications/app.zen_browser.zen.desktop', 'Zen Browser')]
            for file, name in real_apps:
                if Path(file).is_file():
                    icon = next(line.split('=', 1)[1] for line in Path(file).read_text().splitlines() if line.startswith('Icon='))
                    cases.append({'name': 'installed ' + name, 'appId': Path(file).stem, 'contains': icon})
            for case in cases:
                for key in ('appIcon', 'appId', 'appName'):
                    case.setdefault(key, '')
                case.setdefault('fallback', False)
            (config / 'shell.qml').write_text('''//@ pragma IconTheme Yaru
import QtQuick
import Quickshell
import Quickshell.Io
import "notifications" as Notifications
ShellRoot {
    id: root
    function findIcon(item) {
        if (item.objectName === "notificationApplicationIcon") return item;
        for (var i = 0; i < item.children.length; i++) {
            var found = findIcon(item.children[i]);
            if (found) return found;
        }
        return null;
    }
    Item {
        Repeater {
            id: samples
            model: CASES
            Notifications.ApplicationIcon {
                required property var modelData
                appIcon: modelData.appIcon; appId: modelData.appId; appName: modelData.appName
            }
        }
        Notifications.Card {
            id: card
            width: 400; height: implicitHeight
            entry: ({id: "test", appId: "org.dofs.IconFixture", appName: "Dofs Icon Fixture", appIcon: "", summary: "Test", body: "", timestamp: Date.now(), read: true, urgency: 1})
            palette: colors
            service: dummy
        }
        Notifications.NotificationButton { id: button; palette: colors; text: "Test" }
        Notifications.ApplicationIcon { id: changing; appIcon: "dofs-fixture-themed" }
    }
    QtObject {
        id: dummy
        property var settings: ({options: {padding: 15}})
        function find(key) { return null; }
    }
    QtObject {
        id: colors
        property color background: "#0d0e11"
        property color surface: "#313244"
        property color text: "#e7e3ff"
        property color muted: "#879099"
        property color accent: "#7e9cd8"
        property color border: "#383850"
        property color red: "#f38ba8"
    }
    IpcHandler {
        target: "icons"
        function state(): string {
            var results = [];
            for (var i = 0; i < samples.count; i++) {
                var icon = samples.itemAt(i);
                results.push({name: icon.modelData.name, status: icon.status, source: icon.source.toString(),
                    fallback: icon.usingFallback, width: icon.children[0].paintedWidth,
                    height: icon.children[0].paintedHeight, candidates: icon.candidates});
            }
            var header = root.findIcon(card);
            return JSON.stringify({samples: results, header: {status: header.status, source: header.source.toString()},
                cardRadius: card.radius, buttonRadius: button.background.radius,
                changing: {status: changing.status, source: changing.source.toString(), fallback: changing.usingFallback}});
        }
        function change(): void { changing.appIcon = "dofs-missing-after-update"; }
    }
}'''.replace('CASES', json.dumps(cases)))
            env = dict(os.environ, XDG_DATA_HOME=str(data),
                       XDG_DATA_DIRS=str(exports) + ':' + os.environ.get('XDG_DATA_DIRS', '/usr/local/share:/usr/share'),
                       QT_QPA_PLATFORM='wayland', PYTHONDONTWRITEBYTECODE='1')
            log = directory / 'icons.log'
            with log.open('w') as stream:
                process = subprocess.Popen(['qs', '-p', str(config), '--no-color'], env=env, stdout=stream, stderr=subprocess.STDOUT)
            try:
                def state():
                    reply = subprocess.run(['qs', '-p', str(config), 'ipc', 'call', 'icons', 'state'], env=env,
                                           capture_output=True, text=True, timeout=4)
                    return json.loads(reply.stdout) if reply.stdout.startswith('{') else None

                def correct(actual, expected):
                    return (actual['status'] == 1 and actual['fallback'] == expected['fallback']
                            and (not expected.get('contains') or expected['contains'] in actual['source'])
                            and (not expected.get('file') or unquote(urlparse(actual['source']).path) == expected['file']))

                deadline = time.monotonic() + 15
                last = None
                while time.monotonic() < deadline:
                    last = state()
                    if (last and len(last['samples']) == len(cases)
                            and all(correct(actual, expected) for actual, expected in zip(last['samples'], cases))
                            and last['header']['status'] == 1):
                        break
                    if process.poll() is not None:
                        self.fail(log.read_text())
                else:
                    self.fail('Icons did not decode correctly: ' + json.dumps(last, indent=2) + '\n' + log.read_text())
                self.assertEqual(unquote(urlparse(last['header']['source']).path), str(logo))
                self.assertEqual(last['cardRadius'], 0)
                self.assertEqual(last['buttonRadius'], 0)
                for sample in last['samples']:
                    self.assertGreater(sample['width'], 0)
                    self.assertGreater(sample['height'], 0)
                    self.assertFalse(any(candidate.startswith(('http:', 'https:')) for candidate in sample['candidates']))
                subprocess.run(['qs', '-p', str(config), 'ipc', 'call', 'icons', 'change'], env=env, check=True, capture_output=True, timeout=4)
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline:
                    changed = state()['changing']
                    if changed['status'] == 1 and changed['fallback']:
                        break
                else:
                    self.fail('Changing an icon did not reset its fallback chain')
            finally:
                process.terminate()
                process.wait(timeout=8)
            self.assertNotIn('TypeError', log.read_text())
            self.assertNotIn('Binding loop', log.read_text())

    def test_native_server_and_persistent_history(self):
        if self.private_bus():
            return
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            config = directory / 'shell'
            shutil.copytree(SHELL, config)
            entrypoint = config / 'shell.qml'
            entrypoint.write_text('import QtQuick\n' + entrypoint.read_text().rsplit('}', 1)[0] + '''
    function notificationItem(item, name) {
        if (item.objectName === name) return item;
        for (var i = 0; i < item.children.length; i++) {
            var found = notificationItem(item.children[i], name);
            if (found) return found;
        }
        return null;
    }
    Item {
        width: 440; height: 800
        Notifications.Card {
            id: testCard
            property string iconSummary: ""
            width: 400; height: implicitHeight
            service: notificationHost.service
            palette: testPalette
            entry: service.entries.find(e => e.summary === iconSummary) || service.entries[0] || {id: "empty", appName: "Test", summary: "Empty", body: "", timestamp: Date.now(), read: true, urgency: 1}
        }
        Notifications.Card {
            id: testPopup
            width: 400; height: implicitHeight
            toast: true
            service: notificationHost.service
            palette: testPalette
            entry: testCard.entry
        }
    }
    BarPalette { id: testPalette }
    IpcHandler {
        target: "notificationTest"
        function previews(): string {
            return JSON.stringify(["image://icon/preferences-system-notifications", "https://example.com/image.png",
                "image://qsimage/1", "file:///tmp/image.png", "image://icon//tmp/image.png"].map(value => testCard.previewSource(value)));
        }
        function state(): string {
            var s = notificationHost.service;
            var icon = notificationItem(testCard, "notificationApplicationIcon");
            var preview = notificationItem(testCard, "notificationImagePreview");
            return JSON.stringify({entries: s.entries, unread: s.unreadCount, dnd: s.dnd,
                padding: {history: testCard.padding, popup: testPopup.padding,
                    historyInset: testCard.children[0].x, popupInset: testPopup.children[0].x},
                icon: {status: icon.status, source: icon.source.toString()},
                preview: {status: preview.status, source: preview.source.toString(), visible: preview.visible},
                loaded: s.loaded, error: s.error, popups: s.popups.length, options: s.settings.options,
                live: s.live.map(w => ({key: w.key, id: w.notification.id, timeout: w.timeout}))});
        }
        function hide(): void { var s = notificationHost.service; if (s.live.length) s.hidePopup(s.live[0].key); }
        function selectIcon(summary: string): void { testCard.iconSummary = summary; }
        function invoke(identifier: string): void { var s = notificationHost.service; if (s.live.length) s.invoke(s.live[0].key, identifier); }
        function reply(text: string): void { var s = notificationHost.service; if (s.live.length) s.reply(s.live[0].key, text); }
    }
}''')
            env = dict(os.environ, DOFS_BAR_TEST='1', DOFS_NOTIFICATION_TEST='1',
                       XDG_STATE_HOME=str(directory / 'state'), QT_QPA_PLATFORM='wayland', PYTHONDONTWRITEBYTECODE='1')
            process = None
            log = directory / 'shell.log'

            def start():
                nonlocal process
                stream = log.open('a')
                process = subprocess.Popen(['qs', '-p', str(config), '--no-color'], env=env, stdout=stream, stderr=subprocess.STDOUT)
                stream.close()
                wait(lambda s: s['loaded'])

            def stop():
                nonlocal process
                if process:
                    process.terminate()
                    process.wait(timeout=8)
                    process = None

            def ipc(target, method, *args):
                result = subprocess.run(['qs', '-p', str(config), 'ipc', 'call', target, method, *args],
                                        env=env, capture_output=True, text=True, timeout=4)
                return result.stdout.strip()

            def state():
                reply = ipc('notificationTest', 'state')
                return json.loads(reply) if reply.startswith('{') else None

            def wait(predicate):
                deadline = time.monotonic() + 10
                last = None
                while time.monotonic() < deadline:
                    last = state()
                    if last and predicate(last):
                        return last
                    if process and process.poll() is not None:
                        self.fail('Shell exited: ' + log.read_text())
                self.fail('Notification state did not converge: ' + str(last) + '\n' + log.read_text())

            def dbus(method, *args):
                result = subprocess.run(['gdbus', 'call', '--session', '--dest', 'org.freedesktop.Notifications',
                                         '--object-path', '/org/freedesktop/Notifications', '--method',
                                         'org.freedesktop.Notifications.' + method, '--', *map(str, args)],
                                        env=env, capture_output=True, text=True, timeout=4)
                self.assertEqual(result.returncode, 0, result.stderr)
                return result.stdout

            def notify(title, body='Message', app='Test Chat', replaces=0, actions='[]', hints='{}', timeout=6000, icon=''):
                result = dbus('Notify', app, replaces, icon, title, body, actions, hints, timeout)
                return int(re.search(r'uint32 (\d+)', result)[1])

            history = directory / 'state/quickshell/dofs/notifications/history.json'

            def disk_wait(predicate):
                deadline = time.monotonic() + 10
                while time.monotonic() < deadline:
                    if history.exists():
                        data = json.loads(history.read_text())
                        if predicate(data):
                            return data
                self.fail('History was not saved')

            monitor = None
            monitor_logs = []
            notification_icon = directory / 'notification app icon.svg'
            shutil.copy2(config / 'notifications/icons/application.svg', notification_icon)
            try:
                start()
                self.assertEqual(state()['padding'], {'history': 15, 'popup': 15, 'historyInset': 15, 'popupInset': 15})
                self.assertEqual(json.loads(ipc('notificationTest', 'previews')),
                                 ['', '', 'image://qsimage/1', 'file:///tmp/image.png', 'file:///tmp/image.png'])
                monitor = subprocess.Popen(['gdbus', 'monitor', '--session', '--dest', 'org.freedesktop.Notifications',
                                            '--object-path', '/org/freedesktop/Notifications'], env=env,
                                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                with selectors.DefaultSelector() as selector:
                    selector.register(monitor.stdout, selectors.EVENT_READ)
                    self.assertTrue(selector.select(timeout=5), 'D-Bus monitor did not start')
                    monitor_logs.append(os.read(monitor.stdout.fileno(), 65536).decode())
                caps = dbus('GetCapabilities')
                for cap in ('actions', 'persistence', 'inline-reply'):
                    self.assertIn(cap, caps)
                self.assertNotIn('body-markup', caps)
                notification_id = notify('First', '<b>Hello</b> &amp; <3', icon=str(notification_icon))
                first = wait(lambda s: len(s['entries']) == 1 and s['icon']['status'] == 1)
                self.assertEqual(first['entries'][0]['body'], 'Hello & <3')
                self.assertEqual(first['unread'], 1)
                self.assertEqual(first['popups'], 1)
                self.assertEqual(unquote(urlparse(first['icon']['source']).path), str(notification_icon))
                self.assertEqual(first['preview']['source'], '', 'an app logo must not become a large message preview')
                self.assertFalse(first['preview']['visible'], 'an empty QUrl must not reserve image-preview space')
                key = first['entries'][0]['id']
                self.assertEqual(notify('Updated', replaces=notification_id, icon=str(notification_icon)), notification_id)
                updated = wait(lambda s: s['entries'][0]['summary'] == 'Updated')
                self.assertEqual(len(updated['entries']), 1)
                self.assertEqual(updated['entries'][0]['id'], key)
                ipc('notificationTest', 'hide')
                self.assertEqual(wait(lambda s: s['popups'] == 0)['unread'], 1)
                self.assertEqual(len(state()['live']), 1, 'hiding a toast must preserve actions')
                ipc('notifications', 'toggleDnd')
                notify('Silent')
                silent = wait(lambda s: len(s['entries']) == 2)
                self.assertTrue(silent['dnd'])
                self.assertEqual(silent['popups'], 0)
                notify('Critical', hints="{'urgency': <byte 2>}")
                self.assertEqual(wait(lambda s: len(s['entries']) == 3)['popups'], 0)
                transient = notify('Transient', hints="{'transient': <true>}")
                wait(lambda s: len(s['live']) == 3)
                self.assertEqual(len(state()['entries']), 3)
                disk_wait(lambda d: len(d['entries']) == 3 and d['dnd'])
                stop()
                start()
                restored = wait(lambda s: len(s['entries']) == 3)
                self.assertTrue(restored['dnd'])
                self.assertEqual(restored['popups'], 0)
                self.assertEqual(restored['live'], [])
                ipc('notificationTest', 'selectIcon', 'Updated')
                archived_icon = wait(lambda s: s['icon']['status'] == 1 and 'notification app icon.svg' in unquote(s['icon']['source']))
                self.assertEqual(unquote(urlparse(archived_icon['icon']['source']).path), str(notification_icon))
                ipc('notificationTest', 'selectIcon', '')
                ipc('notifications', 'open')
                self.assertEqual(wait(lambda s: s['unread'] == 0)['popups'], 0)
                ipc('notifications', 'close')
                ipc('notifications', 'toggleDnd')
                notify('Quick', timeout=100)
                wait(lambda s: len(s['entries']) == 4 and s['popups'] == 0)
                action_id = notify('Action', actions="['default', 'Open']")
                wait(lambda s: len(s['entries']) == 5)
                ipc('notificationTest', 'invoke', 'default')
                wait(lambda s: not any(w['id'] == action_id for w in s['live']))
                self.assertTrue(state()['entries'][0]['read'])
                reply_id = notify('Reply', actions="['inline-reply', 'Write a reply']")
                wait(lambda s: len(s['entries']) == 6)
                ipc('notificationTest', 'reply', 'Hello back')
                wait(lambda s: not any(w['id'] == reply_id for w in s['live']))
                close_id = notify('Withdraw')
                wait(lambda s: len(s['entries']) == 7)
                dbus('CloseNotification', close_id)
                wait(lambda s: not any(w['id'] == close_id for w in s['live']))
                self.assertEqual(state()['entries'][0]['summary'], 'Withdraw')
                self.assertTrue(state()['entries'][0]['read'])

                options_path = config / 'notifications/config.json'
                options = json.loads(options_path.read_text())
                options.update(privateApps=['Private'], mutedApps=['Quiet'], padding=4)
                options_path.write_text(json.dumps(options))
                wait(lambda s: s['options']['privateApps'] == ['Private'])
                self.assertEqual(state()['padding'], {'history': 4, 'popup': 4, 'historyInset': 4, 'popupInset': 4})
                notify('Secret', app='Private')
                wait(lambda s: len(s['entries']) == 8)
                disk_wait(lambda d: len(d['entries']) == 7)
                self.assertNotIn('Secret', history.read_text())
                ipc('notifications', 'dismissPopups')
                notify('Muted', app='Quiet')
                muted = wait(lambda s: len(s['entries']) == 9)
                self.assertEqual(muted['popups'], 0)
                disk_wait(lambda d: len(d['entries']) == 8 and d['entries'][0]['summary'] == 'Muted')
                self.assertNotIn('Secret', history.read_text())
                options_path.write_text('{ invalid json')
                invalid = wait(lambda s: bool(s['error']))
                self.assertEqual(invalid['options']['privateApps'], ['Private'])
                options_path.write_text(json.dumps(dict(options, padding=-1)))
                invalid_padding = wait(lambda s: 'Invalid notification options' in s['error'])
                self.assertEqual(invalid_padding['options']['padding'], 4)
                self.assertEqual(invalid_padding['padding']['popup'], 4)
                options_path.write_text(json.dumps(options))
                wait(lambda s: not s['error'])
                # Restart just the storage child. In-memory deletions must win
                # over the older disk snapshot when it reconnects.
                children = Path(f'/proc/{process.pid}/task/{process.pid}/children').read_text().split()
                storage_pid = next(int(pid) for pid in children if b'history-store.py' in Path(f'/proc/{pid}/cmdline').read_bytes())
                os.kill(storage_pid, 9)
                wait(lambda s: bool(s['error']))
                ipc('notifications', 'clear')
                wait(lambda s: not s['entries'] and not s['live'])
                disk_wait(lambda d: not d['entries'])
                wait(lambda s: not s['error'])

                notify('Photo', icon=str(notification_icon), hints="{'image-path': <'" + str(notification_icon) + "'>}")
                image = wait(lambda s: s['entries'] and s['entries'][0]['summary'] == 'Photo' and s['preview']['status'] == 1)
                self.assertEqual(unquote(urlparse(image['preview']['source']).path), str(notification_icon))
                ipc('notifications', 'clear')
                wait(lambda s: not s['entries'] and not s['live'])

                options.update(historyLimit=3, maxVisible=2)
                options_path.write_text(json.dumps(options))
                wait(lambda s: s['options']['historyLimit'] == 3)
                for i in range(5):
                    notify('Burst ' + str(i))
                    burst = wait(lambda s: s['entries'][0]['summary'] == 'Burst ' + str(i))
                    self.assertLessEqual(len(burst['entries']), 3)
                    self.assertLessEqual(len(burst['live']), 3)
                    self.assertLessEqual(burst['popups'], 2)
                self.assertEqual(len(state()['entries']), 3)
                notify('Sticky', hints="{'urgency': <byte 2>}", timeout=-1)
                sticky = wait(lambda s: s['entries'][0]['summary'] == 'Sticky')
                self.assertEqual(sticky['live'][0]['timeout'], 0)
                old_options = dict(options)
                old_options.pop('padding')
                options_path.write_text(json.dumps(old_options))
                wait(lambda s: s['options']['padding'] == 15)
                self.assertEqual(state()['padding'], {'history': 15, 'popup': 15, 'historyInset': 15, 'popupInset': 15})
                options['historyEnabled'] = False
                options_path.write_text(json.dumps(options))
                wait(lambda s: not s['options']['historyEnabled'])
                disk_wait(lambda d: not d['entries'])
                stop()
                start()
                self.assertEqual(state()['entries'], [])
                self.assertFalse(state()['error'])
            finally:
                stop()
                if monitor:
                    monitor.terminate()
                    remaining, _ = monitor.communicate(timeout=5)
                    monitor_logs.append(remaining.decode())
            signals = ''.join(monitor_logs)
            self.assertIn('ActionInvoked', signals)
            self.assertIn("'default'", signals)
            self.assertIn('NotificationReplied', signals)
            self.assertIn('Hello back', signals)
            logs = log.read_text()
            self.assertNotIn('ERROR:', logs, logs)
            self.assertNotIn('WARN scene:', logs, logs)
            self.assertNotIn('TypeError', logs, logs)
            self.assertNotIn('Binding loop', logs, logs)


if __name__ == '__main__':
    unittest.main()
