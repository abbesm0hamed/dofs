import QtQuick
import Quickshell
import Quickshell.Io
import "NiriState.js" as State

// The launcher keeps its bounded on-demand focused-output query. Only the
// bar's shared instance enables the event stream (never one per output).
QtObject {
    id: root
    property bool watchEvents: false
    property bool connected: false
    property string streamError: ""
    property var state: State.initial()
    property int reconnectDelay: 500
    function workspacesOn(output) { return State.onOutput(state, output); }
    function titleOn(output) { return State.titleOnOutput(state, output); }
    function focusWorkspace(id) {
        // CLI workspace references are names/indices, not stable ids. Send an
        // explicit Id over a separate socket so another output cannot win a race.
        Quickshell.execDetached(["python3", decodeURIComponent(Qt.resolvedUrl("niri-action.py").toString().replace(/^file:\/\//, "")), String(id)]);
    }
    onWatchEventsChanged: {
        if (watchEvents) events.running = true;
        else { reconnect.stop(); events.running = false; }
    }
    property Process events: Process {
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    var event = JSON.parse(line);
                    root.state = State.reduce(root.state, event);
                    root.connected = true;
                    root.streamError = "";
                    // Reset only after a healthy connection, not a single line
                    // from a rapidly failing process.
                    stable.start();
                } catch (error) { console.warn("Niri event:", error); }
            }
        }
        stderr: SplitParser { onRead: line => console.warn("Niri:", line) }
        onExited: {
            stable.stop();
            root.connected = false;
            root.state = State.initial();
            root.streamError = "Niri disconnected; reconnecting";
            if (root.watchEvents) {
                reconnect.interval = root.reconnectDelay;
                root.reconnectDelay = Math.min(30000, root.reconnectDelay * 2);
                reconnect.restart();
            }
        }
    }
    property Timer stable: Timer { interval: 10000; onTriggered: root.reconnectDelay = 500 }
    property Timer reconnect: Timer { onTriggered: events.running = root.watchEvents }
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
