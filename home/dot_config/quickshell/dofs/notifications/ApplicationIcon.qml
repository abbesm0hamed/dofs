import QtQuick
import Quickshell

Item {
    id: root
    property string appIcon: ""
    property string appId: ""
    property string appName: ""
    implicitWidth: 20
    implicitHeight: 20
    readonly property url fallbackSource: Qt.resolvedUrl("icons/application.svg")
    readonly property var candidates: iconCandidates()
    property int candidateIndex: 0
    readonly property int status: image.status
    readonly property url source: image.source
    readonly property bool usingFallback: image.source.toString() === fallbackSource.toString()
    onCandidatesChanged: candidateIndex = 0

    function iconUrl(value) {
        value = String(value || "").trim();
        if (!value) return "";
        if (value.startsWith("image://icon/")) value = value.slice("image://icon/".length);
        if (value.startsWith("/"))
            return "file://" + value.split("/").map(part => encodeURIComponent(part)).join("/");
        // Only local files and theme icons: never fetch network resources.
        if (/^file:\/\/(?:\/|localhost\/)/.test(value)) return value.replace(/^file:\/\/localhost\//, "file:///");
        if (!/^[\w.+@-]+$/.test(value)) return "";
        return Quickshell.iconPath(value, true)
            || Quickshell.iconPath(value.replace(/\.(png|svg|xpm|ico)$/i, ""), true);
    }
    function iconCandidates() {
        // Observe index changes, including Flatpak exports in XDG_DATA_DIRS.
        var applications = DesktopEntries.applications.values;
        var id = appId.replace(/\.desktop$/i, "");
        var desktop = (id ? DesktopEntries.heuristicLookup(id) : null)
            || (appName ? DesktopEntries.heuristicLookup(appName) : null)
            || applications.find(app => app.name.toLowerCase() === appName.toLowerCase());
        var values = [appIcon, desktop ? desktop.icon : "", id];
        var result = [];
        values.forEach(value => {
            var url = iconUrl(value);
            if (url && result.indexOf(url) < 0) result.push(url);
        });
        result.push(fallbackSource.toString());
        return result;
    }
    Image {
        id: image
        anchors.fill: parent
        source: root.candidates[root.candidateIndex] || root.fallbackSource
        sourceSize.width: Math.ceil(root.width * 2)
        sourceSize.height: Math.ceil(root.height * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        onStatusChanged: {
            if (status !== Image.Error || root.candidateIndex >= root.candidates.length - 1) return;
            var failedSource = source.toString(), failedIndex = root.candidateIndex;
            // A bad or deleted application icon must not leave an empty slot.
            Qt.callLater(() => {
                if (image.source.toString() === failedSource && root.candidateIndex === failedIndex)
                    root.candidateIndex++;
            });
        }
    }
}
