import QtQuick
import Quickshell.Io

// Dedicated shell palette, written by set-theme.sh or Matugen.
QtObject {
    id: root
    property var colors: ({})
    property string error: ""
    function get(name, fallback) { return colors[name] || fallback; }
    readonly property color background: get("background", "#0d0e11")
    readonly property color surface: get("surface", "#313244")
    readonly property color text: get("text", "#e7e3ff")
    readonly property color muted: get("muted", "#879099")
    readonly property color accent: get("accent", "#7e9cd8")
    readonly property color border: get("border", "#383850")
    readonly property color red: get("red", "#f38ba8")
    readonly property color yellow: get("yellow", "#f9e2af")
    readonly property color green: get("green", "#a6e3a1")
    property FileView file: FileView {
        path: Qt.resolvedUrl("theme.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoadFailed: root.error = "Cannot read bar/theme.json; retaining palette"
        onLoaded: {
            try {
                var result = JSON.parse(text());
                var keys = ["background", "surface", "text", "muted", "accent", "border", "red", "yellow", "green"];
                if (keys.some(key => typeof result[key] !== "string" || !/^#[\da-fA-F]{6}$/.test(result[key])))
                    throw new Error("Expected nine #RRGGBB shell colors");
                root.colors = result;
                root.error = "";
            } catch (error) {
                root.error = "Invalid bar/theme.json: " + String(error);
                console.warn("Shell theme: retaining last valid palette:", error);
            }
        }
    }
}
