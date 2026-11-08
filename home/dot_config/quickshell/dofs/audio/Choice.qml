import QtQuick
import QtQuick.Controls

ComboBox {
    id: root
    required property var palette
    required property string label
    property var choices: []
    property string selected: ""
    readonly property bool editing: popup.visible
    signal chosen(string value)
    model: choices
    textRole: "description"
    valueRole: "name"
    currentIndex: choices.findIndex(choice => choice.name === selected)
    implicitHeight: 34
    leftPadding: 10
    rightPadding: 26
    Accessible.name: label
    onActivated: root.chosen(String(currentValue))
    contentItem: Text {
        text: root.displayText
        textFormat: Text.PlainText
        color: root.enabled ? root.palette.text : root.palette.muted
        font.family: "Inter"
        font.pixelSize: 12
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Text {
        x: root.width - width - 10
        anchors.verticalCenter: parent.verticalCenter
        text: "⌄"
        color: root.palette.muted
    }
    background: Rectangle {
        radius: 0
        color: Qt.alpha(root.palette.text, 0.04)
        border.width: 1
        border.color: root.activeFocus ? root.palette.accent : Qt.alpha(root.palette.text, 0.12)
    }
    delegate: ItemDelegate {
        id: option
        required property var modelData
        required property int index
        width: root.width
        enabled: modelData.available !== false
        highlighted: root.highlightedIndex === index
        contentItem: Text {
            text: option.modelData.description
            textFormat: Text.PlainText
            color: !option.enabled ? root.palette.muted : option.highlighted ? root.palette.accent : root.palette.text
            font.family: "Inter"
            font.pixelSize: 12
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 0
            color: option.highlighted ? root.palette.surface : "transparent"
        }
    }
    popup: Popup {
        y: root.height + 2
        width: root.width
        padding: 4
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 260)
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollBar.vertical: ScrollBar {}
        }
        background: Rectangle {
            radius: 0
            color: root.palette.background
            border.width: 1
            border.color: Qt.alpha(root.palette.text, 0.16)
        }
    }
}
