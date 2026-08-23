-- label

local gui = require("stellargui")

local utf = require("utf8")

---@class Label : ObjectUI
---@field ObjectUI ObjectUI
---@field noLocale boolean
---@field text_binding string Locale string address OR plain string
---@field text string Visual text
---@field curParams table Current parameters for parametrized text
---@field textCache table Set of data for printing button text. WARNING: This should be nullified on label size/text change.
local Label = {
	name = "Label",
	rules = {
		"palette",
		{{"text", "label"}, "text_binding"},
		{{"no_localize", "ignore_locale", "no_locale"}, "noLocale"},
		{{"format", "cur_params", "params", "with"}, "curParams"}
	},
	default = {
		w = "hug", h = "hug",
		text = "Label",
		font = 12,

		horizontal = "left",
		textColor = {1, 1, 1, 1},
		noLocale = false,
		cur_params = {}
	},

	locale = gui.getLocaleStorage()
}

function Label:paint()
    -- Text
    love.graphics.setColor(self.palette[2])
    love.graphics.setFont(self.font)
    love.graphics.printf(self.textCache.textVisual, 0, self.textCache.y, self.w, self.layout.horizontal)
end

function Label:getLayoutSize(fill_w, fill_h)
	local ow, oh = self.ObjectUI.getLayoutSize(self, fill_w, fill_h)

	if not ow or not oh then
		if not ow and self.layout.w == "fill" then
			return nil, nil
		end

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

function Label:setData(...)
	self:setText(nil, {...})
end

function Label:setText(new_text, params)
	new_text = new_text or self.text_binding
	params = params or self.curParams

	self.text_binding = new_text

	if self.noLocale then
		self.text = new_text
	else
		self.text = self.locale:format(self.text_binding, params)
		self.curParams = params
	end

	self:generateTextCache()

	if self.parent then
		self.parent:relayout()
	end

	self:redraw()
end

function Label:resize(new_w, new_h)
	self.ObjectUI.resize(self, new_w, new_h)

	self:generateTextCache()
end

---Regenerate crucial data for button text printing (to be rewritten for new layout system)
---@package
function Label:generateTextCache()
	if not self.h then
		return
	end

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

function Label:new()
	self:setInteractible(false)

	self:setText()
end

return Label