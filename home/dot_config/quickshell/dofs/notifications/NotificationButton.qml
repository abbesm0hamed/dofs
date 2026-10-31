import QtQuick
import QtQuick.Controls

Button {
    id: root
    required property var palette
    property bool active: false
    property bool destructive: false
    focusPolicy: Qt.StrongFocus
    padding: 8
    horizontalPadding: 10
    Accessible.name: text
    contentItem: Text {
        text: root.text
        textFormat: Text.PlainText
        color: root.destructive ? root.palette.red : root.active || root.hovered ? root.palette.accent : root.palette.text
        font.family: "Inter"
        font.pixelSize: 12
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 0
        color: root.down || root.hovered || root.active ? root.palette.surface : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: root.palette.accent
        Behavior on color { ColorAnimation { duration: 100 } }
    }
}
