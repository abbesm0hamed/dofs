import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var modelData
    required property var service
    required property var palette
    required property var settings
    required property bool shown
    property string configError: ""
    signal openEntry(string entry)
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: settings.height
    exclusiveZone: settings.height
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dofs-bar"
    visible: shown && Quickshell.env("DOFS_BAR_TEST") !== "1"
    color: palette.background
    readonly property var workspaces: service.niri.workspacesOn(screen.name)
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.palette.border }
    Row {
        id: left
        height: parent.height - 1
        BarButton {
            height: parent.height
            palette: root.palette
            fontFamily: root.settings.font
            fontSize: root.settings.fontSize
            highlighted: true
            icon: ""
            iconSize: root.settings.iconSize
            tooltip: root.configError || "Left: keybindings · right: launcher"
            foreground: root.configError ? root.palette.red : root.palette.text
            onClicked: button => root.openEntry(button === Qt.RightButton ? "" : "binds")
        }
        BarButton {
            visible: !root.service.niri.connected
            width: visible ? implicitWidth : 0
            height: parent.height
            palette: root.palette
            text: "!"
            foreground: root.palette.red
            tooltip: root.service.niri.streamError || "Connecting to Niri"
        }
        Repeater {
            model: root.workspaces
            delegate: BarButton {
                required property var modelData
                palette: root.palette
                height: left.height
                fontFamily: root.settings.font
                fontSize: root.settings.fontSize
                text: String(modelData.idx)
                tooltip: modelData.name || "Workspace " + modelData.idx
                selected: modelData.is_active
                flat: true
                padding: 4
                minimumWidth: 18
                bold: selected || hovered
                hoverForeground: root.palette.accent
                foreground: selected ? root.palette.accent : modelData.is_urgent ? root.palette.red : root.palette.muted
                onClicked: root.service.niri.focusWorkspace(modelData.id)
            }
        }
    }
    Text {
        anchors.left: left.right
        anchors.right: right.left
        anchors.margins: 10
        anchors.verticalCenter: parent.verticalCenter
        visible: root.settings.showTitle && width > 40
        text: root.service.niri.titleOn(root.screen.name)
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: root.palette.muted
        font.family: root.settings.font
        font.pixelSize: root.settings.fontSize
    }
    // On narrow outputs keep the clock end visible rather than overlap
    // workspaces. Drag horizontally to reach the rest of the configured modules.
    Flickable {
        id: right
        anchors.right: parent.right
        height: parent.height - 1
        width: Math.min(contentWidth, Math.max(0, root.width - left.width - 12))
        contentWidth: modules.width
        contentHeight: height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        Row {
            id: modules
            height: right.height
            Repeater {
                model: root.settings.modules
                delegate: StatusModule {
                    required property string modelData
                    name: modelData
                    service: root.service
                    palette: root.palette
                    settings: root.settings
                    panel: root
                    onOpenEntry: entry => root.openEntry(entry)
                }
            }
        }
        Component.onCompleted: contentX = Math.max(0, contentWidth - width)
        onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
        onWidthChanged: contentX = Math.max(0, contentWidth - width)
    }
}
