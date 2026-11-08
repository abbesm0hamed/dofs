import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property var config: ({
        launchers: ["app.zen_browser.zen", "md.obsidian.Obsidian", "separator",
            "com.t3tools.T3Code", "dev.zed.Zed", "com.mitchellh.ghostty", "com.termius.Termius",
            "separator", "com.github.IsmaelMartinez.teams_for_linux", "com.rtosta.zapzap",
            "com.slack.Slack", "com.discordapp.Discord", "separator", "steam"],
        showRunning: true,
        iconSize: 32,
        padding: 6,
        spacing: 2,
        margin: 8,
        outputs: []
    })
    property string error: ""
    property FileView file: FileView {
        path: Qt.resolvedUrl("config.json")
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: root.error = "Cannot read dock/config.json; retaining last valid options"
        onLoaded: {
            try {
                var c = JSON.parse(text());
                if (!Array.isArray(c.launchers) || c.launchers.some(l => typeof l !== "string")
                    || !Array.isArray(c.outputs) || c.outputs.some(o => typeof o !== "string")
                    || typeof c.showRunning !== "boolean"
                    || !Number.isInteger(c.iconSize) || c.iconSize < 24 || c.iconSize > 64
                    || !Number.isInteger(c.padding) || c.padding < 0 || c.padding > 24
                    || !Number.isInteger(c.spacing) || c.spacing < 0 || c.spacing > 32
                    || !Number.isInteger(c.margin) || c.margin < 0 || c.margin > 64)
                    throw new Error("Invalid dock options");
                root.config = c;
                root.error = "";
            } catch (e) { root.error = String(e); console.warn("Dock config:", e); }
        }
    }
}
