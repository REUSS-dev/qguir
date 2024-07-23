-- composite
local composite = {}

local uiobj = require("classes.ObjectUI")

-- documentation



-- config



-- consts



-- vars



-- init



-- fnc



-- classes

---@class CompositeObject : ObjectUI
---@field objects ObjectUI[]
local CompositeObject = {}
local CompositeObject_meta = {__index = CompositeObject}

---Check, if coordinates provided are in boundaries of any of UI objects in the composite object
---@param x pixels Mouse X position in pixels
---@param y pixels Mouse Y position in pixels
---@return ObjectUI|false hover Returns object pointer if the mouse if hovering on the object, false otherwise
function CompositeObject:checkHover(x, y)
    local hlObject

    for _, uiobject in pairs(self.objects) do
        hlObject = uiobject:checkHover(x, y) or hlObject
    end

    return hlObject
end

---Tick all UI objects in a composite object.
---@param dt seconds
function CompositeObject:tick(dt)
    for _, uiobject in pairs(self.objects) do
        uiobject:tick(dt)
    end
end

---Paint all UI objects in a composite object.
function CompositeObject:paint()
    for _, uiobject in pairs(self.objects) do
        uiobject:paint()
    end
end

setmetatable(CompositeObject, {__index = uiobj.class}) -- Set parenthesis

-- composite fnc

function composite.new(dimensions)
    local obj = uiobj.new(dimensions)
    ---@cast obj CompositeObject

    obj.objects = {}

    setmetatable(obj, CompositeObject_meta)

    return obj
end

return composite