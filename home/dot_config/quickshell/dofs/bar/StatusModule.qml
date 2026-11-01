import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Small fixed module catalog, not a plugin host. Data and process lifetimes
// belong to the one BarService, not these per-output presentation components.
Row {
    id: root
    required property string name
    required property var service
    required property var palette
    required property var settings
    required property var panel
    signal openEntry(string entry)
    height: parent.height
    readonly property var stats: service.stats
    function command(args) { service.run(args); }
    function legacy(name) { command(service.script(name)); }
    function terminal(args) { command(["ghostty", "-e"].concat(args)); }
    function percent(n) { return n === undefined || n === null ? "—" : Math.round(n) + "%"; }
    function statusLabel(status) { return status.plain(status.value.text).replace(/^\S+\s*/, ""); }
    Loader {
        height: root.height
        sourceComponent: {
            switch (root.name) {
            case "visualizer": return visualizer;
            case "media": return media;
            case "fingerprint": return fingerprint;
            case "updates": return updates;
            case "tray": return tray;
            case "monitoring": return monitoring;
            case "brightness": return brightness;
            case "audio": return audio;
            case "connectivity": return connectivity;
            case "battery": return battery;
            case "profile": return profile;
            case "notifications": return notifications;
            case "idle": return idle;
            case "power": return power;
            case "clock": return clock;
            case "prayer": return prayer;
            default: return null;
            }
        }
    }
    component Button: BarButton {
        palette: root.palette
        fontFamily: root.settings.font
        fontSize: root.settings.fontSize
        iconSize: root.settings.iconSize
        height: root.height
    }
    Component {
        id: visualizer
        Button {
            visible: !!root.service.visualizerText
            width: visible ? implicitWidth : 0
            text: root.service.visualizerText
            foreground: root.palette.accent
            tooltip: "Left: mixer · right: Cava terminal"
            onClicked: button => { if (button === Qt.RightButton) root.terminal(["cava"]); else root.command(["pavucontrol"]); }
        }
    }
    Component {
        id: media
        Button {
            visible: !!root.service.player
            width: visible ? implicitWidth : 0
            icon: root.service.player && root.service.player.isPlaying ? "󰐊" : "󰏤"
            tooltip: root.service.player ? [root.service.player.identity, root.service.player.trackTitle, root.service.player.trackArtist].filter(Boolean).join("\n") : ""
            onClicked: button => {
                var p = root.service.player;
                if (!p) return;
                if (button === Qt.RightButton && p.canGoNext) p.next();
                else if (button === Qt.MiddleButton && p.canGoPrevious) p.previous();
                else if (button === Qt.LeftButton && p.canTogglePlaying) p.togglePlaying();
            }
            onScrolled: delta => { var p = root.service.player; if (p && p.canControl && p.volumeSupported) p.volume = Math.max(0, Math.min(1, p.volume + (delta > 0 ? 0.05 : -0.05))); }
        }
    }
    Component {
        id: fingerprint
        Button {
            visible: !!root.service.fingerprint.value.text
            width: visible ? implicitWidth : 0
            icon: root.service.fingerprint.plain(root.service.fingerprint.value.text)
            tooltip: root.service.fingerprint.plain(root.service.fingerprint.value.tooltip)
            foreground: root.palette.yellow
            onClicked: root.terminal(["bash", root.service.configDir + "/quickshell/dofs/scripts/fingerprint-setup.sh", "setup"])
        }
    }
    Component {
        id: updates
        Button {
            visible: !!root.service.updates.value.text
            width: visible ? implicitWidth : 0
            icon: "󰚰"
            text: root.statusLabel(root.service.updates)
            tooltip: root.service.updates.plain(root.service.updates.value.tooltip)
            onClicked: root.terminal(["bash", Quickshell.env("HOME") + "/dofs/dofs", "update"])
        }
    }
    Component { id: tray; Tray { palette: root.palette; panel: root.panel; iconSize: root.settings.iconSize } }
    Component {
        id: monitoring
        Row {
            id: monitoringGroup
            property bool expanded: false
            height: root.height
            Item {
                id: metricsDrawer
                objectName: "monitoringMetrics"
                width: monitoringGroup.expanded ? metrics.width : 0
                height: parent.height
                clip: true
                visible: width > 0
                enabled: monitoringGroup.expanded
                Behavior on width {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Row {
                    id: metrics
                    anchors.right: parent.right
                    height: parent.height
                    Button {
                        visible: !!root.service.docker.value.text
                        width: visible ? implicitWidth : 0
                        icon: "󰡨"
                        text: root.statusLabel(root.service.docker)
                        tooltip: root.service.docker.plain(root.service.docker.value.tooltip)
                        onClicked: root.terminal(["lazydocker"])
                    }
                    Button { icon: "󰋊"; text: root.percent(root.stats.storage); tooltip: "Home filesystem usage"; onClicked: root.terminal(["btop"]) }
                    Button { icon: ""; text: root.percent(root.stats.memory); tooltip: "Memory: " + (root.stats.memoryUsedGiB || "—") + " / " + (root.stats.memoryTotalGiB || "—") + " GiB"; onClicked: root.terminal(["btop"]) }
                    Button { icon: ""; text: root.percent(root.stats.cpu); tooltip: root.service.statsConnected ? "CPU usage" : "System sampler unavailable; retrying"; onClicked: root.terminal(["btop"]) }
                }
            }
            Button {
                objectName: "monitoringToggle"
                icon: monitoringGroup.expanded ? "" : ""
                tooltip: monitoringGroup.expanded ? "Hide performance metrics" : "Show performance metrics"
                onClicked: button => {
                    if (button === Qt.LeftButton)
                        monitoringGroup.expanded = !monitoringGroup.expanded;
                }
            }
        }
    }
    Component {
        id: brightness
        Button {
            visible: root.stats.brightness !== undefined && root.stats.brightness !== null
            width: visible ? implicitWidth : 0
            highlighted: true
            icon: "󰃠"
            text: root.percent(root.stats.brightness)
            tooltip: "Brightness · scroll to adjust"
            onScrolled: delta => root.service.brightness(delta)
        }
    }
    Component {
        id: audio
        Button {
            readonly property var sink: root.service.sink
            readonly property var audio: sink && sink.ready ? sink.audio : null
            highlighted: true
            icon: !audio || audio.muted ? "󰖁" : ""
            text: !audio ? "—" : audio.muted ? "" : root.percent(audio.volume * 100)
            tooltip: audio ? (sink.description || "Audio") + "\nLeft: mixer · right: mute · middle: mute microphone\nMicrophone: " + (root.service.source && root.service.source.ready && root.service.source.audio ? (root.service.source.audio.muted ? "muted" : "on") : "unavailable") : "Audio device unavailable"
            onClicked: button => {
                if (button === Qt.LeftButton) root.command(["pavucontrol"]);
                else root.service.toggleMute(button === Qt.MiddleButton);
            }
            onScrolled: delta => root.service.changeVolume(delta > 0 ? 0.05 : -0.05, false)
        }
    }
    Component {
        id: connectivity
        Row {
            height: root.height
            Button {
                readonly property var adapter: root.service.adapter
                icon: adapter && adapter.enabled ? "󰂯" : "󰂲"
                tooltip: adapter ? adapter.name + (adapter.enabled ? " · on" : " · off") + "\nLeft: manager · right: toggle power" : "Bluetooth adapter unavailable"
                onClicked: button => { if (button === Qt.RightButton && adapter) adapter.enabled = !adapter.enabled; else root.command(["blueman-manager"]); }
            }
            Button {
                readonly property string status: root.service.network.value.text || ""
                readonly property bool connected: /:connected:/.test(status)
                icon: connected ? (/:wifi:connected:/.test(status) ? "󰤨" : "󰛳") : "󰤭"
                tooltip: root.service.network.error || status || "Network unavailable"
                onClicked: root.command(["nm-connection-editor"])
            }
        }
    }
    Component {
        id: battery
        Button {
            readonly property var device: root.service.battery
            visible: device.ready && device.isLaptopBattery && device.isPresent
            width: visible ? implicitWidth : 0
            readonly property bool charging: device.state === UPowerDeviceState.Charging
            icon: charging ? "󰂄" : "󰁹"
            text: root.percent(device.percentage * 100)
            foreground: charging ? root.palette.green : device.percentage < 0.15 ? root.palette.red : device.percentage < 0.30 ? root.palette.yellow : root.palette.text
            tooltip: "Battery: " + root.percent(device.percentage * 100) + "\nPower: " + Math.abs(device.changeRate).toFixed(1) + " W\n" + (charging ? "Full in " : "Remaining ") + Math.round((charging ? device.timeToFull : device.timeToEmpty) / 60) + " min"
            onClicked: root.openEntry("controls")
        }
    }
    Component {
        id: profile
        Button {
            icon: PowerProfiles.profile === PowerProfile.PowerSaver ? "" : PowerProfiles.profile === PowerProfile.Performance ? "" : ""
            foreground: PowerProfiles.profile === PowerProfile.PowerSaver ? root.palette.green : root.palette.accent
            tooltip: "Power profile: " + (PowerProfiles.profile === PowerProfile.PowerSaver ? "power saver" : PowerProfiles.profile === PowerProfile.Performance ? "performance" : "balanced") + "\nClick to cycle"
            onClicked: root.service.cycleProfile()
        }
    }
    Component {
        id: notifications
        Button {
            icon: root.service.notifications.dnd ? "󰂛" : "󰂞"
            text: root.service.notifications.unreadCount ? String(root.service.notifications.unreadCount) : ""
            foreground: root.service.notifications.unreadCount ? root.palette.accent : root.palette.text
            tooltip: root.service.notifications.error || root.service.notifications.unreadCount + " unread · Left: history · right: do not disturb (" + (root.service.notifications.dnd ? "on" : "off") + ")"
            onClicked: button => { if (button === Qt.RightButton) root.service.notifications.toggleDnd(); else if (button === Qt.LeftButton) root.openEntry("notifications"); }
        }
    }
    Component {
        id: idle
        Button {
            icon: root.service.idle.inhibited ? "󰾪" : "󰅶"
            foreground: root.service.idle.inhibited ? root.palette.yellow : root.palette.text
            tooltip: "Idle locking: " + (root.service.idle.inhibited ? "off · keeping awake" : "on")
                + "\nClick to toggle" + (root.service.idle.error ? "\n" + root.service.idle.error : "")
            onClicked: root.service.idle.toggle()
        }
    }
    Component { id: power; Button { icon: ""; tooltip: "Power menu"; onClicked: root.openEntry("power") } }
    Component {
        id: clock
        Button {
            SystemClock { id: time; precision: SystemClock.Minutes }
            highlighted: true
            highlightColor: Qt.darker(root.palette.surface, 1.5)
            text: Qt.formatDateTime(time.date, "dd, HH:mm")
            tooltip: Qt.formatDateTime(time.date, "dddd, d MMMM yyyy")
        }
    }
    Component {
        id: prayer
        Button {
            highlighted: true
            text: root.service.prayer.value.text || "Prayer —"
            tooltip: root.service.prayer.error || "Next prayer: " + text
            maximumWidth: 180
        }
    }
}
