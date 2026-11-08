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
    property alias service: wallpapers
    signal opening()
    function open() {
        opening();
        opened = true;
        wallpapers.scan();
        focusQuery.requestFocusedOutput();
    }
    function close() { opened = false; surfaceReady = false; }
    function toggle() { if (opened) close(); else open(); }
    Service { id: wallpapers }
    Bar.BarPalette { id: colors }
    NiriService {
        id: focusQuery
        onFocusedOutput: name => {
            root.targetScreen = Quickshell.screens.find(screen => screen.name === name) || Quickshell.screens[0] || null;
            root.surfaceReady = root.opened;
        }
    }
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.opened && Quickshell.screens.indexOf(root.targetScreen) < 0) root.close();
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            required property var modelData
            Surface {
                screen: modelData
                service: wallpapers
                roleName: "workspace"
                imageSource: wallpapers.state.workspaceUrl
                revision: wallpapers.state.revision
            }
            Surface {
                screen: modelData
                service: wallpapers
                roleName: "backdrop"
                imageSource: wallpapers.state.backdropUrl
                revision: wallpapers.state.revision
            }
        }
    }
    Panel {
        service: wallpapers
        palette: colors
        opened: root.opened && root.surfaceReady
        targetScreen: root.targetScreen
        barHeight: root.barHeight
        onCloseRequested: root.close()
    }
}
