import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../notifications" as Notifications

PanelWindow {
    id: root
    required property var service
    required property var palette
    required property bool opened
    required property var targetScreen
    required property int barHeight
    required property string tab
    signal tabRequested(string section)
    signal closeRequested()
    screen: targetScreen
    visible: opened
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "#33000000"
    WlrLayershell.namespace: "dofs-connectivity"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    property var selectedNetwork: null
    property bool confirmHotspot: false
    property string forgetCandidate: ""
    readonly property bool bluetoothBlocked: (service.bluetooth.radios || []).some(r => r.soft)
    readonly property bool bluetoothHardBlocked: (service.bluetooth.radios || []).some(r => r.hard)
    readonly property var adapters: service.bluetooth.adapters || []
    readonly property var hotspot: (service.network.hotspots || [])[0] || null
    readonly property var hotspotDevices: (service.network.devices || []).filter(d => d.canHotspot)
    onOpenedChanged: {
        if (!opened) {
            wifiPassword.text = ""; hotspotPassword.text = ""; pin.text = "";
            selectedNetwork = null; confirmHotspot = false; forgetCandidate = "";
        }
    }
    onTabChanged: { root.service.hideHotspotPassword(); selectedNetwork = null; wifiPassword.text = ""; confirmHotspot = false; }
    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
    Rectangle {
        id: card
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right; topMargin: root.barHeight + 8; bottomMargin: 8; rightMargin: 8 }
        width: Math.min(480, parent.width - 16)
        color: root.palette.background
        radius: 0
        MouseArea { anchors.fill: parent }
        focus: true
        Keys.onEscapePressed: root.closeRequested()
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                Label { text: "Connections"; color: root.palette.text; font.pixelSize: 22; Layout.fillWidth: true }
                Notifications.NotificationButton { palette: root.palette; text: "Close"; onClicked: root.closeRequested() }
            }
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: [{key:"wifi", title:"Wi-Fi"}, {key:"hotspot", title:"Hotspot"}, {key:"bluetooth", title:"Bluetooth"}]
                    delegate: Notifications.NotificationButton {
                        required property var modelData
                        palette: root.palette
                        text: modelData.title
                        active: root.tab === modelData.key
                        onClicked: root.tabRequested(modelData.key)
                    }
                }
            }
            Label {
                visible: !!root.service.error
                text: root.service.error
                textFormat: Text.PlainText
                color: root.palette.red
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Label {
                visible: !root.service.loaded || root.service.busy || !!root.service.message
                text: !root.service.loaded ? "Loading connection status…" : root.service.busy ? "Working…" : root.service.message
                color: root.palette.muted
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Rectangle {
                visible: root.service.pairing !== null
                Layout.fillWidth: true
                implicitHeight: pairingContent.implicitHeight + 20
                color: root.palette.surface
                radius: 8
                ColumnLayout {
                    id: pairingContent
                    anchors.fill: parent; anchors.margins: 10
                    Label { text: root.service.pairing ? "Pairing · " + root.service.pairing.name : "Bluetooth pairing"; textFormat: Text.PlainText; wrapMode: Text.Wrap; Layout.fillWidth: true; color: root.palette.text; font.bold: true }
                    Label {
                        Layout.fillWidth: true
                        text: root.service.pairing ? (root.service.pairing.method === "RequestConfirmation" ? "Confirm this code matches your device" : /Display/.test(root.service.pairing.method) ? "Enter this code on your device" : /RequestPinCode|RequestPasskey/.test(root.service.pairing.method) ? "Enter the code shown on your device" : "Allow this device to pair?") + (root.service.pairing.code ? " · " + root.service.pairing.code : "") : ""
                        textFormat: Text.PlainText; wrapMode: Text.Wrap; color: root.palette.text
                    }
                    Field {
                        colors: root.palette;
                        id: pin
                        visible: !!root.service.pairing && /RequestPinCode|RequestPasskey/.test(root.service.pairing.method)
                        placeholderText: "Enter the device PIN or passkey"; color: root.palette.text
                    }
                    RowLayout {
                        Notifications.NotificationButton {
                            palette: root.palette; text: "Accept"
                            visible: !!root.service.pairing && !!root.service.pairing.id
                            onClicked: { root.service.respond(true, pin.text); pin.text = ""; }
                        }
                        Notifications.NotificationButton {
                            palette: root.palette; text: "Reject"
                            visible: !!root.service.pairing && !!root.service.pairing.id
                            onClicked: { root.service.respond(false); pin.text = ""; }
                        }
                    }
                }
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width
                    spacing: 10
                    ColumnLayout {
                        visible: root.tab === "wifi"
                        Layout.fillWidth: true
                        spacing: 10
                        RowLayout {
                            Label { text: "Wi-Fi"; color: root.palette.text; font.pixelSize: 18; Layout.fillWidth: true }
                            Notifications.NotificationButton {
                                palette: root.palette
                                text: root.service.network.enabled ? "Turn off" : "Turn on"
                                enabled: root.service.ready && root.service.loaded && !root.service.busy && (root.service.network.devices || []).length > 0
                                onClicked: root.service.request("wifi-power", {enabled: !root.service.network.enabled})
                            }
                            Notifications.NotificationButton {
                                palette: root.palette; text: "Scan"
                                enabled: root.service.ready && root.service.loaded && !root.service.busy && !!root.service.network.enabled
                                onClicked: root.service.request("scan-wifi")
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            text: root.service.network.error || (!(root.service.network.devices || []).length ? "No Wi-Fi adapter found." : !root.service.network.enabled ? "Wi-Fi is turned off." : "Select a network to connect. Leave the password blank to use a saved connection.")
                            color: root.palette.muted; wrapMode: Text.Wrap
                        }
                        Repeater {
                            model: root.service.network.devices || []
                            delegate: Label {
                                required property var modelData
                                Layout.fillWidth: true
                                text: modelData.interface + " · " + modelData.status + (modelData.connection ? " · " + modelData.connection : "") + (modelData.address ? "\n" + modelData.address : "")
                                textFormat: Text.PlainText; color: root.palette.muted; wrapMode: Text.Wrap
                            }
                        }
                        Repeater {
                            model: root.service.network.networks || []
                            delegate: Notifications.NotificationButton {
                                required property var modelData
                                palette: root.palette
                                Layout.fillWidth: true
                                text: (modelData.active ? "✓ " : "") + modelData.ssid + " · " + modelData.signal + "% · " + modelData.security
                                active: modelData.active || (root.selectedNetwork !== null && root.selectedNetwork.path === modelData.path)
                                enabled: root.service.ready && root.service.loaded && !root.service.busy && !modelData.active
                                onClicked: { root.selectedNetwork = modelData; wifiPassword.text = ""; wifiPassword.forceActiveFocus(); }
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: !!root.service.network.enabled && !(root.service.network.networks || []).length
                            text: root.hotspot ? "Your adapter is sharing a hotspot. Stop it before scanning for Wi-Fi." : "No networks found yet. Press Scan to look nearby."
                            color: root.palette.muted; wrapMode: Text.Wrap
                        }
                        ColumnLayout {
                            visible: root.selectedNetwork !== null
                            Layout.fillWidth: true
                            Label { text: root.selectedNetwork ? "Connect to " + root.selectedNetwork.ssid : ""; textFormat: Text.PlainText; color: root.palette.text }
                            Field {
                                colors: root.palette;
                                id: wifiPassword
                                Layout.fillWidth: true
                                visible: root.selectedNetwork !== null && root.selectedNetwork.security !== "Open"
                                placeholderText: "Password (blank for saved connection)"
                                echoMode: TextInput.Password
                                color: root.palette.text
                                onAccepted: connectButton.clicked()
                            }
                            RowLayout {
                                Notifications.NotificationButton {
                                    id: connectButton
                                    palette: root.palette; text: "Connect"; enabled: root.service.ready && root.service.loaded && !root.service.busy
                                    onClicked: {
                                        if (!root.selectedNetwork || root.service.busy) return;
                                        root.service.request("connect-wifi", {ap: root.selectedNetwork.path, device: root.selectedNetwork.device, password: wifiPassword.text});
                                        wifiPassword.text = "";
                                    }
                                }
                                Notifications.NotificationButton { palette: root.palette; text: "Cancel"; onClicked: { root.selectedNetwork = null; wifiPassword.text = ""; } }
                            }
                        }
                    }
                    ColumnLayout {
                        visible: root.tab === "hotspot"
                        Layout.fillWidth: true
                        spacing: 10
                        Label { text: "Mobile hotspot"; color: root.palette.text; font.pixelSize: 18 }
                        Label {
                            Layout.fillWidth: true
                            text: "Share this computer’s internet connection with other devices over Wi-Fi."
                            wrapMode: Text.Wrap; color: root.palette.muted
                        }
                        Label {
                            visible: !!root.hotspot
                            Layout.fillWidth: true
                            text: root.hotspot ? "Sharing: " + root.hotspot.ssid + "\nAdapter: " + root.hotspot.interface + "\nAddress: " + (root.hotspot.address || "Starting…") : ""
                            textFormat: Text.PlainText; wrapMode: Text.Wrap; color: root.palette.text
                        }
                        RowLayout {
                            visible: !!root.hotspot
                            Notifications.NotificationButton {
                                palette: root.palette; text: "Stop hotspot"; enabled: root.service.ready && root.service.loaded && !root.service.busy
                                onClicked: { root.service.request("stop-hotspot", {active: root.hotspot.active}); root.service.hideHotspotPassword(); }
                            }
                            Notifications.NotificationButton {
                                palette: root.palette; text: root.service.hotspotPassword ? "Hide password" : "Show password"
                                enabled: root.service.ready && root.service.loaded && !root.service.busy
                                onClicked: {
                                    if (root.service.hotspotPassword) root.service.hideHotspotPassword();
                                    else root.service.request("hotspot-password", {profile: root.hotspot.profile});
                                }
                            }
                        }
                        Label {
                            visible: !!root.hotspot && !!root.service.hotspotPassword
                            text: root.service.hotspotPassword
                            textFormat: Text.PlainText; color: root.palette.text
                        }
                        ColumnLayout {
                            visible: !root.hotspot
                            Layout.fillWidth: true
                            Label { text: "Wi-Fi adapter"; color: root.palette.text }
                            ComboBox {
                                id: hotspotAdapter
                                Layout.fillWidth: true
                                model: root.hotspotDevices
                                textRole: "interface"
                                palette.text: root.palette.text
                                palette.buttonText: root.palette.text
                                palette.button: root.palette.surface
                                palette.base: root.palette.surface
                                palette.highlight: root.palette.accent
                                enabled: root.service.ready && root.service.loaded && !root.service.busy
                            }
                            Label { text: "Network name"; color: root.palette.text }
                            Field {
                                colors: root.palette; id: hotspotName; Layout.fillWidth: true; text: "My computer"; maximumLength: 32; color: root.palette.text }
                            Label { text: "Password"; color: root.palette.text }
                            Field {
                                colors: root.palette; id: hotspotPassword; Layout.fillWidth: true; placeholderText: "At least 8 characters"; echoMode: TextInput.Password; color: root.palette.text }
                            CheckBox {
                                id: keepWifi
                                checked: true
                                text: "Keep my current Wi-Fi connection"
                                palette.windowText: root.palette.text
                            }
                            Label {
                                Layout.fillWidth: true
                                text: !root.service.loaded ? "Loading adapters…" : !root.hotspotDevices.length ? "No hotspot-capable Wi-Fi adapter is available." : (keepWifi.checked ? "When already connected to Wi-Fi, sharing uses the same Wi-Fi channel. You may be asked to authenticate to prepare the sharing adapter. Your hardware must support simultaneous Wi-Fi and hotspot mode." : "Starting replaces the Wi-Fi connection on this adapter. Use Ethernet, USB tethering, or a second adapter for internet access.")
                                wrapMode: Text.Wrap; color: root.palette.yellow
                            }
                            Label { visible: root.confirmHotspot; text: "Start sharing using these settings?"; color: root.palette.text }
                            RowLayout {
                                Notifications.NotificationButton {
                                    palette: root.palette; text: root.confirmHotspot ? "Confirm start" : "Start hotspot"
                                    enabled: root.service.ready && root.service.loaded && !root.service.busy && root.hotspotDevices.length > 0 && !!root.service.network.enabled && hotspotName.text.length > 0 && hotspotPassword.text.length >= 8
                                    onClicked: {
                                        if (!root.confirmHotspot) { root.confirmHotspot = true; return; }
                                        var device = root.hotspotDevices[hotspotAdapter.currentIndex];
                                        if (!device) return;
                                        root.service.request("start-hotspot", {device: device.path, ssid: hotspotName.text, password: hotspotPassword.text, keepConnection: keepWifi.checked});
                                        hotspotPassword.text = ""; root.confirmHotspot = false;
                                    }
                                }
                                Notifications.NotificationButton { palette: root.palette; text: "Cancel"; visible: root.confirmHotspot; onClicked: root.confirmHotspot = false }
                            }
                            Label { visible: !root.service.network.enabled; text: "Turn on Wi-Fi in the Wi-Fi tab first."; color: root.palette.muted }
                        }
                    }
                    ColumnLayout {
                        visible: root.tab === "bluetooth"
                        Layout.fillWidth: true
                        spacing: 10
                        Label { text: "Bluetooth"; color: root.palette.text; font.pixelSize: 18 }
                        Label { visible: !root.adapters.length && !root.bluetoothBlocked && !root.bluetoothHardBlocked; text: root.service.bluetooth.error || "No Bluetooth adapter found."; color: root.palette.muted; wrapMode: Text.Wrap; Layout.fillWidth: true }
                        Label {
                            visible: root.bluetoothBlocked || root.bluetoothHardBlocked
                            text: root.bluetoothHardBlocked ? "Bluetooth is blocked by a hardware switch or firmware setting." : "Bluetooth is turned off by the system radio switch."
                            color: root.palette.yellow; wrapMode: Text.Wrap; Layout.fillWidth: true
                        }
                        Notifications.NotificationButton {
                            palette: root.palette; text: "Enable Bluetooth radio"
                            visible: root.bluetoothBlocked && !root.bluetoothHardBlocked
                            enabled: root.service.ready && root.service.loaded && !root.service.busy
                            onClicked: root.service.request("unblock-bluetooth")
                        }
                        Repeater {
                            model: root.adapters
                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Label { text: modelData.name; textFormat: Text.PlainText; color: root.palette.text; Layout.fillWidth: true }
                                Notifications.NotificationButton {
                                    palette: root.palette; text: modelData.enabled ? "Turn off" : "Turn on"; enabled: root.service.ready && root.service.loaded && !root.service.busy
                                    onClicked: root.service.request("bluetooth-power", {adapter: modelData.path, enabled: !modelData.enabled})
                                }
                                Notifications.NotificationButton {
                                    palette: root.palette; text: modelData.discovering ? "Stop scan" : "Scan"; enabled: root.service.ready && root.service.loaded && !root.service.busy && modelData.enabled
                                    onClicked: root.service.request(modelData.discovering ? "stop-bluetooth-scan" : "scan-bluetooth", {adapter: modelData.path})
                                }
                            }
                        }
                        Repeater {
                            model: root.service.bluetooth.devices || []
                            delegate: ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.name + " · " + (modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Available") + (modelData.battery !== null ? " · " + modelData.battery + "%" : "")
                                    textFormat: Text.PlainText; color: root.palette.text; wrapMode: Text.Wrap
                                }
                                RowLayout {
                                    Notifications.NotificationButton {
                                        palette: root.palette
                                        text: modelData.connected ? "Disconnect" : modelData.paired ? "Connect" : "Pair"
                                        enabled: root.service.ready && root.service.loaded && !root.service.busy
                                        onClicked: root.service.request(modelData.connected ? "disconnect-bluetooth" : modelData.paired ? "connect-bluetooth" : "pair-bluetooth", {device: modelData.path})
                                    }
                                    Notifications.NotificationButton {
                                        palette: root.palette
                                        text: root.forgetCandidate === modelData.path ? "Confirm forget" : "Forget"
                                        visible: modelData.paired
                                        enabled: root.service.ready && root.service.loaded && !root.service.busy
                                        onClicked: {
                                            if (root.forgetCandidate !== modelData.path) { root.forgetCandidate = modelData.path; return; }
                                            root.service.request("forget-bluetooth", {device: modelData.path}); root.forgetCandidate = "";
                                        }
                                    }
                                }
                            }
                        }
                        Label { visible: !(root.service.bluetooth.devices || []).length; text: "Press Scan to discover nearby devices."; color: root.palette.muted }
                    }

                }
            }
            Notifications.NotificationButton {
                palette: root.palette
                text: "Advanced network settings"
                onClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }
}
