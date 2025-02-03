-- Enable JIT compilation
jit.on()

-- Use local variables for better JIT performance
local _ENV = _ENV
local tonumber = tonumber
local string = string
local math = math

-- Awesome libraries with local references for better performance
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

-- Cache string patterns for better performance
local BATTERY_PATTERN = "(%d+)%%"
local STATUS_PATTERN = "Battery %d: (%w+)"

local battery_widget = wibox.widget {
    {
        id = "icon",
        text = " ",  -- Battery icon
        font = "Font Awesome 6 Free 11",
        widget = wibox.widget.textbox,
    },
    {
        id = "txt",
        widget = wibox.widget.textbox,
    },
    layout = wibox.layout.fixed.horizontal,
}

-- Function to update battery status
local function update_battery()
    awful.spawn.easy_async_with_shell(
        "acpi -b | grep -E 'Battery 0'",
        function(stdout)
            local battery_info = stdout:match(BATTERY_PATTERN)
            local status = stdout:match(STATUS_PATTERN)
            local battery_level = tonumber(battery_info)
            
            -- Cache icon lookups
            local icon = status == "Charging" and " " or
                        (battery_level and (
                            battery_level <= 10 and " " or
                            battery_level <= 25 and " " or
                            battery_level <= 50 and " " or
                            battery_level <= 75 and " " or
                            " "
                        ))
            
            if status == "Charging" then
                battery_widget.icon:set_text(" ")
            elseif battery_level then
                if battery_level <= 10 then
                    battery_widget.icon:set_text(" ")
                elseif battery_level <= 25 then
                    battery_widget.icon:set_text(" ")
                elseif battery_level <= 50 then
                    battery_widget.icon:set_text(" ")
                elseif battery_level <= 75 then
                    battery_widget.icon:set_text(" ")
                else
                    battery_widget.icon:set_text(" ")
                end
            end
            
            battery_widget.txt:set_text(battery_info .. "% ")
        end
    )
end

-- Update battery status every 30 seconds
gears.timer {
    timeout = 30,
    call_now = true,
    autostart = true,
    callback = update_battery
}

return battery_widget
