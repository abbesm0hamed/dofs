import QtQuick
import Quickshell
import Quickshell.Widgets

// One dock tile: a pinned launcher, an unpinned running group, or a
// separator. Toplevels are live objects, so indicator bindings track the
// windows themselves, not the snapshot they came from.
Rectangle {
    id: root
    required property var palette
    required property var settings
    // Declare the Repeater role on this component so its bindings receive
    // the same app record as the delegate.
    required property var modelData
    // Windows on another output still count, but interactions prefer this
    // screen's windows so a monitor's dock acts on what it shows first.
    required property var targetScreen

    readonly property bool separator: !!modelData && modelData.kind === "separator"
    readonly property string name: modelData ? (modelData.entry ? modelData.entry.name : modelData.id) : ""
    readonly property var localWindows: modelData
        ? modelData.windows.filter(w => targetScreen && w.screens.indexOf(targetScreen) >= 0) : []
    readonly property bool running: !!modelData && modelData.windows.length > 0
    readonly property bool active: !!modelData && modelData.windows.some(w => w.activated)
    readonly property bool minimized: !!modelData && modelData.windows.length
        && !modelData.windows.some(w => !w.minimized)
    readonly property int size: settings.iconSize + settings.padding * 2
    implicitWidth: separator ? 2 : size
    implicitHeight: size
    radius: 8
    color: hovered && !separator ? Qt.rgba(palette.text.r, palette.text.g, palette.text.b, 0.08) : "transparent"
    readonly property bool hovered: mouse.containsMouse
    property bool showTip: false

    function iconSource(icon) {
        var value = String(icon || "");
        if (value.startsWith("/")) return Qt.resolvedUrl(value).toString();
        if (value.startsWith("file://") || value.startsWith("image://")) return value;
        return Quickshell.iconPath(value || "application-x-executable", true)
            || Quickshell.iconPath("application-x-executable", true);
    }

    // Prefer windows on this screen, falling back to everything the
    // application has on any output.
    function pool() {
        return localWindows.length ? localWindows : modelData.windows;
    }

    function launch() {
        // Use the resolved desktop id when one exists: raw window appIds do
        // not always match the desktop file GIO should start.
        var id = modelData.entry ? modelData.entry.id : modelData.id;
        var helper = decodeURIComponent(Qt.resolvedUrl("../launcher/launch.py").toString().replace(/^file:\/\//, ""));
        Quickshell.execDetached(["python3", helper, "app", id]);
    }

    function activate() {
        var list = pool();
        if (!list.length) { launch(); return; }
        var focused = list.find(w => w.activated);
        if (focused) { focused.minimized = true; return; }
        var target = list.find(w => !w.minimized) || list[0];
        target.minimized = false;
        target.activate();
    }

    function cycle() {
        var list = pool();
        if (!list.length) return;
        if (list.length === 1) { activate(); return; }
        var focused = list.findIndex(w => w.activated);
        var target = list[(focused + 1) % list.length];
        target.minimized = false;
        target.activate();
    }

    function closeFocused() {
        var list = pool();
        if (!list.length) return;
        var target = list.find(w => w.activated) || list[0];
        target.close();
    }

    Rectangle {
        visible: root.separator
        anchors.centerIn: parent
        width: 2
        height: parent.implicitHeight * 0.55
        radius: 1
        color: root.palette.border
    }

    IconImage {
        visible: !root.separator
        anchors.centerIn: parent
        width: root.settings.iconSize
        height: root.settings.iconSize
        source: root.iconSource(root.modelData && root.modelData.entry ? root.modelData.entry.icon : "")
        scale: root.hovered ? 1.14 : 1.0
        opacity: root.minimized ? 0.45 : 1.0
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Rectangle {
        visible: !root.separator && root.running
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        width: root.active || root.minimized ? 12 : 5
        height: 3
        radius: 2
        color: root.active || root.minimized ? root.palette.accent : root.palette.muted
        Behavior on width { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !root.separator
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: event => {
            showTip = false;
            if (event.button === Qt.LeftButton) root.activate();
            else if (event.button === Qt.RightButton) root.cycle();
            else root.closeFocused();
        }
        onEntered: delay.restart()
        onExited: { delay.stop(); showTip = false; }
    }

    Timer { id: delay; interval: 550; onTriggered: showTip = true }

    PopupWindow {
        anchor.item: root
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Top | Edges.Right
        visible: showTip && root.visible && !root.separator
        implicitWidth: Math.min(560, tip.implicitWidth + 20)
        implicitHeight: tip.implicitHeight + 14
        color: root.palette.surface
        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: root.palette.border }
        Text {
            id: tip
            anchors.fill: parent
            anchors.margins: 7
            text: root.running
                ? root.name + "\n" + root.modelData.windows.map(w => w.title || "(untitled)").slice(0, 4).join("\n")
                    + (root.modelData.windows.length > 4 ? "\n…" : "")
                : root.name
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: root.palette.text
            font.family: "Inter"
            font.pixelSize: 12
        }
    }
}
