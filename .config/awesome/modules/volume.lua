local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local volume_widget = wibox.widget {
    {
        id = "icon",
        text = " ",  -- Volume icon
        font = "Font Awesome 6 Free 11",
        widget = wibox.widget.textbox,
    },
    {
        id = "txt",
        widget = wibox.widget.textbox,
    },
    layout = wibox.layout.fixed.horizontal,
}

-- Function to update volume
local function update_volume()
    awful.spawn.easy_async_with_shell(
        "pamixer --get-volume-human",
        function(stdout)
            local volume = stdout:match("(%d+)%%") or "0"
            local muted = stdout:match("muted")
            
            if muted then
                volume_widget.icon:set_text(" ")
            else
                local vol = tonumber(volume)
                if vol == 0 then
                    volume_widget.icon:set_text(" ")
                elseif vol <= 50 then
                    volume_widget.icon:set_text(" ")
                else
                    volume_widget.icon:set_text(" ")
                end
            end
            
            volume_widget.txt:set_text(volume .. "% ")
        end
    )
end

-- Update volume on signal
awesome.connect_signal("volume::update", update_volume)

-- Initial update
update_volume()

-- Mouse bindings
volume_widget:buttons(gears.table.join(
    awful.button({ }, 4, function() -- Scroll up
        awful.spawn("pamixer -i 5")
        gears.timer.delayed_call(function()
            awesome.emit_signal("volume::update")
        end)
    end),
    awful.button({ }, 5, function() -- Scroll down
        awful.spawn("pamixer -d 5")
        gears.timer.delayed_call(function()
            awesome.emit_signal("volume::update")
        end)
    end),
    awful.button({ }, 1, function() -- Left click
        awful.spawn("pamixer -t")
        gears.timer.delayed_call(function()
            awesome.emit_signal("volume::update")
        end)
    end)
))

return volume_widget
