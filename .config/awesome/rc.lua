-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors,
	})
end

-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		-- Make sure we don't go into an endless error loop
		if in_error then
			return
		end
		in_error = true

		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = tostring(err),
		})
		in_error = false
	end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_configuration_dir() .. "themes/mytheme/theme.lua")

-- This is used later as the default terminal and editor to run.
-- locals
local terminal         = "wezterm"
local second_terminal  = "alacritty"
local browser          = "brave"
local filemanager      = "thunar"
local color_picker     = "xcolor"
local mailclient       = "evolution"
local editor           = os.getenv("EDITOR") or "nvim"
local editor_cmd       = terminal .. " -e " .. editor
local mediaplayer      = "vlc"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey           = "Mod4"
local altkey           = "Mod1"
local controlkey       = "Control"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts   = {
	awful.layout.suit.tile,
	awful.layout.suit.tile.left,
	awful.layout.suit.tile.bottom,
	awful.layout.suit.tile.top,
	awful.layout.suit.fair,
	awful.layout.suit.fair.horizontal,
	awful.layout.suit.spiral,
	awful.layout.suit.spiral.dwindle,
	awful.layout.suit.max,
	awful.layout.suit.max.fullscreen,
	awful.layout.suit.magnifier,
	awful.layout.suit.corner.nw,
	-- awful.layout.suit.floating,
	-- awful.layout.suit.corner.ne,
	-- awful.layout.suit.corner.sw,
	-- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu          = {
	{
		"hotkeys",
		function()
			hotkeys_popup.show_help(nil, awful.screen.focused())
		end,
	},
	{ "manual",      terminal .. " -e man awesome" },
	{ "edit config", editor_cmd .. " " .. awesome.conffile },
	{ "restart",     awesome.restart },
	{
		"quit",
		function()
			awesome.quit()
		end,
	},
}

mymainmenu             = awful.menu({
	items = {
		{ "awesome",       myawesomemenu, beautiful.awesome_icon },
		{ "open terminal", terminal },
	},
})

mylauncher             = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout       = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock            = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons  = gears.table.join(
	awful.button({}, 1, function(t)
		t:view_only()
	end),
	awful.button({ modkey }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
	awful.button({}, 3, awful.tag.viewtoggle),
	awful.button({ modkey }, 3, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),
	awful.button({}, 4, function(t)
		awful.tag.viewnext(t.screen)
	end),
	awful.button({}, 5, function(t)
		awful.tag.viewprev(t.screen)
	end)
)

local tasklist_buttons = gears.table.join(
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			c:emit_signal("request::activate", "tasklist", { raise = true })
		end
	end),
	awful.button({}, 3, function()
		awful.menu.client_list({ theme = { width = 250 } })
	end),
	awful.button({}, 4, function()
		awful.client.focus.byidx(1)
	end),
	awful.button({}, 5, function()
		awful.client.focus.byidx(-1)
	end)
)

local function set_wallpaper(s)
	-- Wallpaper
	if beautiful.wallpaper then
		local wallpaper = beautiful.wallpaper
		-- If wallpaper is a function, call it with the screen
		if type(wallpaper) == "function" then
			wallpaper = wallpaper(s)
		end
		gears.wallpaper.maximized(wallpaper, s, true)
	end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
	-- Wallpaper
	set_wallpaper(s)

	-- Each screen has its own tag table.
	awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create an imagebox widget which will contain an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(gears.table.join(
		awful.button({}, 1, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 3, function()
			awful.layout.inc(-1)
		end),
		awful.button({}, 4, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 5, function()
			awful.layout.inc(-1)
		end)
	))
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist({
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = taglist_buttons,
	})

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist({
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = tasklist_buttons,
	})

	-- Other widgets
	local cpu_widget = require("awesome-wm-widgets.cpu-widget.cpu-widget")
	local battery_widget = require("awesome-wm-widgets.battery-widget.battery")
	brightness_widget = require("awesome-wm-widgets.brightness-widget.brightness")
	-- volume_widget = require("awesome-wm-widgets.pactl-widget.volume")
	local pacman_widget = require("awesome-wm-widgets.pacman-widget.pacman")
	local separator = wibox.widget.textbox("  ")
	local logout_menu_widget = require("awesome-wm-widgets.logout-menu-widget.logout-menu")

	-- Create the wibox
	s.mywibox = awful.wibar({ position = "top", screen = s })

	-- Add widgets to the wibox
	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			mylauncher,
			s.mytaglist,
			s.mypromptbox,
		},
		s.mytasklist, -- Middle widget
		{           -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			-- separator,
			-- cpu_widget({
			-- 	width = 30,
			-- 	step_width = 2,
			-- 	step_spacing = 0,
			-- 	color = "#fff",
			-- }),
			-- mykeyboardlayout,
			pacman_widget({
				interval = 600, -- Refresh every 10 minutes
				popup_bg_color = "#222222",
				popup_border_width = 1,
				popup_border_color = "#7e7e7e",
				popup_height = 20, -- 10 packages shown in scrollable window
				popup_width = 300,
				polkit_agent_path = "/usr/bin/lxpolkit",
			}),
			separator,
			wibox.widget.systray(),
			separator,
			brightness_widget({
				-- type = "arc",
				type = "icon_and_text",
				program = "brightnessctl",
				step = 5,
			}),
			separator,
			battery_widget({
				show_current_level = true,
				font = "sans 7",
				display_notification = true,
				warning_msg_title = "Abbes we have a problem",
			}),
			-- separator,
			-- volume_widget({
			-- 	widget_type = "arc",
			-- }),
			separator,
			logout_menu_widget({
				font = "sans 9",
				onlock = function()
					awful.spawn.with_shell("i3lock-fancy")
				end,
			}),
			separator,
			mytextclock,
			separator,
			s.mylayoutbox,
		},
	})
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
	awful.button({}, 3, function()
		mymainmenu:toggle()
	end),
	awful.button({}, 4, awful.tag.viewnext),
	awful.button({}, 5, awful.tag.viewprev)
))
-- }}}

-- volume functionalities
local volume_control = {
	raise = "pactl set-sink-volume @DEFAULT_SINK@ +1%",
	lower = "pactl set-sink-volume @DEFAULT_SINK@ -1%",
	toggle_mute = "pactl set-sink-mute @DEFAULT_SINK@ toggle",
	set_max_volume = "pactl set-sink-volume @DEFAULT_SINK@ 100%",
	set_min_volume = "pactl set-sink-volume @DEFAULT_SINK@ 0%"
}

-- {{{ Key bindings
globalkeys = gears.table.join(
	awful.key({ modkey }, "s", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),
	awful.key({ modkey }, "Left", awful.tag.viewprev, { description = "view previous", group = "tag" }),
	awful.key({ modkey }, "Right", awful.tag.viewnext, { description = "view next", group = "tag" }),
	awful.key({ modkey }, "Escape", awful.tag.history.restore, { description = "go back", group = "tag" }),

	-- By direction client focus
	awful.key({ modkey }, "j",
		function()
			awful.client.focus.global_bydirection("down")
			if client.focus then client.focus:raise() end
		end,
		{ description = "focus down", group = "client" }),
	awful.key({ modkey }, "k",
		function()
			awful.client.focus.global_bydirection("up")
			if client.focus then client.focus:raise() end
		end,
		{ description = "focus up", group = "client" }),
	awful.key({ modkey }, "h",
		function()
			awful.client.focus.global_bydirection("left")
			if client.focus then client.focus:raise() end
		end,
		{ description = "focus left", group = "client" }),
	awful.key({ modkey }, "l",
		function()
			awful.client.focus.global_bydirection("right")
			if client.focus then client.focus:raise() end
		end,
		{ description = "focus right", group = "client" }),

	-- By direction client focus with arrows
	awful.key({ controlkey, modkey }, "Down",
		function()
			awful.client.focus.global_bydirection("down")
			if client.focus then client.focus:raise() end
		end,
		{ description = "focus down", group = "client" }),
	awful.key({ controlkey, modkey }, "Up",
		function()
			awful.client.focus.global_bydirection("up")
			if client.focus then client.focus:raise() end
		end,
		{ description = "focus up", group = "client" }),
	awful.key({ controlkey, modkey }, "Left",
		function()
			awful.client.focus.global_bydirection("left")
			if client.focus then client.focus:raise() end
		end,
		{ description = "focus left", group = "client" }),
	awful.key({ controlkey, modkey }, "Right",
		function()
			awful.client.focus.global_bydirection("right")
			if client.focus then client.focus:raise() end
		end,
		{ description = "focus right", group = "client" }),

	awful.key({ modkey }, "w", function()
		mymainmenu:show()
	end, { description = "show main menu", group = "awesome" }),

	-- Appearance manipulation
	awful.key({ controlkey, altkey }, "p", function()
		awful.spawn.with_shell("$HOME/.config/awesome/scripts/picom-toggle.sh")
	end, { description = "Picom toggle", group = "appearance" }),

	-- Layout manipulation
	awful.key({ modkey, "Shift" }, "j", function()
		awful.client.swap.byidx(1)
	end, { description = "swap with next client by index", group = "client" }),
	awful.key({ modkey, "Shift" }, "k", function()
		awful.client.swap.byidx(-1)
	end, { description = "swap with previous client by index", group = "client" }),
	awful.key({ modkey, controlkey }, "j", function()
		awful.screen.focus_relative(1)
	end, { description = "focus the next screen", group = "screen" }),
	awful.key({ modkey, controlkey }, "k", function()
		awful.screen.focus_relative(-1)
	end, { description = "focus the previous screen", group = "screen" }),
	awful.key({ modkey }, "u", awful.client.urgent.jumpto, { description = "jump to urgent client", group = "client" }),
	awful.key({ modkey }, "Tab", function()
		awful.client.focus.history.previous()
		if client.focus then
			client.focus:raise()
		end
	end, { description = "go back", group = "client" }),
	-- Show/Hide Wibox
	awful.key({ modkey }, "w", function()
			for s in screen do
				s.mywibox.visible = not s.mywibox.visible
				if s.mybottomwibox then
					s.mybottomwibox.visible = not s.mybottomwibox.visible
				end
			end
		end,
		{ description = "toggle wibox", group = "awesome" }),

	-- Show/Hide Systray
	awful.key({ modkey }, "-", function()
		awful.screen.focused().systray.visible = not awful.screen.focused().systray.visible
	end, { description = "Toggle systray visibility", group = "awesome" }),
	-- Show/Hide Systray
	awful.key({ modkey }, "KP_Subtract", function()
		awful.screen.focused().systray.visible = not awful.screen.focused().systray.visible
	end, { description = "Toggle systray visibility", group = "awesome" }),

	-- conky
	awful.key({ modkey }, "c", function() awful.util.spawn("conky-toggle") end,
		{ description = "conky-toggle", group = "conky" }),
	awful.key({ modkey, controlkey }, "c", function() awful.util.spawn("killall conky") end,
		{ description = "conky killall", group = "conky" }),
	awful.key({ controlkey, altkey }, "Next", function() awful.util.spawn("conky-rotate -n") end,
		{ description = "Next conky rotation", group = "alt+ctrl" }),
	awful.key({ controlkey, altkey }, "Prior", function() awful.util.spawn("conky-rotate -p") end,
		{ description = "Previous conky rotation", group = "alt+ctrl" }),

	-- Standard program
	-- launcher
	awful.key({ modkey }, "Return", function()
		awful.spawn(terminal)
	end, { description = "open wezterm", group = "launcher" }),
	awful.key({ modkey }, "/", function()
		awful.spawn(second_terminal)
	end, { description = "open alacritty", group = "launcher" }),
	awful.key({ modkey }, "b", function()
		awful.spawn(browser)
	end, { description = "open browser", group = "launcher" }),
	awful.key({ modkey, "Control" }, "c", function()
		awful.spawn(color_picker)
	end, { description = "open color picker", group = "launcher" }),
	awful.key({ modkey, "Control" }, "f", function()
		awful.spawn.with_shell("flameshot gui")
	end, { description = "open flameshot screenshot tool", group = "launcher" }),
	awful.key({ modkey, "Control" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
	awful.key({ modkey, "Shift" }, "q", awesome.quit, { description = "quit awesome", group = "awesome" }),

	-- manage windows
	awful.key({ altkey, "Shift" }, "l", function() awful.tag.incmwfact(0.05) end,
		{ description = "increase master width factor", group = "layout" }),
	awful.key({ altkey, "Shift" }, "h", function() awful.tag.incmwfact(-0.05) end,
		{ description = "decrease master width factor", group = "layout" }),
	awful.key({ modkey, "Shift" }, "h", function() awful.tag.incnmaster(1, nil, true) end,
		{ description = "increase the number of master clients", group = "layout" }),
	awful.key({ modkey, "Shift" }, "l", function() awful.tag.incnmaster(-1, nil, true) end,
		{ description = "decrease the number of master clients", group = "layout" }),
	awful.key({ modkey, "Control" }, "h", function() awful.tag.incncol(1, nil, true) end,
		{ description = "increase the number of columns", group = "layout" }),
	awful.key({ modkey, "Control" }, "l", function() awful.tag.incncol(-1, nil, true) end,
		{ description = "decrease the number of columns", group = "layout" }),
	awful.key({ modkey, }, "space", function() awful.layout.inc(1) end,
		{ description = "select next", group = "layout" }),
	awful.key({ modkey, "Shift" }, "space", function()
		awful.layout.inc(-1)
	end, { description = "select previous", group = "layout" }),

	awful.key({ modkey, "Control" }, "n", function()
		local c = awful.client.restore()
		-- Focus restored client
		if c then
			c:emit_signal(
				"request::activate",
				"key.unminimize",
				{ raise = true }
			)
		end
	end, { description = "restore minimized", group = "client" }),

	-- Brightness
	awful.key({}, "XF86MonBrightnessUp", function()
		brightness_widget:inc()
		-- naughty.notify({ text = "Brightness increased!" })
	end, { description = "+10% brightness", group = "controls" }),
	awful.key({}, "XF86MonBrightnessDown", function()
		brightness_widget:dec()
		-- naughty.notify({ text = "Brightness decreased!" })
	end, { description = "-10% brightness", group = "controls" }),

	-- ALSA volume control
	awful.key({}, "XF86AudioRaiseVolume",
		function()
			os.execute(volume_control.raise)
			-- Update volume widget
		end),

	awful.key({}, "XF86AudioLowerVolume",
		function()
			os.execute(volume_control.lower)
			-- Update volume widget
		end),

	awful.key({}, "XF86AudioMute",
		function()
			os.execute(volume_control.toggle_mute)
			-- Update volume widget
		end),

	awful.key({ controlkey, "Shift" }, "m",
		function()
			os.execute(volume_control.set_max_volume)
			-- Update volume widget
		end),

	awful.key({ controlkey, "Shift" }, "0",
		function()
			os.execute(volume_control.set_min_volume)
			-- Update volume widget
		end),
	-- awful.key({}, "XF86AudioRaiseVolume", function()
	-- 	volume_widget.inc()
	-- end),
	-- awful.key({}, "XF86AudioLowerVolume", function()
	-- 	volume_widget.dec()
	-- end),
	-- awful.key({}, "XF86AudioMute", function()
	-- 	volume_widget.toggle()
	-- end),

	-- Prompt
	awful.key({ modkey }, "r", function()
		awful.screen.focused().mypromptbox:run()
	end, { description = "run prompt", group = "launcher" }),

	awful.key({ modkey }, "x", function()
		awful.prompt.run({
			prompt = "Run Lua code: ",
			textbox = awful.screen.focused().mypromptbox.widget,
			exe_callback = awful.util.eval,
			history_path = awful.util.get_cache_dir() .. "/history_eval",
		})
	end, { description = "lua execute prompt", group = "awesome" }),
	-- Menubar
	awful.key({ modkey }, "p", function()
		menubar.show()
	end, { description = "show the menubar", group = "launcher" })
)

clientkeys = gears.table.join(
	awful.key({ modkey }, "f", function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end, { description = "toggle fullscreen", group = "client" }),
	awful.key({ modkey, "Shift" }, "c", function(c)
		c:kill()
	end, { description = "close", group = "client" }),
	awful.key(
		{ modkey, "Control" },
		"space",
		awful.client.floating.toggle,
		{ description = "toggle floating", group = "client" }
	),
	awful.key({ modkey, "Control" }, "Return", function(c)
		c:swap(awful.client.getmaster())
	end, { description = "move to master", group = "client" }),
	awful.key({ modkey }, "o", function(c)
		c:move_to_screen()
	end, { description = "move to screen", group = "client" }),
	awful.key({ modkey }, "t", function(c)
		c.ontop = not c.ontop
	end, { description = "toggle keep on top", group = "client" }),
	awful.key({ modkey }, "n", function(c)
		-- The client currently has the input focus, so it cannot be
		-- minimized, since minimized clients can't have the focus.
		c.minimized = true
	end, { description = "minimize", group = "client" }),
	awful.key({ modkey }, "m", function(c)
		c.maximized = not c.maximized
		c:raise()
	end, { description = "(un)maximize", group = "client" }),
	awful.key({ modkey, "Control" }, "m", function(c)
		c.maximized_vertical = not c.maximized_vertical
		c:raise()
	end, { description = "(un)maximize vertically", group = "client" }),
	awful.key({ modkey, "Shift" }, "m", function(c)
		c.maximized_horizontal = not c.maximized_horizontal
		c:raise()
	end, { description = "(un)maximize horizontally", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	globalkeys = gears.table.join(
		globalkeys,
		-- View tag only.
		awful.key({ modkey }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				tag:view_only()
			end
		end, { description = "view tag #" .. i, group = "tag" }),
		-- Toggle tag display.
		awful.key({ modkey, "Control" }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end, { description = "toggle tag #" .. i, group = "tag" }),
		-- Move client to tag.
		awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end, { description = "move focused client to tag #" .. i, group = "tag" }),
		-- Toggle tag on focused client.
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end, { description = "toggle focused client on tag #" .. i, group = "tag" })
	)
end

clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
	end),
	awful.button({ modkey }, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.move(c)
	end),
	awful.button({ modkey }, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.resize(c)
	end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	-- All clients will match this rule.
	{
		rule = {},
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
		},
	},

	-- Floating clients.
	{
		rule_any = {
			instance = {
				"DTA", -- Firefox addon DownThemAll.
				"copyq", -- Includes session name in class.
				"pinentry",
			},
			class = {
				"Arandr",
				"Blueman-manager",
				"Gpick",
				"Kruler",
				"MessageWin", -- kalarm.
				"Sxiv",
				"Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
				"Wpa_gui",
				"veromix",
				"xtightvncviewer",
			},

			-- Note that the name property shown in xprop might be set slightly after creation of the client
			-- and the name shown there might not match defined rules here.
			name = {
				"Event Tester", -- xev.
			},
			role = {
				"AlarmWindow", -- Thunderbird's calendar.
				"ConfigManager", -- Thunderbird's about:config.
				"pop-up",    -- e.g. Google Chrome's (detached) Developer Tools.
			},
		},
		properties = { floating = true },
	},

	-- Add titlebars to normal clients and dialogs
	{ rule_any = { type = { "normal", "dialog" } }, properties = { titlebars_enabled = false } },

	-- Set Firefox to always map on the tag named "2" on screen 1.
	-- { rule = { class = "Firefox" },
	--   properties = { screen = 1, tag = "2" } },
	--
	-- Set applications to be maximized at startup.
	-- find class or role via xprop command
	{
		rule = { class = "Gimp*", role = "gimp-image-window" },
		properties = { maximized = true }
	},

	{
		rule = { class = filemanager },
		properties = { maximized = true }
	},

	{
		rule = { class = mediaplayer },
		properties = { maximized = true }
	},

	{
		rule = { class = "VirtualBox Manager" },
		properties = { maximized = true }
	},

	{
		rule = { class = "VirtualBox Machine" },
		properties = { maximized = true }
	},
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
	-- Set the windows at the slave,
	-- i.e. put it at the end of others instead of setting it master.
	-- if not awesome.startup then awful.client.setslave(c) end

	if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
		-- Prevent clients from being unreachable after screen count changes.
		awful.placement.no_offscreen(c)
	end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
	-- buttons for the titlebar
	local buttons = gears.table.join(
		awful.button({}, 1, function()
			c:emit_signal("request::activate", "titlebar", { raise = true })
			awful.mouse.client.move(c)
		end),
		awful.button({}, 3, function()
			c:emit_signal("request::activate", "titlebar", { raise = true })
			awful.mouse.client.resize(c)
		end)
	)

	awful.titlebar(c):setup({
		{ -- Left
			awful.titlebar.widget.iconwidget(c),
			buttons = buttons,
			layout = wibox.layout.fixed.horizontal,
		},
		{ -- Middle
			{ -- Title
				align = "center",
				widget = awful.titlebar.widget.titlewidget(c),
			},
			buttons = buttons,
			layout = wibox.layout.flex.horizontal,
		},
		{ -- Right
			awful.titlebar.widget.floatingbutton(c),
			awful.titlebar.widget.maximizedbutton(c),
			awful.titlebar.widget.stickybutton(c),
			awful.titlebar.widget.ontopbutton(c),
			awful.titlebar.widget.closebutton(c),
			layout = wibox.layout.fixed.horizontal(),
		},
		layout = wibox.layout.align.horizontal,
	})
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
	c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
-- }}}

-- Autostart applications
awful.spawn.with_shell("~/.config/awesome/autostart.sh")
awful.spawn.with_shell("~/.config/awesome/screens_setup.sh")
awful.spawn.with_shell("picom -b --config  ~/.confik/awesome/picom.conf")
