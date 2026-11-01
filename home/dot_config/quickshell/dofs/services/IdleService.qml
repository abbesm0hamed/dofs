import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// One native idle policy for the whole shell, independent of bar visibility.
Scope {
    id: root
    property bool active: true
    property bool sleepIntegration: true
    property bool inhibited: false
    property int screenTimeout: 600
    property int lockTimeout: 900
    property bool monitorsOff: false
    property bool sleepReady: false
    property string error: ""
    readonly property bool timersEnabled: active && !inhibited

    function toggle() {
        inhibited = !inhibited;
        Quickshell.execDetached(["timeout", "3s", "notify-send", "--app-name=dofs", "--icon=system-suspend",
            "Idle locking " + (inhibited ? "disabled" : "enabled"),
            "Automatic locking and monitor idle timeouts are " + (inhibited ? "off." : "on.")]);
    }
    function wake() {
        if (!monitorsOff) return;
        monitorsOff = false;
        Quickshell.execDetached(["timeout", "3s", "niri", "msg", "action", "power-on-monitors"]);
    }
    function screenIdleChanged(idle) {
        if (!idle) { wake(); return; }
        if (!timersEnabled || monitorsOff) return;
        monitorsOff = true;
        Quickshell.execDetached(["timeout", "3s", "niri", "msg", "action", "power-off-monitors"]);
    }
    function lock() {
        if (!active) return;
        if (sleepReady) sleepBridge.write("lock\n");
        else Quickshell.execDetached(["hyprlock", "--immediate-render", "--no-fade-in"]);
    }
    onInhibitedChanged: if (inhibited) wake()

    Loader {
        active: root.active
        sourceComponent: Component {
            Scope {
                IdleMonitor {
                    timeout: root.screenTimeout
                    enabled: root.timersEnabled
                    respectInhibitors: true
                    onIsIdleChanged: root.screenIdleChanged(isIdle)
                }
                IdleMonitor {
                    timeout: root.lockTimeout
                    enabled: root.timersEnabled
                    respectInhibitors: true
                    onIsIdleChanged: if (isIdle && root.timersEnabled) root.lock()
                }
            }
        }
    }

    // logind sleep/lock signals are separate from Wayland inactivity. The small
    // bridge holds a delay inhibitor until Niri confirms the session is locked.
    Process {
        id: sleepBridge
        running: root.active && root.sleepIntegration && !retry.running
        command: ["/usr/bin/python3", "-u", decodeURIComponent(Qt.resolvedUrl("session-lock.py").toString().replace(/^file:\/\//, ""))]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    var event = JSON.parse(line);
                    if (event.type === "ready") { root.sleepReady = true; root.error = ""; }
                    else if (event.type === "resume") root.wake();
                    else if (event.type === "error") root.error = event.message;
                } catch (e) { root.error = "Invalid session lock response"; }
            }
        }
        onExited: {
            root.sleepReady = false;
            root.error = "Session sleep/lock integration unavailable; retrying";
            if (root.active && root.sleepIntegration) retry.restart();
        }
    }
    Timer { id: retry; interval: 5000 }
}
