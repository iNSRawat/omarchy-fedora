#!/usr/bin/env bash
#
# install.sh — sets up an Omarchy-style Hyprland session on Fedora 44.
#
# Installs packages (via dnf5), deploys configs, grabs the Nerd Font,
# and sets up Starship. Backs up anything it'd overwrite.
#
# Run with --help for options, or just: ./install.sh
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$REPO_DIR/config"
SCRIPTS_SRC="$REPO_DIR/scripts"
WALLPAPERS_SRC="$REPO_DIR/wallpapers"
BACKUP_DIR="$HOME/.config/omarchy-fedora-backup"
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"

CONFIG_DIRS=(hypr waybar rofi foot dunst)
STANDALONE_CONFIGS=(starship/starship.toml)

DEFAULT_COPR="lionheartp/Hyprland"

HYPR_PACKAGES=(hyprland hyprlock hypridle xdg-desktop-portal-hyprland)

CORE_PACKAGES=(
  waybar rofi-wayland foot starship dunst swaybg
  wl-clipboard cliphist grim slurp jq
  brightnessctl pavucontrol playerctl polkit-gnome
)

EXTRA_PACKAGES=(
  jetbrains-mono-fonts-all xdg-desktop-portal xdg-desktop-portal-gtk
  qt6ct network-manager-applet blueman thunar papirus-icon-theme
  curl unzip
)

OMARCHY_COPR="whelanh/omarchy"
OMARCHY_PACKAGES=(
  hyprland-preview-share-picker
  omacalc
  omawrite
  omacut
  herdr
  ttfx
)

# defaults
ASSUME_YES=0
DRY_RUN=0
COPY_MODE=0
DO_PACKAGES=1
DO_COPR=1
DO_OMARCHY_APPS=0
DO_FONT=1
DO_SHELL_INIT=1
COPR="$DEFAULT_COPR"

# --- output helpers ---

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  RST=$'\033[0m'; BOLD=$'\033[1m'; BLUE=$'\033[34m'
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
else
  RST=''; BOLD=''; BLUE=''; GREEN=''; YELLOW=''; RED=''
fi

info()  { printf '%s==>%s %s\n' "$BLUE$BOLD" "$RST" "$*"; }
ok()    { printf '  %sok%s  %s\n' "$GREEN" "$RST" "$*"; }
warn()  { printf '  %s!!%s  %s\n' "$YELLOW" "$RST" "$*" >&2; }
die()   { printf '  %sERR%s %s\n' "$RED" "$RST" "$*" >&2; exit 1; }
have()  { command -v "$1" &>/dev/null; }

run() {
  if (( DRY_RUN )); then
    printf '  [dry] %s\n' "$*"
    return 0
  fi
  "$@"
}

confirm() {
  (( ASSUME_YES )) && return 0
  local reply
  read -rp "  $1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# --- arg parsing ---

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  -y, --yes            no prompts
  -n, --dry-run        just print, don't do anything
      --copy           copy configs instead of symlink
      --config-only    skip package install
      --no-copr        don't enable Hyprland COPR
      --copr <repo>    use a different COPR (default: solopasha/hyprland)
      --omarchy-apps   install official Omarchy tools (from whelanh/omarchy)
      --no-font        skip Nerd Font download
      --no-shell-init  don't touch bashrc/zshrc
  -h, --help           this message
EOF
}

while (($#)); do
  case "$1" in
    -y|--yes)         ASSUME_YES=1 ;;
    -n|--dry-run)     DRY_RUN=1 ;;
    --copy)           COPY_MODE=1 ;;
    --config-only)    DO_PACKAGES=0 ;;
    --no-copr)        DO_COPR=0 ;;
    --copr)           shift; COPR="${1:?--copr needs a value}" ;;
    --omarchy-apps)   DO_OMARCHY_APPS=1 ;;
    --no-font*)       DO_FONT=0 ;;
    --no-shell-init)  DO_SHELL_INIT=0 ;;
    -h|--help)        usage; exit 0 ;;
    *)                usage >&2; die "unknown option: $1" ;;
  esac
  shift
done

# --- checks ---

SUDO=()
if [[ $EUID -ne 0 ]]; then
  have sudo || die "need sudo (or run as root)"
  SUDO=(sudo)
fi

check_fedora() {
  local id="" version=""
  [[ -r /etc/os-release ]] && . /etc/os-release
  id="${ID:-}"; version="${VERSION_ID:-}"

  if [[ "$id" != "fedora" ]]; then
    warn "this is meant for Fedora (got: ${PRETTY_NAME:-unknown})"
    confirm "continue anyway?" || exit 1
  else
    ok "${PRETTY_NAME:-Fedora}"
  fi

  if [[ -n "$version" ]] && (( ${version%%.*} < 41 )); then
    warn "Fedora $version — this targets 41+, dnf5 might not be default"
  fi
}

# figure out the package manager
find_dnf() {
  if have dnf5; then
    DNF=dnf5
  elif have dnf; then
    DNF=dnf
  else
    die "can't find dnf"
  fi
  ok "using $DNF"
}

# --- package install ---

enable_copr() {
  (( DO_COPR )) || return 0
  info "enabling Hyprland COPR: $COPR"
  if ! run "${SUDO[@]}" "$DNF" -y copr enable "$COPR"; then
    warn "couldn't enable $COPR on this Fedora release"
    for fallback in "dtutila/hyprland" "lionheartp/Hyprland"; do
      if [[ "$COPR" != "$fallback" ]]; then
        info "trying fallback COPR: $fallback"
        if run "${SUDO[@]}" "$DNF" -y copr enable "$fallback"; then
          COPR="$fallback"
          ok "enabled fallback COPR: $fallback"
          return 0
        fi
      fi
    done
    die "failed to enable a working Hyprland COPR repository"
  fi
}

install_packages() {
  (( DO_PACKAGES )) || { warn "skipping packages (--config-only)"; return 0; }

  info "installing core packages"
  run "${SUDO[@]}" "$DNF" -y install "${CORE_PACKAGES[@]}" \
    || warn "some core packages failed"

  info "installing Hyprland stack"
  if ! run "${SUDO[@]}" "$DNF" -y install "${HYPR_PACKAGES[@]}"; then
    die "Hyprland packages failed to install! Run: sudo $DNF copr enable $COPR"
  fi

  info "installing extras"
  run "${SUDO[@]}" "$DNF" -y install "${EXTRA_PACKAGES[@]}" \
    || warn "some extras failed (non-critical)"

  if (( DO_OMARCHY_APPS )); then
    info "enabling Omarchy COPR ($OMARCHY_COPR)"
    run "${SUDO[@]}" "$DNF" -y copr enable "$OMARCHY_COPR" \
      || warn "couldn't enable $OMARCHY_COPR"

    info "installing Omarchy apps (share picker, omacalc, etc.)"
    run "${SUDO[@]}" "$DNF" -y install "${OMARCHY_PACKAGES[@]}" \
      || warn "some Omarchy apps failed to install (non-critical)"
  fi
}

# --- nerd font ---

install_nerd_font() {
  (( DO_FONT )) || return 0

  local font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerdFont"

  if [[ -d "$font_dir" ]] && compgen -G "$font_dir/*.ttf" &>/dev/null; then
    ok "nerd font already installed"
    return 0
  fi

  have curl && have unzip || { warn "need curl+unzip for font download, skipping"; return 0; }

  info "downloading JetBrainsMono Nerd Font"
  local tmp; tmp=$(mktemp -d)
  run curl -fL --retry 3 --progress-bar -o "$tmp/font.zip" "$NERD_FONT_URL" \
    || { warn "download failed"; rm -rf "$tmp"; return 0; }

  run mkdir -p "$font_dir"
  run unzip -qo "$tmp/font.zip" -d "$font_dir" '*.ttf' || true
  rm -rf "$tmp"
  have fc-cache && run fc-cache -f "$font_dir" &>/dev/null || true
  ok "nerd font -> $font_dir"
}

# --- config deployment ---

backup() {
  local target=$1
  local stamp; stamp=$(date +%Y%m%d-%H%M%S)
  local dest="$BACKUP_DIR/$stamp/$(basename "$target")"
  run mkdir -p "$(dirname "$dest")"
  run mv "$target" "$dest"
  warn "backed up $(basename "$target") -> $dest"
}

deploy() {
  local src=$1 dest=$2 name=$3
  [[ -e "$src" ]] || { warn "missing: $src"; return 0; }
  run mkdir -p "$(dirname "$dest")"

  # already linked correctly
  if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    ok "$name (already linked)"
    return 0
  fi

  # back up existing stuff
  [[ -e "$dest" && ! -L "$dest" ]] && backup "$dest"
  [[ -L "$dest" ]] && run rm -f "$dest"

  if (( COPY_MODE )); then
    if [[ -d "$src" ]]; then
      run mkdir -p "$dest"
      run cp -a "$src/." "$dest/"
    else
      run cp -a "$src" "$dest"
    fi
    ok "$name (copied)"
  else
    run ln -sfn "$src" "$dest"
    ok "$name (linked)"
  fi
}

deploy_configs() {
  local mode; mode=$( (( COPY_MODE )) && echo "copy" || echo "symlink" )
  info "deploying configs ($mode)"

  for d in "${CONFIG_DIRS[@]}"; do
    deploy "$CONFIG_SRC/$d" "$HOME/.config/$d" "$d"
  done

  for f in "${STANDALONE_CONFIGS[@]}"; do
    deploy "$CONFIG_SRC/$f" "$HOME/.config/$(basename "$f")" "$(basename "$f")"
  done
}

deploy_scripts() {
  [[ -d "$SCRIPTS_SRC" ]] || return 0
  info "installing helper scripts"

  local dest="$HOME/.config/hypr/scripts"
  run mkdir -p "$dest"

  for f in "$SCRIPTS_SRC"/*; do
    [[ -f "$f" ]] || continue
    if (( COPY_MODE )); then
      run install -m 755 "$f" "$dest/"
    else
      run ln -sfn "$f" "$dest/$(basename "$f")"
    fi
  done
  chmod +x "$dest"/*.sh 2>/dev/null || true
  ok "scripts -> ~/.config/hypr/scripts"
}

deploy_wallpapers() {
  [[ -d "$WALLPAPERS_SRC" ]] && compgen -G "$WALLPAPERS_SRC/*" &>/dev/null || return 0
  info "copying wallpapers"
  local dest="$HOME/.local/share/omarchy-fedora/wallpapers"
  run mkdir -p "$dest"
  run cp -a "$WALLPAPERS_SRC/." "$dest/"
  ok "wallpapers -> $dest"
}

# --- shell init (starship) ---

setup_starship() {
  (( DO_SHELL_INIT )) || return 0
  info "setting up starship"

  local config_line='export STARSHIP_CONFIG="$HOME/.config/starship.toml"'

  # bash
  if [[ -f "$HOME/.bashrc" ]]; then
    if ! grep -q "starship init bash" "$HOME/.bashrc"; then
      printf '\n# starship prompt\n%s\neval "$(starship init bash)"\n' \
        "$config_line" >> "$HOME/.bashrc"
      ok "added to ~/.bashrc"
    else
      ok "already in ~/.bashrc"
    fi
  fi

  # zsh
  if [[ -f "$HOME/.zshrc" ]]; then
    if ! grep -q "starship init zsh" "$HOME/.zshrc"; then
      printf '\n# starship prompt\n%s\neval "$(starship init zsh)"\n' \
        "$config_line" >> "$HOME/.zshrc"
      ok "added to ~/.zshrc"
    else
      ok "already in ~/.zshrc"
    fi
  fi
}

# --- main ---

echo ""
echo "  omarchy-fedora installer"
echo "  Hyprland + Tokyo Night for Fedora 44"
echo ""

(( DRY_RUN )) && warn "dry run — nothing will be changed"

check_fedora
find_dnf

if ! (( ASSUME_YES )); then
  echo ""
  echo "  This will install Hyprland and a bunch of supporting packages,"
  echo "  then deploy Omarchy-style configs. Your existing configs get"
  echo "  backed up to ~/.config/omarchy-fedora-backup/ first."
  echo ""
  confirm "ready?" || exit 1
  if confirm "also install official Omarchy apps (share picker, omacalc, etc.)?"; then
    DO_OMARCHY_APPS=1
  fi
fi

enable_copr
install_packages
install_nerd_font
deploy_configs
deploy_scripts
deploy_wallpapers
  # verify session registered with GDM
  if [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
    ok "Hyprland session registered in /usr/share/wayland-sessions/"
  else
    warn "warning: /usr/share/wayland-sessions/hyprland.desktop was not found"
    warn "Hyprland might not appear in GDM. Run: sudo $DNF reinstall hyprland"
  fi

  echo ""
  echo "  ${GREEN}done!${RST}"
echo ""
echo "  Log out, pick Hyprland at the login screen, log back in."
echo "  Super+Enter for terminal, Super+Space for launcher."
echo ""