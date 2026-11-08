import QtQuick

Rectangle {
    id: root
    required property string text
    required property color foreground
    required property color outline
    required property string fontFamily

    implicitWidth: Math.max(22, label.implicitWidth + 12)
    implicitHeight: 22
    radius: 0
    color: "transparent"
    border.width: 1
    border.color: outline

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: 10
    }
}
