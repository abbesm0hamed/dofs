import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // set-theme.sh already updates this file for every supported theme.
    // Reuse Niri's active border instead of maintaining another palette copy.
    property color activeBorder: accent
    property FileView niriColors: FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/niri/colors.kdl"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var match = text().match(/\bborder\s*\{[^}]*\bactive-color\s+"(#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)"/);
            if (match) root.activeBorder = match[1];
        }
    }
    readonly property color background: "#0d0e11"
    readonly property color surface: "#1b1c26"
    readonly property color selection: "#313244"
    readonly property color border: activeBorder
    readonly property color accent: "#7e9cd8"
    readonly property color text: "#e7e3ff"
    readonly property color muted: "#a6adc8"
    readonly property color error: "#f38ba8"
    readonly property string font: "Inter"
    readonly property string mono: "JetBrains Mono"
}
