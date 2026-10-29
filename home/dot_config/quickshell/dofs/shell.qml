//@ pragma IconTheme Yaru
import Quickshell
import Quickshell.Io
import "launcher"
import "bar"

ShellRoot {
    Launcher { id: launcher }
    BarHost {
        id: bar
        onOpenEntry: entry => { if (entry) launcher.openEntry(entry); else launcher.toggle(); }
    }

    IpcHandler {
        target: "bar"
        function ping(): string { return "ready"; }
        function toggle(): void { bar.shown = !bar.shown; }
        function show(): void { bar.shown = true; }
        function hide(): void { bar.shown = false; }
        function refresh(): void { bar.service.updates.refresh(); bar.service.notifications.refresh(); }
        function status(): string {
            return JSON.stringify({shown: bar.shown, niri: bar.service.niri.connected,
                workspaces: bar.service.niri.state.workspaces, stats: bar.service.stats,
                options: bar.options, theme: bar.paletteColors, configError: bar.configError});
        }
    }

    IpcHandler {
        target: "launcher"
        function ping(): string { return "ready"; }
        function open(): void { launcher.open(); }
        function toggle(): void { launcher.toggle(); }
        function close(): void { launcher.close(); }
        function openEntry(id: string): void { launcher.openEntry(id); }
    }
}
