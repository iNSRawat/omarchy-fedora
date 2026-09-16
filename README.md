# Omarchy-Fedora

Hyprland rice for Fedora 44, inspired by [Omarchy](https://omarchy.com/). Tokyo Night everywhere, vim-style window nav, minimal and keyboard-driven.

![Fedora 44](https://img.shields.io/badge/Fedora-44-blue?logo=fedora)

<!-- screenshot goes here once you've got one you like -->
<!-- ![screenshot](assets/screenshot.png) -->

## What's in here

- **Hyprland** — tiling compositor with gaps, blur, animations
- **Waybar** — floating pill-style bar, Tokyo Night
- **Rofi** — app launcher
- **Foot** — terminal
- **Starship** — shell prompt
- **Dunst** — notifications
- **Hyprlock + Hypridle** — lock screen (blurred screenshot) and idle management
- Helper scripts for screenshots, volume/brightness OSD, power menu

## Install

Needs Fedora 44 (or 41+), sudo, internet.

```bash
git clone https://github.com/iNSRawat/omarchy-fedora.git
cd omarchy-fedora
./install.sh
```

This will:
- Enable the Hyprland COPR repo (`solopasha/hyprland`)
- Install everything through dnf5
- Back up your existing `~/.config` stuff before touching anything
- Symlink configs from this repo into place
- Grab JetBrainsMono Nerd Font
- Set up Starship in your bashrc/zshrc

Then log out, pick **Hyprland** from the gear menu at GDM, and log back in.

### Options

```
./install.sh -y              # skip prompts
./install.sh --dry-run       # see what it'd do without doing it
./install.sh --copy          # copy instead of symlink
./install.sh --config-only   # skip package install
./install.sh --no-copr       # don't add the COPR
./install.sh --no-font       # skip nerd font download
./install.sh --no-shell-init # don't touch bashrc/zshrc
```

## Keybindings

Everything is `SUPER` + something. Vim-style (`h/j/k/l`) for window focus.

### Basics

| Key | What it does |
|-----|-------------|
| `Super + Enter` | Terminal |
| `Super + Space` | App launcher |
| `Super + Q` | Kill window |
| `Super + L` | Lock |
| `Super + E` | File manager |
| `Super + Shift + E` | Quit Hyprland |

### Windows

| Key | What it does |
|-----|-------------|
| `Super + h/j/k` | Focus left/down/up |
| `Super + ;` | Focus right |
| `Super + Shift + h/j/k/l` | Move window |
| `Super + Ctrl + h/j/k/l` | Resize |
| `Super + F` | Fullscreen |
| `Super + V` | Float |
| `Super + 1-9` | Workspace |
| `Super + Shift + 1-9` | Send to workspace |

### Media

Volume keys, brightness keys, and Print Screen all work. Print does region screenshot to clipboard, `Super + Print` does full screen, `Super + Shift + Print` does active window.

## Layout

```
config/
  hypr/
    hyprland.conf       # main config
    hyprlock.conf       # lock screen
    hypridle.conf       # idle timeouts
  waybar/
    config.jsonc        # bar layout
    style.css           # bar styling
  rofi/
    config.rasi         # launcher theme
  foot/
    foot.ini            # terminal
  dunst/
    dunstrc             # notifications
  starship/
    starship.toml       # prompt
scripts/
  screenshot.sh
  volume.sh
  brightness.sh
  power-menu.sh
```

## Customization

**Wallpaper** — drop an image in `wallpapers/` and change the swaybg line in hyprland.conf:
```ini
exec-once = swaybg -i ~/path/to/wallpaper.jpg -m fill
```

**Monitors** — edit the `monitor` line:
```ini
monitor = DP-1, 2560x1440@165, 0x0, 1.25
```

**Colors** — everything uses Tokyo Night. The main values:
- Background: `#1a1b26`
- Foreground: `#c0caf5`
- Blue: `#7aa2f7`
- Purple: `#bb9af7`
- Red: `#f7768e`
- Green: `#9ece6a`
- Yellow: `#e0af68`
- Cyan: `#7dcfff`

If you want a different scheme, you'll need to find-and-replace across the config files. Might script that someday.

## Idle / Lock behavior

Hypridle does this progression:

1. **2.5 min** — dim the screen
2. **5 min** — lock (hyprlock with blurred screenshot)
3. **5.5 min** — displays off
4. **30 min** — suspend

Edit `config/hypr/hypridle.conf` to adjust the timeouts.

## Uninstall

```bash
./uninstall.sh
```

Removes the symlinks, offers to restore your backed-up configs, and optionally removes packages.

## Troubleshooting

**No Hyprland option at login** — check that `/usr/share/wayland-sessions/hyprland.desktop` exists. If not: `sudo dnf5 reinstall hyprland`.

**Icons are boxes** — the Nerd Font isn't installed or detected. Run `fc-list | grep -i nerd` to check.

**Screen sharing broken** — restart the portal: `systemctl --user restart xdg-desktop-portal-hyprland`.

## Credits

- [Omarchy](https://omarchy.com/) for the original vision
- [Hyprland](https://hyprland.org/)
- [Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme) color scheme

## License

MIT — see [LICENSE](LICENSE).
