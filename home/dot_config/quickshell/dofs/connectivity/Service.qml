import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property bool active: false
    property var network: ({devices: [], networks: [], hotspots: []})
    property var bluetooth: ({adapters: [], devices: []})
    property var pairing: null
    property string hotspotPassword: ""
    property bool allowPasswordReply: false
    property string error: ""
    property string message: ""
    property bool busy: false
    property int serial: 0
    property int pending: -1
    property bool polling: false
    property bool loaded: false
    property bool ready: false
    property bool scanOnOpen: true
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("backend.py").toString().replace(/^file:\/\//, ""))
    onActiveChanged: {
        if (active) { scanOnOpen = true; loaded = false; }
        if (!active) {
            hideHotspotPassword(); pairing = null; error = ""; message = "";
            busy = false; polling = false; pending = -1;
        }
    }
    function hideHotspotPassword() { allowPasswordReply = false; hotspotPassword = ""; }
    function request(action, args) {
        if (!ready || busy) return;
        error = ""; message = "";
        allowPasswordReply = action === "hotspot-password";
        pending = ++serial;
        busy = true;
        backend.write(JSON.stringify(Object.assign({}, args || {}, {action: action, id: pending})) + "\n");
        deadline.restart();
    }
    function refresh() {
        if (!ready || polling || busy) return;
        polling = true;
        backend.write(JSON.stringify({action: "snapshot", id: 0}) + "\n");
    }
    function respond(accept, value) {
        if (!pairing || !pairing.id) return;
        backend.write(JSON.stringify({action: "pairing-response", token: pairing.id, accept: accept, value: value || ""}) + "\n");
        pairing = null;
    }
    function receive(line) {
        if (!active) return;
        try {
            var reply = JSON.parse(line);
            if (reply.pairing !== undefined) { pairing = reply.pairing; return; }
            if (reply.id === 0) polling = false;
            if (reply.id === pending) {
                busy = false; deadline.stop();
            }
            if (!reply.ok) { error = reply.error || "Connectivity request failed"; return; }
            var data = reply.data || {};
            if (data.network) {
                network = data.network; loaded = true;
                if (scanOnOpen) {
                    scanOnOpen = false;
                    if (network.enabled && !(network.hotspots || []).length)
                        Qt.callLater(() => root.request("scan-wifi"));
                }
            }
            if (data.bluetooth) bluetooth = data.bluetooth;
            if (data.hotspotPassword !== undefined && allowPasswordReply) hotspotPassword = data.hotspotPassword;
        } catch (e) { error = "Could not read connectivity status"; }
    }
    Process {
        id: backend
        command: ["/usr/bin/python3", "-u", root.helper]
        stdinEnabled: true
        running: root.active
        onStarted: { root.ready = true; root.refresh(); }
        stdout: SplitParser { onRead: line => root.receive(line) }
        onExited: {
            root.ready = false; root.busy = false; root.polling = false; deadline.stop();
            if (root.active) root.error = "Connectivity service stopped. Close and reopen this panel to retry.";
        }
    }
    Timer { interval: 5000; repeat: true; running: root.active; onTriggered: root.refresh() }
    Timer {
        id: deadline
        interval: 100000
        onTriggered: { root.error = "The request timed out. Close and reopen the panel to retry."; }
    }
}
