#!/usr/bin/env bash
# screenshot to clipboard + file
set -euo pipefail

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"

case "${1:-region}" in
  region)
    grim -g "$(slurp -d)" "$file"
    ;;
  full)
    grim "$file"
    ;;
  window)
    geom=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    grim -g "$geom" "$file"
    ;;
  *)
    echo "usage: screenshot.sh [region|full|window]" >&2
    exit 1
    ;;
esac

wl-copy < "$file"
notify-send -i "$file" "Screenshot" "Saved and copied" 2>/dev/null || true
