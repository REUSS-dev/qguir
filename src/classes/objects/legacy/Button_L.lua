-- button_legacy
local button_legacy = {}

local gui = require("stellargui")

local uiobj = require("classes.ObjectUI")

-- documentation



-- config

button_legacy.name = "Button_L"
button_legacy.aliases = {}

-- consts



-- vars



-- init



-- fnc



-- classes

---@class Button_L : ObjectUI
local Button_L = {}
local Button_L_meta = {__index = Button_L}

setmetatable(Button_L, {__index = uiobj.class}) -- Set parenthesis

button_legacy.class = Button_L

-- button_legacy fnc

function button_legacy.new(dimensions)
    local obj = uiobj.new(dimensions)
    ---@cast obj Button_L

    setmetatable(obj, Button_L_meta)

    return obj
end

function button_legacy.construct(parameters)
    
end

return button_legacy