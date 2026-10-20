import QtQuick
import Quickshell.Io

// Launcher-only, on-demand query; no polling or bar state yet.
QtObject {
    id: root
    signal focusedOutput(string name)
    property bool pending: false

    function requestFocusedOutput() {
        if (pending) return;
        pending = true;
        timeout.restart();
        query.running = true;
    }

    function finish(name) {
        if (!pending) return;
        pending = false;
        timeout.stop();
        focusedOutput(name);
    }

    property Timer timeout: Timer {
        interval: 1500
        onTriggered: {
            root.finish("");
            query.running = false;
        }
    }

    property Process query: Process {
        command: ["niri", "msg", "--json", "focused-output"]
        property string output: ""
        onStarted: output = ""
        stdout: StdioCollector { onStreamFinished: query.output = text }
        onExited: (code, status) => {
            var name = "";
            try { name = JSON.parse(output).name || ""; } catch (error) {}
            root.finish(name);
        }
    }
}
