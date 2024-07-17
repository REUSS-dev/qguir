-- layout
local layout = {}

local uiobj = require("classes.ObjectUI")

-- documentation



-- config



-- consts



-- vars



-- init



-- fnc



-- classes

---@class Layout: ObjectUI
---@field objects ObjectUI[]
local Layout = {}
local Layout_meta = {__index = Layout}

setmetatable(Layout, {__index = uiobj.class}) -- Set parenthesis

-- layout fnc

function layout.new(dimensions)
    local obj = uiobj.new(dimensions)
    ---@cast obj Layout

    obj.objects = {}

    setmetatable(obj, Layout_meta)

    return obj
end

return layout