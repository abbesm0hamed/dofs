import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property bool active: false
    property bool ready: false
    property bool loaded: false
    property bool busy: false
    property bool interacting: false
    property bool stopped: false
    property string error: ""
    property int serial: 0
    property int pending: -1
    property var queued: []
    property var data: ({sinks: [], sources: [], playback: [], recording: [], cards: []})
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("backend.py").toString().replace(/^file:\/\//, ""))
    onActiveChanged: {
        stopped = false;
        busy = false;
        interacting = false;
        queued = [];
        pending = -1;
        deadline.stop();
        if (active) { error = ""; loaded = false; }
    }
    function request(action, args) {
        if (!ready || !active || stopped) return;
        if (action === "snapshot" && (pending >= 0 || interacting)) return;
        if (pending >= 0) {
            var waiting = action === "volume" ? queued.filter(command => command.action !== "volume"
                || command.args.kind !== args.kind || command.args.index !== args.index) : queued;
            queued = waiting.concat([{action: action, args: args}]);
            return;
        }
        busy = action !== "snapshot";
        pending = ++serial;
        backend.write(JSON.stringify(Object.assign({}, args || {}, {action: action, id: pending})) + "\n");
        deadline.restart();
    }
    function update(entry, action, value) {
        request(action, {kind: entry.kind, index: entry.index, value: value});
    }
    function receive(line) {
        if (!active) return;
        try {
            var reply = JSON.parse(line);
            if (reply.id !== pending) return;
            busy = false;
            pending = -1;
            deadline.stop();
            if (reply.ok) {
                if (!interacting && !queued.length) data = reply.data;
                loaded = true; error = "";
            }
            else error = reply.error || "The audio request failed.";
            if (queued.length) {
                var next = queued[0];
                queued = queued.slice(1);
                request(next.action, next.args);
            }
        } catch (error) {
            root.error = "Could not read audio status.";
        }
    }
    Process {
        id: backend
        command: ["/usr/bin/python3", "-u", root.helper]
        stdinEnabled: true
        running: root.active && !root.stopped
        onStarted: { root.ready = true; root.request("snapshot"); }
        stdout: SplitParser { onRead: line => root.receive(line) }
        onExited: {
            root.ready = false; root.busy = false; root.pending = -1; root.queued = []; deadline.stop();
            if (root.active && !root.stopped)
                root.error = "Audio service stopped. Close and reopen the panel to retry.";
        }
    }
    Timer { interval: 3000; repeat: true; running: root.active; onTriggered: root.request("snapshot") }
    Timer {
        id: deadline
        interval: 60000
        onTriggered: {
            root.stopped = true;
            root.error = "The audio server timed out. Close and reopen the panel to retry.";
        }
    }
}
