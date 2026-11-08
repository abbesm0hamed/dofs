//@ pragma IconTheme Yaru
import Quickshell
import Quickshell.Io
import "launcher"
import "bar"
import "dock"
import "connectivity" as Connectivity
import "notifications" as Notifications

ShellRoot {
    Launcher { id: launcher; onOpening: { notificationHost.close(); connectivity.close(); } }
    DockHost { id: dock }
    Connectivity.Host {
        id: connectivity
        barHeight: bar.shown ? bar.options.height : 0
        onOpening: { launcher.close(); notificationHost.close(); }
    }
    Notifications.Host {
        id: notificationHost
        niri: bar.service.niri
        barHeight: bar.shown ? bar.options.height : 0
        onOpening: { launcher.close(); connectivity.close(); }
    }
    BarHost {
        id: bar
        notifications: notificationHost.service
        onOpenEntry: entry => {
            if (entry === "network" || entry === "wifi") connectivity.open("wifi");
            else if (entry === "bluetooth" || entry === "hotspot") connectivity.open(entry);
            else if (entry === "notifications") notificationHost.toggle();
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
        target: "dock"
        function ping(): string { return "ready"; }
        function toggle(): void { dock.shown = !dock.shown; }
        function show(): void { dock.shown = true; }
        function hide(): void { dock.shown = false; }
        function status(): string {
            return JSON.stringify({shown: dock.shown, error: dock.configError,
                options: dock.options, palette: dock.paletteColors});
        }
    }

    IpcHandler {
        target: "connectivity"
        function ping(): string { return "ready"; }
        function open(section: string): void { connectivity.open(section); }
        function close(): void { connectivity.close(); }
        function status(): string {
            return JSON.stringify({opened: connectivity.opened, tab: connectivity.tab,
                ready: connectivity.service.ready, busy: connectivity.service.busy,
                error: connectivity.service.error});
        }
    }

    IpcHandler {
        target: "idle"
        function ping(): string { return "ready"; }
        function toggle(): void { bar.service.idle.toggle(); }
        function inhibited(): bool { return bar.service.idle.inhibited; }
        function status(): string {
            return JSON.stringify({inhibited: bar.service.idle.inhibited,
                enabled: bar.service.idle.timersEnabled, error: bar.service.idle.error});
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
