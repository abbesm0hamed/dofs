import QtQuick
import Quickshell
import "../bar" as Bar
import "../services"

Scope {
    id: root
    property bool opened: false
    property bool surfaceReady: false
    property var targetScreen: null
    property string tab: "wifi"
    property int barHeight: 24
    property alias service: connectivity
    signal opening()
    function open(section) {
        tab = ["wifi", "hotspot", "bluetooth"].indexOf(section) >= 0 ? section : "wifi";
        opening(); opened = true;
        focusQuery.requestFocusedOutput();
    }
    function close() { opened = false; surfaceReady = false; }
    Service { id: connectivity; active: root.opened }
    Bar.BarPalette { id: colors }
    NiriService {
        id: focusQuery
        onFocusedOutput: name => {
            root.targetScreen = Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0] || null;
            root.surfaceReady = root.opened;
        }
    }
    Connections {
        target: Quickshell
        function onScreensChanged() { if (root.opened && Quickshell.screens.indexOf(root.targetScreen) < 0) root.close(); }
    }
    Panel {
        service: connectivity
        palette: colors
        opened: root.opened && root.surfaceReady
        targetScreen: root.targetScreen
        barHeight: root.barHeight
        tab: root.tab
        onTabRequested: section => root.tab = section
        onCloseRequested: root.close()
    }
}
