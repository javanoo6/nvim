#!/bin/sh
set -eu

if ! command -v pgrep >/dev/null 2>&1 || ! command -v pkill >/dev/null 2>&1; then
  echo 'Error: pgrep and pkill are required.' >&2
  exit 1
fi

pattern='[i]deaformatter[[:space:]]+--daemon([[:space:]]|$)'
if ! pgrep -u "$(id -u)" -f "$pattern" >/dev/null; then
  echo 'No formatter daemons running.'
  exit 0
fi
pkill -u "$(id -u)" -f "$pattern"
echo 'Sent termination signal to formatter daemons.'
