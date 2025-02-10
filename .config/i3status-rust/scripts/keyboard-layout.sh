#!/bin/bash
setxkbmap -query | grep layout | awk '{print $2}'
