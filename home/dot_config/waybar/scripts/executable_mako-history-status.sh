#!/usr/bin/env bash
# Compatibility entry point for the archived bar.
qs -c dofs ipc call notifications status | jq -c '{text: ("󰂞 " + (.unread | tostring)), tooltip: "Quickshell notification center"}'
