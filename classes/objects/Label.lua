-- label
local label = {}

local uiobj = require("classes.ObjectUI")

local utf = require("utf8")

-- documentation



-- config

label.name = "Label"
label.aliases = {}
label.rules = {
    {{"text", "label"}, "text", "Label"},
    {{"font"}, "font", love.graphics.getFont()},

    {"layout", {w = "hug", h = "hug", horizontal = "left"}},

    {"palette", {color = {0, 0.5, 0, 0.4}, textColor = {1, 1, 1}}},
}

-- consts



-- vars



-- init



-- fnc



-- classes

---@class Label : ObjectUI
---@field textCache table Set of data for printing button text. WARNING: This should be nullified on label size/text change.
---@field text string Button text
---@field font love.Font Button text font
local Label = {}
local Label_meta = {__index = Label}
setmetatable(Label, {__index = uiobj.class}) -- Set parenthesis

function Label:paint()
    -- Text
    love.graphics.setColor(self.palette[2])
    love.graphics.setFont(self.font)
    love.graphics.printf(self.textCache.textVisual, 0, self.textCache.y, self.w, self.layout.horizontal)
end

function Label:autolayout(fill_w, fill_h)
	local ow, oh = uiobj.class.autolayout(self, fill_w, fill_h)

	if not ow or not oh then
		local max_width, wrapped_lines = self.font:getWrap(self.text, ow or math.huge)

		if self.layout.w == "hug" then
			ow = max_width
		end

		if self.layout.h == "hug" then
			local fontHeight = self.font:getHeight()

			oh = fontHeight * #wrapped_lines
		end

		if ow and oh then
			if ow ~= self.w or oh ~= self.h then
				self:resize(ow, oh)
			end
		end
	end

	return ow, oh
end

function Label:resize(new_w, new_h)
	uiobj.class.resize(self, new_w, new_h)

	self:generateTextCache()
end

---Regenerate crucial data for button text printing (to be rewritten for new layout system)
---@package
function Label:generateTextCache()
    self.textCache = {}

    local fontHeight = self.font:getHeight()
    local allowedLines = math.floor(self.h/fontHeight)

    local _, wrapped_lines = self.font:getWrap(self.text, self.w)

    self.textCache.y = math.floor((self.h - fontHeight * math.min(#wrapped_lines, allowedLines)) / 2)

    if allowedLines == 0 then
        self.textCache.textVisual = "?"
    elseif #wrapped_lines <= allowedLines then
        self.textCache.textVisual = self.text
    else -- text has more lines than allowed
        local tocut = self.text

        -- cut text progressively from end until it is possible to fit it 
        repeat
            tocut = utf.sub(tocut, 1, -2)

            local _, cutlines = self.font:getWrap(tocut .. "..", self.w)
        until #cutlines <= allowedLines
    
        self.textCache.textVisual = tocut .. ".."
    end
end

label.class = Label

-- button fnc

function label.new(prototype)
    local obj = uiobj.new(prototype)

    setmetatable(obj, Label_meta) ---@cast obj Label

    return obj
end

return label