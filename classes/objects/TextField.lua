-- textfield
local textfield = {}

local uiobj = require("classes.ObjectUI")

local utf = require("utf8")

-- documentation

---@alias TextFieldCharLine {[1]: integer, [2]: integer} 1 - char, 2 - line

---@alias TextFieldDisplayTable {caretteX: integer, beginLine: integer, lastLine: integer, lineYOffset: integer}
---@alias TextFieldCaretteParameters {line: integer, char: integer, nominalChar: integer}
---@alias TextFieldScrollParameters {[1]: integer, [2]: integer} 1 - horizontal, 2 - vertical
---@alias TextFieldSelectionParameters {sel1: {[1]: integer, [2]: integer}, sel2: {[1]: integer, [2]: integer}, exists: boolean, active: boolean}

-- config

textfield.name = "TextField"
textfield.aliases = {}
textfield.rules = {
    {"sizeRectangular", {0, 0, 100, 50}},
    {"position", {position = {"center", "center"}}},

    {"palette", {colors = {{1, 1, 1, 1}, {0, 0, 0, 1}, {0.5, 0.5, 0.5, 1}, {0.2, 0.2, 0.6, 0.8}}}},

    {{"action", "enter", "return"}, "action", function() end},
    {{"text"}, "text", ""},
    {{"placeholder", "default", "defaultText"}, "placeholder", ""},
    {{"font"}, "font", love.graphics.getFont()},
    {{"oneline", "forceOneline", "force_oneline"}, "oneline", nil},
    {{"r", "radius", "rounding", "round"}, "r", nil},
    {{"password"}, "password", false}
}

-- consts

local TEXT_OFFSET_LEFT = 5
local TEXT_OFFSET_TOP = 5

local TEXT_CARETTE_BLINK_PERIOD = 0.5

local PROTECT_NEWLINE_SYMBOL = "\x0C"

local PASSWORD_CHAR = "*"

-- vars



-- init



-- fnc

local function utf_len_exclude_newline(str)
    local length = utf.len(str)

    if str:sub(-1, -1) == "\n" then
        return length - 1
    end

    return length
end

local function protectNewline(textOrTable)
    if type(textOrTable) == "table" then
        for i = 1, #textOrTable do
            textOrTable[i] = protectNewline(textOrTable[i])
        end
    else
        return textOrTable:gsub("\r?\n", PROTECT_NEWLINE_SYMBOL .. "\n")
    end
end

local function convertNewlineMarker(textOrTable)
    if type(textOrTable) == "table" then
        for i = 1, #textOrTable do
            textOrTable[i] = convertNewlineMarker(textOrTable[i])
        end
    else
        return textOrTable:gsub(PROTECT_NEWLINE_SYMBOL, "\n")
    end
end

-- classes

---@class TextField : ObjectUI
---@field text string[]
---@field font love.Font
---@field action fun(self: TextField)
---@field stencil fun() 
---@field textX number X text offset from TextField origin
---@field textY number Y text offset from TextField origin
---@field textareaW number Width of actual text display area
---@field textareaH number Height of actual text display area
---@field private caretteVisibility boolean
---@field private caretteTimer number
---@field carettePosition TextFieldCaretteParameters Carette X and Y position (in characters, lines)
---@field scroll TextFieldScrollParameters Scroll horizontal and vertical values
---@field selection TextFieldSelectionParameters
---@field lineHeight number To be PRIVATED
---@field oneline boolean To be PRIVATED
---@field display TextFieldDisplayTable Display parameters and cache
---@field r number Radius of round corner
---@field password boolean Flag. If set to true, all displayed characters should be PASSWORD_CHAR
---@field placeholder string Placeholder text. Printed with Palette.additionalColor if no text is present
local TextField = { defaultCursor = "ibeam" }
local TextField_meta = {__index = TextField}

--#region text wrap & lines processing

function TextField:doWrap()
    local new_text = {}

    for i = 1, self:getLineCount() do
        -- Since LOVE 11.4 love.Font:getWrap() does not leave CR at the end of the line
        -- when wrapping CRLF newlines. This is very bad as now we do not currently have 
        -- an easy method of telling apart the CRLF wrap from the limit-reach wrap
        -- based on the resulting lines table. CR is a zero-width breaking symbol,
        -- that didn't mess up wrapping logic and was very convenient for that purpose.
        --
        -- Currently, we use a small, invisible symbol before every CRLF newline,
        -- that MESSES UP wrapping; behaviour of space-ending line and
        -- newline-ending line is different during wrapping. Very sad.
        local prepared_text = protectNewline(self.text[i])

        local _, wrapped = self.font:getWrap(prepared_text, self.textareaW - self.font:getWidth(" "))
    
        if #wrapped ~= 0 then
            for j = 1, #wrapped do
                new_text[#new_text+1] = convertNewlineMarker(wrapped[j])
            end
        else
            new_text[#new_text+1] = ""
        end
    end

    self.text = new_text
end

function TextField:updateWrap()
    -- Calcaulate and save carette absoute location (in characters)
    local carette_absolute_location = 0

    for i = 1, self.carettePosition.line - 1 do
        carette_absolute_location = carette_absolute_location + self:getLineLength(i)
    end

    carette_absolute_location = carette_absolute_location + self.carettePosition.char

    -- Recalculate wrap
    self:setText(self:getText())

    local last_line = self:getLineCount()

    -- Carette restore
    local restored = false

    for i = 1, last_line do
        local lineLength = self:getLineLength(i)

        if carette_absolute_location >= lineLength then
            carette_absolute_location = carette_absolute_location - lineLength
        else
            self:setCarette(carette_absolute_location, i)
            restored = true
            break
        end
    end

    if not restored then
        self:setCarette(self:getLineLength_woLF(last_line), last_line)
    end
    -- scroll check
    local ostatok = self.lineHeight - self.textareaH % self.lineHeight
    local scroll_very_bottom = self.lineHeight * (last_line - math.ceil(self.textareaH / self.lineHeight) - 1) + ostatok

    if scroll_very_bottom < self.scroll[2] then
        self:setScroll(nil, scroll_very_bottom)
    end
end

function TextField:getText()
    return table.concat(self.text)
end

function TextField:setText(text)
    self.text = {tostring(text)}

    self:doWrap()
    self:updateDisplay()
end

function TextField:getLineCount()
    return #self.text
end

function TextField:getLineLength(line_n)
    return utf.len(self.text[line_n])
end

function TextField:getLineLength_woLF(line_n)
    return utf_len_exclude_newline(self.text[line_n] or "")
end

function TextField:getLineDisplay(line_n)
    return self.text[line_n]
end

function TextField:getLineDisplay_password(line_n)
    if string.sub(self.text[line_n], -1, -1) ~= "\n" then
        return string.rep(PASSWORD_CHAR, self:getLineLength_woLF(line_n))
    else
        return string.rep(PASSWORD_CHAR, self:getLineLength_woLF(line_n)) .. "\n"
    end
end

--#endregion

--#region scroll

---Updates display parameters beginLine, lineLast, lineYOffset according to scroll
function TextField:updateDisplay()
    local display = self.display

    display.lineYOffset = self.scroll[2] % self.lineHeight

    display.beginLine = math.floor(self.scroll[2] / self.lineHeight) + 1

    local free_height = self.textareaH - self.lineHeight + display.lineYOffset
    display.lastLine = display.beginLine + math.ceil(free_height / self.lineHeight)

    -- normalize last line
    if display.lastLine > self:getLineCount() then
        display.lastLine = self:getLineCount()
    end
end

function TextField:setScroll(x, y)
    local scroll = self.scroll

    scroll[1] = x or scroll[1]
    scroll[2] = math.min( math.max( y or scroll[2] , 0) , self:getLineCount()*self.lineHeight) ---@todo Вычислять максимальный скролл здесь так же, как и в других функциях. реализовать максимальный скролл через setScroll(nil, math.huge)

    self:updateDisplay()
end

function TextField:translateClick(x, y)
    x = x - self.x + self.scroll[1] - self.textX
    y = y - self.y + self.display.lineYOffset - self.textY

    local line = math.max( self.display.beginLine + math.floor(y / self.lineHeight) , 1)

    local last_line = self:getLineCount()
    if line > self:getLineCount() then
        return self:getLineLength_woLF(last_line), last_line
    end

    local line_selected = self:getLineDisplay(line)
    line_selected = line_selected:sub(-1, -1) == "\n" and line_selected:sub(1,-2) or line_selected -- remove newline character from line, if such exists

    local char = 0
    local previous_width = 0
    for i = 1, utf.len(line_selected) do
        local cut_line_width = self.font:getWidth(utf.sub(line_selected, 1, i))
        if (cut_line_width + previous_width) / 2 >= x then
            break
        end

        -- Note: We cannot increment current line width by width of a character
        -- and have to compare x to center of current width and prevoius width
        -- because of kerning.

        char = i
        previous_width = cut_line_width
    end

    return char, line
end

--#endregion

--#region carette

function TextField:getCarettePosition()
    return self.carettePosition.char, self.carettePosition.line
end

function TextField:getCaretteNominalChar()
    return self.carettePosition.nominalChar
end

---Move carette horizontally and vertically
---@param x integer Horizontal movement. -1 for left, 1 for right, 0 for unchanged
---@param y integer Vertical movement. -1 for up, 1 for down, 0 for unchanged
---@param adjust_selection boolean Allow carette movement adjust and create selection and not reset it.
function TextField:moveCarette(x, y, adjust_selection)
    x, y = x or 0, y or 0

    local char, line = self:getCarettePosition()

    local keep_nominal

    if self:selectionExists() then
        if not adjust_selection then
            local begin, finish = self:getSelection() --[[@as TextFieldCharLine]]

            if y > 0 then
                char, line = finish[1], finish[2]
            elseif y < 0 then
                char, line = begin[1], begin[2]
            elseif x > 0 then
                char, line = finish[1] - 1, finish[2]
            elseif x < 0 then
                char, line = begin[1] + 1, begin[2]
            end

            self:endSelection()
            self:clearSelection()
        end
    else
        if adjust_selection then
            self:startSelection()
        end
    end

    if x > 0 then
        char = char + 1

        if char > self:getLineLength_woLF(line) then
            char = 0
            line = line + 1
        end
    elseif x < 0 then
        char = char - 1

        if char < 0 then
            line = line - 1
            char = self:getLineLength_woLF(line)
        end
    end

    if y > 0 then
        line = line + 1
        char = self:getCaretteNominalChar()
        keep_nominal = true
    elseif y < 0 then
        line = line - 1
        char = self:getCaretteNominalChar()
        keep_nominal = true
    end

    self:setCarette(char, line, keep_nominal)

    if adjust_selection then
        self.selection.active = false
        self:updateSelection()
    end
end

function TextField:setCarette(char, line, keep_nominal)
    local carette = self.carettePosition

    if not keep_nominal then
        carette.nominalChar = char
    end

    if line < 1 then
        return
    end

    local last_line = self:getLineCount()
    if line > last_line then
        carette.line = last_line
        carette.char = self:getLineLength_woLF(last_line)
        carette.nominalChar = carette.char

        self:updateCaretteVisual()
        return
    end

    if char > self:getLineLength_woLF(line) then
        char = self:getLineLength_woLF(line)
    end

    carette.line = line
    carette.char = char

    self:updateCaretteVisual()

    -- Update scroll
    if line <= self.display.beginLine then
        self:setScroll(nil, (line - 1) * self.lineHeight)
    elseif line >= self.display.lastLine then
        local ostatok = self.lineHeight - self.textareaH % self.lineHeight
        self:setScroll(nil, self.lineHeight * (line - math.ceil(self.textareaH / self.lineHeight) - 1) + ostatok)
    end
end

---Update carette position
---@param noreset boolean? Do not reset carette blink timer
function TextField:updateCaretteVisual(noreset)
    if not noreset then
        self.caretteTimer = 0
        self.caretteVisibility = self.focus and true
    end

    local char, line = self:getCarettePosition()

    self.display.caretteX = self.font:getWidth(utf.sub(self:getLineDisplay(line), 1, char))
end

--#endregion

--#region selection

function TextField:selectionExists()
    return self.selection.sel1[1] ~= self.selection.sel2[1] or self.selection.sel1[2] ~= self.selection.sel2[2]
end

function TextField:clearSelection()
    self.selection.sel2 = self.selection.sel1
end

function TextField:startSelection(mouse_controlled)
    self.selection.active = mouse_controlled

    self.selection.sel1 = {self:getCarettePosition()}
    self.selection.sel2 = {self:getCarettePosition()}
end

function TextField:updateSelection()
    self.selection.sel2[1], self.selection.sel2[2] = self:getCarettePosition()
end

function TextField:endSelection()
    self.selection.active = false
end

function TextField:getSelection()
    local start, finish = self.selection.sel1, self.selection.sel2

    if not self:selectionExists() then
        return nil
    end

    if start[2] < finish[2] then -- sel1 is on the line before sel2
        return start, finish
    elseif start[2] > finish[2] then -- sel1 is on the line after sel2
        return finish, start
    end

    -- situation: sel1 & sel2 are on the same line

    if start[1] < finish[1] then -- sel1 char is before sel2
        return start, finish
    else -- sel1 char is after sel2 (cannot be equal because it contradicts `not self:selectionExists()` above)
        return finish, start
    end
end

function TextField:cutSelection()
    self:endSelection()

    if not self:selectionExists() then
        return
    end

    local start, finish = self:getSelection() --[[@as TextFieldCharLine]]

    self:setCarette(start[1], start[2])

    if start[2] == finish[2] then -- one-line selection
        local line_contents = self.text[start[2]]

        self.text[start[2]] = utf.sub(line_contents, 1, start[1]) .. utf.sub(line_contents, finish[1] + 1, -1)
    else -- multi-line selection
        self.text[start[2]] = utf.sub(self.text[start[2]], 1, start[1])
        self.text[finish[2]] = utf.sub(self.text[finish[2]], finish[1] + 1, -1)

        for i = finish[2] - 1, start[2] + 1, -1 do
            table.remove(self.text, i)
        end
    end

    self:clearSelection()

    return true
end

--#endregion

--#region text manipulation

function TextField:newline()
    self:cutSelection()

    local carette_char, carette_line = self:getCarettePosition()

    local cur_line = self.text[carette_line]

    self.text[carette_line] = utf.sub(cur_line, 1, carette_char) .. "\n"

    local new_line = utf.sub(cur_line, carette_char + 1, -1)
    table.insert(self.text, carette_line + 1, new_line)

    self:setCarette(0, carette_line + 1)
    self:updateWrap()
end

function TextField:backspace()
    if self:cutSelection() then
        self:updateWrap()
        return
    end

    local carette_char, carette_line = self:getCarettePosition()

    if carette_char > 0 then -- Remove character from current line
        local cur_line = self.text[carette_line]

        self.text[carette_line] = utf.sub(cur_line, 1, carette_char - 1) .. utf.sub(cur_line, carette_char + 1, -1)
        self:moveCarette(-1, 0, false)
    elseif carette_line > 1 then -- Append lines (backspace at char 0)
        -- Cut last character of previous line
        self.text[carette_line - 1] = utf.sub(self.text[carette_line - 1], 1, -2)

        -- Move cursor left
        self:moveCarette(-1, 0, false)
    end

    self:updateWrap()
end

--#endregion

--#region render

function TextField:paintField()
    love.graphics.setColor(self.palette[1])
    love.graphics.rectangle("fill", 0, 0, self.w, self.h, self.r)

    love.graphics.setColor(self.palette[3])
    love.graphics.rectangle("line", 0, 0, self.w, self.h, self.r)
end

function TextField:enableStencil()
    love.graphics.stencil(self.stencil, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
end

function TextField:paintSelection()
    if not self:selectionExists() then
        return
    end

    local start, finish = self:getSelection() --[[@as TextFieldCharLine]]

    love.graphics.setColor(self.palette:getColorByIndex(4))

    -- one-line selection
    if start[2] == finish[2] then
        if start[2] < self.display.beginLine or self.display.lastLine < start[2] then
            return
        end

        local line_contents = self:getLineDisplay(start[2])

        local skiped_text_width = self.font:getWidth(utf.sub(line_contents, 1, start[1]))

        local selection_width = self.font:getWidth(utf.sub(line_contents, start[1] + 1, finish[1]))

        love.graphics.rectangle("fill", self.textX + skiped_text_width, self.textY - self.display.lineYOffset + (start[2] - self.display.beginLine) * self.lineHeight, selection_width, self.lineHeight)

        return
    end

    -- multi-line selection
    for i = math.max(start[2], self.display.beginLine), math.min(finish[2], self.display.lastLine) do
        local lineI = i - self.display.beginLine
        local line_contents = self:getLineDisplay(i)

        local skiped_text_width, selection_width = 0, 0

        if i == start[2] then -- selection beginning line
            skiped_text_width = self.font:getWidth(utf.sub(line_contents, 1, start[1]))
            selection_width = self.font:getWidth(utf.sub(line_contents:gsub("\n", " "), start[1] + 1, -1))
        elseif i < finish[2] then -- selection in-between line
            selection_width = self.font:getWidth(line_contents:gsub("\n", " "))
        else -- selection end line
            selection_width = self.font:getWidth(utf.sub(line_contents, 1, finish[1]))
        end

        love.graphics.rectangle("fill", self.textX + skiped_text_width, self.textY - self.display.lineYOffset + lineI * self.lineHeight, selection_width, self.lineHeight)
    end
end

function TextField:paintText()
    if #self.text == 1 and #self.text[1] == 0 and not self:hasFocus() then
        love.graphics.setColor(self.palette[3])
        love.graphics.print(self.placeholder, self.textX, self.textY - self.display.lineYOffset)

        return
    end

    love.graphics.setColor(self.palette[2])
    love.graphics.setFont(self.font)
    for i = self.display.beginLine, self.display.lastLine do
        local lineI = i - self.display.beginLine

        love.graphics.print(self:getLineDisplay(i), self.textX, self.textY - self.display.lineYOffset + lineI * self.lineHeight)
    end
end

function TextField:paintCarette()
    if self.display.beginLine <= self.carettePosition.line and self.carettePosition.line <= self.display.lastLine then
        love.graphics.rectangle("fill", self.textX + self.display.caretteX, self.textY - self.display.lineYOffset + self.lineHeight * (self.carettePosition.line - self.display.beginLine), 1, self.lineHeight)
    end
end

function TextField:disableStencil()
    love.graphics.setStencilTest()
end

--#endregion

function TextField:keyPress(key)
    local shift_held = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

    if key == "return" then
        if self.oneline then
            self:action()
        else
            if love.keyboard.isDown("lctrl") then
                self:action()
            else
                self:newline()
            end
        end
    elseif key == "backspace" then
        self:backspace()
    elseif key == "left" then
        self:moveCarette(-1, 0, shift_held)
    elseif key == "right" then
        self:moveCarette(1, 0, shift_held)
    elseif key == "up" then
        self:moveCarette(0, -1, shift_held)
    elseif key == "down" then
        self:moveCarette(0, 1, shift_held)
    end
end

function TextField:textinput(text)
    self:cutSelection()

    local carette_char, carette_line = self:getCarettePosition()

    local cur_line = self.text[carette_line]

    self.text[carette_line] = utf.sub(cur_line, 1, carette_char) .. text .. utf.sub(cur_line, carette_char + 1, -1)

    self:moveCarette(1, 0, false)
    self:updateWrap()
end

function TextField:click(x, y, but)
    if but == 1 then
        local char, line = self:translateClick(x, y)

        self:setCarette(char, line)

        self:startSelection(true)
    end
end

function TextField:tick(dt)
    if self.focus then
        self.caretteTimer = self.caretteTimer + dt

        if self.caretteTimer >= TEXT_CARETTE_BLINK_PERIOD then
            self.caretteTimer = self.caretteTimer - TEXT_CARETTE_BLINK_PERIOD
            self.caretteVisibility = not self.caretteVisibility
        end

        if self.selection.active then
            local mx, my = love.mouse.getPosition()
            local char, line = self:translateClick(mx, my)

            self:setCarette(char, line)
            self:updateSelection()

            if not love.mouse.isDown(1) then
                self:endSelection()
            end
        end
    end
end

function TextField:paint()
    self:paintField()

    self:enableStencil()

    self:paintSelection()
    self:paintText()

    if self.caretteVisibility then
        self:paintCarette()
    end

    self:disableStencil()
end

function TextField:gainFocus()
    uiobj.class.gainFocus(self)

    self.caretteVisibility = true
    self.caretteTimer = 0
end

function TextField:loseFocus()
    uiobj.class.loseFocus(self)

    self.caretteVisibility = false
end

setmetatable(TextField, {__index = uiobj.class}) -- Set parenthesis

textfield.class = TextField

-- textfield fnc

---Create new TextField object from object prototype
---@param prototype ObjectPrototype
---@return TextField
function textfield.new(prototype)
    local obj = uiobj.new(prototype)

    setmetatable(obj, TextField_meta)---@cast obj TextField

    obj.textX = TEXT_OFFSET_LEFT
    obj.textY = TEXT_OFFSET_TOP
    obj.textareaW = obj.w - obj.textX * 2
    obj.textareaH = obj.h - obj.textX * 2

    obj.lineHeight = obj.font:getHeight()

    function obj.stencil()
        love.graphics.rectangle("fill", obj.textX, obj.textY, obj.textareaW, obj.textareaH)
    end

    -- oneline check
    if type(obj.oneline) == "nil" then
        if (obj.h - TEXT_OFFSET_TOP * 2)/obj.lineHeight <= 2 then ---@todo use protected parameters instead of getters (scope issue)
            obj.oneline = true
        end
    end

    if obj.oneline then
        obj.textY = math.floor(obj:getHeight()/2 - obj.lineHeight/2)
    end

    if obj.password then
        obj.getLineDisplay = TextField.getLineDisplay_password
    end

    obj.carettePosition = {}
    obj.display = {}
    obj.scroll = {0, 0}
    obj.selection = {sel1 = {0, 0}, sel2 = {0, 0}, active = false}

    obj:updateDisplay()
    obj:setText(obj.text)
    obj:setCarette(0, math.huge)

    obj:updateCaretteVisual()

    return obj
end

return textfield