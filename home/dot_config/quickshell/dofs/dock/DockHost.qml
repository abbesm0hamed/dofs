import QtQuick
import Quickshell
import Quickshell.Io
import "../bar"

Scope {
    id: root
    // Shared widget palette: the dock is shell chrome, so it follows the same
    // theme.json as the bar instead of the app-level palette.
    // Visibility persists to the state directory so a hidden dock stays hidden
    // across restarts. stateLoaded gates writes until the saved value is read,
    // otherwise the startup default would overwrite it.
    property bool shown: true
    property bool stateLoaded: false
    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/dofs/dock.json"
    property alias options: dockSettings.config
    property alias paletteColors: colors.colors
    readonly property string configError: dockSettings.error

    function persist() {
        if (!stateLoaded) return;
        // Pass the payload and path as positional args so no quoting is needed.
        writer.command = ["sh", "-c", "mkdir -p -- \"$(dirname -- \"$2\")\" && printf '%s\\n' \"$1\" > \"$2\"",
            "sh", JSON.stringify({shown: shown}), statePath];
        writer.running = true;
    }

    onShownChanged: persist()

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                var saved = JSON.parse(text());
                if (typeof saved.shown === "boolean") root.shown = saved.shown;
            } catch (e) { console.warn("Dock state:", e); }
            root.stateLoaded = true;
        }
        onLoadFailed: root.stateLoaded = true
    }

    Process {
        id: writer
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) console.warn("Dock state:", text.trim());
            }
        }
    }

    DockSettings { id: dockSettings }
    BarPalette { id: colors }
    Variants {
        model: Quickshell.screens.filter(s => !dockSettings.config.outputs.length || dockSettings.config.outputs.indexOf(s.name) >= 0)
        Dock {
            palette: colors
            settings: dockSettings.config
            shown: root.stateLoaded && root.shown
        }
    }
}
