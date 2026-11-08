import QtQuick
import Quickshell
import "../bar"

Scope {
    id: root
    // Shared widget palette: the dock is shell chrome, so it follows the same
    // theme.json as the bar instead of the app-level palette.
    property bool shown: true
    property alias options: dockSettings.config
    property alias paletteColors: colors.colors
    readonly property string configError: dockSettings.error
    DockSettings { id: dockSettings }
    BarPalette { id: colors }
    Variants {
        model: Quickshell.screens.filter(s => !dockSettings.config.outputs.length || dockSettings.config.outputs.indexOf(s.name) >= 0)
        Dock {
            palette: colors
            settings: dockSettings.config
            shown: root.shown
        }
    }
}
