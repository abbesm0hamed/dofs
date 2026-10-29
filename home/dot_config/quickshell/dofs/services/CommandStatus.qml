import QtQuick
import Quickshell
import Quickshell.Io

// One bounded process per shared data source, never per monitor. Pango
// output is treated as plain text, not executed or rendered as markup.
Scope {
    id: root
    property list<string> command: []
    property int interval: 30000
    property int timeout: 8000
    property bool enabled: true
    property bool json: true
    property var value: ({})
    property string error: ""
    property string output: ""
    property double startedAt: 0
    function refresh() { if (enabled && !process.running) process.running = true; }
    function plain(text) {
        return String(text || "").replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
    }
    onEnabledChanged: { if (enabled) refresh(); else { process.running = false; value = {}; } }
    Component.onCompleted: refresh()
    Timer { interval: root.interval; running: root.enabled && interval > 0; repeat: true; onTriggered: root.refresh() }
    Process {
        id: process
        // GNU timeout owns a process group, so a stuck script's children are
        // terminated too. A QML SIGTERM timer alone would not bound that tree.
        command: ["timeout", "--kill-after=1s", (root.timeout / 1000) + "s"].concat(root.command)
        onStarted: { root.output = ""; root.error = ""; root.startedAt = Date.now(); }
        stdout: StdioCollector { onStreamFinished: root.output = text.trim() }
        onExited: (code, status) => {
            if (code !== 0 || status !== 0) {
                // With --kill-after, GNU timeout may SIGKILL its own group.
                // QProcess reports that as CrashExit/9 rather than exit 137.
                var killedAtDeadline = status !== 0 && code === 9 && Date.now() - root.startedAt >= root.timeout;
                root.value = {};
                root.error = code === 124 || code === 137 || killedAtDeadline ? "Command timed out" : "Command unavailable";
                return;
            }
            try { root.value = root.json ? JSON.parse(root.output) : {text: root.output}; }
            catch (e) { root.value = {}; root.error = "Invalid status output"; }
        }
    }
}
