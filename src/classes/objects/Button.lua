-- button
local button = {}

local uiobj = require("classes.ObjectUI")

local utf = require("utf8")

-- documentation



-- config

button.name = "Button"
button.aliases = {}
button.rules = {
    {"sizeRectangular", {0, 0, 100, 50}},
    {"position", {position = {"center", "center"}}},

    {"palette", {color = {0, 0.5, 0, 0.4}, textColor = {1, 1, 1}}},

    {{"action", "push", "press"}, "action", function() end},
    {{"text", "label"}, "text", "Button"},
    {{"font"}, "font", love.graphics.getFont()}
}

-- consts



-- vars



-- init



-- fnc



-- classes

---@class Button : ObjectUI
---@field held boolean
---@field action fun()
---@field textCache table Set of data for printing button text. WARNING: This should be nullified on button size/text change.
---@field text string
---@field font love.Font
local Button = {}
local Button_meta = {__index = Button}

function Button:paint()
    if self.held then
        love.graphics.setColor(self.palette[1].darker)
    elseif self.hl then
        love.graphics.setColor(self.palette[1].brighter)
    else
        love.graphics.setColor(self.palette[1])
    end
    
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    love.graphics.setColor(self.palette[3])
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

    love.graphics.setColor(self.palette[2])
    love.graphics.setFont(self.font)
    love.graphics.printf(self.textCache.textVisual, self.x, self.textCache.y, self.w, "center")
end

function Button:hoverOn(x, y)
    uiobj.class.hoverOn(self, x, y)

    return "hand"
end

function Button:click(_, _, but)
    if but == 1 then
        self.held = true
    end
end

function Button:clickRelease(x, y, but)
    if but == 1 then
        self.held = false

        if self:checkHover(x, y) then
            self.action()
        end
    end
end

function Button:keyPress(key)
    if key == "return" then
        self.action()
    end
end

function Button:move(x, y)
    uiobj.class.move(self, math.floor(x), math.floor(y))
    self:generateTextCache()
end

setmetatable(Button, {__index = uiobj.class}) -- Set parenthesis

---Generate crucial data for button text printing
---@param nullify boolean? Should the existing text cache be voided completely. Set to true, when button size or text itself changes. 
function Button:generateTextCache(nullify)
    if nullify then
        self.textCache = nil
    end

    if self.textCache then
        self.textCache.y = math.floor(self.y + self.h/2 - self.textCache.fontHeight*self.textCache.textLines/2)
        return
    end

    self.textCache = {}
    
    self.textCache.fontHeight = self.font:getHeight()
    local _, lines = self.font:getWrap(self.text, self.w)

    local allowedLines = math.floor(self.h/self.textCache.fontHeight)

    if allowedLines == 0 then
        self.textCache.textVisual = "?"
        self.textCache.textLines = 0
    elseif #lines <= allowedLines then
        self.textCache.textVisual = self.text
        self.textCache.textLines = #lines
    else
        local tocut = self.text

        repeat
            tocut = string.sub(tocut, 1, utf.offset(tocut, -1) - 1)

            local _, nlines = self.font:getWrap(tocut .. "..", self.w)
        until #nlines <= allowedLines
    
        self.textCache.textVisual = tocut .. ".."
        self.textCache.textLines = allowedLines
    end

    self.textCache.y = math.floor(self.y + self.h/2 - self.textCache.fontHeight*self.textCache.textLines/2)
end

button.class = Button

-- button_legacy fnc

function button.new(prototype)
    local obj = uiobj.new(prototype)
    ---@cast obj Button

    setmetatable(obj, Button_meta)

    obj:generateTextCache()

    return obj
end

return button