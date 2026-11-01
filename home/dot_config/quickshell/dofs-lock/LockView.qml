import QtQuick
import Quickshell

Rectangle {
    id: root
    required property var auth
    required property var palette
    property string wallpaper: ""
    color: palette.background
    Image {
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: 0.35
    }
    MouseArea { anchors.fill: parent; onClicked: password.forceActiveFocus() }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Column {
        anchors.centerIn: parent
        width: Math.min(380, Math.max(160, root.width - 48))
        spacing: 18
        Text {
            width: parent.width
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: root.palette.text
            font.family: "Lilex Nerd Font Mono"
            font.pixelSize: 64
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            width: parent.width
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: root.palette.muted
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            width: parent.width
            text: Quickshell.env("USER") || "Session locked"
            textFormat: Text.PlainText
            color: root.palette.text
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
        }
        Rectangle {
            width: parent.width
            height: 52
            color: root.palette.surface
            border.color: password.activeFocus ? root.palette.accent : root.palette.border
            border.width: 2
            TextInput {
                id: password
                objectName: "lockPassword"
                anchors.fill: parent
                anchors.margins: 14
                enabled: root.auth.canType
                focus: true
                color: root.palette.text
                selectionColor: root.palette.accent
                font.pixelSize: 18
                echoMode: root.auth.responseVisible ? TextInput.Normal : TextInput.Password
                passwordMaskDelay: 0
                maximumLength: 1024
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                verticalAlignment: TextInput.AlignVCenter
                onAccepted: { var response = text; clear(); root.auth.submit(response); }
                onEnabledChanged: if (enabled) forceActiveFocus()
                Keys.onEscapePressed: root.auth.cancelPassword()
            }
            Text {
                anchors.centerIn: parent
                visible: !password.text
                text: root.auth.busy ? "Authenticating…" : "Password"
                color: root.palette.muted
                font.pixelSize: 16
            }
        }
        Text {
            width: parent.width
            text: root.auth.message
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: root.palette.text
            horizontalAlignment: Text.AlignHCenter
        }
        Rectangle {
            width: parent.width
            height: 42
            color: root.palette.surface
            border.color: root.palette.border
            Text {
                anchors.centerIn: parent
                text: "Unlock"
                color: root.auth.canType ? root.palette.accent : root.palette.muted
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.auth.canType
                onClicked: { var response = password.text; password.clear(); root.auth.submit(response); }
            }
        }
        Text {
            width: parent.width
            text: root.auth.fingerprintMessage
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: root.palette.muted
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Retry fingerprint"
            color: root.palette.accent
            MouseArea { anchors.fill: parent; onClicked: root.auth.retryFingerprint() }
        }
    }
    Connections { target: root.auth; function onClearInput() { password.clear(); } }
}
