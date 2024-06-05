#!/usr/bin/env bash

playerctlstatus=$(playerctl status 2>/dev/null)

if [[ $playerctlstatus == "" ]]; then

  echo ""

elif [[ $playerctlstatus =~ "Playing" ]]; then

  playerctlshuffle=$(playerctl shuffle 2>/dev/null)

  if [[ $playerctlshuffle == "" ]]; then
    echo "%{A1:playerctl previous:}%{A} %{A1:playerctl pause:}%{A} %{A1:playerctl next:}%{A}"
  elif [[ $playerctlshuffle =~ "Off" ]]; then
    echo "%{A1:playerctl shuffle on:} %{A} %{A1:playerctl previous:}%{A} %{A1:playerctl pause:}%{A} %{A1:playerctl next:}%{A}"
  else
    echo "%{A1:playerctl shuffle off:}劣 %{A} %{A1:playerctl previous:}%{A} %{A1:playerctl pause:}%{A} %{A1:playerctl next:}%{A}"
  fi

else

  echo "%{A1:playerctl play:}%{A}"

fi
