-- button
local button = {}

local label = require("classes.objects.Label")
local composite = require("classes.CompositeObject")
local uiobj = require("classes.ObjectUI")

-- documentation



-- config

button.name = "Button"
button.aliases = {}
button.rules = {
    {"layout", {w = 100, h = 50, padding = 10}},

    {"palette", {color = {0, 0.5, 0, 0.4}, textColor = {1, 1, 1}, additionalColor = {0, 0.5, 0, 0.4}}},

    {{"action", "push", "press"}, "action", function() end},
    {{"text", "label"}, "text", "Button"},
    {{"font"}, "font", love.graphics.getFont()},
	{{"bsize", "border_size", "borderSize"}, "bsize", 3},
}

-- consts



-- vars



-- init



-- fnc



-- classes

---@class Button : CompositeObject
---@field held boolean Flag if button is currently held (Left mouse button) by user
---@field action fun() Button action callback. Triggers ONLY when user presses and releases LMB on button object
---@field text string Button text
---@field font love.Font Button text font
---@field originalColor ColorTable
local Button = { defaultCursor = "hand" }
local Button_meta = {__index = Button}
setmetatable(Button, {__index = composite.class}) -- Set parenthesis

Button.checkHover = uiobj.class.checkHover

function Button:tick(dt)
	if self.held then
		self.palette.container[1] = self.originalColor.darker
    elseif self.hl then
        self.palette.container[1] = self.originalColor.brighter
    else
        self.palette.container[1] = self.originalColor
    end
end

function Button:click(_, _, but)
    if but == 1 then
        self.held = true
    end
end

function Button:clickRelease(x, y, but)
    if but == 1 then
        self.held = false

        if self.hl then
            self.action()
        end
    end
end

function Button:keyPress(key)
    -- Also trigger button action when button has focus and Return hit
    if key == "return" then
        self.action()
    end
end

button.class = Button

-- button fnc

function button.new(prototype)
    local obj = composite.new(prototype)

    setmetatable(obj, Button_meta) ---@cast obj Button

	obj.originalColor = obj.palette:getColorByIndex(1)

	local button_text = label.new{
		text = obj.text,
		font = obj.font,

		layout = {
			w = "hug",
			h = "hug",
			horizontal = "center",
		},
		palette = obj.palette,

	}
	obj:add(button_text)

    return obj
end

return button