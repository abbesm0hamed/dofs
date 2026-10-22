//@ pragma IconTheme Yaru
import Quickshell
import Quickshell.Io
import "launcher"

ShellRoot {
    Launcher { id: launcher }

    IpcHandler {
        target: "launcher"
        function ping(): string { return "ready"; }
        function open(): void { launcher.open(); }
        function toggle(): void { launcher.toggle(); }
        function close(): void { launcher.close(); }
        function openEntry(id: string): void { launcher.openEntry(id); }
    }
}
