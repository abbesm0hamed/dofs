import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Authentication is shared by all outputs. Never expose this object through IPC.
Scope {
    id: root
    required property var session
    required property var passwordPam
    required property var fingerprintPam
    property bool passwordAttempt: false
    property bool fingerprintAttempt: false
    property bool responseQueued: false
    property string pendingResponse: ""
    property string message: "Enter your password"
    property string fingerprintMessage: ""
    readonly property bool canType: session.locked && session.secure && !cooldown.running
        && (!passwordPam.active || passwordPam.responseRequired)
    readonly property bool responseVisible: passwordPam.active && passwordPam.responseRequired && passwordPam.responseVisible
    readonly property bool busy: passwordAttempt && !passwordPam.responseRequired
    signal clearInput()

    function clearPending() { pendingResponse = ""; responseQueued = false; }
    function cancelPassword() {
        passwordAttempt = false;
        clearPending();
        passwordPam.abort();
        clearInput();
        message = "Enter your password";
    }
    function reset() {
        cancelPassword();
        fingerprintAttempt = false;
        fingerprintPam.abort();
        fingerprintMessage = "";
        cooldown.stop();
    }
    function begin() {
        reset();
        if (session.locked && session.secure) retryFingerprint();
    }
    function retryFingerprint() {
        if (!session.locked || !session.secure) return;
        fingerprintAttempt = false;
        fingerprintPam.abort();
        fingerprintAttempt = true;
        fingerprintMessage = "Scan your fingerprint";
        if (!fingerprintPam.start()) {
            fingerprintAttempt = false;
            fingerprintMessage = "Fingerprint unavailable · use your password";
        }
    }
    function respondPending() {
        if (!passwordAttempt || !responseQueued || !passwordPam.responseRequired) return;
        // Never send a queued secret to an echo-on (e.g. username) prompt.
        if (passwordPam.responseVisible) { clearPending(); return; }
        var response = pendingResponse;
        clearPending();
        passwordPam.respond(response);
    }
    function submit(response) {
        if (!canType || !response || response.length > 1024) return;
        clearInput();
        if (passwordPam.active && passwordPam.responseRequired) {
            passwordPam.respond(response);
            return;
        }
        passwordAttempt = true;
        pendingResponse = response;
        responseQueued = true;
        message = "Checking password…";
        if (!passwordPam.start()) {
            passwordAttempt = false;
            clearPending();
            message = "Authentication unavailable · try again";
            cooldown.restart();
        } else respondPending();
    }
    function completed(fingerprint, result) {
        var expected = fingerprint ? fingerprintAttempt : passwordAttempt;
        if (!expected) return;
        if (fingerprint) fingerprintAttempt = false;
        else { passwordAttempt = false; clearPending(); }
        clearInput();
        if (result === PamResult.Success && session.locked && session.secure) {
            // This is the only code path that releases the compositor lock.
            reset();
            session.locked = false;
        } else if (fingerprint) {
            fingerprintMessage = "Fingerprint not accepted · retry or use your password";
        } else {
            message = result === PamResult.Error ? "Authentication error · try again" : "Password not accepted · try again";
            cooldown.restart();
        }
    }
    Connections {
        target: root.session
        function onSecureChanged() { if (root.session.secure) root.begin(); }
        function onLockedChanged() { if (!root.session.locked) root.reset(); }
    }
    Connections {
        target: root.passwordPam
        function onPamMessage() {
            if (!root.passwordAttempt) return;
            root.message = root.passwordPam.message || "Checking password…";
            root.respondPending();
        }
        function onCompleted(result) { root.completed(false, result); }
    }
    Connections {
        target: root.fingerprintPam
        function onPamMessage() {
            if (root.fingerprintAttempt) root.fingerprintMessage = root.fingerprintPam.message || "Scan your fingerprint";
        }
        function onCompleted(result) { root.completed(true, result); }
    }
    Timer { id: cooldown; interval: 2000 }
}
