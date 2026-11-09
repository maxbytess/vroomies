local colors = require("colors")

------------------
---- MONITORS ----
------------------

hl.monitor({
    output    = "eDP-1",
    mode      = "1920x1080@144",
    position  = "0x0",
    scale     = "1",
    transform = 0
})

---------------------
---- MY PROGRAMS ----
---------------------

local qsdir = "~/.config/quickshell/nn"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal")
    hl.exec_cmd("/nix/store/409xg4jpxgs56m0m62791dqcwkhp8dya-system-path/libexec/polkit-kde-authentication-agent-1")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-decoration-layout ':'")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && awww img ~/.config/niri/wall --transition-type grow --transition-duration 1.5")
    hl.exec_cmd("qs -c nn")
    hl.exec_cmd("easyeffects &")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 16,
        gaps_out = 16,
        border_size = 2,
        col = {
            active_border = "#ffffff",
            inactive_border = "#333333"
        },
        resize_on_border = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        
        shadow = {
            enabled = true,
            range = 40,
            render_power = 6,
            color = 0xee000000,
        },
        
        blur = {
            enabled = true,
            size = 3,
            passes = 3,
            noise = 0.02,
            vibrancy = 0.1696,
            new_optimizations = true
        },
    },

    animations = {
        enabled = true,
    },

    input = {
        kb_layout = "tr",
        follow_mouse = 1,
        sensitivity = 0,
        accel_profile = "flat",
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        }
    }
})

hl.curve("niriOpen", { type = "bezier", points = {{0.05, 0.7}, {0.1, 1.0}} })
hl.curve("niriClose", { type = "bezier", points = {{0.4, 0.0}, {1.0, 1.0}} })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 1.8, bezier = "niriOpen", style = "popin 90%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.8, bezier = "niriOpen" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.3, bezier = "niriClose", style = "popin 90%" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.3, bezier = "niriClose" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "default", style = "slide" })

hl.config({ dwindle = { preserve_split = true } })
hl.config({ misc = { force_default_wallpaper = -1, disable_hyprland_logo = true } })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name = "global-style",
    match = { class = ".*" },
    rounding = 8
})

hl.window_rule({
    name = "firefox-pip",
    match = { class = "^(firefox)$", title = "^Picture-in-Picture$" },
    float = true,
})

hl.window_rule({
    name = "pavucontrol",
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    float = true,
})

hl.window_rule({
    name = "blueman",
    match = { class = "^(blueman-manager)$" },
    float = true,
})

hl.window_rule({
    name = "nautilus-picker",
    match = { class = "^(org.gnome.Nautilus)$", title = "^flutter picker$" },
    float = true,
})

hl.window_rule({
    name = "no-maximize",
    match = { class = "^(firefox|kitty|code|obs|org.telegram.desktop|org.kde.dolphin)$" },
    suppress_event = "maximize",
})

hl.layer_rule({
    name = "quickshell-dock",
    match = { namespace = "quickshell-dock" },
    blur = false,
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("flatpak run com.brave.Browser --enable-features=UseOzonePlatform --ozone-platform=wayland"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd("dolphin"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs -c nn ipc --any-display call sky toggle"))

hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("code"))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Tab",       hl.dsp.exec_cmd("hyprctl dispatch toggleoverview"))

hl.bind("Print",           hl.dsp.exec_cmd("grim ~/Pictures/Screenshots/'Screenshot from '$(date +'%Y-%m-%d %H-%M-%S')'.png'"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | swappy -f -"))
hl.bind("CTRL + Print",    hl.dsp.exec_cmd("grim ~/Pictures/Screenshots/'Screenshot from '$(date +'%Y-%m-%d %H-%M-%S')'.png'"))
hl.bind("ALT + Print",     hl.dsp.exec_cmd("grim -g \"$(hyprctl activewindow -j | jq -r '.at[0],.at[1],.size[0],.size[1]' | paste -sd ' ')\" - | wl-copy"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + Page_Up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { mouse = true })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { mouse = true })

hl.bind(mainMod .. " + R",         hl.dsp.window.resize({ x = 1.5, y = 1.0, relative = true }))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.window.resize({ x = 1.0, y = 1.5, relative = true }))
hl.bind(mainMod .. " + CTRL + R",  hl.dsp.window.resize({ x = 0, y = 0 }))
hl.bind(mainMod .. " + C",         hl.dsp.window.center())
hl.bind(mainMod .. " + Minus",     hl.dsp.window.resize({ x = -0.1, y = 0, relative = true }))
hl.bind(mainMod .. " + Equal",     hl.dsp.window.resize({ x = 0.1, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + Minus", hl.dsp.window.resize({ x = 0, y = -0.1, relative = true }))
hl.bind(mainMod .. " + SHIFT + Equal", hl.dsp.window.resize({ x = 0, y = 0.1, relative = true }))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"), { locked = true })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl --class=backlight set +10%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl --class=backlight set 10%-"), { locked = true, repeating = true })

hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprctl dispatch dpms off"))
hl.bind(mainMod .. " + Escape",    hl.dsp.exec_cmd("hyprctl dispatch submap reset"), { locked = true })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
