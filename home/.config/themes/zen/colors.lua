local M = {}

M.colors = {
    foreground = "#e5e7eb",
    background = "#0e1116",
    cursor_bg = "#e5e7eb",
    cursor_fg = "#0e1116",
    selection_bg = "#242b3a",
    selection_fg = "#e5e7eb",

    ansi = {
        "#1b202c",
        "#242b3a",
        "#2e3545",
        "#3a4354",
        "#4a5468",
        "#5b6680",
        "#a7afba",
        "#e5e7eb",
    },
    brights = {
        "#242b3a",
        "#2e3545",
        "#3a4354",
        "#4a5468",
        "#5b6680",
        "#7c8594",
        "#cfd4dc",
        "#f2f3f5",
    },

    tab_bar = {
        background = "#0e1116",
        active_tab = {
            bg_color = "#3a4354",
            fg_color = "#e5e7eb",
        },
        inactive_tab = {
            bg_color = "#141822",
            fg_color = "#a7afba",
        },
        inactive_tab_hover = {
            bg_color = "#1b202c",
            fg_color = "#e5e7eb",
        },
        new_tab = {
            bg_color = "#141822",
            fg_color = "#a7afba",
        },
        new_tab_hover = {
            bg_color = "#1b202c",
            fg_color = "#e5e7eb",
        },
    },
}

return M
