-- button_legacy
local button_legacy = {}

local uiobj = require("classes.ObjectUI")

-- documentation



-- config

button_legacy.name = "Button_L"
button_legacy.aliases = {}
button_legacy.rules = {
    {"sizeRectangular", {0, 0, 100, 50}},
    {"position", {position = {"center", "center"}}}
}

-- consts



-- vars



-- init



-- fnc



-- classes

---@class Button_L : ObjectUI
local Button_L = {}
local Button_L_meta = {__index = Button_L}

function Button_L:paint()
    love.graphics.setColor(self.hl and {1,0,0} or {1,1,1})
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

setmetatable(Button_L, {__index = uiobj.class}) -- Set parenthesis

button_legacy.class = Button_L

-- button_legacy fnc

function button_legacy.new(prototype)
    local obj = uiobj.new(prototype)
    ---@cast obj Button_L

    setmetatable(obj, Button_L_meta)

    return obj
end

return button_legacy