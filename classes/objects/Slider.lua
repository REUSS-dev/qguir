-- slide

-- config

local default_width, default_height = 20, 20

-- classes

---@class Slider : ObjectUI
---@field ObjectUI ObjectUI
---@field selector {x: number, w: number, h: number, clickedX: integer?, previousX: integer?}
---@field default_value number Default value of a slider
---@field held boolean If slider currently held
local Slider = {
	name = "Slider",
	aliases = "Selector",
	rules = {
		"palette",
		{{"slider", "selector"}, "selector"},
		{{"default", "default_position", "default_value"}, "default_value"}
	},
	default = {
		w = 200, h = 10,
		colors = {
			main = {0, 0.5, 0, 0.4},
			text = {0, 0.4, 0.2, 1},
			border = {1, 1, 1, 0.4}
		},

		slider = {w = default_width, h = default_height},
		default = 0
	}
}

function Slider:paint()
    -- Inside fill
    love.graphics.setColor(self.palette[1])
    love.graphics.rectangle("fill", 0, 0, self.w, self.h)
    -- inside border
    love.graphics.setColor(self.palette[3])
    love.graphics.rectangle("line", 0, 0, self.w, self.h)

    -- Slider
    love.graphics.setColor(self.palette[2])
    love.graphics.rectangle("fill", math.floor(self.selector.x - self.selector.w / 2 + 0.5), math.floor(-self.selector.h / 2 + self.h / 2 + 0.5), self.selector.w, self.selector.h)
    -- Border
    love.graphics.setColor(self.palette[3])
    love.graphics.rectangle("line", math.floor(self.selector.x - self.selector.w / 2 + 0.5), math.floor(-self.selector.h / 2 + self.h / 2 + 0.5), self.selector.w, self.selector.h)
end

function Slider:checkHoverSelector(x, y)
	local tx, ty = self:getTranslation()

    return x >= math.floor(tx + self.selector.x - self.selector.w / 2 + 0.5) and x <= math.floor(tx + self.selector.x + self.selector.w / 2 + 0.5) and y >= math.floor(ty - self.selector.h / 2 + self.h / 2 + 0.5) and y <= math.floor(ty + self.selector.h / 2 + self.h / 2 + 0.5) and self
end

function Slider:checkHover(x, y)
    return self.ObjectUI.checkHover(self, x, y) or self:checkHoverSelector(x, y)
end

function Slider:click(x, y, but)
    if but == 1 then
        self.held = true

        if not self:checkHoverSelector(x, y) then
            local new_selector_x = x

            self:setValue(new_selector_x / self.w)
        end

        self.selector.clickedX = x + (self:getTranslation())
        self.selector.previousX = self.selector.x
    end
end

function Slider:clickRelease(_, _, but)
    if but == 1 then
        self.held = false
    end
end

function Slider:tick(_)
    if self.held then
        self:setValue((self.selector.previousX + love.mouse.getX() - self.selector.clickedX) / self.w)
    end
end

function Slider:setValue(new_value)
    new_value = math.max(0, math.min(1, new_value))

    self.selector.x = new_value * self.w
end

function Slider:getValue(lower, higher)
    lower, higher = not higher and 0 or lower, higher or lower or 1

    return (self.selector.x / self.w) * (higher - lower) + lower
end

function Slider:setDefault()
    self.selector.x = math.floor(self.default_value * self.w + 0.5)
end

-- slide fnc

function Slider:new()
    self:setDefault()
end

return Slider