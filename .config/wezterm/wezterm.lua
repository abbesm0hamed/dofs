local wezterm = require("wezterm")
local kanagwa_theme = require("themes.kanagawa")
local config = {}

-- Set the base font
-- config.font = wezterm.font("JetBrains Mono Nerd Font", { italic = false })
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

-- Default padding for non-Neovim windows
config.window_padding = {
	left = "1cell",
	right = "1cell",
	top = "0.5cell",
	bottom = "0.5cell",
}

-- Event handler for process updates
wezterm.on("update-right-status", function(window, pane)
	local process_name = pane:get_foreground_process_name()
	if process_name then
		-- Check if nvim is running
		if process_name:find("nvim") then
			window:set_config_overrides({
				window_padding = {
					left = 0,
					right = 0,
					top = 0,
					bottom = 0,
				},
			})
		else
			window:set_config_overrides({
				window_padding = {
					left = "1cell",
					right = "1cell",
					top = "0.5cell",
					bottom = "0.5cell",
				},
			})
		end
	end
end)

-- Kanagawa color scheme
config.colors = kanagwa_theme

-- Terminal configuration
config.force_reverse_video_cursor = true
config.tab_bar_at_bottom = true
config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.font_size = 10
config.window_background_opacity = 0.95

-- Inactive pane configuration
config.inactive_pane_hsb = {
	saturation = 0.7,
	brightness = 0.6,
}

-- Enable true color support
config.enable_kitty_graphics = true

return config
