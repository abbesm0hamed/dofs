local wezterm = require("wezterm")
local act = wezterm.action

return {
	font = wezterm.font_with_fallback({
		{ family = "Iosevka", stretch = "Expanded" },
		-- { family = 'Noto Color Emoji' },
	}),
	font_size = 10.0,
	freetype_load_target = "Light",
	freetype_render_target = "HorizontalLcd",
	freetype_load_flags = "NO_HINTING",
	use_cap_height_to_scale_fallback_fonts = true,
	warn_about_missing_glyphs = false,

	window_background_opacity = 1,
	window_decorations = "NONE",

	colors = (function()
		local success, dynamic = pcall(require, "colors")
		if success then
			return dynamic.colors
		end
		local _, static = pcall(require, "dofs_colors")
		return static.colors
	end)(),
	window_padding = {
		left = 10,
		right = 10,
		top = 10,
		bottom = 10,
	},
	scrollback_lines = 10000,
	enable_scroll_bar = false,
	inactive_pane_hsb = {
		saturation = 1.0,
		brightness = 0.9,
	},

	-- Cursor
	default_cursor_style = "SteadyBlock",
	cursor_blink_rate = 0,

	-- Terminal identity
	term = "xterm-256color",

	-- Tabs and UI
	enable_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	use_fancy_tab_bar = false,

	adjust_window_size_when_changing_font_size = false,

	keys = {
		{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
		{ key = "+", mods = "CTRL", action = act.IncreaseFontSize },
		{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
		{ key = "0", mods = "CTRL", action = act.ResetFontSize },
	},

	-- Wayland first (matches Niri setup)
	enable_wayland = true,

	-- Behavior
	window_close_confirmation = "NeverPrompt",
}
