import QtQuick
import Quickshell
import "../bar" as Bar
import "../services"

Scope {
    id: root
    property bool opened: false
    property bool surfaceReady: false
    property var targetScreen: null
    property int barHeight: 24
    property alias service: themes
    function open() { opened = true; themes.refresh(); focusQuery.requestFocusedOutput(); }
    function close() { opened = false; surfaceReady = false; }
    function toggle() { if (opened) close(); else open(); }
    Service { id: themes; active: root.opened }
    Bar.BarPalette { id: colors }
    NiriService {
        id: focusQuery
        onFocusedOutput: name => {
            root.targetScreen = Quickshell.screens.find(screen => screen.name === name) || Quickshell.screens[0] || null;
            root.surfaceReady = root.opened;
        }
    }
    Panel {
        service: themes
        palette: colors
        opened: root.opened && root.surfaceReady
        targetScreen: root.targetScreen
        barHeight: root.barHeight
        onCloseRequested: root.close()
        onApplyRequested: name => themes.apply(name)
    }
}
