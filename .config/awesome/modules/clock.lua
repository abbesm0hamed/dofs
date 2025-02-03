local wibox = require("wibox")

local clock_widget = wibox.widget {
    {
        id = "icon",
        text = " ",  -- Clock icon
        font = "Font Awesome 6 Free 11",
        widget = wibox.widget.textbox,
    },
    {
        format = "%H:%M ",
        widget = wibox.widget.textclock,
    },
    layout = wibox.layout.fixed.horizontal,
}

return clock_widget
