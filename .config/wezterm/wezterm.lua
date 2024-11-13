local wezterm = require("wezterm")
local kanagwa_theme = require("themes.kanagwa")
local config = {}

-- Set the base font
-- config.font = wezterm.font("JetBrains Mono Nerf Font", { italic = false })
config.font = wezterm.font("FiraCode Nerd Font", { italic = false })

-- Font rules for italic and bold italic
config.font_rules = {
  {
    italic = true,
    font = wezterm.font("Victor Mono Semibold", { italic = true }),
  },
  {
    italic = true,
    intensity = "Bold",
    font = wezterm.font("Victor Mono", { italic = true, weight = "Bold" }),
  },
}

-- Kanagawa color scheme
config.colors = kanagwa_theme

-- Terminal configuration
config.force_reverse_video_cursor = true
config.tab_bar_at_bottom = true
config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.font_size = 12

-- Inactive pane configuration
config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.6,
}

-- Enable true color support
config.enable_kitty_graphics = true

return config
