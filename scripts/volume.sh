#!/usr/bin/env bash
# volume control with dunst OSD
set -euo pipefail

step=5

case "${1:-}" in
  up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%+" -l 1.0 ;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%-" ;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  *)    echo "usage: volume.sh [up|down|mute]" >&2; exit 1 ;;
esac

# show OSD via dunst
vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f", $2 * 100}')
muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED || true)

if (( muted )); then
  icon="audio-volume-muted"
  vol="Muted"
elif (( vol > 66 )); then
  icon="audio-volume-high"
elif (( vol > 33 )); then
  icon="audio-volume-medium"
else
  icon="audio-volume-low"
fi

notify-send -i "$icon" -h "int:value:${vol}" -h "string:x-dunst-stack-tag:volume" \
  -t 1500 "Volume" "${vol}%" 2>/dev/null || true
