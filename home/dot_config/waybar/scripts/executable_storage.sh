#!/bin/sh

mount="/"
warning=20
critical=10

df -h -P -l "$mount" 2>/dev/null | awk -v warning="$warning" -v critical="$critical" '
NR==2 {
  fs=$1
  size=$2
  used=$3
  avail=$4
  usep=$5
  mnt=$6

  gsub(/%$/, "", usep)

  text=avail
  tooltip="Storage: " used " / " size " (" usep "%)\\nAvail: " avail "\\nFilesystem: " fs "\\nMounted on: " mnt

  class=""
  free=100-usep
  if (free < critical) {
    class="critical"
  } else if (free < warning) {
    class="warning"
  }

  gsub(/\\/, "\\\\", text)
  gsub(/\"/, "\\\"", text)
  gsub(/\\/, "\\\\", tooltip)
  gsub(/\"/, "\\\"", tooltip)

  print "{\"text\":\"" text "\",\"percentage\":" usep ",\"tooltip\":\"" tooltip "\",\"class\":\"" class "\"}"
  exit 0
}

END {
  if (NR < 2) {
    print "{\"text\":\"\",\"class\":\"hidden\"}"
  }
}
'
