local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local brightness_widget = wibox.widget {
    {
        id = "icon",
        text = " ",  -- Brightness icon
        font = "Font Awesome 6 Free 11",
        widget = wibox.widget.textbox,
    },
    {
        id = "txt",
        widget = wibox.widget.textbox,
    },
    layout = wibox.layout.fixed.horizontal,
}

-- Function to update brightness
local function update_brightness()
    awful.spawn.easy_async_with_shell(
        "brightnessctl -m | cut -d',' -f4 | tr -d '%'",
        function(stdout)
            local brightness = stdout:match("(%d+)") or "0"
            brightness_widget.txt:set_text(brightness .. "% ")
        end
    )
end

-- Update brightness on signal
awesome.connect_signal("brightness::update", update_brightness)

-- Initial update
update_brightness()

-- Mouse bindings
brightness_widget:buttons(gears.table.join(
    awful.button({ }, 4, function() -- Scroll up
        awful.spawn("brightnessctl set +5%")
        gears.timer.delayed_call(function()
            awesome.emit_signal("brightness::update")
        end)
    end),
    awful.button({ }, 5, function() -- Scroll down
        awful.spawn("brightnessctl set 5%-")
        gears.timer.delayed_call(function()
            awesome.emit_signal("brightness::update")
        end)
    end)
))

return brightness_widget
