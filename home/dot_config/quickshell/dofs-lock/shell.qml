import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// A separate, persistent instance. Restarting the desktop shell never kills it.
ShellRoot {
    id: root
    property int requestSerial: 0
    property int securedSerial: 0
    readonly property var authentication: auth
    readonly property var colors: lockColors
    Component.onCompleted: Quickshell.watchFiles = false
    LockPalette { id: lockColors }
    PamContext { id: passwordPam; config: "dofs-lock"; configDirectory: "/etc/pam.d" }
    PamContext { id: fingerprintPam; config: "dofs-lock-fingerprint"; configDirectory: "/etc/pam.d" }
    AuthController { id: auth; session: session; passwordPam: passwordPam; fingerprintPam: fingerprintPam }
    WlSessionLock {
        id: session
        locked: false
        onSecureChanged: if (secure) root.securedSerial = root.requestSerial
        WlSessionLockSurface {
            color: root.colors.background
            LockView {
                anchors.fill: parent
                auth: root.authentication
                palette: root.colors
                wallpaper: "file://" + (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/backgrounds/current-blurry.jpg"
            }
        }
    }
    // Deliberately no unlock, password, or authentication-result IPC methods.
    IpcHandler {
        target: "lock"
        function ping(): string { return "ready"; }
        function lock(): int {
            if (!session.locked) { root.requestSerial++; session.locked = true; }
            return root.requestSerial;
        }
        function secured(): int { return root.securedSerial; }
        function status(): string {
            return JSON.stringify({locked: session.locked, secure: session.secure});
        }
    }
}
