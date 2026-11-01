import QtQuick
import Quickshell
import Quickshell.Io

// Share theme data, not QML imports, across the two independent configurations.
QtObject {
    id: root
    property var colors: ({})
    function get(name, fallback) { return colors[name] || fallback; }
    readonly property color background: get("background", "#0d0e11")
    readonly property color surface: get("surface", "#313244")
    readonly property color text: get("text", "#e7e3ff")
    readonly property color muted: get("muted", "#879099")
    readonly property color accent: get("accent", "#7e9cd8")
    readonly property color border: get("border", "#383850")
    property FileView file: FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/quickshell/dofs/bar/theme.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                var result = JSON.parse(text());
                var keys = ["background", "surface", "text", "muted", "accent", "border"];
                if (keys.some(key => typeof result[key] !== "string" || !/^#[\da-fA-F]{6}$/.test(result[key]))) return;
                root.colors = result;
            } catch (e) { /* Retain the last valid palette. */ }
        }
    }
}
