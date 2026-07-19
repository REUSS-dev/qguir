-- Icon

---@enum Icons
local Icons = {
	ArrowUp = "ArrowUp",
	ArrowDown = "ArrowDown",
	ArrowLeft = "ArrowLeft",
	ArrowRight = "ArrowRight",
	ChevronDown = "ChevronDown",
	ChevronLeft = "ChevronLeft",
	ChevronRight = "ChevronRight",
}

-- classes

---@class Icon : ObjectUI
---@field ObjectUI ObjectUI
---@field style Icons
---@field weight number
local Icon = {
	name = "Icon",
	rules = {
		"palette",
		{{"style"}, "style"},
		{{"weight"}, "weight"},
	},
	default = {
		w = "fill", h = "fill",
		color = {1, 1, 1 ,1},
		weight = 3,
		style = "rectangle"
	}
}

function Icon:paint()
    love.graphics.setColor(self.palette[1])
	love.graphics.setLineWidth(self.weight)

	self:paintIcon()
end

function Icon:paintIcon()
end

---@param new_style Icons
function Icon:setStyle(new_style)
	self.style = assert(Icons[new_style], "Unknown Icon style: " .. new_style)

	self.paintIcon = self["paint_" .. new_style]
	self:redraw()
end

function Icon:paint_ArrowUp()
	love.graphics.polygon("fill", 0, self.h/2, self.w/2, 0, self.w + 1, self.h/2)
	love.graphics.rectangle("fill", self.w/3, self.h/2, self.w/3, self.h/2)
end

function Icon:paint_ArrowDown()
	love.graphics.polygon("fill", 0, self.h/2, self.w/2, self.h, self.w + 1, self.h/2)
	love.graphics.rectangle("fill", self.w/3, 0, self.w/3, self.h/2)
end

function Icon:paint_ArrowLeft()
	love.graphics.polygon("fill", self.w/2, 0, 0, self.h/2, self.w/2, self.h + 1)
	love.graphics.rectangle("fill", self.w/2, self.h/3, self.w/2, self.h/3)
end

function Icon:paint_ArrowRight()
	love.graphics.polygon("fill", self.w/2, 0, self.w, self.h/2, self.w/2, self.h + 1)
	love.graphics.rectangle("fill", 0, self.h/3, self.w/2, self.h/3)
end

function Icon:paint_ChevronDown()
	love.graphics.line(self.w/3, self.h/3, self.w/2, self.h/5*3, self.w/3*2, self.h/3)
end

function Icon:paint_ChevronLeft()
	love.graphics.line(self.w/3*2, self.h/3, self.w/5*2, self.h/2, self.w/3*2, self.h/3*2)
end

function Icon:paint_ChevronRight()
	love.graphics.line(self.w/3, self.h/3, self.w/5*3, self.h/2, self.w/3, self.h/3*2)
end

-- Icon fnc

function Icon:new()
	self:setStyle(self.style)
	self:setInteractible(false)
end

return Icon