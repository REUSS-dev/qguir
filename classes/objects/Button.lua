-- Button

---@class Button : CompositeObject
---@field held boolean Flag if button is currently held (Left mouse button) by user
---@field action fun(self: Button) Button action callback. Triggers ONLY when user presses and releases LMB on button object
---@field text string Button text
---@field originalColor ColorTable
local Button = {
	name = "Button",
		rules = {
		{{"action", "push", "press"}, "action"},
		{{"text", "label"}, "text"},
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
		font = 12,
		hover = true
	},

	defaultCursor = "hand"
}

function Button:click(_, _, but)
    if but == 1 then
        self.held = true
		self.palette.container[1] = self.originalColor.darker
    end
end

function Button:clickRelease(_, _, but)
    if but == 1 then
        self.held = false

		self.palette.container[1] = self.originalColor

        if self.hl then
			self.palette.container[1] = self.originalColor.brighter
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

function Button:hoverOn(x, y)
	if not self.held then
		self.palette.container[1] = self.originalColor.brighter
	end

	return self.ObjectUI.hoverOn(self, x, y)
end

function Button:hoverOff(x, y)
	if not self.held then
		self.palette.container[1] = self.originalColor
	end

	return self.ObjectUI.hoverOff(self, x, y)
end

function Button:action()
end

-- button fnc

function Button:new()
	self.originalColor = self.palette:getColorByIndex(1)

	self:createChild "Label" {
		text = self.text,
		font = self.font,

		horizontal = "center",
		palette = self.palette
	}
end

return Button