import QtQuick
import QtQuick.Controls

TextField {
    id: root
    required property var colors
    color: colors.text
    placeholderTextColor: colors.muted
    selectionColor: colors.accent
    selectedTextColor: colors.background
    padding: 10
    background: Rectangle {
        color: root.colors.surface
        radius: 6
        border.width: root.activeFocus ? 1 : 0
        border.color: root.colors.accent
    }
}
