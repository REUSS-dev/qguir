-- StellarGUI 2 - classes/FontStorage.lua

-- config

local AUTO_CREATE_DEFAULT = true
local DEFAULT_NAME = "default"

local DEFAULT_FILE_CACHING = false

---@class FontStorage
---@field cachingEnabled boolean
---@field cache table<string, table<number, love.Font>>
---@field sources table<string, string|love.FileData>
local FontStorage = {}
FontStorage.__index = FontStorage

---Registers font source into a database
---@param name string
---@param source string|love.FileData
---@return FontStorage self
function FontStorage:registerFont(name, source)
	assert(type(name) == "string", "bad argument #1 to 'FontStorage:registerFont()' (string expected, got " .. type(name) .. ")")

	local source_type = type(source) ~= "userdata" and type(source) or (source.type and source--[[@as love.Font]]:type() or "userdata")
	assert(source_type == "string" or source_type == "FileData", "bad argument #2 to 'FontStorage:registerFont()' (string or FileData expected, got " .. source_type .. ")")

	if source_type == "FileData" then
		self.cache[name] = {}
		self.sources[name] = source
		return self
	end ---@cast source string

	assert(love.filesystem.getInfo(source), "FontStorage: File " .. source .. " does not exist.")

	self.cache[name] = {}

	if self.cachingEnabled then
		self.sources[name] = love.filesystem.newFileData(source)
		return self
	end

	self.sources[name] = source

	return self
end

---Get sourced font of desired size
---@param name string
---@param size number
---@return love.Font
function FontStorage:getFont(name, size)
	assert(type(name) == "string", "bad argument #1 to 'FontStorage:getFont()' (string expected, got " .. type(name) .. ")")
	assert(type(size) == "number", "bad argument #2 to 'FontStorage:getFont()' (number expected, got " .. type(size) .. ")")
	assert(self.cache[name], "FontStorage: No source for font \"" .. name .. "\" in storage instance")

	size = math.floor(size)

	if not self.cache[name][size] then
		self:generateFont(name, size)
	end

	return self.cache[name][size]
end

---@private
function FontStorage:generateFont(name, size)
	if not self.sources[name] then
		self.cache[name] = love.graphics.newFont(size)
		return
	end

	---@diagnostic disable-next-line: param-type-mismatch
	self.cache[name][size] = love.graphics.newFont(self.sources[name], size)
end

function FontStorage:parseFontIdentifier(str)
	assert(type(str) == "string", "bad argument #1 to 'FontStorage:parseFontIdentifier()' (string expected, got " .. type(str) .. ")")

	local name, size = string.match(str, "^(.+)[%-;/\\@#$%:^&*'| \t](%d+%.?%d*)$")

	assert(name, "FontStorage: Could not parse font identifier \"" .. str .. "\"")

	size = tonumber(size)

	return name, size
end

function FontStorage:createDefault()
	self.sources[DEFAULT_NAME] = nil
	self.cache = {}
end

---Returns current file caching flag state
---@return boolean
function FontStorage:getFileCaching()
	return self.cachingEnabled
end

---Sets if font file caching should be used during font registration
---@param new_flag boolean
---@return FontStorage self
function FontStorage:setFileCaching(new_flag)
	self.cachingEnabled = new_flag

	return self
end

function FontStorage:new()
	local new_storage = {
		sources = {},
		cache = {},

		cachingEnabled = DEFAULT_FILE_CACHING
	}
	setmetatable(new_storage, FontStorage) ---@cast new_storage FontStorage

	if AUTO_CREATE_DEFAULT then
		new_storage:createDefault()
	end

	return new_storage
end

setmetatable(FontStorage, { __call = FontStorage.new })

return FontStorage