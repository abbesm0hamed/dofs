import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "History.js" as History

Scope {
    id: root
    required property var settings
    property string focusedOutput: ""
    property bool centerOpen: false
    readonly property bool testing: Quickshell.env("DOFS_BAR_TEST") === "1"
    readonly property bool enabled: !testing || Quickshell.env("DOFS_NOTIFICATION_TEST") === "1"
    property var entries: []
    property var live: []
    property bool dnd: false
    property bool loaded: !enabled
    property bool storageReady: false
    property bool writePending: false
    property bool dirty: false
    property bool dndTouched: false
    property bool resetBeforeLoad: false
    property string storageError: ""
    property string storageWarning: ""
    property int serial: 0
    readonly property int unreadCount: entries.filter(e => !e.read).length
    readonly property var popups: live.filter(w => w.popup)
    readonly property string error: settings.error || storageError || storageWarning

    function prune() {
        entries = History.prune(entries, settings.options, Date.now());
        // Bound tracked DBus objects as well as the on-disk history.
        live.slice().forEach(w => {
            if (!w.notification.transient && !entries.some(e => e.id === w.key)) w.notification.expire();
        });
    }
    function save() {
        if (enabled && loaded) { dirty = true; saveDelay.start(); }
    }
    function snapshot() {
        return {entries: settings.options.historyEnabled ? entries.filter(e => !History.matches(settings.options.privateApps, e)) : [], dnd: dnd};
    }
    function markRead() {
        entries = entries.map(e => Object.assign({}, e, {read: true}));
        save();
    }
    function setDnd(value) {
        dndTouched = true;
        dnd = value;
        if (dnd) live.slice().forEach(w => hidePopup(w.key));
        save();
    }
    function toggleDnd() { setDnd(!dnd); }
    function find(key) { return live.find(w => w.key === key) || null; }
    function hidePopup(key) {
        var w = find(key);
        if (!w) return;
        w.popup = false;
        if (w.notification.transient) w.notification.expire();
    }
    function dismissPopups() { live.slice().forEach(w => hidePopup(w.key)); }
    function remove(key) {
        entries = entries.filter(e => e.id !== key);
        var w = find(key);
        if (w) w.notification.dismiss();
        save();
    }
    function clear() {
        if (!loaded) resetBeforeLoad = true;
        entries = [];
        live.slice().forEach(w => w.notification.dismiss());
        save();
    }
    function invoke(key, identifier) {
        var w = find(key);
        if (!w) return;
        var action = w.notification.actions.find(a => a.identifier === identifier);
        if (action) {
            entries = entries.map(e => e.id === key ? Object.assign({}, e, {read: true}) : e);
            w.popup = false;
            action.invoke();
            save();
        }
    }
    function reply(key, text) {
        var w = find(key);
        if (!w || !w.notification.hasInlineReply || !text.trim()) return;
        entries = entries.map(e => e.id === key ? Object.assign({}, e, {read: true}) : e);
        w.popup = false;
        w.notification.sendInlineReply(text.slice(0, 4000));
        save();
    }
    function refresh(w) {
        var n = w.notification;
        if (!n) return;
        var previous = entries.find(e => e.id === w.key);
        w.entry = {id: w.key, timestamp: Date.now(), appName: History.plain(n.appName).slice(0, 256) || "Application",
            appId: n.desktopEntry.slice(0, 256), summary: History.plain(n.summary).slice(0, 2048), body: History.plain(n.body),
            appIcon: n.appIcon.slice(0, 1024), urgency: n.urgency, read: centerOpen || (previous ? previous.read : false)};
        w.timeout = n.expireTimeout >= 0 ? n.expireTimeout : n.urgency === NotificationUrgency.Critical ? 0 : settings.options.popupTimeout;
        // Replacement notifications update one history entry and restart its popup.
        entries = entries.filter(e => e.id !== w.key);
        if (!n.transient) entries = [w.entry].concat(entries);
        w.popup = !centerOpen && !History.matches(settings.options.mutedApps, w.entry)
            && (!dnd || (settings.options.criticalBypassDnd && n.urgency === NotificationUrgency.Critical));
        w.restartTimer();
        live = live.slice();
        live.filter(item => item.popup).slice(settings.options.maxVisible).forEach(item => hidePopup(item.key));
        prune();
        save();
        if (!w.popup && n.transient) Qt.callLater(() => { if (w.notification) w.notification.expire(); });
    }
    function receive(n) {
        n.tracked = true;
        var w = wrapper.createObject(root, {notification: n,
            key: Date.now() + "-" + (++serial) + "-" + Math.random().toString(36).slice(2), output: focusedOutput});
        live = [w].concat(live);
        refresh(w);
    }
    function closed(w) {
        live = live.filter(item => item !== w);
        entries = entries.map(e => e.id === w.key ? Object.assign({}, e, {read: true}) : e);
        w.notification = null;
        save();
        Qt.callLater(() => w.destroy());
    }
    onCenterOpenChanged: if (centerOpen) { markRead(); dismissPopups(); }
    Connections {
        target: root.settings
        function onOptionsChanged() {
            root.prune();
            root.save();
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: { root.prune(); root.save(); } }

    Loader {
        active: root.enabled
        sourceComponent: Component {
            NotificationServer {
                keepOnReload: false
                actionsSupported: true
                imageSupported: true
                inlineReplySupported: true
                persistenceSupported: true
                // Content is rendered as plain text; never fetch remote body images.
                bodyMarkupSupported: false
                onNotification: n => root.receive(n)
            }
        }
    }
    Component {
        id: wrapper
        QtObject {
            id: item
            property var notification
            property string key
            property string output
            property var entry: ({})
            property bool popup: false
            property bool paused: false
            property int timeout: 6000
            function restartTimer() { if (popup && timeout > 0 && !paused) expiry.restart(); else expiry.stop(); }
            onPopupChanged: restartTimer()
            onPausedChanged: restartTimer()
            property Timer expiry: Timer { interval: Math.max(1, item.timeout); onTriggered: root.hidePopup(item.key) }
            property Timer update: Timer { interval: 0; onTriggered: root.refresh(item) }
            property Connections changes: Connections {
                target: item.notification
                function onSummaryChanged() { item.update.restart(); }
                function onBodyChanged() { item.update.restart(); }
                function onAppNameChanged() { item.update.restart(); }
                function onAppIconChanged() { item.update.restart(); }
                function onUrgencyChanged() { item.update.restart(); }
                function onActionsChanged() { item.update.restart(); }
                function onExpireTimeoutChanged() { item.update.restart(); }
                function onImageChanged() { item.update.restart(); }
                function onDesktopEntryChanged() { item.update.restart(); }
                function onTransientChanged() { item.update.restart(); }
                function onClosed() { item.update.stop(); root.closed(item); }
            }
        }
    }
    Timer {
        id: saveDelay
        interval: 100
        onTriggered: {
            if (!root.storageReady || root.writePending || !root.dirty) return;
            root.dirty = false;
            root.writePending = true;
            writeDeadline.restart();
            storage.write(JSON.stringify(root.snapshot()) + "\n");
        }
    }
    Timer { id: writeRetry; interval: 5000; onTriggered: root.save() }
    Timer {
        id: writeDeadline
        interval: 10000
        onTriggered: {
            root.storageError = "History storage timed out; notifications remain in memory";
            storage.signal(9);
        }
    }
    Timer { id: storageRetry; interval: 5000; onTriggered: storage.running = root.enabled }
    Process {
        id: storage
        running: root.enabled
        command: ["python3", "-u", decodeURIComponent(Qt.resolvedUrl("history-store.py").toString().replace(/^file:\/\//, ""))]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    var reply = JSON.parse(line);
                    if (reply.type === "ready") {
                        writeDeadline.stop();
                        root.storageReady = true;
                        root.writePending = false;
                        root.storageError = "";
                        root.storageWarning = reply.warning || "";
                        if (!root.loaded) {
                            if (!root.resetBeforeLoad && root.settings.options.historyEnabled) root.entries = root.entries.concat(reply.entries);
                            if (!root.dndTouched) root.setDnd(reply.dnd);
                            root.loaded = true;
                            root.prune();
                            if (root.centerOpen) root.markRead();
                        }
                        root.save();
                    } else if (reply.type === "error") {
                        writeDeadline.stop();
                        root.writePending = false;
                        root.storageError = reply.error;
                        writeRetry.restart();
                    } else if (reply.type === "saved") {
                        writeDeadline.stop();
                        root.writePending = false;
                        root.storageError = "";
                        if (root.dirty) saveDelay.start();
                    }
                } catch (error) { root.storageError = "Invalid history storage response"; }
            }
        }
        stderr: SplitParser { onRead: line => root.storageError = "Notification history helper failed" }
        onExited: {
            writeDeadline.stop();
            root.storageReady = false;
            root.writePending = false;
            root.storageError = root.storageError || "Notification history unavailable; changes remain in memory";
            storageRetry.restart();
        }
    }
}
