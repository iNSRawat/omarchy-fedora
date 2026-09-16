#!/usr/bin/env bash
#
# uninstall.sh — undo what install.sh did.
#
# Removes config symlinks, restores backups if you have them,
# cleans starship out of your shell rc, optionally removes packages.
#
set -euo pipefail

BACKUP_DIR="$HOME/.config/omarchy-fedora-backup"
CONFIG_DIRS=(hypr waybar rofi foot dunst)
STANDALONE_CONFIGS=(starship.toml)

# output helpers
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  RST=$'\033[0m'; BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
else
  RST=''; BOLD=''; GREEN=''; YELLOW=''; RED=''
fi

ok()   { printf '  %sok%s  %s\n' "$GREEN" "$RST" "$*"; }
warn() { printf '  %s!!%s  %s\n' "$YELLOW" "$RST" "$*" >&2; }
die()  { printf '  %sERR%s %s\n' "$RED" "$RST" "$*" >&2; exit 1; }

confirm() {
  local reply
  read -rp "  $1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# remove config symlinks
remove_configs() {
  echo "  removing configs..."
  for d in "${CONFIG_DIRS[@]}"; do
    local t="$HOME/.config/$d"
    if [[ -L "$t" ]]; then
      rm -f "$t"
      ok "removed $d"
    elif [[ -d "$t" ]]; then
      warn "$d exists but isn't a symlink — leaving it alone"
    fi
  done
  for f in "${STANDALONE_CONFIGS[@]}"; do
    local t="$HOME/.config/$f"
    if [[ -L "$t" ]]; then
      rm -f "$t"
      ok "removed $f"
    elif [[ -f "$t" ]]; then
      warn "$f isn't a symlink — leaving it"
    fi
  done
}

# restore backed-up configs
restore_backups() {
  [[ -d "$BACKUP_DIR" ]] || { warn "no backups found"; return 0; }

  local latest
  latest=$(ls -1t "$BACKUP_DIR" 2>/dev/null | head -1)
  [[ -n "$latest" ]] || { warn "backup dir is empty"; return 0; }

  echo "  latest backup: $BACKUP_DIR/$latest"
  confirm "restore from this backup?" || return 0

  for item in "$BACKUP_DIR/$latest"/*; do
    [[ -e "$item" ]] || continue
    local name; name=$(basename "$item")
    local dest="$HOME/.config/$name"
    if [[ -e "$dest" ]]; then
      warn "$name already exists, skipping"
    else
      mv "$item" "$dest"
      ok "restored $name"
    fi
  done
}

# clean starship init from shell rcs
clean_shell_rc() {
  echo "  cleaning shell rc files..."
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    if grep -q "starship" "$rc"; then
      # remove the block we added
      sed -i '/^# starship prompt$/,+2d' "$rc"
      ok "cleaned $(basename "$rc")"
    fi
  done
}

# optionally remove packages
remove_packages() {
  confirm "remove Hyprland packages too? (probably don't unless you're sure)" || return 0

  local dnf=dnf
  command -v dnf5 &>/dev/null && dnf=dnf5

  sudo "$dnf" -y remove hyprland hyprlock hypridle xdg-desktop-portal-hyprland \
    || warn "some packages couldn't be removed"
  ok "packages removed"
}

# optionally remove nerd font
remove_font() {
  local font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerdFont"
  [[ -d "$font_dir" ]] || return 0
  confirm "remove JetBrainsMono Nerd Font?" || return 0
  rm -rf "$font_dir"
  fc-cache -f &>/dev/null || true
  ok "font removed"
}

# ---

echo ""
echo "  omarchy-fedora uninstaller"
echo ""
confirm "this will remove omarchy-fedora configs. continue?" || exit 1

remove_configs
restore_backups
clean_shell_rc
remove_font
remove_packages

echo ""
echo "  ${GREEN}done.${RST} log out and pick your old session at the login screen."
echo ""
