-- palette
local palette = {}



-- documentation

---@alias ColorIndex number Number that colors inside the palette are indexed by. Agreement: 1 - main color, 2 - text color, 3 - additional color
---@alias ColorValue number<0,1> Amount of color in a channel. number<0, 1> for LOVE 11 and higher, number<0, 255> for LOVE 0.10 and lower.
---@alias ColorTable {[1]: ColorValue, [2]: ColorValue, [3]: ColorValue, [4]: ColorValue} Table, containing RGBA color.

-- config

---@enum ColorNames
local colorNames = {
    ---@see ColorIndex 1 - Main color
    1,
    color = 1,
    fg = 1,
    foreground = 1,
    main = 1,

    ---@see ColorIndex 2 - Text color
    2,
    text = 2,

    ---@see ColorIndex 3 - Additional color
    3,
    additional = 3,
    background = 3,
    bg = 3,
    frame = 3,
    hl = 3,
}

-- consts



-- vars



-- init



-- fnc



-- classes

---@class Palette
---@field container {[ColorIndex]: ColorTable}
local Palette = {}
local Palette_meta = {}

function Palette_meta:__index(key)
    local colorindex = colorNames[key]

    if colorindex then
        return self.container[colorindex] or self.container[1]
    else
        return Palette[key]
    end
end

---Get color table by color index
---@param index ColorIndex
---@return ColorTable
function Palette:getColorByIndex(index)
    return self.container[index]
end

---Set a color in the palette by index or name
---@param index_or_name ColorNames|ColorIndex
---@param color ColorTable
function Palette:setColor(index_or_name, color)
    if type(index_or_name) == "string" then
        self.container[colorNames[index_or_name]] = color
    else
        self.container[index_or_name] = color
    end
end

-- palette fnc

---Create new palette from an array of color tables
---@param colors ColorTable|table<number|ColorNames, ColorTable>?
---@return Palette PaletteObject
function palette.new(colors)
    local obj = {
        container = {}
    }

    setmetatable(obj, Palette_meta) ---@cast obj Palette

    if not colors then
        return obj
    end

    if type(colors[1]) == "number" then ---@diagnostic disable-next-line: assign-type-mismatch
        obj.container[1] = colors
        return obj
    end

    for key, color in pairs(colors) do
        if type(key) == "number" then
            obj.container[key] = color
        elseif type(key) == "string" then
            if colorNames[key] then
                obj.container[colorNames[key]] = color
            end
        end
    end

    return obj
end

return palette