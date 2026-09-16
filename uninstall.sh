#!/usr/bin/env bash
#
# uninstall.sh — undo what install.sh did.
#
# Removes config symlinks/directories, removes wallpapers,
# restores backups if present, cleans starship from shell rcs,
# and optionally removes packages and disables the COPR repo.
#
set -eo pipefail

BACKUP_DIR="$HOME/.config/omarchy-fedora-backup"
WALLPAPERS_DIR="$HOME/.local/share/omarchy-fedora"
CONFIG_DIRS=(hypr waybar rofi foot dunst)
STANDALONE_CONFIGS=(starship.toml)
COPR_REPO="lionheartp/Hyprland"

HYPR_PACKAGES=(
  hyprland
  hyprlock
  hypridle
  xdg-desktop-portal-hyprland
  hyprpolkitagent
  hyprland-guiutils
)

# defaults
ASSUME_YES=0
DRY_RUN=0
DO_RESTORE=1
REMOVE_PACKAGES=0
DISABLE_COPR=0
FORCE_CONFIGS=0
REMOVE_FONT=0

# output helpers
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  RST=$'\033[0m'; BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'
else
  RST=''; BOLD=''; GREEN=''; YELLOW=''; RED=''; CYAN=''
fi

info() { printf '  %s..%s  %s\n' "$CYAN" "$RST" "$*"; }
ok()   { printf '  %sok%s  %s\n' "$GREEN" "$RST" "$*"; }
warn() { printf '  %s!!%s  %s\n' "$YELLOW" "$RST" "$*" >&2; }
die()  { printf '  %sERR%s %s\n' "$RED" "$RST" "$*" >&2; exit 1; }

run() {
  if (( DRY_RUN )); then
    printf '  %s[dry-run]%s %s\n' "$YELLOW" "$RST" "$*"
  else
    "$@"
  fi
}

confirm() {
  (( ASSUME_YES )) && return 0
  local reply=""
  read -rp "  $1 [y/N] " reply || return 1
  [[ "$reply" =~ ^[Yy]$ ]]
}

usage() {
  cat <<EOF
Usage: ./uninstall.sh [options]

Options:
  -y, --yes          automatic yes to prompts (unattended mode)
  -n, --dry-run      print actions without making any changes
  -p, --packages     remove Hyprland RPM packages via DNF
      --copr         disable the Hyprland COPR repository ($COPR_REPO)
      --font         remove downloaded JetBrainsMono Nerd Font
      --force-configs remove config folders even if they aren't symlinks
      --no-restore   don't restore backed-up configs
      --all          remove configs, wallpapers, font, packages, and disable COPR
  -h, --help         show this help message
EOF
}

while (($#)); do
  case "$1" in
    -y|--yes)          ASSUME_YES=1 ;;
    -n|--dry-run)      DRY_RUN=1 ;;
    -p|--packages)     REMOVE_PACKAGES=1 ;;
    --copr)            DISABLE_COPR=1 ;;
    --font)            REMOVE_FONT=1 ;;
    --force-configs)   FORCE_CONFIGS=1 ;;
    --no-restore)      DO_RESTORE=0 ;;
    --all)
      ASSUME_YES=1
      REMOVE_PACKAGES=1
      DISABLE_COPR=1
      REMOVE_FONT=1
      FORCE_CONFIGS=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "unknown option: $1"
      ;;
  esac
  shift
done

find_dnf() {
  if command -v dnf5 &>/dev/null; then
    echo "dnf5"
  else
    echo "dnf"
  fi
}

# 1. remove configs
remove_configs() {
  info "removing deployed configs"
  for d in "${CONFIG_DIRS[@]}"; do
    local t="$HOME/.config/$d"
    if [[ -L "$t" ]]; then
      run rm -rf "$t"
      ok "removed symlink ~/.config/$d"
    elif [[ -d "$t" ]]; then
      if (( FORCE_CONFIGS )); then
        run rm -rf "$t"
        ok "removed directory ~/.config/$d"
      else
        warn "~/.config/$d is a directory (not a symlink)"
        if confirm "remove ~/.config/$d anyway?"; then
          run rm -rf "$t"
          ok "removed ~/.config/$d"
        fi
      fi
    fi
  done

  for f in "${STANDALONE_CONFIGS[@]}"; do
    local t="$HOME/.config/$f"
    if [[ -L "$t" ]]; then
      run rm -f "$t"
      ok "removed symlink ~/.config/$f"
    elif [[ -f "$t" ]]; then
      if (( FORCE_CONFIGS )); then
        run rm -f "$t"
        ok "removed file ~/.config/$f"
      else
        warn "~/.config/$f is a regular file"
        if confirm "remove ~/.config/$f anyway?"; then
          run rm -f "$t"
          ok "removed ~/.config/$f"
        fi
      fi
    fi
  done
}

# 2. remove wallpapers
remove_wallpapers() {
  if [[ -d "$WALLPAPERS_DIR" ]]; then
    info "removing wallpapers from $WALLPAPERS_DIR"
    run rm -rf "$WALLPAPERS_DIR"
    ok "removed $WALLPAPERS_DIR"
  fi
}

# 3. restore backups
restore_backups() {
  (( DO_RESTORE )) || return 0
  [[ -d "$BACKUP_DIR" ]] || { info "no backup directory found, skipping restore"; return 0; }

  local latest=""
  if compgen -G "$BACKUP_DIR/*" &>/dev/null; then
    latest=$(ls -1td "$BACKUP_DIR"/* 2>/dev/null | head -1 || true)
  fi

  [[ -n "$latest" && -d "$latest" ]] || { info "no backups to restore"; return 0; }

  echo ""
  info "found backup: $latest"
  if confirm "restore your original configs from this backup?"; then
    for item in "$latest"/*; do
      [[ -e "$item" ]] || continue
      local name; name=$(basename "$item")
      local dest="$HOME/.config/$name"
      if [[ -e "$dest" ]]; then
        warn "~/.config/$name already exists, skipping restore"
      else
        run cp -a "$item" "$dest"
        ok "restored ~/.config/$name"
      fi
    done
  fi
}

# 4. clean shell rc
clean_shell_rc() {
  info "cleaning shell rc files"
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    if grep -q "starship" "$rc" 2>/dev/null; then
      if (( DRY_RUN )); then
        ok "[dry-run] would remove starship lines from $(basename "$rc")"
      else
        sed -i '/^# starship prompt$/,+2d' "$rc" || true
        # Also clean direct export if added
        sed -i '/export STARSHIP_CONFIG=/d' "$rc" || true
        sed -i '/starship init/d' "$rc" || true
        ok "cleaned $(basename "$rc")"
      fi
    fi
  done
}

# 5. remove nerd font
remove_font() {
  local font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerdFont"
  [[ -d "$font_dir" ]] || return 0

  if (( REMOVE_FONT )) || confirm "remove JetBrainsMono Nerd Font?"; then
    run rm -rf "$font_dir"
    run fc-cache -f &>/dev/null || true
    ok "JetBrainsMono Nerd Font removed"
  fi
}

# 6. remove packages
remove_packages() {
  local dnf; dnf=$(find_dnf)
  local do_pkg=$REMOVE_PACKAGES

  if ! (( do_pkg )) && ! (( ASSUME_YES )); then
    if confirm "also remove Hyprland RPM packages (${HYPR_PACKAGES[*]})?"; then
      do_pkg=1
    fi
  fi

  if (( do_pkg )); then
    info "removing Hyprland packages via $dnf"
    local sudo_cmd=()
    [[ $EUID -ne 0 ]] && sudo_cmd=(sudo)

    run "${sudo_cmd[@]}" "$dnf" -y remove "${HYPR_PACKAGES[@]}" \
      || warn "some packages could not be removed"
    ok "Hyprland packages removed"
  fi

  local do_copr=$DISABLE_COPR
  if ! (( do_copr )) && ! (( ASSUME_YES )) && (( do_pkg )); then
    if confirm "disable the Hyprland COPR repository ($COPR_REPO)?"; then
      do_copr=1
    fi
  fi

  if (( do_copr )); then
    info "disabling COPR repository: $COPR_REPO"
    local sudo_cmd=()
    [[ $EUID -ne 0 ]] && sudo_cmd=(sudo)

    run "${sudo_cmd[@]}" "$dnf" -y copr disable "$COPR_REPO" \
      || warn "could not disable COPR repo $COPR_REPO"
    ok "COPR repository disabled"
  fi
}

# --- main execution ---

echo ""
echo "  ${BOLD}omarchy-fedora uninstaller${RST}"
echo ""

(( DRY_RUN )) && warn "running in dry-run mode — no changes will be made"

if ! (( ASSUME_YES )); then
  confirm "this will remove omarchy-fedora configs. continue?" || exit 0
fi

remove_configs
remove_wallpapers
restore_backups
clean_shell_rc
remove_font
remove_packages

echo ""
echo "  ${GREEN}Done!${RST} Log out and select your preferred desktop session at the login screen."
echo ""
