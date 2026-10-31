import QtQuick
import Quickshell

Rectangle {
    id: root
    required property var palette
    property string icon: ""
    property int iconSize: fontSize
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
    property int padding: 4
    property int minimumWidth: 20
    property int maximumWidth: 10000
    property bool showTip: false
    signal clicked(int button)
    signal scrolled(int delta)
    readonly property int contentSpacing: icon && text ? 3 : 0
    readonly property real contentWidth: (icon ? iconSize : 0) + label.implicitWidth + contentSpacing
    readonly property color contentColor: hovered ? hoverForeground : foreground
    implicitHeight: parent ? parent.height : 24
    implicitWidth: Math.min(maximumWidth, Math.max(minimumWidth, contentWidth + padding * 2))
    color: !flat && (selected || highlighted) ? palette.surface : "transparent"
    Row {
        id: content
        anchors.centerIn: parent
        height: root.height
        width: Math.min(root.contentWidth, Math.max(0, root.width - root.padding * 2))
        spacing: root.contentSpacing
        BarIcon {
            id: symbol
            visible: !!root.icon
            width: visible ? root.iconSize : 0
            height: parent.height
            glyph: root.icon
            size: root.iconSize
            fontFamily: root.fontFamily
            color: root.contentColor
        }
        Text {
            id: label
            width: Math.max(0, content.width - symbol.width - content.spacing)
            height: parent.height
            text: root.text
            textFormat: Text.PlainText
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.bold: root.bold
            color: root.contentColor
        }
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
