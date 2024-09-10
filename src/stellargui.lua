-- stellar
local stellar = {}



-- documentation

---@meta
---@diagnostic disable

---@alias pixels number Amount of pixels.
---@alias seconds number Amount of seconds
---@alias DimensionsXYWH {[1]: pixels, [2]: pixels, [3]: pixels, [4]:pixels} Structure for some object's X position, Y position, width and height.

---@alias ObjectDefinition table Table, which contains UI object definition fields, and is to be processed by UI object definition Parser
---@alias ObjectParser fun(definition: ObjectDefinition, sink: table):boolean A function, that processes UI object definition and outputs prepared parameters into sink. If it fails to process given definition, it will return false.

---@alias registeredIndex number Index of the registered UI object that it can be referenced by in lib functions

-- config



-- consts



-- vars

local registeredObjects = {}        ---@type {[registeredIndex]: ObjectUI} Currently registered objects in the system that are eligible for update and draw.
local registeredAssociative = {}    ---@type {[ObjectUI]: registeredIndex} Associative array of registered objects used to get registration index by object reference

local currentHl                     ---@type ObjectUI [TODO-1] May be implemented as one-value ephemeron to provide consistent object cleaning. Not needed currently, deleted objects do not update and their references in this variable are getting replaced soon anyway
local heldObject                    ---@type ObjectUI [TODO-1] May be implemented as one-value ephemeron to provide consistent object cleaning. Not needed currently, deleted objects do not update and their references in this variable are getting replaced soon anyway

local definition_parsers = {}       ---@type {[string]: ObjectParser} Collection of parsers for UI objects parameters

-- init

setmetatable(registeredAssociative, {__mode = 'k'})

local love = love
local love_update, love_draw, love_mousepressed, love_mousereleased = love.update, love.draw, love.mousepressed, love.mousereleased

-- fnc

---Standard update function for the functionality of StellarGUI
---@param dt seconds
local function stellar_update(dt)
    local hlObject

    local x, y = love.mouse.getX(), love.mouse.getY()

    for _, registered in pairs(registeredObjects) do
        hlObject = registered:checkHover(x, y) or hlObject
    end

    ---@cast hlObject ObjectUI

    if hlObject ~= currentHl then
        currentHl:hoverOff(x, y)
        hlObject:hoverOn(x, y)
        currentHl = hlObject
    end

    for _, registered in pairs(registeredObjects) do
        registered:tick(dt)
    end
end

---Standard draw function for the functionality of StellarGUI
local function stellar_draw()
    for _, registered in pairs(registeredObjects) do
        registered:paint()
    end
end

--- Parsers collection

---Parser for object width and height.<br>Will parse size (ex. width = 200, height = 100) correctly if it is defined in the definition table as any of following:<br>{0, 0, 200, 100}<br>{"objectName", 0, 0, 200, 100}<br>{w = 200, h = 100}<br>{width = 200, height = 100}<br>{ size = {200, 100} }
---@param def ObjectDefinition
---@param sink table
---@return boolean success
function definition_parsers.sizeRectangular(def, sink)
    local width = def.w or def.width or (def.size or {})[1] or (type(def[1]) == "number") and def[3] or (type(def[2]) == "number") and def[4]
    local height = def.h or def.height or (def.size or {})[2] or (type(def[1]) == "number") and def[4] or (type(def[2]) == "number") and def[5]

    if not width or not height then
        return false
    end

    sink.w = width
    sink.h = height

    return true
end

---Parser for object position on the screen.<br>Will parse position (ex. x = 200, y = 100) correctly if it is defined in the definition table as any of following:<br>{200, 100}<br>{"objectName", 200, 100}<br>{x = 200, y = 100}<br>{horizontal = 200, vertical = 100}<br>{ position = {200, 100} }<br>{ pos = {200, 100} }<br>{ coordinates = {200, 100} }<br>**Also supports setting one of the dimensions to the string<br>"center"/"centered"/"middle"/"mid" (any of the following) to center object's position based on its size.<br>Also supports negative coordinates.<br>Position of the object will be counted from the other edge of screen in this case (respecting object's size)**
---@param def ObjectDefinition
---@param sink table
---@return boolean success
function definition_parsers.position(def, sink)
    local x = def.x or def.horizontal or (def.position or {})[1] or (def.pos or {})[1] or (def.coordinates or {})[1] or (type(def[1]) == "number") and def[1] or (type(def[2]) == "number") and def[2]
    local y = def.y or def.vertical or (def.position or {})[2] or (def.pos or {})[2] or (def.coordinates or {})[2] or (type(def[1]) == "number") and def[2] or (type(def[2]) == "number") and def[3]

    if not x or not y then
        return false
    end

    local sw, sh = love.graphcis.getWidth(), love.graphics.getHeight()

    if type(x) == "string" then
        if x == "center" or x == "centered" or x == "middle" or x == "mid" then
            x = math.floor(sw/2-sink.w/2)
        end
    elseif x < 0 then
        x = sw - sink.w + x
    end

    if type(y) == "string" then
        if y == "center" or y == "centered" or y == "middle" or y == "mid" then
            y = math.floor(sh/2-sink.h/2)
        end
    elseif y < 0 then
        y = sh - sink.h + y
    end

    return true
end

-- classes



-- stellar fnc

---Register the UI object descriptor in a system for update and draw
---@param uiobj ObjectUI A UI object to register
---@return registeredIndex index Index of a registered UI object that it can be referenced by in other functions
function stellar.register(uiobj)
    local newIndex = #registeredObjects+1

    registeredAssociative[uiobj] = newIndex
    registeredObjects[newIndex] = uiobj

    return newIndex
end

function stellar.unregister(uiobj)
    local registeredIndex

    if type(uiobj) == "table" then
        registeredIndex = registeredAssociative[uiobj]

        if not registeredIndex then
            return false
        end
    elseif type(uiobj) == "number" then
        if registeredObjects[uiobj] then
            registeredIndex = uiobj
        else
            return false
        end
    end

    registeredObjects[uiobj] = nil
    return true
end

--- Stellar hook

function stellar.hook()
    love.update = function(dt)
        love_update(dt)
        stellar_update(dt)
    end

    love.draw = function()
        love_draw()
        stellar_draw()
    end

    love.mousepressed = function (x, y, but)
        if currentHl then
            heldObject = currentHl

            currentHl:click(x, y, but)
        else
            love_mousepressed(x, y, but)
        end
    end

    love.mousereleased = function (x, y, but)
        if heldObject then
            heldObject:clickRelease(x, y, but)

            heldObject = nil
        else
            love_mousereleased(x, y, but)
        end
    end

    return stellar
end

--- Parsers

stellar.parser_collection = definition_parsers

return stellar