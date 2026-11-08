import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../notifications" as Notifications

PanelWindow {
    id: root
    required property var service
    required property var palette
    required property bool opened
    required property var targetScreen
    required property int barHeight
    property string selectionTarget: "workspace"
    property string query: ""
    readonly property var filtered: service.images.filter(image => image.name.toLowerCase().indexOf(query.toLowerCase()) >= 0)
    signal closeRequested()
    screen: targetScreen
    visible: opened
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "#55000000"
    WlrLayershell.namespace: "dofs-wallpaper-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenedChanged: {
        if (opened) { query = ""; grid.currentIndex = 0; search.forceActiveFocus(); }
    }
    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(1000, parent.width - 32)
        height: Math.min(800, parent.height - root.barHeight - 32)
        color: root.palette.background
        border.width: 1
        border.color: root.palette.border
        radius: 0
        MouseArea { anchors.fill: parent }
        Keys.onEscapePressed: root.closeRequested()
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16
            Notifications.PanelHeader {
                Layout.fillWidth: true
                palette: root.palette
                title: "Wallpapers"
                subtitle: "Workspace and overview backdrop · independent surfaces"
                titleSize: 24
                titleWeight: Font.Medium
                onCloseRequested: root.closeRequested()
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Repeater {
                    model: ["workspace", "backdrop"]
                    delegate: ColumnLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 6
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(140, card.height * 0.2)
                            color: root.palette.surface
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: modelData === "workspace" ? root.service.state.workspaceUrl : root.service.state.backdropUrl
                                sourceSize.width: 600
                                sourceSize.height: 280
                                asynchronous: true
                                cache: false
                                fillMode: Image.PreserveAspectCrop
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData === "workspace" ? "Workspace" : root.service.state.mode === "blur" ? "Backdrop · follows workspace blur" : "Backdrop · independent image"
                            color: root.palette.muted
                            font.family: "Inter"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Notifications.NotificationButton {
                    palette: root.palette
                    text: "Workspace"
                    active: root.selectionTarget === "workspace"
                    onClicked: root.selectionTarget = "workspace"
                }
                Notifications.NotificationButton {
                    palette: root.palette
                    text: "Backdrop"
                    active: root.selectionTarget === "backdrop"
                    onClicked: root.selectionTarget = "backdrop"
                }
                Item { Layout.fillWidth: true }
                Notifications.NotificationButton {
                    palette: root.palette
                    text: "Follow workspace blur"
                    active: root.service.state.mode === "blur"
                    enabled: !root.service.busy
                    onClicked: root.service.apply(["--blur"])
                }
            }
            TextField {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search wallpapers…"
                text: root.query
                onTextEdited: { root.query = text; grid.currentIndex = 0; }
                color: root.palette.text
                placeholderTextColor: root.palette.muted
                font.family: "Inter"
                font.pixelSize: 14
                padding: 12
                selectByMouse: true
                background: Rectangle {
                    color: root.palette.surface
                    border.width: 1
                    border.color: search.activeFocus ? root.palette.accent : root.palette.border
                    radius: 0
                }
                Keys.onDownPressed: { grid.forceActiveFocus(); grid.currentIndex = Math.max(0, grid.currentIndex); }
                onAccepted: {
                    if (root.filtered.length && !root.service.busy)
                        root.service.select(root.filtered[Math.max(0, grid.currentIndex)].path, root.selectionTarget);
                }
            }
            Text {
                Layout.fillWidth: true
                visible: !!(root.service.error || root.service.renderError)
                text: root.service.error || root.service.renderError
                textFormat: Text.PlainText
                color: root.palette.red
                font.family: "Inter"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Accessible.role: Accessible.AlertMessage
            }
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.filtered
                cellWidth: width / Math.max(1, Math.floor(width / 210))
                cellHeight: cellWidth * 0.62 + 32
                keyNavigationEnabled: true
                ScrollBar.vertical: ScrollBar {}
                Keys.onReturnPressed: {
                    if (currentIndex >= 0 && currentIndex < root.filtered.length && !root.service.busy)
                        root.service.select(root.filtered[currentIndex].path, root.selectionTarget);
                }
                delegate: Button {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool selected: modelData.path === (root.selectionTarget === "workspace"
                        ? root.service.state.workspace : root.service.state.backdrop)
                    width: grid.cellWidth - 12
                    height: grid.cellHeight - 12
                    enabled: !root.service.busy
                    padding: 6
                    focusPolicy: Qt.NoFocus
                    Accessible.name: "Set " + root.selectionTarget + " wallpaper to " + modelData.name
                    onClicked: { grid.currentIndex = index; root.service.select(modelData.path, root.selectionTarget); }
                    background: Rectangle {
                        color: tile.hovered || tile.selected ? root.palette.surface : "transparent"
                        border.width: 1
                        border.color: tile.selected || (grid.activeFocus && grid.currentIndex === tile.index)
                            ? root.palette.accent : tile.hovered ? root.palette.border : "transparent"
                        radius: 0
                    }
                    contentItem: Column {
                        spacing: 8
                        Image {
                            width: parent.width
                            height: tile.availableHeight - 24
                            source: tile.modelData.url
                            sourceSize.width: 320
                            sourceSize.height: 200
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            clip: true
                        }
                        Text {
                            width: parent.width
                            text: tile.modelData.name
                            textFormat: Text.PlainText
                            color: tile.selected ? root.palette.accent : root.palette.text
                            font.family: "Inter"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: !root.filtered.length
                    text: root.service.scanning ? "Loading wallpapers…" : "No wallpapers match your search."
                    color: root.palette.muted
                    font.family: "Inter"
                    font.pixelSize: 13
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.service.busy ? "Preparing wallpaper…" : root.filtered.length + " images · Choose " + root.selectionTarget + " · Arrows to browse · Enter to apply · Esc to close"
                color: root.palette.muted
                font.family: "Inter"
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }
}
