-- uiobj
local uiobj = {}



-- documentation



-- config

uiobj.name = "ObjectUI"
uiobj.aliases = {"uiobj"}

-- consts



-- vars



-- init



-- fnc



-- classes

---@class ObjectUI
---@field protected x pixels X coordinate of the UI object in pixels.
---@field protected y pixels Y coordinate of the UI object in pixels.
---@field protected w pixels Width of the UI object in pixels.
---@field protected h pixels Height of the UI object in pixels.
---@field protected hl boolean Flag, if the UI object is currently hovered on.
---@field protected draw boolean Flag, if the UI object should be drawn on screen on paint call.
---@field protected update boolean Flag, if the UI object should be updated on tick call.<br>If **false**, a UI object also should be treated as non-interactible (as if *interactible* flag was also set to false).
---@field protected interactible boolean Flag, if the UI object is interactible by any means.
local ObjectUI = {}
local ObjectUI_meta = {__index = ObjectUI}

--- Flags

---Hide the UI object. Disables paint and tick for a UI object.
function ObjectUI:hide()
    self.draw = false
    self.update = false
end

---Show the UI object. Enable paint and tick for a UI object.
function ObjectUI:show()
    self.draw = true
    self.update = true
end

---Freeze the UI object. Disables tick for a UI object.
function ObjectUI:freeze()
    self.update = false
end

---Unfreeze the UI object. Enable tick for a UI object.
function ObjectUI:unfreeze()
    self.update = true
end

---Returns, if the UI object is being updated.
---@return boolean update State of the "update" flag for an object.
function ObjectUI:isActive()
    return self.update
end

---Returns, if the UI object is being drawn.
---@return boolean draw State of the "draw" flag for an object.
function ObjectUI:isDrawn()
    return self.draw
end

---Returns, if the UI object is interactible.
---@return boolean interactible State of the "interactible" flag for an object.
function ObjectUI:isInteractible()
    return self.interactible
end

---Sets, if the UI object should be drawn.
---@param bool boolean New state of the *draw* flag.
function ObjectUI:setDraw(bool)
    self.draw = bool
end

---Sets, if the UI object should be updated.
---@param bool boolean New state of the *update* flag.
function ObjectUI:setUpdate(bool)
    self.update = bool
end

---Sets, if the UI object should be interactible.
---@param bool boolean New state of the *interactible* flag.
function ObjectUI:setInteractible(bool)
    self.interactible = bool
end

--- Dimensions

---Returns the dimensions of the UI object.
---@return pixels x X coordinate of a UI object
---@return pixels y Y coordinate of a UI object
---@return pixels width Width of a UI object
---@return pixels height Height of a UI object
function ObjectUI:getDimensions()
    return self.x, self.y, self.w, self.h
end

---Returns the position of the UI object.
---@return pixels x X coordinate of a UI object
---@return pixels y Y coordinate of a UI object
function ObjectUI:getCoordinates()
    return self.x, self.y
end

---Returns the position of the UI object on the X-axis.
---@return pixels x X coordinate of the object
function ObjectUI:getX()
    return self.x
end

---Returns the position of the UI object on the Y-axis.
---@return pixels y Y coordinate of the object
function ObjectUI:getY()
    return self.y
end

---Sets the new position of the UI object.
---@param newX pixels New position of the UI object on an X-axis
---@param newY pixels New position of the UI object on a Y-axis
function ObjectUI:move(newX, newY)
    self.x = newX
    self.y = newY
end

---Returns width and height of the UI object.
---@return pixels width Width of a UI object
---@return pixels height Height of a UI object
function ObjectUI:getResolution()
    return self.w, self.h
end

---Returns the width of the UI object.
---@return pixels width Width of a UI object
function ObjectUI:getWidth()
    return self.w
end

---Returns the height of the UI object.
---@return pixels height Height of a UI object
function ObjectUI:getHeight()
    return self.h
end

--- Hover

---Check, if coordinates provided are in boundaries of the UI object
---@param x pixels Mouse X position in pixels
---@param y pixels Mouse Y position in pixels
---@return ObjectUI|false hover Returns object pointer if the mouse if hovering on the object, false otherwise
function ObjectUI:checkHover(x, y)
    return x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h and self
end

---Trigger hover-on callback when the UI object gains hover focus
---@param x pixels Mouse X position in pixels
---@param y pixels Mouse Y position in pixels
---@diagnostic disable-next-line: unused-local
function ObjectUI:hoverOn(x, y)
    self.hl = true
end

---Trigger hover-off callback when the UI object loses hover focus
---@param x pixels Mouse X position in pixels
---@param y pixels Mouse Y position in pixels
---@diagnostic disable-next-line: unused-local
function ObjectUI:hoverOff(x, y)
    self.hl = false
end

--- Virtuals

---Paint the UI object on screen.<br>**This function is virtual and must be defined in a child class**
function ObjectUI:paint()
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

---Tick the UI object.<br>**This function is virtual and must be defined in a child class**
---@param dt seconds Love update delta-time
---@diagnostic disable-next-line: unused-local
function ObjectUI:tick(dt)
end

---Perform click action on UI object<br>**This function is virtual and must be defined in a child class**
---@param x pixels
---@param y pixels
---@param but number
---@diagnostic disable-next-line: unused-local
function ObjectUI:click(x, y, but)
end

---Perform click release action on UI object<br>**This function is virtual and must be defined in a child class**
---@param x pixels
---@param y pixels
---@param but number
---@diagnostic disable-next-line: unused-local
function ObjectUI:clickRelease(x, y, but)
end

uiobj.class = ObjectUI

-- uiobj fnc

---Create new ObjectUI object and assign class metatable to it.
---@param dimensions DimensionsXYWH Dimensions of a new object in a table[4] format.
---@return ObjectUI object New UI object
function uiobj.new(dimensions)
    ---@type ObjectUI
    local obj = {
        x = dimensions[1],
        y = dimensions[2],
        w = dimensions[3],
        h = dimensions[4],

        hl = false,

        draw = true,
        update = true,
        interactible = true
    }

    setmetatable(obj, ObjectUI_meta)

    return obj
end

uiobj.class = ObjectUI -- Allow child classes.

return uiobj