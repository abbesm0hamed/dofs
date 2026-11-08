import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property var state: ({workspaceUrl: "", backdropUrl: "", mode: "blur", revision: ""})
    property var images: []
    property var surfaces: ({})
    property bool busy: false
    property bool scanning: false
    property string error: ""
    readonly property string renderError: Object.values(surfaces).map(surface => surface.error).filter(Boolean).join("\n")
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("backend.py").toString().replace(/^file:\/\//, ""))
    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/dofs/wallpaper.json"
    function accept(value) {
        if (value.version !== 1 || !value.workspaceUrl || !value.backdropUrl
            || ["blur", "independent"].indexOf(value.mode) < 0) throw new Error("Invalid wallpaper state");
        state = value;
        error = "";
    }
    function apply(args) {
        if (busy) return;
        error = "";
        busy = true;
        setter.command = ["python3", "-B", helper].concat(args, ["--silent", "--json"]);
        setter.running = true;
    }
    function select(path, target) { apply([target === "backdrop" ? "--backdrop" : "--workspace", path]); }
    function scan() {
        if (scanning) return;
        scanning = true;
        scanner.running = true;
    }
    function report(key, ready, message) {
        var next = Object.assign({}, surfaces);
        next[key] = {ready: ready, error: message};
        surfaces = next;
    }
    function forget(key) {
        var next = Object.assign({}, surfaces);
        delete next[key];
        surfaces = next;
    }
    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { root.accept(JSON.parse(text())); }
            catch (error) { root.error = String(error); }
        }
    }
    Process {
        id: setter
        stdout: StdioCollector { id: result }
        stderr: StdioCollector { id: failure }
        onExited: code => {
            root.busy = false;
            if (code !== 0) { root.error = failure.text.trim() || "Could not apply wallpaper."; return; }
            try { root.accept(JSON.parse(result.text)); stateFile.reload(); }
            catch (error) { root.error = String(error); }
        }
    }
    Process {
        id: scanner
        command: ["python3", "-B", root.helper, "--list"]
        stdout: StdioCollector { id: listing }
        stderr: StdioCollector { id: scanFailure }
        onExited: code => {
            root.scanning = false;
            if (code !== 0) { root.error = scanFailure.text.trim() || "Could not list wallpapers."; return; }
            try { root.images = JSON.parse(listing.text); }
            catch (error) { root.error = String(error); }
        }
    }
    Component.onCompleted: apply(["--restore"])
}
