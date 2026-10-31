//@ pragma IconTheme Yaru
import Quickshell
import Quickshell.Io
import "launcher"
import "bar"
import "notifications" as Notifications

ShellRoot {
    Launcher { id: launcher; onOpening: notificationHost.close() }
    Notifications.Host {
        id: notificationHost
        niri: bar.service.niri
        barHeight: bar.shown ? bar.options.height : 0
        onOpening: launcher.close()
    }
    BarHost {
        id: bar
        notifications: notificationHost.service
        onOpenEntry: entry => {
            if (entry === "notifications") notificationHost.toggle();
            else if (entry) launcher.openEntry(entry);
            else launcher.toggle();
        }
    }

    IpcHandler {
        target: "bar"
        function ping(): string { return "ready"; }
        function toggle(): void { bar.shown = !bar.shown; }
        function show(): void { bar.shown = true; }
        function hide(): void { bar.shown = false; }
        function refresh(): void { bar.service.updates.refresh(); }
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
        function openEntry(id: string): void {
            if (id === "notifications") notificationHost.open();
            else launcher.openEntry(id);
        }
    }

    IpcHandler {
        target: "notifications"
        function ping(): string { return "ready"; }
        function open(): void { notificationHost.open(); }
        function close(): void { notificationHost.close(); }
        function toggle(): void { notificationHost.toggle(); }
        function toggleDnd(): void { notificationHost.service.toggleDnd(); }
        function dnd(): bool { return notificationHost.service.dnd; }
        function dismissPopups(): void { notificationHost.service.dismissPopups(); }
        function markRead(): void { notificationHost.service.markRead(); }
        function clear(): void { notificationHost.service.clear(); }
        function status(): string {
            var service = notificationHost.service;
            return JSON.stringify({opened: notificationHost.opened, dnd: service.dnd,
                unread: service.unreadCount, count: service.entries.length,
                loaded: service.loaded, error: service.error});
        }
    }
}
