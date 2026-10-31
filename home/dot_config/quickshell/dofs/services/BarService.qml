import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Bluetooth

Scope {
    id: root
    required property var modules
    required property var notifications
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var battery: UPower.displayDevice
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players[0] || null
    property var stats: ({})
    property string visualizerText: ""
    property bool statsConnected: false
    property bool statsTimedOut: false
    property alias niri: niri
    property alias docker: docker
    property alias fingerprint: fingerprint
    property alias updates: updates
    property alias prayer: prayer
    property alias network: network
    property alias idle: idle
    readonly property bool testing: Quickshell.env("DOFS_BAR_TEST") === "1"
    function has(module) { return modules.indexOf(module) >= 0; }
    function script(name) { return ["bash", configDir + "/quickshell/dofs/scripts/" + name + ".sh"]; }
    function run(command) { Quickshell.execDetached(command); }
    function changeVolume(delta, microphone) {
        var node = microphone ? source : sink;
        if (node && node.ready && node.audio) node.audio.volume = Math.max(0, Math.min(1, node.audio.volume + delta));
    }
    function toggleMute(microphone) {
        var node = microphone ? source : sink;
        if (node && node.ready && node.audio) node.audio.muted = !node.audio.muted;
    }
    function brightness(delta) {
        if (delta > 0) run(["brightnessctl", "set", "+5%"]);
        else run(["sh", "-c", "max=$(brightnessctl max) || exit; current=$(brightnessctl get) || exit; min=$((max * 5 / 100)); new=$((current - max * 5 / 100)); [ \"$new\" -ge \"$min\" ] || new=$min; brightnessctl set \"$new\""]);
    }
    function cycleProfile() {
        if (PowerProfiles.profile === PowerProfile.PowerSaver) PowerProfiles.profile = PowerProfile.Balanced;
        else if (PowerProfiles.profile === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile) PowerProfiles.profile = PowerProfile.Performance;
        else PowerProfiles.profile = PowerProfile.PowerSaver;
    }
    NiriService { id: niri; watchEvents: true }
    PwObjectTracker { objects: [root.sink, root.source].filter(n => n !== null) }
    Process {
        id: visualizer
        command: ["python3", "-u", root.configDir + "/quickshell/dofs/scripts/cava.py", "--bars", "5", "--framerate", "15", "--palette", "default"]
        running: !root.testing && root.has("visualizer") && !visualizerRetry.running
        stdout: SplitParser { onRead: line => root.visualizerText = line.replace(/<[^>]*>/g, "") }
        onExited: { root.visualizerText = ""; if (!root.testing && root.has("visualizer")) visualizerRetry.restart(); }
    }
    Timer { id: visualizerRetry; interval: 10000 }
    Process {
        id: statsProcess
        command: ["python3", "-u", decodeURIComponent(Qt.resolvedUrl("system-stats.py").toString().replace(/^file:\/\//, ""))]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try { root.stats = JSON.parse(line); root.statsConnected = true; root.statsTimedOut = false; statsDeadline.restart(); }
                catch (e) { console.warn("System stats:", e); }
            }
        }
        onStarted: statsDeadline.restart()
        onExited: { statsDeadline.stop(); root.stats = {}; root.statsConnected = false; statsRestart.restart(); }
    }
    Timer { id: statsDeadline; interval: 10000; onTriggered: { root.statsTimedOut = true; statsProcess.running = false; } }
    Timer { id: statsRestart; interval: 5000; onTriggered: statsProcess.running = true }
    CommandStatus { id: docker; enabled: !root.testing && root.has("monitoring"); command: root.script("docker-event-status"); interval: 30000 }
    CommandStatus { id: fingerprint; enabled: !root.testing && root.has("fingerprint"); command: root.script("fingerprint-status"); interval: 30000 }
    CommandStatus { id: updates; enabled: !root.testing && root.has("updates"); command: root.script("check-updates"); interval: 3600000; timeout: 120000 }
    CommandStatus { id: prayer; enabled: !root.testing && root.has("prayer"); command: root.script("next-prayer"); interval: 60000; timeout: 45000; json: false }
    // Quickshell has no NetworkManager API in the supported release. One shared
    // nmcli snapshot is sufficient; no connection subprocesses per widget.
    CommandStatus { id: network; enabled: !root.testing && root.has("connectivity"); command: ["nmcli", "--terse", "--fields", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]; interval: 10000; json: false }
    CommandStatus { id: idle; enabled: !root.testing && root.has("idle"); command: ["sh", "-c", "if pgrep -x swayidle >/dev/null; then printf on; else printf off; fi"]; interval: 5000; json: false }
}
