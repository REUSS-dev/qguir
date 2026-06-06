-- StellarGUI 2 - scripts/parse.lua
local parse = {}

local Palette = require("classes.Palette")

-- docs

---@alias ObjectDefinition table Table, which contains UI object definition fields, and is to be processed by UI object definition Parser
---@alias ObjectParser fun(definition: ObjectDefinition, sink: ObjectPrototype):boolean A function, that processes UI object definition and outputs prepared parameters into sink. If it fails to process given definition, it will return false.
---@alias ObjectParserName string
---@alias ObjectParsingRule ObjectParserName|function|{[1]: ObjectParserName, [2]: ObjectDefinition}|{[1]: string[], [2]: string, [3]: ObjectDefinition, [4]: ObjectParserName[]?}
---@alias ObjectPrototype table Table, which contains valid object keys and parameters. Usually returned from parseDefinition

-- consts



-- init

local collection = {}	---@type {[string]: ObjectParser} Collection of parsers for UI objects parameters

--#region Inbuilt parsers

---@type ObjectParser
function collection.layout(def, sink)
	local layout = sink.layout or {}

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
				padding = {padding[1], padding[2], padding[1], padding[2]}
			elseif #padding == 3 then
				padding = {padding[1], padding[2], padding[1], padding[3]}
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

	if layout.ignore == nil then
		if def.ignoreLayout ~= nil then
			layout.ignore = def.ignoreLayout
		elseif def.ignore_layout ~= nil then
			layout.ignore = def.ignore_layout
		elseif def.static ~= nil then
			layout.ignore = def.static
		end
	end
	
	sink.layout = layout

	if 	not width or
		not height or
		not padding or
		not layout.growth or		---@todo maybe drop growth & gap layout properties for common objects (not CompositeObject children)?
		not layout.horizontal or
		not layout.vertical or
		not layout.gap
	then
		return false
	end

    return true
end

function collection.palette(def, sink)
	local def_palette = def.palette or def.palete or def.colors

	if not sink.palette then
		if def_palette then
			if type(def_palette) == "table" and def_palette.container then
				sink.palette = def_palette
			else
				sink.palette = Palette(def_palette)
			end

			return true
		end

		sink.palette = Palette()
	end

	def_palette = def_palette or {}

    local color = def.color or def.mainColor or def.colorMain or def.main_color or def_palette.main
    local text = def.textColor or def.colorText or def.text_color or def_palette.text
    local alt = def.frameColor or def.colorFrame or def.additionalColor or def.colorAdditional or def.bgColor or def.hlColor or def_palette.border

	if not sink.palette[1] then
		sink.palette:setColor(1, color)
	end
	if not sink.palette[2] then
		sink.palette:setColor(2, text)
	end
	if not sink.palette[3] then
		sink.palette:setColor(3, alt)
	end

    if sink.palette[1] and sink.palette[2] and sink.palette[3] then
        return true
    end

    return false
end

--#endregion

-- Parse fnc

function parse.registerParser(name, parser_fnc)
	collection[name] = parser_fnc
end

---Parse provided definition into object prototype
---@param definition ObjectDefinition
---@param sink ObjectUI
---@return ObjectPrototype
function parse.resolve(definition, sink)
    for _, parser in ipairs(definition.rules) do
		local success, default_index = false, 0

        if type(parser) == "string" then
			while not success and (default_index <= #definition.defaults) do
				success = collection[parser](definition.defaults[default_index], sink)
				default_index = default_index + 1
			end
        elseif type(parser) == "function" then
			while not success and (default_index <= #definition.defaults) do
				success = parser(definition.defaults[default_index], sink)
				default_index = default_index + 1
			end
        elseif type(parser) == "table" then
			while not success and (default_index <= #definition.defaults) do
				local possibleInputNames, outputName = parser[1], parser[2]

				for _, name in ipairs(possibleInputNames) do
                    if definition.defaults[default_index][name] ~= nil then
                        sink[outputName] = definition.defaults[default_index][name]
						success = true
                        break
                    end
                end

				default_index = default_index + 1
			end
        end
    end

    return sink
end

return parse