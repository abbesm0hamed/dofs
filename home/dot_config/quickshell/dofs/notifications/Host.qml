import QtQuick
import Quickshell
import Quickshell.Wayland
import "../bar" as Bar
import "../services"

Scope {
    id: root
    required property var niri
    property int barHeight: 24
    property bool opened: false
    property bool surfaceReady: false
    property var targetScreen: null
    property alias service: notifications
    property alias options: notificationSettings.options
    signal opening()
    readonly property bool testing: Quickshell.env("DOFS_BAR_TEST") === "1"
    readonly property string focusedOutput: {
        var workspace = niri.state.workspaces.find(w => w.is_focused);
        return workspace ? workspace.output || "" : "";
    }
    Settings { id: notificationSettings }
    Bar.BarPalette { id: colors }
    Service { id: notifications; settings: notificationSettings; centerOpen: root.opened; focusedOutput: root.focusedOutput }
    NiriService {
        id: focusQuery
        onFocusedOutput: name => {
            root.targetScreen = Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0] || null;
            root.surfaceReady = root.opened;
        }
    }
    function open() {
        opening();
        opened = true;
        focusQuery.requestFocusedOutput();
    }
    function close() { opened = false; surfaceReady = false; }
    function toggle() { if (opened) close(); else open(); }
    Connections {
        target: Quickshell
        function onScreensChanged() { if (root.opened && Quickshell.screens.indexOf(root.targetScreen) < 0) root.close(); }
    }
    Center {
        service: notifications
        palette: colors
        opened: root.opened && root.surfaceReady && !root.testing
        targetScreen: root.targetScreen
        barHeight: root.barHeight
        onCloseRequested: root.close()
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: window
            required property var modelData
            screen: modelData
            readonly property var popups: notifications.popups.filter(w => {
                var target = Quickshell.screens.find(s => s.name === w.output) || Quickshell.screens[0];
                return target === modelData;
            })
            anchors { top: true; right: true }
            margins { top: root.barHeight + 8; right: 8 }
            implicitWidth: Math.min(notificationSettings.options.toastWidth, screen ? screen.width - 16 : notificationSettings.options.toastWidth)
            implicitHeight: Math.min(stack.implicitHeight, screen ? Math.max(1, screen.height - root.barHeight - 16) : stack.implicitHeight)
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: !root.testing && popups.length > 0
            WlrLayershell.namespace: "dofs-notifications"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region { item: stack }
            Column {
                id: stack
                width: parent.width
                spacing: 6
                Repeater {
                    id: cards
                    model: window.popups
                    delegate: Card {
                        required property var modelData
                        width: stack.width
                        height: implicitHeight
                        entry: modelData.entry
                        service: notifications
                        palette: colors
                        toast: true
                        onOpenCenter: root.open()
                    }
                }
                add: Transition { NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 140 } }
                move: Transition { NumberAnimation { properties: "y"; duration: 140; easing.type: Easing.OutCubic } }
            }
        }
    }
}
