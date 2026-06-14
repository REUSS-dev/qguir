
---@class CanvasObject : CompositeObject
local CanvasObject = {
	name = "Canvas",
	extends = "CompositeObject",
	aliases = {"CanvasObject"},
	default = {
		w = "fill",
		h = "fill",
		padding = 15,
	},

	parent = true
}

function CanvasObject:getTranslation()
	return 0, 0
end

function CanvasObject:resize(new_w, new_h)
	self.w = new_w
	self.h = new_h
end

function CanvasObject:wheel()
end

function CanvasObject:new()
	self.x = self.x or 0
	self.y = self.y or 0

	if self.layout.w == "fill" then
		self.layout.w = love.graphics.getWidth()
	end

	if self.layout.h == "fill" then
		self.layout.h = love.graphics.getHeight()
	end

	self:autolayout()
end

return CanvasObject