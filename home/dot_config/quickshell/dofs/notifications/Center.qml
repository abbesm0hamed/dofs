import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var service
    required property var palette
    required property bool opened
    required property var targetScreen
    required property int barHeight
    signal closeRequested()
    screen: targetScreen
    visible: opened
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "#33000000"
    WlrLayershell.namespace: "dofs-notification-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
    CenterPanel {
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right; topMargin: root.barHeight + 8; bottomMargin: 8; rightMargin: 8 }
        width: Math.min(implicitWidth, parent.width - 16)
        service: root.service
        palette: root.palette
        opened: root.opened
        onCloseRequested: root.closeRequested()
    }
}
