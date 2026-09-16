#!/usr/bin/env bash
# brightness control with dunst OSD
set -euo pipefail

step=5

case "${1:-}" in
  up)   brightnessctl set "${step}%+" ;;
  down) brightnessctl set "${step}%-" ;;
  *)    echo "usage: brightness.sh [up|down]" >&2; exit 1 ;;
esac

brightness=$(brightnessctl -m | awk -F, '{print $4}' | tr -d '%')

if (( brightness > 66 )); then
  icon="display-brightness-high"
elif (( brightness > 33 )); then
  icon="display-brightness-medium"
else
  icon="display-brightness-low"
fi

notify-send -i "$icon" -h "int:value:${brightness}" \
  -h "string:x-dunst-stack-tag:brightness" \
  -t 1500 "Brightness" "${brightness}%" 2>/dev/null || true
