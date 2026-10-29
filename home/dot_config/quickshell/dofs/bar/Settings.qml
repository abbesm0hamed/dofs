import QtQuick
import Quickshell.Io

QtObject {
    id: root
    readonly property var knownModules: ["visualizer", "media", "fingerprint", "updates", "tray", "monitoring", "brightness", "audio", "connectivity", "battery", "profile", "notifications", "idle", "power", "clock", "prayer"]
    property var config: ({height: 24, font: "Lilex Nerd Font Mono", fontSize: 13, outputs: [], showTitle: false, modules: knownModules})
    property string error: ""
    property FileView file: FileView {
        path: Qt.resolvedUrl("config.json")
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: root.error = "Cannot read bar/config.json; retaining last valid options"
        onLoaded: {
            try {
                var c = JSON.parse(text());
                if (!Number.isInteger(c.height) || c.height < 20 || c.height > 64
                    || typeof c.font !== "string" || !c.font
                    || !Number.isInteger(c.fontSize) || c.fontSize < 9 || c.fontSize > 24
                    || typeof c.showTitle !== "boolean"
                    || !Array.isArray(c.outputs) || c.outputs.some(o => typeof o !== "string")
                    || !Array.isArray(c.modules) || c.modules.some(m => root.knownModules.indexOf(m) < 0)
                    || new Set(c.modules).size !== c.modules.length)
                    throw new Error("Invalid bar options or duplicate/unknown module");
                root.config = c;
                root.error = "";
            } catch (e) { root.error = String(e); console.warn("Bar config:", e); }
        }
    }
}
