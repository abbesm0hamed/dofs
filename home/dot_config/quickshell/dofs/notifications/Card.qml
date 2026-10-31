import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    required property var entry
    required property var service
    required property var palette
    property bool toast: false
    property bool expanded: false
    property bool selected: false
    // One live setting for popup and history cards; no surface-specific padding.
    property int padding: service.settings.options.padding
    readonly property var live: service.find(entry.id)
    readonly property var notification: live ? live.notification : null
    readonly property var actions: notification ? notification.actions : []
    signal openCenter()
    implicitHeight: content.implicitHeight + padding * 2
    radius: 0
    color: palette.background
    border.width: 1
    border.color: entry.urgency === 2 ? palette.red : hover.hovered || selected ? palette.accent : palette.border
    Accessible.role: Accessible.Grouping
    Accessible.name: entry.appName + ": " + entry.summary

    function previewSource(value) {
        // Quickshell may fall back to the app icon when no image was sent.
        // Don't reserve a large preview for a theme icon (or a missing one).
        value = String(value || "");
        if (value.startsWith("image://icon/")) {
            var path = value.slice("image://icon/".length);
            return path.startsWith("/") ? "file://" + path : "";
        }
        return /^(image:\/\/qsimage\/|file:\/\/|\/)/.test(value) ? value : "";
    }
    HoverHandler {
        id: hover
        onHoveredChanged: if (root.live && root.toast) root.live.paused = hovered
    }
    Component.onDestruction: if (live && toast) live.paused = false

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ApplicationIcon {
                objectName: "notificationApplicationIcon"
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                appIcon: root.entry.appIcon || ""
                appId: root.entry.appId || ""
                appName: root.entry.appName || ""
            }
            Text {
                Layout.fillWidth: true
                text: root.entry.appName
                textFormat: Text.PlainText
                color: root.palette.muted
                font.family: "Inter"
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Rectangle { visible: !root.entry.read; width: 6; height: 6; radius: 0; color: root.palette.accent }
            Text {
                text: Qt.formatDateTime(new Date(root.entry.timestamp), "HH:mm")
                color: root.palette.muted
                font.family: "Inter"
                font.pixelSize: 10
            }
            NotificationButton {
                palette: root.palette
                text: "×"
                padding: 4
                horizontalPadding: 6
                Accessible.name: root.toast ? "Hide popup; keep in history" : "Delete notification"
                onClicked: if (root.toast) root.service.hidePopup(root.entry.id); else root.service.remove(root.entry.id)
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.entry.summary
            textFormat: Text.PlainText
            color: root.palette.text
            font.family: "Inter"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: root.expanded ? 1000 : 3
            elide: Text.ElideRight
            TapHandler {
                onTapped: {
                    if (root.actions.some(a => a.identifier === "default")) root.service.invoke(root.entry.id, "default");
                    else if (root.toast) root.openCenter();
                }
            }
        }
        Text {
            id: body
            Layout.fillWidth: true
            visible: !!text
            text: root.entry.body
            textFormat: Text.PlainText
            color: root.palette.text
            font.family: "Inter"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            maximumLineCount: root.toast ? 4 : root.expanded ? 10000 : 8
            elide: Text.ElideRight
        }
        NotificationButton {
            visible: !root.toast && (body.truncated || root.expanded)
            palette: root.palette
            text: root.expanded ? "Show less" : "Show more"
            onClicked: root.expanded = !root.expanded
        }
        Image {
            objectName: "notificationImagePreview"
            readonly property string image: root.notification ? root.notification.image : ""
            readonly property bool provided: root.notification !== null && (image.startsWith("image://qsimage/")
                || !!root.notification.hints["image-path"] || !!root.notification.hints["image_path"])
            visible: source.toString().length > 0 && status !== Image.Error
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 120 : 0
            source: provided ? root.previewSource(image) : ""
            sourceSize { width: 640; height: 240 }
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
        Flow {
            Layout.fillWidth: true
            spacing: 4
            visible: root.actions.length > 0 || (root.toast && root.notification && root.notification.hasInlineReply)
            Repeater {
                model: root.actions
                delegate: NotificationButton {
                    required property var modelData
                    palette: root.palette
                    text: modelData.text || (modelData.identifier === "default" ? "Open" : modelData.identifier)
                    width: Math.min(implicitWidth, content.width)
                    onClicked: root.service.invoke(root.entry.id, modelData.identifier)
                }
            }
            NotificationButton {
                visible: root.toast && root.notification !== null && root.notification.hasInlineReply
                palette: root.palette
                text: "Reply…"
                onClicked: root.openCenter()
            }
        }
        RowLayout {
            visible: !root.toast && root.notification !== null && root.notification.hasInlineReply
            Layout.fillWidth: true
            TextField {
                id: reply
                Layout.fillWidth: true
                placeholderText: root.notification ? root.notification.inlineReplyPlaceholder || "Write a reply…" : ""
                color: root.palette.text
                placeholderTextColor: root.palette.muted
                font.family: "Inter"
                font.pixelSize: 12
                maximumLength: 4000
                selectByMouse: true
                Accessible.name: "Notification reply"
                background: Rectangle { radius: 0; color: root.palette.surface }
                onAccepted: { root.service.reply(root.entry.id, text); text = ""; }
            }
            NotificationButton {
                palette: root.palette
                text: "Send"
                enabled: !!reply.text.trim()
                onClicked: { root.service.reply(root.entry.id, reply.text); reply.text = ""; }
            }
        }
    }
}
