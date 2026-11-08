import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../notifications" as Notifications

Rectangle {
    id: root
    required property var entry
    required property var service
    required property var palette
    readonly property bool stream: entry.kind === "sink-input" || entry.kind === "source-output"
    readonly property var devices: entry.kind === "sink-input" ? service.data.sinks : service.data.sources
    implicitHeight: content.implicitHeight + 28
    radius: 0
    color: Qt.alpha(palette.text, 0.035)
    border.width: 1
    border.color: entry.default ? Qt.alpha(palette.accent, 0.35) : Qt.alpha(palette.text, 0.07)
    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    Layout.fillWidth: true
                    text: root.entry.description
                    textFormat: Text.PlainText
                    color: root.palette.text
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: !!text
                    text: root.entry.detail
                    textFormat: Text.PlainText
                    color: root.palette.muted
                    font.family: "Inter"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
            Notifications.NotificationButton {
                palette: root.palette
                visible: !root.stream
                text: root.entry.default ? "Default" : "Set default"
                active: root.entry.default
                enabled: !root.service.busy && !root.entry.default
                onClicked: root.service.update(root.entry, "default")
            }
            Notifications.NotificationButton {
                palette: root.palette
                text: root.entry.muted ? "Unmute" : "Mute"
                active: root.entry.muted
                enabled: !root.service.busy
                onClicked: root.service.update(root.entry, "mute", !root.entry.muted)
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Slider {
                id: volume
                Layout.fillWidth: true
                from: 0
                to: 100
                stepSize: 1
                value: root.entry.volume
                enabled: root.entry.canVolume && root.service.ready
                Accessible.name: root.entry.description + " volume"
                onMoved: { if (!pressed) root.service.update(root.entry, "volume", value); }
                onPressedChanged: {
                    root.service.interacting = pressed;
                    if (!pressed) root.service.update(root.entry, "volume", value);
                }
                background: Rectangle {
                    x: volume.leftPadding
                    y: volume.topPadding + volume.availableHeight / 2 - height / 2
                    width: volume.availableWidth
                    height: 4
                    radius: 0
                    color: Qt.alpha(root.palette.text, 0.12)
                    Rectangle {
                        width: volume.visualPosition * parent.width
                        height: parent.height
                        color: root.entry.muted ? root.palette.muted : root.palette.accent
                    }
                }
                handle: Rectangle {
                    x: volume.leftPadding + volume.visualPosition * (volume.availableWidth - width)
                    y: volume.topPadding + volume.availableHeight / 2 - height / 2
                    implicitWidth: 10
                    implicitHeight: 16
                    radius: 0
                    color: volume.activeFocus ? root.palette.text : root.palette.accent
                    opacity: volume.enabled ? 1 : 0.4
                }
            }
            Text {
                Layout.preferredWidth: 42
                text: root.entry.canVolume ? Math.round(volume.value) + "%" : "—"
                color: root.palette.muted
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
            }
        }
        Choice {
            Layout.fillWidth: true
            palette: root.palette
            label: root.entry.description + (root.stream ? " device" : " port")
            visible: root.stream || root.entry.ports.length > 1
            enabled: !root.service.busy
            choices: root.stream ? root.devices.map(device => ({name: String(device.index), description: device.description}))
                : root.entry.ports
            selected: root.stream ? String(root.entry.target) : root.entry.activePort
            onEditingChanged: root.service.interacting = editing
            onChosen: value => {
                if (root.stream)
                    root.service.request("move", {kind: root.entry.kind, index: root.entry.index, target: Number(value)});
                else root.service.update(root.entry, "port", value);
            }
        }
    }
}
