-- Icon

---@enum Icons
local Icons = {
	ChevronDown = "ChevronDown",
	ChevronLeft = "ChevronLeft",
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

function Icon:setStyle(new_style)
	self.style = assert(Icons[new_style], "Unknown Icon style: " .. new_style)

	self.paintIcon = self["paint" .. new_style]
	self:redraw()
end

function Icon:paintChevronDown()
	love.graphics.line(self.w/3, self.h/3, self.w/2, self.h/5*3, self.w/3*2, self.h/3)
end

function Icon:paintChevronLeft()
	love.graphics.line(self.w/3*2, self.h/3, self.w/5*2, self.h/2, self.w/3*2, self.w/3*2)
end

-- Icon fnc

function Icon:new()
	self:setStyle(self.style)
end

return Icon