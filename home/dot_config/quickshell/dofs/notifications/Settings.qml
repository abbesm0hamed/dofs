import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property var options: ({historyEnabled: true, historyLimit: 200, retentionDays: 7,
        popupTimeout: 6000, maxVisible: 3, toastWidth: 380, padding: 15, criticalBypassDnd: false,
        mutedApps: [], privateApps: []})
    property string error: ""
    property FileView file: FileView {
        path: Qt.resolvedUrl("config.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoadFailed: root.error = "Cannot read notifications/config.json; retaining last valid options"
        onLoaded: {
            try {
                var c = JSON.parse(text());
                // Existing configs keep working; both surfaces share this value.
                if (c.padding === undefined) c.padding = 15;
                var ranges = {historyLimit: [1, 500], retentionDays: [1, 365],
                    popupTimeout: [1000, 60000], maxVisible: [1, 5], toastWidth: [280, 600], padding: [0, 32]};
                if (typeof c.historyEnabled !== "boolean" || typeof c.criticalBypassDnd !== "boolean"
                    || Object.keys(ranges).some(k => !Number.isInteger(c[k]) || c[k] < ranges[k][0] || c[k] > ranges[k][1])
                    || [c.mutedApps, c.privateApps].some(a => !Array.isArray(a) || a.some(s => typeof s !== "string" || !s.trim())))
                    throw new Error("Invalid notification options");
                root.options = c;
                root.error = "";
            } catch (error) { root.error = String(error); }
        }
    }
}
