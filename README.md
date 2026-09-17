# Omarchy-Fedora

Hyprland rice for Fedora 44, inspired by [Omarchy](https://omarchy.org/). Tokyo Night everywhere, vim-style window nav, minimal and keyboard-driven.

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

## Installation Guide

### Prerequisites
- Fedora 44 (or 41+) Workstation
- Active internet connection
- `sudo` privileges

### Step-by-Step

**1. Clone the repo**
```bash
git clone https://github.com/iNSRawat/omarchy-fedora.git
cd omarchy-fedora
```

**2. Make the installer executable**
```bash
chmod +x install.sh
```

**3. (Optional) Preview what will happen**
```bash
./install.sh --dry-run
```

**4. Run the installer**
```bash
./install.sh
```
*(Or `./install.sh -y` to run unattended without prompts)*

What this does automatically:
- Enables the Hyprland COPR repo (`lionheartp/Hyprland`) built for Fedora 44
- Installs Hyprland, Waybar, Rofi, Foot, Starship, Dunst, `hyprpolkitagent`, `hyprland-guiutils`, and Wayland utilities via `dnf5`
- Backs up your existing configs to `~/.config/omarchy-fedora-backup/`
- Symlinks the configs from this repo into `~/.config/`
- Downloads and installs JetBrainsMono Nerd Font
- Sets up the Starship prompt in your `~/.bashrc` (or `~/.zshrc`)

### Direct DNF Package Install

If you want to install the core Hyprland stack directly with DNF:

```bash
sudo dnf5 copr enable -y lionheartp/Hyprland
sudo dnf5 install -y hyprland hyprlock hypridle xdg-desktop-portal-hyprland hyprpolkitagent hyprland-guiutils
```

**5. Log into Hyprland**
1. Save any open work and log out of your current session.
2. At the login screen (GDM), click the **gear icon (⚙️)** in the bottom-right corner.
3. Select **Hyprland** and log in.

**6. Quick verification**
- Press `Super + Enter` to launch the Foot terminal.
- Press `Super + Space` to open the Rofi app launcher.
- Press `Super + C` for the Omarchy calculator (`omacalc`).
- Press `Super + Q` to close the focused window.

### Options

```
./install.sh -y              # skip prompts
./install.sh --dry-run       # see what it'd do without doing it
./install.sh --copy          # copy instead of symlink
./install.sh --config-only   # skip package install
./install.sh --no-copr       # don't add the COPR
./install.sh --copr dtutila/hyprland # use an alternative COPR
./install.sh --omarchy-apps   # install official Omarchy utilities too
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
| `Super + C` | Calculator (`gnome-calculator`) |
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
    hyprland.lua        # modern main config (Hyprland 0.55+ / 0.56+ / 0.57)
    hyprland.conf       # legacy fallback config
    hyprlock.conf       # lock screen
    hypridle.conf       # idle timeouts
    xdph.conf           # screen sharing picker config
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

**Wallpaper** — drop an image in `wallpapers/` and update the swaybg line in `hyprland.lua` (or `hyprland.conf`):
```lua
-- in config/hypr/hyprland.lua:
hl.exec_cmd("swaybg -i " .. home .. "/.local/share/omarchy-fedora/wallpapers/your-wallpaper.jpg -m fill")
```

**Monitors** — edit the `hl.monitor` block in `hyprland.lua`:
```lua
hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@165",
    position = "0x0",
    scale    = 1.25,
})
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

You can uninstall Omarchy-Fedora either using the automated script or manually step-by-step.

### Option A: Automated Uninstaller

Make the script executable (or run directly with `bash`):

```bash
chmod +x uninstall.sh
./uninstall.sh
```

*(Or run `bash uninstall.sh` if your drive is mounted with `noexec`)*

#### Uninstaller Options

| Command | What it does |
|---------|-------------|
| `./uninstall.sh` | Interactive wizard — asks before removing configs, font, and packages |
| `./uninstall.sh -n` or `--dry-run` | Preview what will be removed without touching anything |
| `./uninstall.sh -y` | Non-interactive removal of configs, wallpapers, and shell hooks |
| `./uninstall.sh -p` or `--packages` | Also removes Hyprland RPM packages via DNF |
| `./uninstall.sh --all` | Full cleanup: configs, wallpapers, font, packages, and disables COPR |

### Option B: Step-by-Step Manual Uninstall

If you prefer to uninstall everything manually without running the script:

**1. Remove the deployed config symlinks**
```bash
rm -rf ~/.config/hypr ~/.config/waybar ~/.config/rofi ~/.config/foot ~/.config/dunst ~/.config/starship.toml
```

**2. Remove wallpapers and helper files**
```bash
rm -rf ~/.local/share/omarchy-fedora
```

**3. Restore your original configs from backup**
```bash
LATEST_BACKUP=$(ls -1td ~/.config/omarchy-fedora-backup/* 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
  cp -a "$LATEST_BACKUP"/* ~/.config/
fi
```

**4. Remove Starship prompt from your shell RC**
```bash
sed -i '/starship/d' ~/.bashrc 2>/dev/null || true
sed -i '/starship/d' ~/.zshrc 2>/dev/null || true
```

**5. (Optional) Remove Hyprland packages**
```bash
sudo dnf5 remove -y hyprland hyprlock hypridle xdg-desktop-portal-hyprland hyprpolkitagent hyprland-guiutils
```

**6. (Optional) Disable the COPR repository**
```bash
sudo dnf5 copr disable -y lionheartp/Hyprland
```

**7. (Optional) Remove the downloaded Nerd Font**
```bash
rm -rf ~/.local/share/fonts/JetBrainsMonoNerdFont
fc-cache -f
```

## Troubleshooting

**No Hyprland option at login** — check that `/usr/share/wayland-sessions/hyprland.desktop` exists. If not: `sudo dnf5 reinstall hyprland`.

**Icons are boxes** — the Nerd Font isn't installed or detected. Run `fc-list | grep -i nerd` to check.

**Screen sharing broken** — restart the portal: `systemctl --user restart xdg-desktop-portal-hyprland`.

## Credits

- [Omarchy](https://omarchy.org/) for the original vision
- [Hyprland](https://hypr.land/)
- [lionheartp/Hyprland](https://copr.fedorainfracloud.org/coprs/lionheartp/Hyprland) — Hyprland COPR packages for Fedora
- [Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme) color scheme

## License

MIT — see [LICENSE](LICENSE).
