#!/usr/bin/env bash
# power menu for rofi
# usage: rofi -show power -modi 'power:~/.config/rofi/power-menu.sh'

if [[ -z "${1:-}" ]]; then
  echo "⏻  Shutdown"
  echo "  Reboot"
  echo "  Suspend"
  echo "  Lock"
  echo "  Logout"
  exit 0
fi

case "$1" in
  *Shutdown*) systemctl poweroff ;;
  *Reboot*)  systemctl reboot ;;
  *Suspend*) systemctl suspend ;;
  *Lock*)    hyprlock ;;
  *Logout*)  hyprctl dispatch exit ;;
esac
