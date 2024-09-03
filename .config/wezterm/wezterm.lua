-- Pull in the wezterm API
local wezterm = require("wezterm")

local config = {}
-- font
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular', italic = false })

config.colors = {
  selection_fg = 'none',
  selection_bg = 'none',
}
-- looking
config.tab_bar_at_bottom = true
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true

-- keybinding

config.font_size = 12

config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.6,
}

return config
