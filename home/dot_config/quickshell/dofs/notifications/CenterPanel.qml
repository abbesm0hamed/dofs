import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "History.js" as History

Rectangle {
    id: root
    required property var service
    required property var palette
    required property bool opened
    signal closeRequested()
    objectName: "notificationCenterPanel"
    implicitWidth: 440
    radius: 0
    color: palette.background
    border.width: 1
    border.color: palette.border
    property bool clearConfirmation: false
    onOpenedChanged: if (opened) { search.text = ""; clearConfirmation = false; Qt.callLater(() => search.forceActiveFocus()); }
    readonly property var results: {
        var groups = {}, order = [];
        History.filtered(service.entries, search.text, false).forEach(e => {
            var section = History.day(e.timestamp) + " · " + e.appName;
            if (!groups[section]) { groups[section] = []; order.push(section); }
            groups[section].push(Object.assign({}, e, {section: section}));
        });
        return order.reduce((all, key) => all.concat(groups[key]), []);
    }
    // Preserve focused cards and reply drafts while incoming messages arrive.
    function syncHistory() {
        if (!historyModel) return;
        for (var i = 0; i < results.length; i++) {
            var entry = results[i], found = i;
            while (found < historyModel.count && historyModel.get(found).key !== entry.id) found++;
            if (found === historyModel.count) historyModel.insert(i, {key: entry.id, section: entry.section, record: entry});
            else {
                if (found !== i) historyModel.move(found, i, 1);
                var old = historyModel.get(i);
                if (old.section !== entry.section) historyModel.setProperty(i, "section", entry.section);
                if (Object.keys(entry).some(key => old.record[key] !== entry[key])) historyModel.setProperty(i, "record", entry);
            }
        }
        if (historyModel.count > results.length) historyModel.remove(results.length, historyModel.count - results.length);
    }
    onResultsChanged: syncHistory()
    Component.onCompleted: syncHistory()
    ListModel { id: historyModel; dynamicRoles: true }
    MouseArea { anchors.fill: parent }
    Keys.onEscapePressed: root.closeRequested()
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: root.service.settings.options.padding
        anchors.bottomMargin: root.service.settings.options.padding
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.service.settings.options.padding
            Layout.rightMargin: root.service.settings.options.padding
            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: root.palette.text
                font.family: "Inter"
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }
            NotificationButton { palette: root.palette; text: "Close"; onClicked: root.closeRequested() }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.service.settings.options.padding
            Layout.rightMargin: root.service.settings.options.padding
            NotificationButton {
                palette: root.palette
                text: root.service.dnd ? "Do not disturb · On" : "Do not disturb · Off"
                active: root.service.dnd
                onClicked: root.service.toggleDnd()
            }
            Item { Layout.fillWidth: true }
            NotificationButton {
                palette: root.palette
                text: root.clearConfirmation ? "Confirm clear" : "Clear all"
                destructive: root.clearConfirmation
                enabled: root.service.entries.length > 0
                onClicked: {
                    if (root.clearConfirmation) { root.service.clear(); root.clearConfirmation = false; }
                    else { root.clearConfirmation = true; confirmationTimeout.restart(); }
                }
            }
        }
        TextField {
            id: search
            Layout.fillWidth: true
            Layout.leftMargin: root.service.settings.options.padding
            Layout.rightMargin: root.service.settings.options.padding
            placeholderText: "Search apps, titles and messages…"
            color: root.palette.text
            placeholderTextColor: root.palette.muted
            font.family: "Inter"
            font.pixelSize: 12
            selectByMouse: true
            padding: 6
            Accessible.name: "Search notification history"
            background: Rectangle { color: root.palette.surface; radius: 0 }
            Keys.onEscapePressed: root.closeRequested()
            Keys.onDownPressed: history.view.forceActiveFocus()
        }
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: root.service.settings.options.padding
            Layout.rightMargin: root.service.settings.options.padding
            visible: !!text
            text: root.service.error
            textFormat: Text.PlainText
            color: root.palette.yellow
            font.family: "Inter"
            font.pixelSize: 11
            wrapMode: Text.Wrap
            Accessible.role: Accessible.AlertMessage
        }
        HistoryList {
            id: history
            objectName: "notificationCenterHistory"
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: historyModel
            service: root.service
            palette: root.palette
            query: search.text
            onClearSection: section => root.results.filter(e => e.section === section).forEach(e => root.service.remove(e.id))
        }
        Text {
            Layout.leftMargin: root.service.settings.options.padding
            Layout.rightMargin: root.service.settings.options.padding
            text: root.service.entries.length + " saved · " + root.service.settings.options.retentionDays + "-day history"
            color: root.palette.muted
            font.family: "Inter"
            font.pixelSize: 10
        }
    }
    Timer { id: confirmationTimeout; interval: 3000; onTriggered: root.clearConfirmation = false }
}
