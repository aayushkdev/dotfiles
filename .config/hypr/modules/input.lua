hl.device({
    name = "hypreco-kb-default",
    kb_variant = "",
    kb_model = "pc105",
    kb_layout = "us",
    kb_options = "",
    kb_rules = "",
    numlock_by_default = true,
})

hl.config({
    input = {
        follow_mouse = 1,
        sensitivity = 0,
        scroll_factor = 1,

        touchpad = {
            natural_scroll = false,
            disable_while_typing = true,
            scroll_factor = 1.5,
        },
    },

    cursor = {
        no_hardware_cursors = false,
        enable_hyprcursor = true,
        sync_gsettings_theme = true,
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.gesture({
    fingers = 3,
    direction = "up",
    action = "fullscreen",
})

hl.gesture({
    fingers = 3,
    direction = "down",
    action = "fullscreen",
})
