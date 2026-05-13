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
    name = "float-nm",
    match = { title = "nmtui" },
    float = true,
    move = "(cursor_x-(window_w*0.5))-180 (cursor_y-(window_h*0.5))+220",
    size = "600 400",
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
