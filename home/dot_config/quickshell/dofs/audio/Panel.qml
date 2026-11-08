import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../notifications" as Notifications

PanelWindow {
    id: root
    required property var service
    required property var palette
    required property bool opened
    required property var targetScreen
    required property int barHeight
    required property string tab
    signal tabRequested(string section)
    signal closeRequested()
    readonly property var entries: tab === "output" ? service.data.sinks
        : tab === "input" ? service.data.sources.filter(source => !source.monitor) : []
    screen: targetScreen
    visible: opened
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "#33000000"
    WlrLayershell.namespace: "dofs-audio"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenedChanged: { if (opened) card.forceActiveFocus(); }
    onTabChanged: { if (root.service) root.service.interacting = false; }
    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
    Rectangle {
        id: card
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right; topMargin: root.barHeight + 8; bottomMargin: 8; rightMargin: 8 }
        width: Math.min(540, parent.width - 16)
        radius: 0
        color: root.palette.background
        border.width: 1
        border.color: Qt.alpha(root.palette.text, 0.12)
        MouseArea { anchors.fill: parent }
        focus: true
        Keys.onEscapePressed: root.closeRequested()
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16
            Notifications.PanelHeader {
                Layout.fillWidth: true
                palette: root.palette
                title: "Sound"
                subtitle: "Devices, applications and routing"
                titleSize: 24
                titleWeight: Font.Medium
                onCloseRequested: root.closeRequested()
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [{key: "output", title: "Output"}, {key: "input", title: "Input"},
                        {key: "apps", title: "Applications"}, {key: "profiles", title: "Profiles"}]
                    delegate: Notifications.NotificationButton {
                        required property var modelData
                        palette: root.palette
                        text: modelData.title
                        active: root.tab === modelData.key
                        onClicked: root.tabRequested(modelData.key)
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                visible: !!root.service.error
                text: root.service.error
                textFormat: Text.PlainText
                color: root.palette.red
                font.family: "Inter"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Accessible.role: Accessible.AlertMessage
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                clip: true
                ColumnLayout {
                    width: parent.width
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        visible: !root.service.loaded
                        text: root.service.busy ? "Connecting to the audio server…" : "Audio devices are unavailable."
                        color: root.palette.muted
                        font.family: "Inter"
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                    Repeater {
                        model: root.entries.length
                        delegate: Node {
                            required property int index
                            Layout.fillWidth: true
                            entry: root.entries[index]
                            service: root.service
                            palette: root.palette
                        }
                    }
                    Text {
                        visible: root.service.loaded && (root.tab === "output" || root.tab === "input") && !root.entries.length
                        text: root.tab === "output" ? "No output devices connected." : "No microphones connected."
                        color: root.palette.muted
                        font.family: "Inter"
                        font.pixelSize: 12
                    }
                    Repeater {
                        model: root.tab === "apps" ? 2 : 0
                        delegate: ColumnLayout {
                            id: streamGroup
                            required property int index
                            readonly property string title: index === 0 ? "PLAYBACK" : "RECORDING"
                            readonly property var entries: index === 0 ? root.service.data.playback : root.service.data.recording
                            Layout.fillWidth: true
                            spacing: 12
                            Text { text: streamGroup.title; color: root.palette.muted; font.family: "Inter"; font.pixelSize: 11; font.letterSpacing: 1.2 }
                            Repeater {
                                model: streamGroup.entries.length
                                delegate: Node {
                                    required property int index
                                    Layout.fillWidth: true
                                    entry: streamGroup.entries[index]
                                    service: root.service
                                    palette: root.palette
                                }
                            }
                            Text {
                                visible: !streamGroup.entries.length
                                text: streamGroup.title === "PLAYBACK" ? "No applications playing audio." : "No applications recording audio."
                                color: root.palette.muted
                                font.family: "Inter"
                                font.pixelSize: 12
                            }
                        }
                    }
                    Repeater {
                        model: root.tab === "profiles" ? root.service.data.cards.length : 0
                        delegate: ColumnLayout {
                            required property int index
                            readonly property var modelData: root.service.data.cards[index]
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                Layout.fillWidth: true
                                text: modelData.description
                                textFormat: Text.PlainText
                                color: root.palette.text
                                font.family: "Inter"
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                            Choice {
                                Layout.fillWidth: true
                                palette: root.palette
                                label: modelData.description + " profile"
                                choices: modelData.profiles
                                selected: modelData.activeProfile
                                enabled: !root.service.busy
                                onEditingChanged: root.service.interacting = editing
                                onChosen: value => root.service.request("profile", {index: modelData.index, value: value})
                            }
                        }
                    }
                    Text {
                        visible: root.service.loaded && root.tab === "profiles" && !root.service.data.cards.length
                        text: "No hardware profiles available."
                        color: root.palette.muted
                        font.family: "Inter"
                        font.pixelSize: 12
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.alpha(root.palette.text, 0.09) }
            Text {
                Layout.fillWidth: true
                text: root.tab === "profiles" ? "Changing profiles can interrupt playback or disconnect a microphone."
                    : root.tab === "input" ? "Muted microphones stay muted when their volume changes."
                    : "Volume is limited to 100%. Route running applications in the Applications tab."
                color: root.palette.muted
                font.family: "Inter"
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }
    }
}
