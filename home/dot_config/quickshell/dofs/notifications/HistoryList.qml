import QtQuick
import QtQuick.Controls

Item {
    id: root
    required property var model
    required property var service
    required property var palette
    property string query: ""
    property alias view: list
    signal clearSection(string section)

    ListView {
        id: list
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: Math.max(0, root.width - historyScroll.width - 6)
        clip: true
        spacing: 6
        model: root.model
        boundsBehavior: Flickable.StopAtBounds
        // Keep the scrollbar outside the viewport, with a stable 6 px gutter.
        // Attaching it inside the ListView would overlay cards and Clear buttons.
        ScrollBar.vertical: ScrollBar {
            id: historyScroll
            objectName: "notificationHistoryScroll"
            parent: root
            anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
            width: 4
            padding: 0
            policy: ScrollBar.AsNeeded
            visible: size < 1
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: 4
                implicitHeight: 32
                radius: 0
                color: root.palette.muted
                opacity: historyScroll.active || historyScroll.hovered ? 1 : 0.5
            }
        }
        section.property: "section"
        section.criteria: ViewSection.FullString
        section.delegate: Item {
            id: heading
            required property string section
            objectName: "notificationHistoryHeading"
            width: list.width
            height: 28
            Text {
                anchors {
                    left: parent.left; leftMargin: root.service.settings.options.padding
                    right: clear.left; rightMargin: 6
                    verticalCenter: parent.verticalCenter
                }
                text: heading.section
                textFormat: Text.PlainText
                color: root.palette.muted
                font.family: "Inter"
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            NotificationButton {
                id: clear
                objectName: "notificationHistoryClear"
                anchors {
                    right: parent.right; rightMargin: root.service.settings.options.padding
                    verticalCenter: parent.verticalCenter
                }
                palette: root.palette
                text: "Clear"
                padding: 4
                horizontalPadding: 6
                Accessible.name: "Clear " + heading.section
                onClicked: root.clearSection(heading.section)
            }
        }
        delegate: Card {
            required property var record
            width: list.width
            height: implicitHeight
            entry: record
            service: root.service
            palette: root.palette
            selected: ListView.isCurrentItem && list.activeFocus
        }
        Keys.onDeletePressed: if (currentItem) root.service.remove(currentItem.entry.id)
        Keys.onReturnPressed: if (currentItem) root.service.invoke(currentItem.entry.id, "default")
        Text {
            anchors.centerIn: parent
            width: parent.width - 16
            visible: list.count === 0
            text: root.query ? "No matching notifications" : "You're all caught up\nNew notifications will appear here"
            color: root.palette.muted
            font.family: "Inter"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }
}
