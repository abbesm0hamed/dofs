import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property bool active: false
    property var themes: []
    property string current: ""
    property string error: ""
    property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    function refresh() { listProc.running = true; }
    function apply(name) {
        error = "";
        applyProc.command = ["bash", configHome + "/niri/scripts/set-theme.sh", "--from-picker", name];
        applyProc.running = true;
    }
    Process {
        id: listProc
        command: ["python3", "-c", "import glob,json,os; c=os.environ.get('XDG_CONFIG_HOME',os.path.expanduser('~/.config')); s=os.environ.get('XDG_STATE_HOME',os.path.expanduser('~/.local/state')); p=os.path.join(s,'themes/current_theme'); legacy=os.path.join(c,'themes/current_theme'); current=(open(p).read().strip() if os.path.isfile(p) else (open(legacy).read().strip() if os.path.isfile(legacy) else '')); print(json.dumps({'themes':sorted(os.path.basename(x) for x in glob.glob(os.path.join(c,'themes','*')) if os.path.isdir(x)),'current':current}))"]
        stdout: StdioCollector { id: listOut }
        stderr: StdioCollector { id: listErr }
        onExited: (code, status) => {
            if (code !== 0) { root.error = listErr.text.trim() || "Could not list themes."; return; }
            try { var data = JSON.parse(listOut.text); root.themes = data.themes; root.current = data.current; root.error = ""; }
            catch (e) { root.error = "Could not read theme list: " + String(e); }
        }
    }
    Process {
        id: applyProc
        command: []
        stdout: StdioCollector { }
        stderr: StdioCollector { id: applyErr }
        onExited: (code, status) => {
            if (code !== 0) root.error = applyErr.text.trim() || "Could not apply theme.";
            else { root.current = applyProc.command[applyProc.command.length - 1]; root.refresh(); }
        }
    }
}
