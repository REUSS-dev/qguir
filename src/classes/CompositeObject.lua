-- composite
local composite = {}

local uiobj = require("classes.ObjectUI")

-- documentation



-- config

composite.name = "CompositeObject"
composite.aliases = {"Composite"}

-- consts



-- vars



-- init



-- fnc



-- classes

---@class CompositeObject : ObjectUI
---@field objects ObjectUI[] List of UI objects inside the composite object
---@field hlObject ObjectUI|false UI object, that currently has focus out of all UI objects iside the composite object
---@field hlObjectBuffer ObjectUI|false UI object, that potentially can get focus after the call of onHover()
---@field clickObjectBuffer ObjectUI|false UI object, that will recieve clickRelease event call when the composite object receives it
local CompositeObject = {}
local CompositeObject_meta = {__index = CompositeObject}

---Check, if coordinates provided are in boundaries of any of UI objects in the composite object
---@param x pixels Mouse X position in pixels
---@param y pixels Mouse Y position in pixels
---@return ObjectUI|false hover Returns object pointer if the mouse if hovering on the object, false otherwise
function CompositeObject:checkHover(x, y)
    if not uiobj.class.checkHover(self, x, y) then
        return false
    end

    local hlObject

    for _, uiobject in pairs(self.objects) do
        hlObject = uiobject:checkHover(x, y) or hlObject
    end

    if not hlObject then
        return false
    end

    self.hlObjectBuffer = hlObject

    return self
end

---Promote buffered hlObject and trigger its hover-on callback when the composite UI object gains hover focus.
---@param x pixels Mouse X position in pixels
---@param y pixels Mouse Y position in pixels
function CompositeObject:hoverOn(x, y)
    self.hl = true

    self.hlObject = self.hlObjectBuffer
    self.hlObjectBuffer = false

    self.hlObject:hoverOn(x, y)
end

---Clear hlObject and trigger its hover-off callback when the composite UI object loses hover focus.
---@param x pixels Mouse X position in pixels
---@param y pixels Mouse Y position in pixels
function CompositeObject:hoverOff(x, y)
    self.hl = false

    self.hlObject:hoverOff(x, y)

    self.hlObject = false
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

---Perform click action on one of UI objects inside the composite object
---@param x pixels
---@param y pixels
---@param but number
function CompositeObject:click(x, y, but)
    if self.hlObject then
        self.clickObjectBuffer = self.hlObject
        self.hlObject:click(x, y, but)
    end
end

---Perform click release action on one of UI objects inside the composite object
---@param x pixels
---@param y pixels
---@param but number
function CompositeObject:clickRelease(x, y, but)
    if self.clickObjectBuffer then
       self.clickObjectBuffer:clickRelease(x, y, but)
       self.clickObjectBuffer = false
    end
end

setmetatable(CompositeObject, {__index = uiobj.class}) -- Set parenthesis

composite.class = CompositeObject

-- composite fnc

function composite.new(dimensions)
    local obj = uiobj.new(dimensions)
    ---@cast obj CompositeObject

    obj.objects = {}

    obj.hlObject = false
    obj.hlObjectBuffer = false
    obj.clickObjectBuffer = false

    setmetatable(obj, CompositeObject_meta)

    return obj
end

return composite