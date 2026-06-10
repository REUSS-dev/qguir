-- Button

---@class Button : CompositeObject
---@field held boolean Flag if button is currently held (Left mouse button) by user
---@field action fun(self: Button) Button action callback. Triggers ONLY when user presses and releases LMB on button object
---@field text string Button text
---@field font love.Font Button text font
---@field originalColor ColorTable
local Button = {
	name = "Button",
		rules = {
		{{"action", "push", "press"}, "action"},
		{{"text", "label"}, "text"},
		{{"font"}, "font"},
	},
	extends = "CompositeObject",

	default = {
		w = 100, h = 50, padding = 10,
		colors = {
			main = {0, 0.5, 0, 0.4},
			text = {1, 1, 1},
			border = {0, 0.5, 0, 0.4}
		},

		text = "Button",
		font = love.graphics.getFont()
	},

	defaultCursor = "hand"
}

function Button:tick(_)
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

function Button:clickRelease(_, _, but)
    if but == 1 then
        self.held = false

        if self.hl then
            self:action()
        end
    end
end

function Button:keyPress(key)
    -- Also trigger button action when button has focus and Return hit
    if key == "return" then
        self:action()
    end
end

function Button:action()
end

-- button fnc

function Button:new()
	self.checkHover = self.ObjectUI.checkHover
	self.originalColor = self.palette:getColorByIndex(1)

	self:createChild "Label" {
		text = self.text,
		font = self.font,

		horizontal = "center",
		palette = self.palette
	}
end

return Button