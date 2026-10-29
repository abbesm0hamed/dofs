import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Row {
    id: root
    required property var palette
    required property var panel
    height: parent.height
    spacing: 2
    Repeater {
        model: SystemTray.items
        delegate: BarButton {
            id: button
            required property var modelData
            visible: ["nm-applet", "blueman-applet"].indexOf(modelData.id) < 0
            width: visible ? 24 : 0
            height: root.height
            palette: root.palette
            tooltip: modelData.tooltipTitle || modelData.title || modelData.id
            Image { anchors.centerIn: parent; width: 14; height: 14; source: button.modelData.icon; sourceSize.width: 28; sourceSize.height: 28 }
            onClicked: mouseButton => {
                if (mouseButton === Qt.MiddleButton) modelData.secondaryActivate();
                else if (mouseButton === Qt.RightButton || modelData.onlyMenu) {
                    if (modelData.hasMenu) {
                        var point = button.mapToItem(root.panel.contentItem, 0, button.height);
                        modelData.display(root.panel, point.x, point.y);
                    }
                } else modelData.activate();
            }
            onScrolled: delta => modelData.scroll(delta, false)
        }
    }
}
