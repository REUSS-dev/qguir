-- panel
local panel = {}

local composite = require("classes.CompositeObject")

-- documentation



-- config

panel.name = "Panel"
panel.aliases = {}

-- consts



-- vars



-- init



-- fnc



-- classes

---@class Panel: CompositeObject
local Panel = {}
local Panel_meta = {__index = Panel}

setmetatable(Panel, {__index = composite.class}) -- Set parenthesis

-- panel fnc

function panel.new(dimensions)
    local obj = composite.new(dimensions)
    ---@cast obj Panel

    setmetatable(obj, Panel_meta)

    return obj
end

return panel