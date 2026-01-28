local M = {}

M.colors = {
    foreground = "#e7e3ff",
    background = "#0d0e11",
    cursor_bg = "#f5e0dc",
    cursor_fg = "#0d0e11",
    selection_bg = "#585b70",
    selection_fg = "#e7e3ff",

    ansi = {
        "#45475a",
        "#f38ba8",
        "#a6e3a1",
        "#f9e2af",
        "#7e9cd8",
        "#f5c2e7",
        "#94e2d5",
        "#bac2de",
    },
    brights = {
        "#585b70",
        "#f38ba8",
        "#a6e3a1",
        "#f9e2af",
        "#7e9cd8",
        "#f5c2e7",
        "#94e2d5",
        "#a6adc8",
    },

    tab_bar = {
        background = "#0d0e11",
        active_tab = {
            bg_color = "#7e9cd8",
            fg_color = "#0d0e11",
        },
        inactive_tab = {
            bg_color = "#0d0e11",
            fg_color = "#bac2de",
        },
        inactive_tab_hover = {
            bg_color = "#0d0e11",
            fg_color = "#e7e3ff",
        },
        new_tab = {
            bg_color = "#0d0e11",
            fg_color = "#bac2de",
        },
        new_tab_hover = {
            bg_color = "#0d0e11",
            fg_color = "#e7e3ff",
        },
    },
}

return M
