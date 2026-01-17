local wezterm = require 'wezterm'

return {
  font = wezterm.font_with_fallback({
    { family = 'Iosevka', stretch = 'Expanded' },
    'Noto Color Emoji',
  }),
  font_size = 12.0,

  window_background_opacity = 0.98,
  window_decorations = 'NONE',
  colors = {
    foreground = '#e7e3ff',
    background = '#0d0e11',
    cursor_bg = '#f5e0dc',
    cursor_fg = '#0d0e11',
    selection_bg = '#585b70',
    selection_fg = '#e7e3ff',

    ansi = {
      '#45475a',
      '#f38ba8',
      '#a6e3a1',
      '#f9e2af',
      '#89b4fa',
      '#f5c2e7',
      '#94e2d5',
      '#bac2de',
    },
    brights = {
      '#585b70',
      '#f38ba8',
      '#a6e3a1',
      '#f9e2af',
      '#89b4fa',
      '#f5c2e7',
      '#94e2d5',
      '#a6adc8',
    },

    tab_bar = {
      background = '#0d0e11',
      active_tab = {
        bg_color = '#89b4fa',
        fg_color = '#0d0e11',
      },
      inactive_tab = {
        bg_color = '#0d0e11',
        fg_color = '#bac2de',
      },
      inactive_tab_hover = {
        bg_color = '#0d0e11',
        fg_color = '#e7e3ff',
      },
      new_tab = {
        bg_color = '#0d0e11',
        fg_color = '#bac2de',
      },
      new_tab_hover = {
        bg_color = '#0d0e11',
        fg_color = '#e7e3ff',
      },
    },
  },
  window_padding = {
    left = 10,
    right = 10,
    top = 10,
    bottom = 10,
  },
  inactive_pane_hsb = {
    saturation = 1.0,
    brightness = 0.9,
  },

  -- Cursor
  default_cursor_style = 'SteadyBlock',
  cursor_blink_rate = 0,

  -- Terminal identity
  term = 'xterm-256color',

  -- Tabs and UI
  hide_tab_bar_if_only_one_tab = true,
  use_fancy_tab_bar = false,

  -- Wayland first (matches Niri setup)
  enable_wayland = true,

  -- Behavior
  window_close_confirmation = 'NeverPrompt',
}
