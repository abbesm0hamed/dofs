-- Pull in the wezterm API
local wezterm = require("wezterm")
local config = {}

-- Set the base font
config.font = wezterm.font("JetBrains Mono Nerd Font", { italic = false })

-- Font rules for italic and bold italic
config.font_rules = {
  {
    italic = true,
    font = wezterm.font("Victor Mono Semibold", { italic = true }), -- Victor Mono Italic for italics
  },
  {
    italic = true,
    intensity = "Bold",                                                     -- Use intensity instead of bold
    font = wezterm.font("Victor Mono", { italic = true, weight = "Bold" }), -- Victor Mono Bold Italic for bold italics
  },
}

-- Other configurations
config.force_reverse_video_cursor = true
config.colors = {
  foreground = "#dcd7ba",
  background = "#1f1f28",
  cursor_bg = "#c8c093",
  cursor_fg = "#c8c093",
  cursor_border = "#c8c093",
  selection_fg = "#c8c093",
  selection_bg = "#2d4f67",
  scrollbar_thumb = "#16161d",
  split = "#16161d",
  ansi = { "#090618", "#c34043", "#76946a", "#c0a36e", "#7e9cd8", "#957fb8", "#6a9589", "#c8c093" },
  brights = { "#727169", "#e82424", "#98bb6c", "#e6c384", "#7fb4ca", "#938aa9", "#7aa89f", "#dcd7ba" },
  indexed = { [16] = "#ffa066", [17] = "#ff5d62" },
}

config.tab_bar_at_bottom = true
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.font_size = 12
config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.6,
}

return config
