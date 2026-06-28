
---@class CanvasObject : CompositeObject
---@field CompositeObject CompositeObject
---@field canvas love.Canvas
local CanvasObject = {
	name = "Canvas",
	extends = "CompositeObject",
	aliases = {"CanvasObject"},
	default = {
		w = "fill",
		h = "fill",
		padding = 15,
	}
}

function CanvasObject:performRepaint()
	if not self.pictureDirty then
		return
	end

	love.graphics.origin()

	love.graphics.setCanvas({self.canvas, stencil = true})

	self.CompositeObject.performRepaint(self)

	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.canvas, 0, 0)

	love.graphics.present()
end

function CanvasObject:redraw()
	self.pleaseRedraw = true
	self:markDirty()
end

function CanvasObject:markDirty()
	self.pictureDirty = true
end

function CanvasObject:paint()
	love.graphics.clear(self:getBackgroundColor())

    for _, uiobject in ipairs(self.objects) do
        if uiobject:isDrawn() then
			local tx, ty = uiobject:getCoordinates()
            love.graphics.translate(tx, ty)
            uiobject:paint()
			uiobject:resetDirty()
            love.graphics.translate(-tx, -ty)
        end
    end
end

function CanvasObject:getBackgroundColor()
	local fill_color = self.palette.main

	if fill_color then
		return fill_color[1], fill_color[2], fill_color[3], fill_color[4]
	end

	return love.graphics.getBackgroundColor()
end

function CanvasObject:getTranslation()
	return 0, 0
end

function CanvasObject:resize(new_w, new_h)
	self.w = new_w
	self.h = new_h

	self.canvas = love.graphics.newCanvas()
	self:redraw()
	collectgarbage("collect")
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

	self:redraw()
end

return CanvasObject