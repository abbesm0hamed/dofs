local M = {}

M.colors = {
    foreground = "{{colors.on_surface.default.hex}}",
    background = "{{colors.surface.default.hex}}",
    cursor_bg = "{{colors.secondary.default.hex}}",
    cursor_fg = "{{colors.surface.default.hex}}",
    selection_bg = "{{colors.surface_container_highest.default.hex}}",
    selection_fg = "{{colors.on_surface.default.hex}}",

    ansi = {
        "{{colors.surface_container_high.default.hex}}",
        "{{colors.error.default.hex}}",
        "{{colors.primary.default.hex}}",
        "{{colors.tertiary.default.hex}}",
        "{{colors.secondary.default.hex}}",
        "{{colors.primary_container.default.hex}}",
        "{{colors.secondary_container.default.hex}}",
        "{{colors.on_surface.default.hex}}",
    },
    brights = {
        "{{colors.outline.default.hex}}",
        "{{colors.error.default.hex}}",
        "{{colors.primary.default.hex}}",
        "{{colors.tertiary.default.hex}}",
        "{{colors.secondary.default.hex}}",
        "{{colors.primary_container.default.hex}}",
        "{{colors.secondary_container.default.hex}}",
        "{{colors.on_surface.default.hex}}",
    },

    tab_bar = {
        background = "{{colors.surface.default.hex}}",
        active_tab = {
            bg_color = "{{colors.secondary.default.hex}}",
            fg_color = "{{colors.surface.default.hex}}",
        },
        inactive_tab = {
            bg_color = "{{colors.surface.default.hex}}",
            fg_color = "{{colors.outline.default.hex}}",
        },
        inactive_tab_hover = {
            bg_color = "{{colors.surface.default.hex}}",
            fg_color = "{{colors.on_surface.default.hex}}",
        },
        new_tab = {
            bg_color = "{{colors.surface.default.hex}}",
            fg_color = "{{colors.outline.default.hex}}",
        },
        new_tab_hover = {
            bg_color = "{{colors.surface.default.hex}}",
            fg_color = "{{colors.on_surface.default.hex}}",
        },
    },
}

return M
