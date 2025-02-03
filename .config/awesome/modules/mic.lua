local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local mic_widget = wibox.widget {
    {
        id = "icon",
        text = " ",  -- Mic icon
        font = "Font Awesome 6 Free 11",
        widget = wibox.widget.textbox,
    },
    {
        id = "txt",
        widget = wibox.widget.textbox,
    },
    layout = wibox.layout.fixed.horizontal,
}

-- Function to update microphone status
local function update_mic()
    awful.spawn.easy_async_with_shell(
        "pamixer --source 1 --get-volume-human",
        function(stdout)
            local volume = stdout:match("(%d+)%%") or "0"
            local muted = stdout:match("muted")
            
            if muted then
                mic_widget.icon:set_text(" ")
                mic_widget.txt:set_text("muted ")
            else
                mic_widget.icon:set_text(" ")
                mic_widget.txt:set_text(volume .. "% ")
            end
        end
    )
end

-- Update mic on signal
awesome.connect_signal("mic::update", update_mic)

-- Initial update
update_mic()

-- Mouse bindings
mic_widget:buttons(gears.table.join(
    awful.button({ }, 1, function() -- Left click to toggle mute
        awful.spawn("pamixer --source 1 -t")
        gears.timer.delayed_call(function()
            awesome.emit_signal("mic::update")
        end)
    end),
    awful.button({ }, 4, function() -- Scroll up
        awful.spawn("pamixer --source 1 -i 5")
        gears.timer.delayed_call(function()
            awesome.emit_signal("mic::update")
        end)
    end),
    awful.button({ }, 5, function() -- Scroll down
        awful.spawn("pamixer --source 1 -d 5")
        gears.timer.delayed_call(function()
            awesome.emit_signal("mic::update")
        end)
    end)
))

return mic_widget
