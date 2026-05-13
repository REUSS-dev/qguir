-- stellar
local stellar = {}

local selfpath = (...):match("^(.*%.?[^.]+)$"):gsub("%.", "/")
love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";" .. love.filesystem.getRequirePath():gsub("(%?%.lua)", selfpath .. "/%1"))

local utf = require("utf8")

local composite = require("classes.CompositeObject")
local paletteClass = require("classes.Palette")

-- documentation

---@meta

---@alias pixels number Amount of pixels.
---@alias seconds number Amount of seconds
---@alias DimensionsXYWH {[1]: pixels, [2]: pixels, [3]: pixels, [4]: pixels} Structure for some object's X position, Y position, width and height.

---@alias ObjectDescriptor {name: string, aliases: string[]?, new: (fun(prototype: ObjectPrototype):ObjectUI), rules: ObjectParsingRule[], cursors: table<string, love.Cursor>?, construct: fun(ObjectDefinition): ObjectUI}

---@alias ObjectDefinition table Table, which contains UI object definition fields, and is to be processed by UI object definition Parser
---@alias ObjectParser fun(definition: ObjectDefinition, sink: ObjectPrototype):boolean A function, that processes UI object definition and outputs prepared parameters into sink. If it fails to process given definition, it will return false.
---@alias ObjectParserName string
---@alias ObjectParsingRule ObjectParserName|function|{[1]: ObjectParserName, [2]: ObjectDefinition}|{[1]: string[], [2]: string, [3]: ObjectDefinition, [4]: ObjectParserName[]?}
---@alias ObjectPrototype table Table, which contains valid object keys and parameters. Usually returned from parseDefinition

---@alias ResolutiionValue "hug"|"fill"|number
---@alias GrowthVariants "vertical"|"horizontal"
---@alias HorizontalAlignmentVariants "left"|"center"|"right"
---@alias VerticalAlignmentVariants "top"|"center"|"bottom"
---@alias FourSides {[1]: number, [2]: number, [3]: number, [4]: number}
---@alias LayoutProperties {w: ResolutiionValue, h: ResolutiionValue, padding: FourSides, growth: GrowthVariants, horizontal: HorizontalAlignmentVariants, vertical: VerticalAlignmentVariants, ignore: boolean?, gap: number}

-- config

local externalTypesDir = selfpath .. "/classes/objects"

-- consts

local DEFAULT_CURSOR = "arrow"
local DEFAULT_DOUBLE_CLICK_TIME = 0.5

local DEFAULT_GROWTH = "vertical"
local DEFAULT_ALIGNMENT_HORIZONTAL = "center"
local DEFAULT_ALIGNMENT_VERTICAL = "center"
local DEFAULT_GAP = 10

local CANVAS_DEFAULT_GAP = DEFAULT_GAP
local CANVAS_DEFAULT_PADDING = {15, 15, 15, 15}

-- vars

local currentCursor = DEFAULT_CURSOR ---@type love.CursorType
local doubleClickTime = DEFAULT_DOUBLE_CLICK_TIME


local object_descriptors = {}       ---@type table<string, ObjectDescriptor>
local definition_parsers = {}       ---@type {[string]: ObjectParser} Collection of parsers for UI objects parameters
local cursorStorage = {}            ---@type {[love.CursorType|string]: love.Cursor}

local current_canvas				---@type CanvasObject
local canvases = {}					---@type CanvasObject[]

local currentHl                     ---@type ObjectUI? UI object mouse cursor currently on
local heldObject = {}               ---@type table<integer, ObjectUI> UI object last mousepressed event was on (table element for every mouse button)
local focusedObject                 ---@type ObjectUI? UI object that currently has keyboard focus

local hooked

-- Double click detection
local lastClickTime, lastClickButton, lastClickPosition, lastClickedObject = 0, 0, {-1, -1}, nil

-- init

local love = love -- НЕ УДАЛЯТЬ. Предотвращает варнинги в других местах, где объявляются коллбеки love
local nopFunc = function() end

setmetatable(stellar, {
    __index = function (self, key)
        if object_descriptors[key] then
            return object_descriptors[key].construct
        end
    end
})

setmetatable(cursorStorage, {
    __index = function (self, key)
        self[key] = love.mouse.getSystemCursor(key)
        return self[key]
    end
})

--- Figuring out the doubleclick time

if love.system.getOS() == "Windows" then
	local ffi = require("ffi")

    ffi.cdef[[
        uint32_t GetDoubleClickTime();
    ]]
    
    doubleClickTime = ffi.C.GetDoubleClickTime() / 1000
end

-- fnc

--- utf-aware string.sub()
local function utf_sub(str, b, e)
    return string.sub(str, utf.offset(str, b), e ~= -1 and (utf.offset(str, e + 1) - 1) or -1)
end

---Standard update function for the functionality of StellarGUI
---@param dt seconds
local function stellar_update(dt)
    local x, y = love.mouse.getX(), love.mouse.getY()

	local hlObject = current_canvas:isActive() and current_canvas:checkHover(x, y)

    ---@cast hlObject ObjectUI?

    if hlObject ~= currentHl then
        local newCursor = DEFAULT_CURSOR

        if currentHl then
            currentHl:hoverOff(currentHl:convertGlobalCoords(x, y))
        end

        if hlObject then
            newCursor = hlObject:hoverOn(hlObject:convertGlobalCoords(x, y)) or newCursor
        end

        if newCursor ~= currentCursor then
            currentCursor = newCursor
            love.mouse.setCursor(cursorStorage[newCursor])
        end

        currentHl = hlObject
    end

	current_canvas:tick(dt)
end

---Standard draw function for the functionality of StellarGUI
local function stellar_draw()
    love.graphics.push("transform")

    current_canvas:paint()

    love.graphics.pop()
end

--#region Parsers collection

---Parser for object width and height.<br>Will parse size (ex. width = 200, height = 100) correctly if it is defined in the definition table as any of following:<br>{0, 0, 200, 100}<br>{"objectName", 0, 0, 200, 100}<br>{w = 200, h = 100}<br>{width = 200, height = 100}<br>{ size = {200, 100} }
---@type ObjectParser
function definition_parsers.layout(def, sink)
	layout = sink.layout or {}

    local width = layout.w or def.w or def.width or (def.size or {})[1]
    local height = layout.h or def.h or def.height or (def.size or {})[2]
    layout.w = width
    layout.h = height

	local padding = def.padding

	if padding then
		if type(padding) == "number" then
			padding = {padding, padding, padding, padding}
		elseif type(padding) == "table" then
			if #padding == 1 then
				padding = {padding[1], padding[1], padding[1], padding[1]}
			elseif #padding == 2 then
				padding = {padding[2], padding[1], padding[2], padding[1]}
			elseif #padding == 3 then
				padding = {padding[2], padding[1], padding[2], padding[3]}
			elseif #padding >= 4 then
				padding = {padding[1], padding[2], padding[3], padding[4]}
			else
				padding = nil
			end
		end
	end

	layout.padding = layout.padding or padding

	layout.growth = layout.growth or def.growth
	layout.horizontal = layout.horizontal or def.horizontal
	layout.vertical = layout.vertical or def.vertical
	layout.gap = layout.gap or def.gap

	layout.ignore = layout.ignore or def.ignoreLayout or def.ignore_layout or def.static

	if sink.layout then
		layout.padding = layout.padding or {0, 0, 0, 0}

		layout.growth = layout.growth or DEFAULT_GROWTH
		layout.horizontal = layout.horizontal or DEFAULT_ALIGNMENT_HORIZONTAL
		layout.vertical = layout.vertical or DEFAULT_ALIGNMENT_VERTICAL
		layout.gap = layout.gap or DEFAULT_GAP

		return true
	end

	sink.layout = layout

    return false
end

function definition_parsers.palette(def, sink)
    local palette = def.palette or def.palete or def.colors

    if palette then
        if type(palette) == "table" and palette.container then
            sink.palette = palette
            return true
        end

        sink.palette = paletteClass.new(palette)
        return true
    end

    local color = def.color or def.mainColor or def.colorMain or def.main_color
    local text = def.textColor or def.colorText or def.text_color
    local alt = def.frameColor or def.colorFrame or def.additionalColor or def.colorAdditional or def.bgColor or def.hlColor

    if sink.palette then
        if not sink.palette:getColorByIndex(1) then
            sink.palette:setColor(1, color)
        end
        if not sink.palette:getColorByIndex(2) then
            sink.palette:setColor(2, text)
        end
        if not sink.palette:getColorByIndex(3) then
            sink.palette:setColor(3, alt)
        end

        return true
    end

    sink.palette = paletteClass.new({color, text, alt})

    if not color or not text or not alt then
        return false        
    end

    return true
end

--#endregion

---Parse provided definition into object prototype
---@param definition ObjectDefinition
---@param rules ObjectParsingRule[]
---@return ObjectPrototype
local function parseDefinition(definition, rules)
    local objectPrototype = {}
    
    for _, parser in ipairs(rules) do
        if type(parser) == "string" then -- 1. Stupid parsing (not aware of failure)
            definition_parsers[parser](definition, objectPrototype)
        elseif type(parser) == "function" then -- 2. Custom object type-provided parser
            parser(definition, objectPrototype)
        elseif type(parser) == "table" then
            if type(parser[1]) == "string" then -- 3. Parsing with default value set
                if not definition_parsers[parser[1]](definition, objectPrototype) then
                    definition_parsers[parser[1]](parser[2], objectPrototype)
                end
            elseif type(parser[1]) == "table" then -- 4. Simple parsing
                local possibleInputNames, outputName, defaultValue, appliedRules = parser[1], parser[2], parser[3], parser[4]
                local value

                for _, name in ipairs(possibleInputNames) do
                    if type(definition[name]) ~= "nil" then
                        value = definition[name]
                        break
                    end
                end

                if type(value) == "nil" then
                    value = defaultValue
                end

                if not appliedRules then -- 4.1. Generalized passthrough
                    objectPrototype[outputName] = value
                else -- 4.2 Generalized recursive parsing
                    objectPrototype[outputName] = parseDefinition(value, appliedRules)
                end
            end
        end
    end

    return objectPrototype
end

---@debug parsing test print(parseDefinition({numb = false, aquarium = {12, 123}}, {{"position", {10, 20}}, {{"isWhale"}, "fish", "false"}, {{"numb"}, "n", 123}, {{"fishtank", "aquarium"}, "aqua", {}, {"position"}}}).aqua.x)

---Register UI object type descriptor
---@param typeDescriptor ObjectDescriptor
local function registerType(typeDescriptor)
    function typeDescriptor.construct(def)
        local prototype = parseDefinition(def, typeDescriptor.rules)
        return typeDescriptor.new(prototype)
    end

    object_descriptors[typeDescriptor.name] = typeDescriptor

    if typeDescriptor.aliases then
        for _, alias in ipairs(typeDescriptor.aliases) do
            object_descriptors[alias] = typeDescriptor
        end        
    end

    if typeDescriptor.cursors then
        for cursorName, cursor in pairs(typeDescriptor.cursors) do
            cursorStorage[cursorName] = cursor
        end
    end
end

-- classes

--#region Canvas class

---UI objects meta-parent, UI state can be manipulated through this object. Meant to be singleton
---@class CanvasObject : CompositeObject
local CanvasObject = { parent = true }
setmetatable(CanvasObject, {__index = composite.class})

--Volunteerly revoke focus from self and optionally give it to another object.
---@param origin ObjectUI
---@param successor ObjectUI?
function CanvasObject:revokeFocus(origin, successor)
    if focusedObject == origin then
        focusedObject:loseFocus()
        
        if successor and successor:isInteractible() then
            focusedObject = successor
            successor:gainFocus()
        end
    end
end

---Change current system cursor type
---@param origin ObjectUI
---@param type love.CursorType?
function CanvasObject:setCursor(origin, type)
    type = type or DEFAULT_CURSOR

    if type ~= currentCursor then
        currentCursor = type
        love.mouse.setCursor(cursorStorage[type])
    end
end

function CanvasObject:getTranslation()
	return 0, 0
end

function CanvasObject:resize(new_w, new_h)
	self.w = new_w
	self.h = new_h
end

local function newCanvas(protoype)
	protoype = protoype or {}

	protoype.x = protoype.x or 0
	protoype.y = protoype.y or 0

	local width = protoype.w or love.graphics.getWidth()
	local height = protoype.h or love.graphics.getHeight()
	protoype.layout = {
		w = width,
		h = height,
		padding = protoype.padding or CANVAS_DEFAULT_PADDING,

		growth = protoype.growth or "vertical",
		gap = protoype.gap or CANVAS_DEFAULT_GAP,
		horizontal = protoype.horizontal or "center",
		vertical = protoype.vertical or "center"
	}

	local obj = composite.new(protoype)

	setmetatable(obj, {__index = CanvasObject})

	obj:autolayout()

	return obj
end

--#endregion

-- stellar fnc

--#region Canvas manipulation

function stellar.createCanvas(prototype)
	return newCanvas(prototype)
end

function stellar.getCanvas()
	return current_canvas
end

function stellar.setCanvas(canvas)
	if type(canvas) == "table" then
		current_canvas = canvas
	else
		current_canvas = canvases[canvas]
	end
end

function stellar.storeCanvas(name, canvas)
	canvases[name] = canvas
end

--#endregion

--#region Current canvas operations

function stellar.add(object)
	current_canvas:add(object)
end

function stellar.remove(object)
	current_canvas:remove(object)
end

--#endregion

function stellar.loadExternalObjects(path)
    local path = path or externalTypesDir

    local path_info = love.filesystem.getInfo(path)

    if not path_info then
        print(string.format("Failed loading object from %s. Path does not exist", path))
        return
    end

    if path_info.type == "file" then
        local objectFileChunk = love.filesystem.load(path)

        if not objectFileChunk then
            print(string.format("Failed loading object from %s. Compilation failed", path))
            return
        end

        local descriptor = objectFileChunk()

        if type(descriptor) ~= "table" or not descriptor.name then
            print(string.format("Failed loading object from %s. Bad returning or table is not an object descriptor", path))
            return
        end

        registerType(descriptor)

        print(string.format("Loaded object %s from %s, aliases: %s", descriptor.name, path, table.concat(descriptor.aliases or {}, ", ")))

        return true
    end

    local items = love.filesystem.getDirectoryItems(path)

    for _, item in ipairs(items) do
        print(string.format("Loading object from %s", path .. "/" .. item))
        stellar.loadExternalObjects(path .. "/" .. item)
    end
end

--#region Debug functions

function stellar.drawMousePosition()
    love.graphics.setColor(
        love.mouse.isDown(1) and {0.3, 0.3, 1, 1} or 
        love.mouse.isDown(2) and {1, 0.3, 0.3, 1} or 
        love.mouse.isDown(3) and {0.3, 1, 0.3, 1} or
        love.mouse.isDown(4, 5, 6) and {1, 1, 0, 1} or
        {1, 1, 1, 1}
    )

    local text = love.mouse.getX() .. "; " .. love.mouse.getY()

    if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
        text = text .. " <SHIFT>"
    end

	if currentHl then
		text = "UI object" .. "\n" .. text
	end

    love.graphics.print(text, love.mouse.getX(), love.mouse.getY() - love.graphics.getFont():getHeight())
    love.graphics.print(text, 0, 0)
end

--#endregion

--- Stellar hook

function stellar.hook(force)
    if hooked and not force then
        return stellar
    end

    --- Set up utf.sub if such is not provided

    if not utf.sub then
        utf.sub = utf_sub
    end

    --- Set up callbacks
    
    local love_update, love_draw, love_mousepressed, love_mousereleased, love_keypressed, love_keyreleased, love_textinput, love_resize = love.update or nopFunc, love.draw or nopFunc, love.mousepressed or nopFunc, love.mousereleased or nopFunc, love.keypressed or nopFunc, love.keyreleased or nopFunc, love.textinput or nopFunc, love.resize or nopFunc

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
            if currentHl:isInteractible() then
                heldObject[but] = currentHl

                if focusedObject ~= currentHl then
                    if focusedObject then
                        focusedObject:loseFocus()
                    end

                    focusedObject = currentHl
                    focusedObject:gainFocus()
                end

				local cx, cy = currentHl:convertGlobalCoords(x, y)

                -- Double click shenanigans
                if
                    love.timer.getTime() - lastClickTime <= doubleClickTime and 
                    but == lastClickButton and
                    lastClickedObject == currentHl and
                    x == lastClickPosition[1] and y == lastClickPosition[2]
                then
                    currentHl:doubleClick(cx, cy, but)
                    lastClickTime = 0 -- avoid counting possible third click as double click
                    return
                end

				currentHl:click(cx, cy, but)

                lastClickButton, lastClickTime, lastClickPosition[1], lastClickPosition[2], lastClickedObject = but, love.timer.getTime(), x, y, currentHl
            end
        else
            if focusedObject then
                focusedObject:loseFocus()
                focusedObject = nil
            end

            love_mousepressed(x, y, but)
        end
    end

    love.mousereleased = function (x, y, but)
        if heldObject[but] then
			local cx, cy = heldObject[but]:convertGlobalCoords(x, y)

            if heldObject[but]:isInteractible() then
                if not heldObject[but]:clickRelease(cx, cy, but) then
                    heldObject[but] = nil
                    return
                end
            end

            if currentHl and (heldObject[but] ~= currentHl) and currentHl:isInteractible() then
				local cx, cy = currentHl:convertGlobalCoords(x, y)
                currentHl:clickReleaseExterior(cx, cy, but, heldObject[but])

                heldObject[but] = nil
                return
            end
        else
            love_mousereleased(x, y, but)
        end
    end

    love.keypressed = function (key, scancode, isrepeat)
        if focusedObject and focusedObject:isInteractible() then
            if focusedObject:keyPress(
                key,
                love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl"),
                love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift"),
                love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"),
                scancode,
                isrepeat
            ) then
                focusedObject:loseFocus()
                focusedObject = nil
            end
        else
            love_keypressed(key, scancode, isrepeat)
        end
    end

    love.keyreleased = function (key, scancode, isrepeat)
        if focusedObject and focusedObject:isInteractible() then
            if focusedObject:keyRelease(
                key,
                love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl"),
                love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift"),
                love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"),
                scancode,
                isrepeat
            ) then
                focusedObject:loseFocus()
                focusedObject = nil
            end
        else
            love_keyreleased(key, scancode, isrepeat)
        end
    end

    love.textinput = function (text)
        if focusedObject and focusedObject:isInteractible() then
            focusedObject:textinput(text)
        else
            love_textinput(text)
        end
    end

	love.resize = function (w, h)
		for _, canvas in pairs(canvases) do
			canvas.layout.w, canvas.layout.h = w, h
			canvas:autolayout()
		end

		love_resize(w, h)
	end

    hooked = true

	local new_canvas = stellar.createCanvas()
	stellar.storeCanvas(1, new_canvas)
	stellar.setCanvas(1)

    return stellar
end

return stellar