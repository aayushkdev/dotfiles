hl.window_rule({
    name = "float-pavu",
    match = { class = "org.pulseaudio.pavucontrol" },
    float = true,
    move = "(cursor_x-(window_w*0.5))-210 (cursor_y-(window_h*0.5))+220",
    size = "600 400",
})

hl.window_rule({
    name = "float-blueman",
    match = { class = "blueman-manager" },
    float = true,
    move = "(cursor_x-(window_w*0.5))-180 (cursor_y-(window_h*0.5))+220",
    size = "600 400",
})

hl.window_rule({
    name = "float-satty",
    match = { class = "com\\.gabm\\.satty" },
    float = true,
    center = true,
    size = "900 650",
})

hl.window_rule({
    name = "whatsapp-special",
    match = { class = "chrome-web\\.whatsapp\\.com__-Default" },
    workspace = "special:whatsapp silent",
    no_initial_focus = true,
})

hl.window_rule({
    name = "whatsapp-special-title",
    match = { title = "web\\.whatsapp\\.com" },
    workspace = "special:whatsapp silent",
    no_initial_focus = true,
})

hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

hl.window_rule({
    name = "no-gaps-wtv1",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding = 0,
})

hl.window_rule({
    name = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding = 0,
})

hl.window_rule({
    name = "float-thunar-dialogs",
    match = {
        class = "thunar",
        title = "^(Rename|Bulk Rename|File Operation Progress|Confirm|Error|Properties|Permissions).*",
    },
    float = true,
    center = true,
})

hl.window_rule({
    name = "float-xarchiver",
    match = { class = "xarchiver" },
    float = true,
    center = true,
    size = "700 500",
})

hl.window_rule({
    name = "noctalia-settings",
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size = { 1080, 920 },
})

for i, name in ipairs({ "1", "2", "3", "4", "5", "6", "7" }) do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = "eDP-1",
        persistent = true,
        default_name = name,
    })
end
