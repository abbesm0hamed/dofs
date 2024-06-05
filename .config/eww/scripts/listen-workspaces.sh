#!/bin/bash
get_workspaces() {
    i3-msg -t get_workspaces
}

get_workspaces;
while true; do
    i3-msg -t subscribe '["workspace"]' > /dev/null && get_workspaces;
done