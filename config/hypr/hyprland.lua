-- hyprland.lua — Omarchy-style Hyprland configuration for Fedora
-- Modern Lua config format (Hyprland 0.55+)
-- https://wiki.hypr.land/Configuring/

------------------
---- MONITORS ----
------------------

-- Monitor setup (change this for your setup)
-- Example: hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "0x0", scale = 1.25 })
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-------------------
---- AUTOSTART ----
-------------------

local home = os.getenv("HOME") or ""
local scripts = home .. "/.config/hypr/scripts"

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent || /usr/libexec/hyprpolkitagent")
    hl.exec_cmd("swaybg -i " .. home .. "/.local/share/omarchy-fedora/wallpapers/minimal-bars.jpg -m fill || swaybg -c '#1a1b26'")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgb(7aa2f7)", "rgb(bb9af7)" }, angle = 45 },
            inactive_border = "rgb(24283b)",
        },
        layout = "dwindle",
        allow_tearing = false,
    },

    decoration = {
        rounding = 8,
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            new_optimizations = true,
            xray = false,
        },
        shadow = {
            enabled = true,
            range = 15,
            render_power = 3,
            color = "rgba(1a1a2eee)",
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_hyprland_guiutils_check = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },

    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            drag_lock = true,
        },
    },
})

--------------------
---- ANIMATIONS ----
--------------------

hl.curve("overshot",   { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("smoothOut",  { type = "bezier", points = { {0.36, 0},   {0.66, -0.56} } })
hl.curve("smoothIn",   { type = "bezier", points = { {0.25, 1},   {0.5, 1} } })

hl.animation({ leaf = "windows",     enabled = true, speed = 4,  bezier = "overshot",  style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 4,  bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 40, bezier = "default",  style = "loop" })
hl.animation({ leaf = "fade",        enabled = true, speed = 4,  bezier = "smoothIn" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 4,  bezier = "default" })

----------------------
---- WINDOW RULES ----
----------------------

local window_rules = {
    { name = "float-pavucontrol", match = { class = "pavucontrol" }, float = true },
    { name = "float-nm-connection-editor", match = { class = "nm-connection-editor" }, float = true },
    { name = "float-blueman", match = { class = "blueman-manager" }, float = true },
    { name = "float-pip", match = { title = "Picture-in-Picture" }, float = true },
    { name = "float-open-file", match = { title = "Open File" }, float = true },
    { name = "float-save-file", match = { title = "Save File" }, float = true },
    { name = "float-calc", match = { class = "gnome-calculator" }, float = true },
    { name = "float-omacalc", match = { class = "omacalc" }, float = true },
    { name = "float-share-picker", match = { class = "hyprland-preview-share-picker" }, float = true },
    { name = "opacity-foot", match = { class = "foot" }, opacity = "0.92 0.88" },
    { name = "opacity-code", match = { class = "Code" }, opacity = "0.95 0.90" },
    { name = "opacity-code-url", match = { class = "code-url-handler" }, opacity = "0.95 0.90" },
}

for _, rule in ipairs(window_rules) do
    hl.window_rule(rule)
end

---------------------
---- KEYBINDINGS ----
---------------------

local function dispatch(cmd, arg)
    return function()
        hl.dispatch(cmd, arg or "")
    end
end

local mainMod = "SUPER"

-- Apps
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("foot"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("rofi -show drun -show-icons"))
hl.bind(mainMod .. " + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("gnome-calculator"))

-- Window management
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))

-- Focus (Vim-style + Arrows)
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + semicolon", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))

-- Move windows (Vim-style)
hl.bind(mainMod .. " + SHIFT + h", dispatch("movewindow", "l"))
hl.bind(mainMod .. " + SHIFT + j", dispatch("movewindow", "d"))
hl.bind(mainMod .. " + SHIFT + k", dispatch("movewindow", "u"))
hl.bind(mainMod .. " + SHIFT + l", dispatch("movewindow", "r"))

-- Resize active window
hl.bind(mainMod .. " + CTRL + h", dispatch("resizeactive", "-30 0"), { repeating = true })
hl.bind(mainMod .. " + CTRL + j", dispatch("resizeactive", "0 30"), { repeating = true })
hl.bind(mainMod .. " + CTRL + k", dispatch("resizeactive", "0 -30"), { repeating = true })
hl.bind(mainMod .. " + CTRL + l", dispatch("resizeactive", "30 0"), { repeating = true })

-- Workspaces 1-9
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Workspace navigation
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Mouse window drag & resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys (Volume & Mic)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scripts .. "/volume.sh up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scripts .. "/volume.sh down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scripts .. "/volume.sh mute"), { locked = true })

-- Multimedia keys (Brightness)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scripts .. "/brightness.sh up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "/brightness.sh down"), { locked = true, repeating = true })

-- Screenshots
hl.bind("PRINT", hl.dsp.exec_cmd(scripts .. "/screenshot.sh region"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd(scripts .. "/screenshot.sh full"))
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd(scripts .. "/screenshot.sh window"))

