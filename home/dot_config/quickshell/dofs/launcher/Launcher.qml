import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../services"
import "Search.js" as Search

Scope {
    id: root

    property bool opened: false
    property bool surfaceReady: false
    property var targetScreen: null
    property string errorMessage: ""
    property string configError: ""
    property string historyError: ""
    property var historyIds: []
    property bool historyReadAgain: false
    property var actions: []
    property var hiddenApps: ({})
    property var actionParent: null
    property string savedQuery: ""
    property int savedIndex: 0
    property string filter: "All"
    property alias query: search.text
    readonly property int selectedIndex: list.currentIndex
    readonly property bool searchFocused: search.activeFocus
    readonly property var applications: DesktopEntries.applications.values
    readonly property var results: buildResults()

    Theme { id: theme }
    NiriService {
        id: niri
        onFocusedOutput: name => {
            root.targetScreen = Quickshell.screens.find(screen => screen.name === name)
                || Quickshell.screens[0] || null;
            root.surfaceReady = root.opened;
            if (root.opened) Qt.callLater(() => search.forceActiveFocus());
        }
    }

    function open() {
        actionParent = null;
        filter = "All";
        errorMessage = "";
        search.text = "";
        opened = true;
        refreshHistory();
        niri.requestFocusedOutput();
        Qt.callLater(() => search.forceActiveFocus());
    }
    function close() { opened = false; surfaceReady = false; }
    function toggle() { if (opened) close(); else open(); }
    function refreshHistory() {
        if (historyReader.running) historyReadAgain = true;
        else historyReader.running = true;
    }
    function clearHistory() {
        if (!historyClear.running) historyClear.running = true;
    }
    Component.onCompleted: refreshHistory()

    function localPath(file) {
        return decodeURIComponent(Qt.resolvedUrl(file).toString().replace(/^file:\/\//, ""));
    }
    function iconSource(icon) {
        var value = String(icon || "");
        if (value.startsWith("/")) return Qt.resolvedUrl(value).toString();
        if (value.startsWith("file://") || value.startsWith("image://")) return value;
        return Quickshell.iconPath(value || "application-x-executable", true)
            || Quickshell.iconPath("application-x-executable", true);
    }

    function buildResults() {
        var query = search.text.trim();
        if (actionParent) {
            return Search.search(actionParent.app.actions.map(action => ({
                name: action.name, description: actionParent.name,
                icon: action.icon || actionParent.icon, kind: "shortcut", shortcut: action,
                app: actionParent.app
            })), query);
        }
        var entries = [];
        if (filter !== "Actions") {
            applications.forEach(app => {
                if (!app.noDisplay && !hiddenApps[app.id]) entries.push({
                    name: app.name, description: app.genericName || app.comment || app.id,
                    searchText: [app.genericName, app.comment, app.id, app.keywords.join(" ")].join(" "),
                    icon: app.icon, kind: "app", app: app
                });
            });
        }
        if (filter !== "Apps") {
            actions.forEach(action => entries.push({
                name: action.name, description: action.description || "Quick action",
                searchText: (action.keywords || "") + " " + (action.description || ""),
                icon: action.icon || "system-run", kind: "action", command: action.command
            }));
            if (historyIds.length) entries.push({name: "Clear launch history",
                description: "Forget recently launched apps on this device",
                icon: "edit-clear", kind: "clearHistory"});
        }
        var found = Search.search(entries, query);
        if (filter === "All") {
            var result = Search.calculate(query);
            if (result !== null) found.unshift({name: result, description: "Copy result · " + query,
                icon: "accessories-calculator", kind: "calculator", value: result});
            if (query.startsWith("?")) {
                var terms = query.slice(1).trim();
                if (terms) found.unshift({name: "Search the web for “" + terms + "”",
                    description: "Open in your default browser", icon: "web-browser", kind: "action",
                    command: ["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(terms)]});
            }
        }
        return !query && filter !== "Actions" ? Search.withRecents(found, historyIds) : found;
    }

    function moveSelection(delta) {
        if (!results.length) return;
        list.currentIndex = (Math.max(0, list.currentIndex) + delta + results.length) % results.length;
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }
    function showAppActions() {
        var entry = results[list.currentIndex];
        if (!entry || entry.kind !== "app" || !entry.app.actions.length) return;
        savedQuery = search.text;
        savedIndex = list.currentIndex;
        actionParent = entry;
        search.text = "";
    }
    function back() {
        actionParent = null;
        search.text = savedQuery;
        list.currentIndex = savedIndex;
    }
    function fail(message) {
        errorMessage = message;
        opened = true;
        niri.requestFocusedOutput();
    }
    function run(command, label, workingDirectory, appId, historyId) {
        errorMessage = "";
        var expanded = command.map(arg => arg === "~" ? Quickshell.env("HOME")
            : arg.startsWith("~/") ? Quickshell.env("HOME") + arg.slice(1) : arg);
        var helper = localPath("launch.py");
        var process = runner.createObject(root, {
            command: appId ? ["python3", helper, "app", appId]
                : ["python3", helper, "command", JSON.stringify(expanded), workingDirectory || "", historyId || ""],
            label: label
        });
        close();
        process.running = true;
    }
    function activate(index) {
        var entry = results[index];
        if (!entry) return;
        if (entry.kind === "app") {
            if (entry.app.runInTerminal) {
                var terminalCommand = Search.appCommand(entry.app.command);
                if (!terminalCommand.length) { fail("This terminal entry has no command."); return; }
                run(["ghostty", "-e"].concat(terminalCommand), entry.name, entry.app.workingDirectory, "", entry.app.id);
            } else {
                run([], entry.name, "", entry.app.id);
            }
        } else if (entry.kind === "shortcut") {
            // DesktopAction exposes a parsed argument array, not a shell command.
            var command = Search.appCommand(entry.shortcut.command);
            if (!command.length) { fail("This application shortcut has no command."); return; }
            if (entry.app.runInTerminal) command = ["ghostty", "-e"].concat(command);
            run(command, entry.name, entry.app.workingDirectory, "", entry.app.id);
        } else if (entry.kind === "calculator") {
            run(["wl-copy", "--", entry.value], "Copy result");
        } else if (entry.kind === "clearHistory") {
            clearHistory();
        } else {
            run(entry.command, entry.name);
        }
    }

    onResultsChanged: list.currentIndex = results.length ? 0 : -1

    Process {
        id: historyReader
        command: ["python3", root.localPath("launch.py"), "history"]
        stdout: StdioCollector { id: historyOutput }
        stderr: StdioCollector { id: historyReadError }
        onExited: (code, status) => {
            try {
                if (code !== 0 || status !== 0) throw new Error(historyReadError.text.trim());
                var ids = JSON.parse(historyOutput.text);
                if (JSON.stringify(ids) !== JSON.stringify(root.historyIds)) root.historyIds = ids;
            } catch (error) { root.historyError = "Could not read app history: " + error.message; }
            if (root.historyReadAgain) {
                root.historyReadAgain = false;
                Qt.callLater(() => root.refreshHistory());
            }
        }
    }
    Process {
        id: historyClear
        command: ["python3", root.localPath("launch.py"), "clear-history"]
        stderr: StdioCollector { id: historyClearError }
        onExited: (code, status) => {
            if (code !== 0 || status !== 0) {
                root.historyError = "Could not clear app history: " + historyClearError.text.trim();
                return;
            }
            root.historyError = "";
            root.historyIds = [];
            root.refreshHistory();
            search.text = "";
            search.forceActiveFocus();
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { hiddenScanDelay.restart(); }
    }
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.opened && Quickshell.screens.indexOf(root.targetScreen) < 0) root.close();
        }
    }
    Timer {
        id: hiddenScanDelay
        interval: 150
        running: true
        onTriggered: {
            if (hiddenScan.running) restart();
            else hiddenScan.running = true;
        }
    }
    Process {
        id: hiddenScan
        command: ["python3", root.localPath("launch.py"), "hidden"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var next = {};
                    JSON.parse(text).forEach(id => next[id] = true);
                    root.hiddenApps = next;
                } catch (error) { console.warn("Could not refresh hidden desktop entries: " + error); }
            }
        }
    }

    FileView {
        id: entriesFile
        path: root.localPath("entries.jsonc")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.actions = Search.parseEntries(text());
                root.configError = "";
            } catch (error) {
                root.configError = "Could not load actions: " + error.message;
            }
        }
        onLoadFailed: error => root.configError = "Could not read entries.jsonc (" + error + ")."
    }

    Component {
        id: runner
        Process {
            id: process
            property string label
            stderr: StdioCollector { id: stderr }
            stdout: StdioCollector {}
            onExited: (code, status) => {
                if (code !== 0 || status !== 0) {
                    root.fail(label + " failed (" + code + "). " + stderr.text.trim().slice(0, 300));
                } else {
                    root.historyError = stderr.text.trim();
                    root.refreshHistory();
                }
                destroy();
            }
        }
    }

    PanelWindow {
        id: window
        visible: root.opened && root.surfaceReady
        screen: root.targetScreen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "#66000000"
        WlrLayershell.namespace: "dofs-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        MouseArea { anchors.fill: parent; onClicked: root.close() }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(600, parent.width - 24)
            height: Math.min(420, parent.height - 24)
            radius: 0
            color: theme.background
            border.color: theme.border
            border.width: 1
            // Consume inside clicks; clicks outside dismiss the launcher.
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    spacing: 12
                    Item {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 28
                        IconImage {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            implicitSize: 18
                            source: root.iconSource(root.actionParent ? "go-previous-symbolic" : "edit-find")
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.actionParent !== null
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.back(); search.forceActiveFocus(); }
                            Accessible.role: Accessible.Button
                            Accessible.name: "Back to applications"
                        }
                    }
                    TextField {
                        id: search
                        Layout.fillWidth: true
                        placeholderText: root.actionParent ? "Search shortcuts for " + root.actionParent.name
                            : "Search apps and actions…"
                        color: theme.text
                        placeholderTextColor: theme.muted
                        font.family: theme.font
                        font.pixelSize: 16
                        selectByMouse: true
                        background: Item {}
                        focus: true
                        Accessible.name: "Search apps and actions"
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N)) {
                                root.moveSelection(1);
                            } else if (event.key === Qt.Key_Up || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_P)) {
                                root.moveSelection(-1);
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.activate(list.currentIndex);
                            } else if (event.key === Qt.Key_Escape) {
                                if (root.actionParent) root.back(); else root.close();
                            } else if (event.key === Qt.Key_Backspace && !text && root.actionParent) {
                                root.back();
                            } else if (event.modifiers & Qt.ControlModifier
                                && event.key >= Qt.Key_1 && event.key <= Qt.Key_3 && !root.actionParent) {
                                root.filter = ["All", "Apps", "Actions"][event.key - Qt.Key_1];
                            } else if (event.key === Qt.Key_Tab || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_K)) {
                                if (root.actionParent) root.back(); else root.showAppActions();
                            } else { return; }
                            event.accepted = true;
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: theme.border }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 16
                    Layout.preferredHeight: 36
                    spacing: 6
                    Repeater {
                        model: ["All", "Apps", "Actions"]
                        delegate: Button {
                            required property string modelData
                            text: modelData
                            ToolTip.visible: hovered
                            ToolTip.text: "Ctrl+" + (["All", "Apps", "Actions"].indexOf(modelData) + 1)
                            enabled: !root.actionParent
                            focusPolicy: Qt.NoFocus
                            onClicked: { root.filter = modelData; search.forceActiveFocus(); }
                            contentItem: Text {
                                text: parent.text
                                font.family: theme.font
                                font.pixelSize: 12
                                color: root.filter === modelData ? theme.text : theme.muted
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 0
                                color: "transparent"
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 2
                                    color: root.filter === modelData ? theme.accent : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        visible: root.historyIds.length > 0 && !root.actionParent && !search.text.trim()
                        enabled: !historyClear.running
                        text: "Clear history"
                        focusPolicy: Qt.NoFocus
                        onClicked: root.clearHistory()
                        contentItem: Text {
                            text: parent.text
                            color: theme.muted
                            font.family: theme.font
                            font.pixelSize: 12
                        }
                        background: Item {}
                    }
                    Text {
                        text: root.results.length + " results"
                        color: theme.muted
                        font.family: theme.font
                        font.pixelSize: 12
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    Layout.bottomMargin: visible ? 8 : 0
                    visible: text.length > 0
                    text: root.errorMessage || root.configError || root.historyError
                    textFormat: Text.PlainText
                    color: theme.error
                    font.family: theme.font
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    Accessible.role: Accessible.AlertMessage
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    clip: true
                    spacing: 0
                    model: root.results
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: list.width
                        height: 46
                        radius: 0
                        color: list.currentIndex === index ? theme.selection : mouse.containsMouse ? theme.surface : "transparent"
                        Accessible.role: Accessible.ListItem
                        Accessible.name: modelData.name + ", " + modelData.description
                        Accessible.selected: list.currentIndex === index
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 3
                            color: theme.accent
                            visible: list.currentIndex === index
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12
                            IconImage {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                source: root.iconSource(row.modelData.icon)
                                implicitSize: 24
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.name
                                    textFormat: Text.PlainText
                                    color: theme.text
                                    font.family: row.modelData.kind === "calculator" ? theme.mono : theme.font
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.description
                                    textFormat: Text.PlainText
                                    color: theme.muted
                                    font.family: theme.font
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                            Text {
                                text: row.modelData.recent ? "Recent" : row.modelData.kind === "app" ? "Application"
                                    : row.modelData.kind === "calculator" ? "Copy" : "Action"
                                color: theme.muted
                                font.family: theme.font
                                font.pixelSize: 10
                            }
                        }
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { list.currentIndex = row.index; root.activate(row.index); }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !root.results.length
                        text: root.actionParent ? "No matching shortcuts" : "No matches. Try ? followed by a web search."
                        color: theme.muted
                        font.family: theme.font
                        font.pixelSize: 12
                        width: parent.width - 32
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.topMargin: 6; implicitHeight: 1; color: theme.border }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    Text {
                        text: "↑ ↓ Navigate   ↵ Open   Esc " + (root.actionParent ? "Back" : "Close")
                        color: theme.muted
                        font.family: theme.font
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: {
                            var entry = root.results[list.currentIndex];
                            return entry && entry.kind === "app" && entry.app.actions.length ? "Tab  App actions" : "= Calculate   ? Web";
                        }
                        color: theme.accent
                        font.family: theme.font
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
