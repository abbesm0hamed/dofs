-- Enable JIT compilation
jit.on()

-- Use local variables for better JIT performance
local _ENV = _ENV
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table
local type = type
local tostring = tostring
local tonumber = tonumber

-- Awesome libraries
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")

-- Use table.new when available (LuaJIT)
local table_new = require("table.new")
if not table_new then
    table_new = function() return {} end
end

-- Widgets
local battery_widget = require("modules.battery")
local volume_widget = require("modules.volume")
local brightness_widget = require("modules.brightness")
local clock_widget = require("modules.clock")
local mic_widget = require("modules.mic")

-- Create a minimal bar
local function create_bar(s)
    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        height = 24,
        bg = beautiful.bg_normal .. "cc" -- Semi-transparent background
    })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            spacing = 10,
            s.mytaglist,
        },
        { -- Middle widget
            layout = wibox.layout.flex.horizontal,
            s.mytasklist,
        },
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            spacing = 10,
            wibox.container.margin(brightness_widget, 4, 4),
            wibox.container.margin(volume_widget, 4, 4),
            wibox.container.margin(mic_widget, 4, 4),
            wibox.container.margin(battery_widget, 4, 4),
            wibox.container.margin(clock_widget, 4, 4),
            wibox.widget.systray(),
            s.mylayoutbox,
        },
    }
end

return create_bar
