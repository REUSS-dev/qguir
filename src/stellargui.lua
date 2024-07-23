-- stellar
local stellar = {}



-- documentation

---@alias pixels number Amount of pixels.
---@alias seconds number Amount of seconds
---@alias DimensionsXYWH {[1]: pixels, [2]: pixels, [3]: pixels, [4]:pixels} Structure for some object's X position, Y position, width and height.

---@alias registeredIndex number Index of the registered UI object that it can be referenced by in lib functions

-- config



-- consts



-- vars

local registeredObjects = {}        ---@type {[registeredIndex]: ObjectUI}
local registeredAssociative = {}    ---@type {[ObjectUI]: registeredIndex}

local currentHl                     ---@type ObjectUI [TODO-1] May be implemented as one-value ephemeron to provide consistent object cleaning. Not needed currently, deleted objects do not update and their references in this variable are getting replaced soon anyway

-- init

setmetatable(registeredAssociative, {__mode = 'k'})

-- fnc

local function stellar_update(dt)
    local hlObject

    for _, registered in pairs(registeredObjects) do
        hlObject = registered:checkHover(x, y) or hlObject
    end

    if hlObject ~= currentHl then
        currentHl:hoverOff()
        hlObject:hoverOn()
        currentHl = hlObject
    end

    for _, registered in pairs(registeredObjects) do
        registered:tick(dt)
    end
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

return stellar