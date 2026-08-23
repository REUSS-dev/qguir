-- StellarGUI 2 - classes/LocaleStorage.lua

local ffi = require("ffi")

-- docs

---@alias LocalizedString (string|PatternModifer)[]
---@alias PatternModifer {var: string|integer, modifier: string?, [string]: string|integer|true}

-- cfg

local LOCALE_DEFAULT = "en"

-- plural rules
-- https://www.unicode.org/cldr/charts/48/supplemental/language_plural_rules.html

---@enum PluralCategory
local PluralCategory = {
    ZERO = "zero",
    ONE = "one",
    FEW = "few",
    MANY = "many",
    OTHER = "other",
}

---@type table<string, {cardinal: fun(number: number): PluralCategory}>
local plural = {
    en = {
        cardinal = function(number)
            number = math.abs(number)

            if number == 1 then
                return PluralCategory.ONE
            end

            return PluralCategory.OTHER
        end
    },
    ru = {
        cardinal = function(number)
            number = math.abs(number)

            if number ~= math.floor(number) then
                return PluralCategory.OTHER
            end

            local div10 = number % 10
            local div100 = number % 100

            if div10 == 1 and div100 ~= 11 then
                return PluralCategory.ONE
            end

            if (div10 <= 4 and div10 >= 2) and (div100 > 14 or div100 < 12) then
                return PluralCategory.FEW
            end

            if div10 == 0 then
                return PluralCategory.MANY
            end

            if 5 <= div10 and div10 <= 9 then
                return PluralCategory.MANY
            end

            if 11 <= div100 and div100 <= 14 then
                return PluralCategory.MANY
            end

            return PluralCategory.OTHER
        end
    }
}

---@type (fun(self: LocaleStorage, modifier: PatternModifer, vars: any[]|table<string, any>, str: LocalizedString): string)[]
local modifiers = {
    plural = function (self, modifier, vars, str)
        if vars[modifier.var] == 0 and modifier.params[PluralCategory.ZERO] then
            return modifier.params[PluralCategory.ZERO]
        end

        return modifier.params[plural[self.currentLanguage].cardinal(vars[modifier.var] or -1)] or modifier.params[PluralCategory.OTHER] or "nil"
    end
}

---@class LocaleStorage
---@field localesDir string? Path to a directory with locale files. May be nil
---@field availableLocales string[] An array of available locales in `locales_dir`. May be empty.
---@field currentLanguage string? Currently set locale language. May be nil
---@field currentLocale string? Currently set locale code. May be nil
---@field text table<string, string|table> Locale table with locale paths as keys and locale strings as values. May be empty
local LocaleStorage = {}
LocaleStorage.__index = LocaleStorage

function LocaleStorage:format(key, variables)
    local str = self:get(key)
    local typ = type(str)

    if typ ~= "string" and typ ~= "table" then
        return str
    end

    if typ == "string" then
        return str
    end

    local total = ""

    for _, part in ipairs(str) do
        if type(part) == "string" then
            total = total .. part
        elseif not part.modifier then
            total = total .. tostring(variables[part.var or 0])
        else
            total = total .. (modifiers[part.modifier](self, part, variables, str) or "nil")
        end
    end

    return total
end

function LocaleStorage:get(key)
    local str = self.text[key]

    if not str then
        return key
    end

    return str
end

function LocaleStorage:rawget(key)
    return self.text[key]
end

---@param new_path string
function LocaleStorage:setLocalePath(new_path)
    assert(type(new_path) == "string", "bad argument #1 to 'LocaleStorage:setLocalePath()' (string expected, got " .. type(new_path) .. ")")

    local path_info = love.filesystem.getInfo(new_path)

    if not path_info then
        print(string.format("Failed to set locale path as %s. Path does not exist", new_path))
        return
    end

    if path_info.type ~= "directory" then
        print(string.format("Failed to set locale path as %s. Path is not a directory", new_path))
        return
    end

    self.localesDir = new_path
    local locales, languages = {}, {}

    local items = love.filesystem.getDirectoryItems(new_path)

    for _, locale in ipairs(items) do
        local language, country = string.match(locale, "^_?(%l+)[_-]?([%u%d]*)%.lua$")

        if language then
            local locale_code = #country > 0 and (language .. "_" .. country) or language

            locales[locale_code] = locale

            if not locales[language] then
                languages[language] = languages[language] or {}
                languages[language][#languages[language]+1] = locale
            end
        end
    end

    for language, language_locales in pairs(languages) do
        if not locales[language] then
            if #language_locales ~= 1 then
                table.sort(language_locales)
            end

            locales[language] = language_locales[1]
        end
    end

    self.availableLocales = locales
end

---@param new_locale string?
function LocaleStorage:setLocale(new_locale)
    assert(self.localesDir, "Set locale dir before setting a locale!")

    new_locale = new_locale or LOCALE_DEFAULT
    local locale_code, language = self:formatLocaleCode(new_locale)

    assert(locale_code, "Invalid locale code: " .. new_locale)

    if self.currentLocale == locale_code then
        return
    end

    if self.availableLocales[locale_code] then
        self.currentLocale = locale_code
        self.currentLanguage = language
        return self:installLocale()
    end

    if self.availableLocales[language] then
        print("Failed to set locale \"" .. locale_code .. "\". Falling back to " .. language)
        return self:setLocale(language)
    end

    if new_locale ~= LOCALE_DEFAULT then
        print("Failed to set locale \"" .. locale_code .. "\". Falling back to default locale " .. LOCALE_DEFAULT)
        return self:setLocale(LOCALE_DEFAULT)
    end
end

function LocaleStorage:installLocale()
    local cur_locale = self.currentLocale
    assert(cur_locale, "Cannot install locale, locale is not set")

    self.text = {}
    local cascade = self:loadLocale(cur_locale)

    while cascade.extends do
        local parent = self:loadLocale(cascade.extends)

        if cascade == parent then
            error("Locale " .. cascade.extends .. " extends itself. Inherit loop")
        end

        cascade = parent
    end
end

---@param name string
---@return {extends: string?, text: table}
function LocaleStorage:loadLocale(name)
    assert(type(name) == "string", "bad argument #1 to 'LocaleStorage:loadLocale()' (string expected, got " .. type(name) .. ")")

    local fullpath = self.localesDir .. "/" .. self.availableLocales[name]
    local info = love.filesystem.getInfo(fullpath)
    assert(type(info) == "table", "Unable to find locale files for locale " .. name)
    assert(info.type ~= "directory", "Unable to load locale " .. name .. ". " .. fullpath .. " is a directory.")

    local chunk, err = loadfile(fullpath)
    assert(chunk, "Unable to load locale " .. name .. ". " .. fullpath .. " is not a valid lua chunk. " .. (err or ""))

    local result, ret = pcall(chunk)
    assert(result, "Unable to load locale " .. name .. ". " .. fullpath .. " contains errors. " .. tostring(ret))
    assert(ret, "Unable to load locale " .. name .. ". " .. fullpath .. " does not return locale table.")
    assert(type(ret.text) == "table", "Unable to load locale " .. name .. ". " .. fullpath .. " does not contain strings. Please return table { text = your_strings_table }")

    self:indexLocale(ret)

    return ret
end

---@param locale {text: table, extends: string?}
function LocaleStorage:indexLocale(locale)
    self:indexLocaleRecursive(locale.text, nil)

    return locale
end

---@param tbl table
---@param path string?
function LocaleStorage:indexLocaleRecursive(tbl, path)
    for key, value in pairs(tbl) do
        local index = path and (path .. "." .. key) or key
        local value_type = type(value)

        if value_type == "table" then
            self:indexLocaleRecursive(value, index)
        elseif not self.text[index] then
            self.text[index] = self:processString(value)
        end
    end
end

function LocaleStorage:processString(val)
    if type(val) ~= "string" then
        return val
    end

    local fstring = {fstring = true}

    local ptr = ffi.cast("const uint8_t*", val)
    local copy_beg = 1
    local pos = 0
    local length = #val

    local ignore_next
    local var, modifier
    local params = {}

    while pos < length do
        if ignore_next then
            ignore_next = false
        else
            local ch = string.char(ptr[pos])

            if modifier then
                if ch == "}" then
                    fstring[#fstring+1] = {var = var, modifier = modifier, params = params}

                    var = nil
                    modifier = nil
                    params = {}
                    copy_beg = pos + 1 + 1
                elseif string.match(ch, "[%w_\128-\255]") then
                    local _, f, param = string.find(val, "^([%w_\128-\255]+)%s*", pos + 1)

                    local eqf
                    _, eqf = string.find(val, "^=%s*", f + 1)
                    if eqf then
                        local num
                        _, f, num = string.find(val, "^(%-?%d*%.?%d*)%s*", eqf + 1)

                        if num and tonumber(num) then
                            params[param] = tonumber(num)
                        elseif string.sub(val, eqf + 1, eqf + 1) == "'" then
                            f = eqf + 1
                            copy_beg = f + 1
                            local str = ""

                            local marker
                            repeat
                                _, f, marker = string.find(val, "([%%'])", f + 1)

                                if marker == "%" then
                                    if string.sub(val, f + 1, f + 1) == "'" then
                                        str = str .. string.sub(val, copy_beg, f - #marker) .. "'"
                                        f = f + 2
                                        copy_beg = f
                                    end
                                end

                                if not marker then
                                    print("LocaleStorage: bad pattern modifier in string " .. val .. " locale " .. self.currentLocale .. " (or its parents)")

                                    if copy_beg == 1 then
                                        return val
                                    else
                                        fstring[#fstring+1] = string.sub(copy_beg, -1)
                                        return fstring
                                    end
                                end
                            until marker == "'"

                            str = str .. string.sub(val, copy_beg, f - #marker)

                            params[param] = str
                        else
                            print("LocaleStorage: bad pattern modifier in string " .. val .. " locale " .. self.currentLocale .. " (or its parents)")

                            if copy_beg == 1 then
                                return val
                            else
                                fstring[#fstring+1] = string.sub(copy_beg, -1)
                                return fstring
                            end
                        end
                    else
                        params[param] = true
                    end

                    pos = f - 1 --[[@as integer]]
                elseif not string.match(ch, "[%s,;]") then
                    print("LocaleStorage: bad pattern in string " .. val .. " locale " .. self.currentLocale .. " (or its parents)")

                    if copy_beg == 1 then
                        return val
                    else
                        fstring[#fstring+1] = string.sub(copy_beg, -1)
                        return fstring
                    end
                end
            elseif var then
                if ch == "}" then
                    fstring[#fstring+1] = {var = var}

                    var = nil
                    copy_beg = pos + 1 + 1
                elseif ch == ":" then
                    local _, f
                    _, f, modifier = string.find(val, "^%s*([%w_]+)", pos + 1 + 1)

                    if not modifier or not modifiers[modifier] then
                        if not modifier then
                            print("LocaleStorage: bad pattern modifier in string " .. val .. " locale " .. self.currentLocale .. " (or its parents)")
                        else
                            print("LocaleStorage: unknown pattern modifier in string " .. val .. " locale " .. self.currentLocale .. " (or its parents)")
                        end

                        if copy_beg == 1 then
                            return val
                        else
                            fstring[#fstring+1] = string.sub(copy_beg, -1)
                            return fstring
                        end
                    end

                    params = {}

                    pos = f - 1 --[[@as integer]]
                elseif not string.match(ch, "%s") then
                    print("LocaleStorage: bad pattern in string " .. val .. " locale " .. self.currentLocale .. " (or its parents)")

                    if copy_beg == 1 then
                        return val
                    else
                        fstring[#fstring+1] = string.sub(copy_beg, -1)
                        return fstring
                    end
                end
            elseif ch == "%" then
                ignore_next = true
            elseif ch == "{" then
                if copy_beg ~= pos + 1 then
                    fstring[#fstring+1] = string.sub(val, copy_beg, pos)
                end

                local _, f
                _, f, var = string.find(val, "^%s*([%w_]+)", pos + 1 + 1)
                var = tonumber(var) or var

                if not var then
                    print("LocaleStorage: bad pattern in string " .. val .. " locale " .. self.currentLocale .. " (or its parents)")

                    if copy_beg == 1 then
                        return val
                    else
                        fstring[#fstring+1] = string.sub(copy_beg, -1)
                        return fstring
                    end
                end

                pos = f - 1 --[[@as integer]]
            end
        end

        pos = pos + 1
    end

    if copy_beg == 1 then
        return val
    end

    if copy_beg > #val then
        return fstring
    end

    fstring[#fstring+1] = string.sub(val, copy_beg, -1)

    return fstring
end

---@param code string
---@return string?
---@return string?
function LocaleStorage:formatLocaleCode(code)
    assert(type(code) == "string", "bad argument #1 to 'LocaleStorage:formatLocaleCode()' (string expected, got " .. type(code) .. ")")
    local language, country = string.match(code, "^(%l+)[_-]?([%u%d]*)$")

    if not language then
        return nil
    end

    if #country == 0 then
        return language, language
    end

    return string.format("%s_%s", language, country), language
end

function LocaleStorage:new()
	local new_storage = {
        localesDir = nil,
        availableLocales = {},

		currentLocale = nil,
        currentLanguage = nil,
        text = {},
	}
	setmetatable(new_storage, LocaleStorage) ---@cast new_storage LocaleStorage

	return new_storage
end

setmetatable(LocaleStorage, { __call = LocaleStorage.new })

return LocaleStorage