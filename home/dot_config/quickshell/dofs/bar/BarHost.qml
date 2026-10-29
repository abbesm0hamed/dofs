import QtQuick
import Quickshell
import "../services"

Scope {
    id: root
    property bool shown: true
    signal openEntry(string entry)
    property alias service: sharedService
    property alias options: barSettings.config
    readonly property string configError: barSettings.error || colors.error
    property alias paletteColors: colors.colors
    Settings { id: barSettings }
    BarPalette { id: colors }
    BarService { id: sharedService; modules: barSettings.config.modules }
    Variants {
        model: Quickshell.screens.filter(s => !barSettings.config.outputs.length || barSettings.config.outputs.indexOf(s.name) >= 0)
        Bar {
            service: sharedService
            palette: colors
            settings: barSettings.config
            shown: root.shown
            configError: root.configError
            onOpenEntry: entry => root.openEntry(entry)
        }
    }
}
