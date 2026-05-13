hl.config({
    binds = {
        drag_threshold = 10,
        disable_keybind_grabbing = true,
        pass_mouse_when_bound = false,
    },
})

hl.bind("SUPER + R", hl.dsp.layout("togglesplit"))
hl.bind("CTRL + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind("SUPER + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + D", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

hl.bind("SUPER + Left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "down" }))

hl.bind("SUPER + SHIFT + Left", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.move({ direction = "down" }))

hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind("SUPER + Semicolon", hl.dsp.layout("splitratio -0.1"), { repeating = true })
hl.bind("SUPER + Apostrophe", hl.dsp.layout("splitratio +0.1"), { repeating = true })

for i = 1, 10 do
    local key = i % 10
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + CTRL + Right", hl.dsp.focus({ workspace = "e+1" }), { locked = true, repeating = true })
hl.bind("SUPER + CTRL + SHIFT + Right", hl.dsp.window.move({ workspace = "e+1" }), { locked = true, repeating = true })
hl.bind("SUPER + CTRL + Left", hl.dsp.focus({ workspace = "e-1" }), { locked = true, repeating = true })
hl.bind("SUPER + CTRL + SHIFT + Left", hl.dsp.window.move({ workspace = "e-1" }), { locked = true, repeating = true })

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), {
    locked = true,
    description = "Suspend system",
})
hl.bind("CTRL + SHIFT + ALT + SUPER + Delete", hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"), {
    description = "Shutdown",
})

hl.bind("XF86MonBrightnessUp", hl.dsp.global("quickshell:brightness_up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("quickshell:brightness_down"), { locked = true, repeating = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.global("quickshell:volume_up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.global("quickshell:volume_down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.global("quickshell:volume_mute"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("Print", hl.dsp.global("quickshell:take_screenshot"))
hl.bind("SUPER + End", hl.dsp.global("quickshell:power_menu"))
hl.bind("SUPER + Space", hl.dsp.global("quickshell:app_launcher"))
hl.bind("SUPER + V", hl.dsp.global("quickshell:clipboard_history"))
hl.bind("SUPER + W", hl.dsp.global("quickshell:wallpaper_picker"))

hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("zen-browser"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("code"))
hl.bind("SUPER + K", hl.dsp.exec_cmd("kwrite"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("nmsurf"))
