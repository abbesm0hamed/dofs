# Quickshell connectivity panel

Click the Wi-Fi or Bluetooth icon in the bar, or search the launcher for
Network settings, Bluetooth settings, or Mobile hotspot. The settings and
system controls menus also open the panel. Escape, Close, or clicking outside
closes it.

The Wi-Fi tab scans nearby networks, shows signal/security and the current IP
address, and connects using saved profiles or a password entered in the panel.
New WPA personal and open networks are supported. Enterprise/WPA3-only/WEP
configuration remains available through Advanced network settings. Existing
saved profiles can still connect through NetworkManager. Updating a saved WPA
personal password preserves the profile’s UUID and IP settings. If a password
previously held by an applet is unavailable, enter it again in the panel.

The Hotspot tab shares internet through NetworkManager's IPv4 shared mode
(DHCP and NAT). Choose an adapter, set a name and WPA2 password, and confirm
Start. The active hotspot shows its name, interface, IP address, and a button
to reveal its saved password. Stop hotspot stops sharing. Profiles do not
autoconnect and are reused on subsequent starts.

Keep my current Wi-Fi connection is enabled by default. For an adapter that
supports simultaneous managed/AP mode, the backend creates a `dofs-apN`
interface on the same radio and channel, preserving the existing connection.
Preparing that interface uses `pkexec iw`, so the session's polkit agent may
ask for administrator authentication. This mode supports 2.4 GHz and 5 GHz;
regulatory restrictions or driver limitations can still prevent activation.
The extra interface remains available until reboot, avoiding repeated prompts.
If simultaneous operation is unavailable, use Ethernet, USB tethering, or a
second Wi-Fi adapter. Disabling Keep my current Wi-Fi connection explicitly
allows the selected adapter's current connection to be replaced.

Bluetooth supports radio power, soft-block recovery, discovery, pairing with
confirmation/PIN/passkey prompts, connect/disconnect, and confirmed removal of
paired devices. Scanning belongs to this panel's BlueZ client and stops when
that client exits. Hardware radio blocks require a hardware/firmware change.

NetworkManager, BlueZ, polkit, `iw`, and Python's GObject bindings remain the
backends. No Blueman UI or network applet is needed for these panel actions.
Ansible excludes `blueman`, `network-manager-applet`, and `crystal-dock` from
its installation list. Existing installations are not explicitly removed. The
advanced `nm-connection-editor` remains available for VPNs and uncommon Wi-Fi
security. Passwords travel over the backend's private stdin pipe and D-Bus,
never command arguments or diagnostic logs. Input fields and revealed hotspot
passwords are cleared when the panel closes. NetworkManager stores credentials
using its own profile permissions and secret handling.

The backend runs and refreshes status only while the panel is open. Opening
it requests one Wi-Fi scan when Wi-Fi is on and no hotspot is active. Radio
power, Bluetooth discovery, connections, and hotspot activation require user
actions. Closing the panel does not stop an active network or hotspot.

Validation:

```sh
PYTHONDONTWRITEBYTECODE=1 DOFS_QML_TEST=1 /usr/bin/python3 -m unittest discover -s scripts/tests -p test_quickshell_connectivity.py
```

Integration checks can read live D-Bus status without activating connections.
Starting a hotspot and pairing real devices require explicit on-device testing.
