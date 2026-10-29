import QtQuick
import Quickshell

Rectangle {
    id: root
    required property var palette
    property string text: ""
    property string tooltip: ""
    property string fontFamily: "Lilex Nerd Font Mono"
    property int fontSize: 13
    property color foreground: palette.text
    property color hoverForeground: palette.accent
    property bool selected: false
    property bool highlighted: false
    property bool flat: false
    property bool bold: false
    readonly property bool hovered: mouse.containsMouse
    property int padding: 8
    property int minimumWidth: 24
    property int maximumWidth: 10000
    property bool showTip: false
    signal clicked(int button)
    signal scrolled(int delta)
    implicitHeight: parent ? parent.height : 24
    implicitWidth: Math.min(maximumWidth, Math.max(minimumWidth, label.implicitWidth + padding * 2))
    color: !flat && (hovered || selected || highlighted) ? palette.surface : "transparent"
    Text {
        id: label
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        text: root.text
        textFormat: Text.PlainText
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.bold: root.bold
        color: root.hovered ? root.hoverForeground : root.foreground
    }
    Rectangle { visible: root.selected && !root.flat; anchors.bottom: parent.bottom; width: parent.width; height: 2; color: root.palette.accent }
    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: event => { root.showTip = false; root.clicked(event.button); }
        onWheel: event => { if (event.angleDelta.y) root.scrolled(event.angleDelta.y); event.accepted = true; }
        onEntered: delay.restart()
        onExited: { delay.stop(); root.showTip = false; }
    }
    Timer { id: delay; interval: 550; onTriggered: root.showTip = true }
    PopupWindow {
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        visible: root.showTip && root.visible && root.tooltip.length > 0
        implicitWidth: Math.min(560, tip.implicitWidth + 20)
        implicitHeight: tip.implicitHeight + 14
        color: root.palette.surface
        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: root.palette.border }
        Text {
            id: tip
            anchors.fill: parent
            anchors.margins: 7
            text: root.tooltip
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: root.palette.text
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
        }
    }
}
