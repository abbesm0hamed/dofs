local M = {}

M.colors = {
    foreground = "#e6ecf3",
    background = "#0e1116",
    cursor_bg = "#e6ecf3",
    cursor_fg = "#0e1116",
    selection_bg = "#242b3a",
    selection_fg = "#e6ecf3",

    ansi = {
        "#1b202c",
        "#f09aaa",
        "#8ee0c4",
        "#f3dfb8",
        "#7ab8ff",
        "#c5b8ff",
        "#7fd6d1",
        "#e6ecf3",
    },
    brights = {
        "#2a3040",
        "#f4a5b6",
        "#9ee7d3",
        "#f7e8c8",
        "#9ccfff",
        "#d7ccff",
        "#8bd9d1",
        "#f9fafd",
    },

    tab_bar = {
        background = "#0e1116",
        active_tab = {
            bg_color = "#7ab8ff",
            fg_color = "#0e1116",
        },
        inactive_tab = {
            bg_color = "#141822",
            fg_color = "#b7c1cf",
        },
        inactive_tab_hover = {
            bg_color = "#1b202c",
            fg_color = "#e6ecf3",
        },
        new_tab = {
            bg_color = "#141822",
            fg_color = "#b7c1cf",
        },
        new_tab_hover = {
            bg_color = "#1b202c",
            fg_color = "#e6ecf3",
        },
    },
}

return M
