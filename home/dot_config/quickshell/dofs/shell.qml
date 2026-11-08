//@ pragma IconTheme Yaru
import Quickshell
import Quickshell.Io
import "launcher"
import "bar"
import "dock"
import "connectivity" as Connectivity
import "audio" as Audio
import "notifications" as Notifications
import "wallpaper" as Wallpaper
import "theme" as ThemePicker

ShellRoot {
    Launcher { id: launcher; onOpening: { notificationHost.close(); connectivity.close(); audio.close(); wallpaper.close(); themePicker.close(); } }
    DockHost { id: dock }
    Connectivity.Host {
        id: connectivity
        barHeight: bar.shown ? bar.options.height : 0
        onOpening: { launcher.close(); notificationHost.close(); audio.close(); wallpaper.close(); themePicker.close(); }
    }
    Audio.Host {
        id: audio
        barHeight: bar.shown ? bar.options.height : 0
        onOpening: { launcher.close(); notificationHost.close(); connectivity.close(); wallpaper.close(); themePicker.close(); }
    }
    Notifications.Host {
        id: notificationHost
        niri: bar.service.niri
        barHeight: bar.shown ? bar.options.height : 0
        onOpening: { launcher.close(); connectivity.close(); audio.close(); wallpaper.close(); themePicker.close(); }
    }
    Wallpaper.Host {
        id: wallpaper
        barHeight: bar.shown ? bar.options.height : 0
        onOpening: { launcher.close(); notificationHost.close(); connectivity.close(); audio.close(); themePicker.close(); }
    }
    ThemePicker.Host { id: themePicker; barHeight: bar.shown ? bar.options.height : 0 }
    BarHost {
        id: bar
        notifications: notificationHost.service
        onOpenEntry: entry => {
            if (entry === "network" || entry === "wifi") connectivity.open("wifi");
            else if (entry === "bluetooth" || entry === "hotspot") connectivity.open(entry);
            else if (entry === "notifications") notificationHost.toggle();
            else if (entry === "audio") audio.toggle();
            else if (entry === "wallpapers") wallpaper.toggle();
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
            else if (id === "audio") audio.open("output");
            else if (id === "wallpapers") wallpaper.open();
            else if (id === "themes") themePicker.open();
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
        target: "audio"
        function ping(): string { return "ready"; }
        function open(section: string): void { audio.open(section); }
        function close(): void { audio.close(); }
        function toggle(): void { audio.toggle(); }
        function status(): string {
            return JSON.stringify({opened: audio.opened, tab: audio.tab, ready: audio.service.ready,
                loaded: audio.service.loaded, busy: audio.service.busy, error: audio.service.error});
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
        target: "themes"
        function ping(): string { return "ready"; }
        function open(): void { themePicker.open(); }
        function close(): void { themePicker.close(); }
        function toggle(): void { themePicker.toggle(); }
        function status(): string { return JSON.stringify({opened: themePicker.opened, current: themePicker.service.current, error: themePicker.service.error}); }
    }

    IpcHandler {
        target: "wallpaper"
        function ping(): string { return "ready"; }
        function open(): void { wallpaper.open(); }
        function close(): void { wallpaper.close(); }
        function toggle(): void { wallpaper.toggle(); }
        function restore(): void { wallpaper.service.apply(["--restore"]); }
        function status(): string {
            return JSON.stringify({opened: wallpaper.opened, busy: wallpaper.service.busy,
                error: wallpaper.service.error || wallpaper.service.renderError,
                state: wallpaper.service.state, surfaces: wallpaper.service.surfaces});
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
