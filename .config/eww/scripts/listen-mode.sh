#!/bin/bash

echo "default";
while true; do
    i3-msg -t subscribe '["mode"]' | jq '.change' | cut -d '"' -f2;
done