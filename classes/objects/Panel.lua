-- panel

---@class Panel: ObjectUI
---@field r number Radius of round corner
local Panel = {
	name = "Panel",
	rules = {
		"palette",
		{{"r", "radius", "rounding", "round"}, "r"}
	},
	default = {
		w = "fill", h = "fill",
		color = {1, 1, 1, 1}
	}
}

function Panel:paint()
    love.graphics.setColor(self.palette[1])
    love.graphics.rectangle("fill", 0, 0, self.w, self.h, self.r)
end

return Panel