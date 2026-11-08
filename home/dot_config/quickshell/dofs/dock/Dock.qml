import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

// One compact floating pill per output. Match the surface to the pill so
// compositor background blur stays confined to the dock.
PanelWindow {
    id: root
    required property var modelData
    required property var palette
    required property var settings
    required property bool shown
    screen: modelData
    anchors { bottom: true }
    margins.bottom: settings.margin
    readonly property int containerPadding: 6
    implicitWidth: row.implicitWidth + containerPadding * 2
    implicitHeight: settings.iconSize + settings.padding * 2 + containerPadding * 2
    exclusionMode: ExclusionMode.Ignore
    visible: shown && Quickshell.env("DOFS_DOCK_TEST") !== "1"
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dofs-dock"
    focusable: false

    mask: Region { item: pill }

    // Running windows grouped by application. Modal dialogs are skipped: they
    // are filed under their main window and activating that is close enough.
    readonly property var groups: buildGroups(ToplevelManager.toplevels.values)
    readonly property var entries: buildEntries()

    function buildGroups(toplevels) {
        var result = [];
        toplevels.forEach(t => {
            if (t.parent) return;
            var group = result.find(group => group.appId === t.appId);
            if (group) group.windows.push(t);
            else result.push({appId: t.appId || "", entry: desktopEntryFor(t.appId), windows: [t]});
        });
        return result;
    }

    function desktopEntryFor(name) {
        if (!name) return null;
        return DesktopEntries.byId(name) || DesktopEntries.heuristicLookup(name);
    }

    // Launchers pin desktop ids, but flatpak ids and raw window appIds
    // disagree often enough that exact, heuristic and last-dotted-segment
    // lookups are all tried before treating a pin as launch-only.
    function pinEntry(id) {
        var value = String(id || "");
        if (!value) return null;
        return DesktopEntries.byId(value)
            || DesktopEntries.byId(value + ".desktop")
            || DesktopEntries.heuristicLookup(value)
            || (value.indexOf(".") >= 0 ? DesktopEntries.heuristicLookup(value.split(".").pop()) : null);
    }

    function sameApp(a, b) {
        if (!a || !b) return false;
        a = String(a).toLowerCase();
        b = String(b).toLowerCase();
        return a === b || a.endsWith("." + b) || b.endsWith("." + a);
    }

    function buildEntries() {
        // Pinned launchers are desktop ids resolved independently of window
        // appIds. Take a dependency on the application index too: it loads
        // asynchronously and pins need it to resolve their icons.
        var applications = DesktopEntries.applications.values;
        var result = [];
        var consumed = [];
        var launchers = Array.isArray(settings.launchers) ? settings.launchers : [];
        launchers.forEach(id => {
            if (id === "separator") { result.push({kind: "separator", id: "", entry: null, windows: []}); return; }
            var entry = pinEntry(id);
            var group = groups.find(group => consumed.indexOf(group) < 0
                && (sameApp(group.appId, id) || (group.entry && entry && sameApp(group.entry.id, entry.id))));
            if (group) consumed.push(group);
            result.push({kind: "app", id: id, entry: entry, windows: group ? group.windows : []});
        });
        if (settings.showRunning) groups.forEach(group => {
            if (consumed.indexOf(group) >= 0) return;
            result.push({kind: "app", id: group.appId, entry: group.entry, windows: group.windows});
        });
        // Collapse leading separators and consecutive runs; trailing ones go
        // at the end. Everything collapses away when no launchers resolve and
        // no windows are open.
        var collapsed = [];
        var applicationsSeen = false;
        result.forEach(item => {
            if (item.kind === "separator") {
                if (!applicationsSeen) return;
                if (collapsed.length && collapsed[collapsed.length - 1].kind === "separator") return;
            } else applicationsSeen = true;
            collapsed.push(item);
        });
        while (collapsed.length && collapsed[collapsed.length - 1].kind === "separator") collapsed.pop();
        return collapsed;
    }

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: 12
        border.width: 0
        // A softly lit tint keeps the surface glassy without an outline.
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(root.palette.surface.r, root.palette.surface.g,
                    root.palette.surface.b, 0.32)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(root.palette.background.r, root.palette.background.g,
                    root.palette.background.b, 0.20)
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: root.settings.spacing
            Repeater {
                model: root.entries
                delegate: DockItem {
                    palette: root.palette
                    settings: root.settings
                    targetScreen: root.screen
                }
            }
        }
    }
}
