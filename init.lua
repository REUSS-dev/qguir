-- stellar
local stellar = {}

local selfpath = (...):match("^(.*%.?[^.]+)$"):gsub("%.", "/")
love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";" .. love.filesystem.getRequirePath():gsub("(%?%.lua)", selfpath .. "/%1"))

package.loaded["stellargui"] = stellar

local utf = require("utf8")

local parse = require("scripts.parse")

-- documentation

---@meta

---@alias pixels number Amount of pixels.

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

-- vars

local currentCursor = DEFAULT_CURSOR ---@type love.CursorType
local doubleClickTime = DEFAULT_DOUBLE_CLICK_TIME


local object_descriptors = {}       ---@type table<string, ObjectUI>
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
    __index = function (_, key)
        if object_descriptors[key] then
            return object_descriptors[key]
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
---@param dt number
local function stellar_update(dt)
    local x, y = love.mouse.getX(), love.mouse.getY()

	local hlObject = current_canvas:isActive() and current_canvas:checkHover(x, y) or nil

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

---Register UI object type descriptor
---@param typeDescriptor ObjectUI
local function registerType(typeDescriptor)
    if object_descriptors[typeDescriptor.name] then
		print("Object " .. typeDescriptor.name .. " is already registered within system, skipping.")
		return
	end

	object_descriptors[typeDescriptor.name] = typeDescriptor

	typeDescriptor.aliases = typeDescriptor.aliases or typeDescriptor.alias or {}
	if type(typeDescriptor.aliases) == "string" then
		typeDescriptor.aliases = {typeDescriptor.aliases}
	end

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

local function stellar_construct(self, definition)
	definition = definition or {}

	definition.defaults = definition.defaults or {[0] = definition}
	if self.default then
		definition.defaults[#definition.defaults+1] = self.default
	end

	local new_object

	if self.extends then
		new_object = object_descriptors[self.extends](definition)
	else
		new_object = {}
	end

	definition.rules = self.rules

	setmetatable(new_object, nil)
	parse.resolve(definition, new_object)

	setmetatable(new_object, self)
	self.new(new_object)

	return new_object
end

-- stellar fnc

--#region Canvas manipulation

function stellar.createCanvas(prototype)
	return stellar.Canvas(prototype)
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

function stellar.activate_object(obj)
	if obj.__index then
		return
	end

	assert(obj.name, "Name is required for an unknown UI object that inherits " .. (obj.extends or "no one"))

	obj.__index = obj

	obj.new = obj.new or function()end

	if obj.extends == nil then
		obj.extends = object_descriptors.ObjectUI.name
	end

	-- Generailze rules
	obj.rules = obj.rules or {}

	for _, rule in ipairs(obj.rules) do
		if type(rule) == "table" then
			if type(rule[1]) == "string" then
				rule[1] = {rule[1]}
			end

			if not rule[2] then
				rule[2] = rule[1]
			end
		end
	end

	if obj.extends then
		local parent = object_descriptors[obj.extends]

		assert(parent, "There is no such object class as \"" .. tostring(obj.extends) .. "\" to register as a parent of " .. obj.name)

		parent.__call = stellar_construct

		setmetatable(obj, parent)
		obj[obj.extends] = parent
	else
		setmetatable(obj, {__call = stellar_construct})
	end
end

---Loads object(s) from a specified path
---@param path string?
---@param skip_init boolean? Skip ObjectUI:stellar_activate() call. This flag is used internally.
---@return ObjectUI[]
function stellar.loadExternalObjects(path, skip_init)
    path = path or externalTypesDir

    local path_info = love.filesystem.getInfo(path)

    if not path_info then
        print(string.format("Failed loading object from %s. Path does not exist", path))
        return {}
    end

    if path_info.type == "file" then
        local objectFileChunk = love.filesystem.load(path)

        if not objectFileChunk then
            print(string.format("Failed loading object from %s. Compilation failed", path))
            return {}
        end

        local descriptor = objectFileChunk()

        if type(descriptor) ~= "table" or not descriptor.name then
            print(string.format("Failed loading object from %s. Bad returning or table is not an object descriptor", path))
            return {}
        end

        registerType(descriptor)

        print(string.format("Loaded object %s from %s, aliases: %s", descriptor.name, path, table.concat(descriptor.aliases or {}, ", ")))

        if not skip_init then
			stellar.activate_object(descriptor)
		end

		return {descriptor}
    end

    local items = love.filesystem.getDirectoryItems(path)
	local toactivate = {} ---@type ObjectUI[]

    for _, item in ipairs(items) do
        print(string.format("Loading object from %s", path .. "/" .. item))
        local loaded_objects = stellar.loadExternalObjects(path .. "/" .. item, true)

		for _, object in ipairs(loaded_objects) do
			toactivate[#toactivate+1] = object
		end
    end

	if not skip_init then
		for _, object in ipairs(toactivate) do
			stellar.activate_object(object)
		end
	end

	return toactivate
end

function stellar.getObjectDescriptor(descriptor_name)
	return object_descriptors[descriptor_name]
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
		text = currentHl.name .. "\n" .. text
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
    
    local love_update, love_draw, love_mousepressed, love_mousereleased, love_keypressed, love_keyreleased, love_textinput, love_resize, love_wheelmoved = love.update or nopFunc, love.draw or nopFunc, love.mousepressed or nopFunc, love.mousereleased or nopFunc, love.keypressed or nopFunc, love.keyreleased or nopFunc, love.textinput or nopFunc, love.resize or nopFunc, love.wheelmoved or nopFunc

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

	love.wheelmoved = function (x, y)
		if currentHl then
            if currentHl:isInteractible() then
				currentHl:wheel(x, y)
			end
		end
	end

	stellar.loadExternalObjects(selfpath .. "/classes/primitives")

	local new_canvas = stellar.createCanvas()
	stellar.storeCanvas(1, new_canvas)
	stellar.setCanvas(1)

	hooked = true

    return stellar
end

return stellar