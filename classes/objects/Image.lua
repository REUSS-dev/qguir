-- image

-- documentation

---@alias ImageDisplayMode "normal"|"stretch"|"limit"
---@alias ImageDrawCache {x: integer, y: integer, wscale: number, hscale: number}

-- vars

local x, y, w, h, r

-- fnc

local function stencil_function()
	love.graphics.rectangle("fill", x, y, w, h, r)
end

-- classes

---@class Image : ObjectUI
---@field ObjectUI ObjectUI
---@field r number Radius of round corner
---@field image love.Image
---@field display ImageDisplayMode
---@field drawCache ImageDrawCache
local Image = {
	name = "Image",
	rules = {
		"palette",
		
		{{"image", "img", "picture"}, "image"},
		{{"displayMode", "display"}, "display", "normal"},
    	{{"r", "radius", "rounding", "round"}, "r"}
	},
	default = {
		w = "fill", h = "fill",
		color = {1, 1, 1 ,1},
		display = "normal"
	}
}

function Image:paint()
    love.graphics.setColor(self.palette[1])

	if self.r then
		x, y, r, w, h = self.drawCache.x, self.drawCache.y, self.image:getWidth() * self.drawCache.wscale, self.image:getHeight() * self.drawCache.hscale, self.r
		love.graphics.stencil(stencil_function, "increment", 0, true)

		local oldStencil = {love.graphics.getStencilTest()}

		love.graphics.setStencilTest("gequal", oldStencil[2] + 1)

		love.graphics.draw(self.image, self.drawCache.x, self.drawCache.y, 0, self.drawCache.wscale, self.drawCache.hscale)

		love.graphics.stencil(stencil_function, "decrement", 0, true)
		love.graphics.setStencilTest(unpack(oldStencil))

		return
	end

	love.graphics.draw(self.image, self.drawCache.x, self.drawCache.y, 0, self.drawCache.wscale, self.drawCache.hscale)
end

function Image:getLayoutSize(fill_w, fill_h)
	local ow, oh = self.ObjectUI.getLayoutSize(self, fill_w, fill_h)

	if not ow or not oh then
		if self.layout.w == "hug" then
			if self.layout.h == "hug" then
				error("Image object cannot be [\"hug\", \"hug\"]")
			end

			if self.display == "stretch" then
				error("Image object display mode cannot be \"stretch\", when one of dimensions is \"hug\"")
			end

			if oh then
				if oh == self.h then
					return self.w, self.h
				end

				local img_h = self.image:getHeight()
				local scale = oh / img_h

				if self.display == "limit" then
					scale = math.min(scale, 1)
				end

				ow = math.floor(self.image:getWidth() * scale + .5)
			else
				return 0, nil
			end
		elseif self.layout.h == "hug" then
			if self.display == "stretch" then
				error("Image object display mode cannot be \"stretch\", when one of dimensions is \"hug\"")
			end

			if ow then
				if ow == self.w then
					return self.w, self.h
				end

				local img_w = self.image:getWidth()
				local scale = ow / img_w

				if self.display == "limit" then
					scale = math.min(scale, 1)
				end

				oh = math.floor(self.image:getHeight() * scale + .5)
			else
				return nil, 0
			end
		end

		if ow and oh then
			if ow ~= self.w or oh ~= self.h then
				self:resize(ow, oh)
			end
		end
	end

	return ow, oh
end

function Image:resize(new_w, new_h)
	self.ObjectUI.resize(self, new_w, new_h)

	self:calculateDrawParameters()
end

function Image:calculateDrawParameters()
	if not self.w or not self.h then
		return
	end

	local drawCache = {} ---@type ImageDrawCache

	local img_w, img_h = self.image:getDimensions()

	if self.display == "stretch" then
		drawCache.x = 0
		drawCache.y = 0
		drawCache.wscale = self.w / img_w
		drawCache.hscale = self.h / img_h
	elseif self.display == "normal" or self.display == "limit" then
		local scale

		if self.w / self.h >= img_w / img_h then -- мерить по высоте
			scale = self.h / img_h
		else -- мерить по ширине
			scale = self.w / img_w
		end

		if self.display == "limit" then
			scale = math.min(scale, 1)
		end

		drawCache.x = math.floor((self.w - img_w * scale)/2 + .5)
		drawCache.y = math.floor((self.h - img_h * scale)/2 + .5)
		drawCache.wscale = scale
		drawCache.hscale = scale
	end

	self.drawCache = drawCache
end

-- image fnc

function Image:new()
	if self.display ~= "normal" and self.display ~= "stretch" and self.display ~= "limit" then
		error("Display mode of an image can be: normal, stretch, limit. Got: " .. self.display)
	end

	if not self.image then
		error("Image must be provided for an Image object")
	end
end

return Image