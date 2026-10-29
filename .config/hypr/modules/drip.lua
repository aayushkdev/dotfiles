hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 3,
        border_size = 2,
        col = {
            active_border = "rgb(6272a4)",
            inactive_border = "rgb(282a36)",
        },
        resize_on_border = true,
        allow_tearing = true,
        layout = "dwindle",
    },

    dwindle = {
        smart_split = true,
    },

    decoration = {
        rounding = 20,
        rounding_power = 2,
        active_opacity = 0.95,
        inactive_opacity = 0.95,
        border_part_of_window = false,
        dim_special = 0.2,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a,
        },

        blur = {
            enabled = true,
            xray = true,
            size = 3,
            passes = 2,
            vibrancy = 0.1696,
            popups = true,
            special = false,
            ignore_opacity = true,
            new_optimizations = true,
        },
    },

    ecosystem = {
        no_update_news = true,
    },
})

hl.layer_rule({
    name = "noctalia",
    match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
    },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.5,
    no_anim = true,
})
