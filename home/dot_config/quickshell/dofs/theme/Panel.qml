import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
    signal applyRequested(string name)
    screen: targetScreen
    visible: opened
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "#33000000"
    WlrLayershell.namespace: "dofs-themes"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenedChanged: if (opened) card.forceActiveFocus()
    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
    Rectangle {
        id: card
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right; topMargin: root.barHeight + 8; bottomMargin: 8; rightMargin: 8 }
        width: Math.min(440, parent.width - 16)
        color: root.palette.background
        border.width: 1
        border.color: Qt.alpha(root.palette.text, 0.14)
        MouseArea { anchors.fill: parent }
        focus: true
        Keys.onEscapePressed: root.closeRequested()
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14
            Text { text: "Appearance"; color: root.palette.text; font.family: "Inter"; font.pixelSize: 23; font.weight: Font.Medium }
            Text { text: "Choose a session theme"; color: root.palette.muted; font.family: "Inter"; font.pixelSize: 12 }
            TextField {
                id: query
                Layout.fillWidth: true
                placeholderText: "Search themes…"
                color: root.palette.text
                placeholderTextColor: root.palette.muted
                background: Rectangle { color: Qt.alpha(root.palette.text, 0.045); border.color: Qt.alpha(root.palette.text, 0.12) }
                Keys.onDownPressed: themeList.forceActiveFocus()
            }
            Text { visible: !!root.service.error; Layout.fillWidth: true; text: root.service.error; color: root.palette.red; wrapMode: Text.Wrap }
            ListView {
                id: themeList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.service.themes.filter(name => name.toLowerCase().includes(query.text.toLowerCase()))
                currentIndex: model.length ? 0 : -1
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    width: themeList.width
                    height: 54
                    color: index === themeList.currentIndex ? Qt.alpha(root.palette.accent, 0.15) : hover.containsMouse ? Qt.alpha(root.palette.text, 0.05) : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                        Text { Layout.fillWidth: true; text: modelData; color: root.palette.text; font.family: "Inter"; font.pixelSize: 14 }
                        Text { text: modelData === root.service.current ? "ACTIVE" : ""; color: root.palette.accent; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                    }
                    MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; onClicked: root.applyRequested(modelData) }
                    Keys.onReturnPressed: root.applyRequested(modelData)
                }
                Keys.onUpPressed: if (currentIndex > 0) currentIndex--
                Keys.onDownPressed: if (currentIndex < count - 1) currentIndex++
                Keys.onReturnPressed: if (currentIndex >= 0) root.applyRequested(model[currentIndex])
            }
            Text { text: "↑ ↓ navigate  ·  Enter apply  ·  Esc close"; color: root.palette.muted; font.family: "Inter"; font.pixelSize: 11 }
        }
    }
}
