import QtQuick

Item {
    id: root
    required property var palette
    required property string title
    property string subtitle: ""
    property int titleSize: 20
    property int titleWeight: Font.DemiBold
    signal closeRequested()
    implicitHeight: Math.max(labels.implicitHeight, closeButton.implicitHeight)

    Column {
        id: labels
        anchors {
            left: parent.left
            right: closeButton.left
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        spacing: 5
        Text {
            width: parent.width
            text: root.title
            textFormat: Text.PlainText
            color: root.palette.text
            font.family: "Inter"
            font.pixelSize: root.titleSize
            font.weight: root.titleWeight
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: !!root.subtitle
            text: root.subtitle
            textFormat: Text.PlainText
            color: root.palette.muted
            font.family: "Inter"
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }
    NotificationButton {
        id: closeButton
        objectName: "controlCenterClose"
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        palette: root.palette
        text: "Close"
        onClicked: root.closeRequested()
    }
}
