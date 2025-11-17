-- slide
local slide = {}

local uiobj = require("classes.ObjectUI")

-- documentation



-- config

local default_width, default_height = 20, 20

slide.name = "Slider"
slide.aliases = {"Selector"}
slide.rules = {
    {"sizeRectangular", {0, 0, 200, 10}},
    {"position", {position = {"center", "center"}}},

    {"palette", {color = {0, 0.5, 0, 0.4}, textColor = {0, 0.4, 0.2, 1}, additionalColor = {1, 1, 1, 0.4}}},
    {{"slider", "selector"}, "selector", {width = default_width, height = default_height}, {"sizeRectangular"}},
    {{"default", "default_position", "default_value"}, "default", 0}
}

-- consts



-- vars



-- init



-- fnc



-- classes

---@class Slider : ObjectUI
---@field selector {x: number, w: number, h: number, clickedX: integer?, previousX: integer?}
---@field default number Default value of a slider
---@field held boolean If slider currently held
local Slider = {}
local Slider_meta = { __index = Slider }
setmetatable(Slider, {__index = uiobj.class}) -- Set parenthesis

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
    return x >= math.floor(self.x + self.selector.x - self.selector.w / 2 + 0.5) and x <= math.floor(self.x + self.selector.x + self.selector.w / 2 + 0.5) and y >= math.floor(self.y - self.selector.h / 2 + self.h / 2 + 0.5) and y <= math.floor(self.y + self.selector.h / 2 + self.h / 2 + 0.5)
end

function Slider:checkHover(x, y)
    return uiobj.class.checkHover(self, x, y) or self:checkHoverSelector(x, y) and self
end

function Slider:click(x, y, but)
    if but == 1 then
        self.held = true

        if not self:checkHoverSelector(x, y) then
            local new_selector_x = x - self.x

            self:setValue(new_selector_x / self.w)
        end

        self.selector.clickedX = x
        self.selector.previousX = self.selector.x
    end
end

function Slider:clickRelease(x, y, but)
    if but == 1 then
        self.held = false
    end
end

function Slider:tick(dt)
    if self.held then
        self:setValue((self.selector.previousX + love.mouse.getX() - self.selector.clickedX) / self.w)
    end
end

function Slider:setValue(new_value)
    new_value = math.max(0, math.min(1, new_value))

    self.selector.x = new_value * self.w
end

function Slider:getValue(lower, higher)
    local lower, higher = not higher and 0 or lower, higher or lower or 1

    return (self.selector.x / self.w) * (higher - lower) + lower
end

function Slider:setDefault()
    self.selector.x = math.floor(self.default * self.w + 0.5)
end

-- slide fnc

function slide.new(prototype)
    local obj = uiobj.new(prototype)

    setmetatable(obj, Slider_meta) ---@cast obj Slider

    obj:setDefault()

    return obj
end

return slide