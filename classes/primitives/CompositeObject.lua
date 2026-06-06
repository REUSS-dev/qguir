-- composite

local gui = require("stellargui")

-- classes

---@class CompositeObject : ObjectUI
---@field ObjectUI ObjectUI
---@field objects ObjectUI[] List of UI objects inside the composite object
---@field fill_flag boolean
---@field border_flag boolean
---@field bsize number
---@field r number
local CompositeObject = {
	name = "CompositeObject",
	aliases = {"Composite", "Container"},
	rules = {
		"palette",
		{{"r", "radius"}, "r"},
		{{"bsize", "border_size", "borderSize"}, "bsize"}
	},
	default = {
		w = "hug",
		h = "hug",
		r = 0,
		bsize = 3
	}
}

---Check, if coordinates provided are in boundaries of any of UI objects in the composite object
---@param x pixels Mouse X position in pixels
---@param y pixels Mouse Y position in pixels
---@return ObjectUI|false hover Returns object pointer if the mouse if hovering on the object, false otherwise
function CompositeObject:checkHover(x, y)
    if not self.ObjectUI.checkHover(self, x, y) and not self:hasFocus() then
        return false
    end

    local hlObject

    for _, uiobject in ipairs(self.objects) do
        hlObject = uiobject:isActive() and uiobject:checkHover(x, y) or hlObject
    end

    if not hlObject then
        return false
    end

    return hlObject
end

---Hide all objects im a composite
function CompositeObject:hide()
    for _, uiobject in ipairs(self.objects) do
        uiobject:hide()
    end
end

---Show all objects im a composite
function CompositeObject:show()
    for _, uiobject in ipairs(self.objects) do
        uiobject:show()
    end
end

---Tick all UI objects in a composite object.
---@param dt number
function CompositeObject:tick(dt)
    for _, uiobject in ipairs(self.objects) do
        if uiobject:isActive() then
            uiobject:tick(dt)
        end
    end
end

---Paint all UI objects in a composite object.
function CompositeObject:paint()
	if self.fill_flag then
		love.graphics.setColor(self.palette.main)
		love.graphics.rectangle("fill", 0, 0, self.w, self.h, self.r)
	end

	if self.border_flag then
		local old_bsize = love.graphics.getLineWidth()
		love.graphics.setLineWidth(self.bsize)

		love.graphics.setColor(self.palette.border)
		love.graphics.rectangle("line", 0, 0, self.w, self.h, self.r)

		love.graphics.setLineWidth(old_bsize)
	end

    for _, uiobject in ipairs(self.objects) do
        if uiobject:isDrawn() then
			local tx, ty = uiobject:getCoordinates()
            love.graphics.translate(tx, ty)
            uiobject:paint()
            love.graphics.translate(-tx, -ty)
        end
    end

	if DEBUG then
		love.graphics.setColor(1, 1, 1)

		love.graphics.rectangle("line", 0, 0, self.w, self.h)
		love.graphics.print(string.format("Container; width: %s, height: %s\nGrowth: %s (%s-%s); Gap: %s\nPadding: [%d, %d, %d, %d]\nActual dimensions: %d %d", self.layout.w, self.layout.h, self.layout.growth, self.layout.horizontal, self.layout.vertical, self.layout.gap, self.layout.padding[1], self.layout.padding[2], self.layout.padding[3], self.layout.padding[4], self.w, self.h), 10, 10)
	
		love.graphics.setColor(0.5, 0.5, 1)
		love.graphics.rectangle("line", self.layout.padding[1], self.layout.padding[2], self.w - self.layout.padding[1] - self.layout.padding[3], self.h - self.layout.padding[2] - self.layout.padding[4])
	end
end

---Add new object to composite object
---@param obj ObjectUI
function CompositeObject:add(obj)
    obj.parent = self
    self.objects[#self.objects+1] = obj

	self:relayout()

	return self
end

function CompositeObject:remove(to_remove)
    for i, obj in ipairs(self.objects) do
        if obj == to_remove then
            table.remove(self.objects, i)

			self:relayout()

            return self
        end
    end
end

function CompositeObject:create(object_type)
	return gui[object_type or self] -- allows to call both with a function call "." and method call ":"
end

function CompositeObject:createChild(object_type)
	local function childinit(prototype)
		local new_child = gui[object_type](prototype)
		self:add(new_child)

		return new_child
	end

	return childinit
end

--#region Layout

function CompositeObject:setGrowth(new_growth)
	if new_growth ~= self.layout.growth then
		self.layout.growth = new_growth
		self:relayout()
	end

	return self
end

function CompositeObject:setPadding(left, top, right, bottom)
	if type(left) == "table" then
		assert(left[1] and left[2] and left[3] and left[4], "Padding table must contain data for all 4 sides")
		self.layout.padding = left
	else
		self.layout.padding[1] = left or self.layout.padding[1]
		self.layout.padding[2] = top or self.layout.padding[2]
		self.layout.padding[3] = right or self.layout.padding[3]
		self.layout.padding[4] = bottom or self.layout.padding[4]
	end

	return self
end

function CompositeObject:relayout()
	if not self.parent then
		return
	end

	self:autolayout(self.w, self.h)
end

function CompositeObject:autolayout(free_w, free_h)
	local w, h = self.ObjectUI.autolayout(self, free_w, free_h)

	local layout = self.layout

	local internal_w, internal_h = w, h

	if layout.growth == "horizontal" then
		if internal_h then
			internal_h = internal_h - layout.padding[2] - layout.padding[4]
		end

		internal_w = nil
	elseif layout.growth == "vertical" then
		if internal_w then
			internal_w = internal_w - layout.padding[1] - layout.padding[3]
		end

		internal_h = nil
	end

	-- First pass
	local width_miss_count, height_miss_count = 0, 0

	local object_sizes = {}
	local layout_object_count = 0

	for i, object in ipairs(self.objects) do
		if object:canLayout() then
			local ow, oh = object:autolayout(internal_w, internal_h)

			object_sizes[i] = {ow, oh}

			if not ow then
				width_miss_count = width_miss_count + 1
			end
			if not oh then
				height_miss_count = height_miss_count + 1
			end

			layout_object_count = layout_object_count + 1
		else
			object_sizes[i] = {ignore = true}
		end
	end

	-- Secondary dimension fill resolve

	if layout.growth == "horizontal" then
		if layout.h == "hug" then
			local result_height

			for i = 1, #self.objects do
				local object_size = object_sizes[i]

				result_height = result_height and math.max(result_height, object_size[2] or 0) or object_size[2]
			end

			if not result_height and layout_object_count ~= 0 then
				error("Not a single fixed/hug height object inside a hug height container")
			end

			internal_h = result_height or 0
		end
	elseif layout.growth == "vertical" then
		if layout.w == "hug" then
			local result_width

			for i = 1, #self.objects do
				local object_size = object_sizes[i]

				result_width = result_width and math.max(result_width, object_size[1] or 0) or object_size[1]
			end

			if not result_width and layout_object_count ~= 0 then
				error("Not a single fixed/hug width object inside a hug width container")
			end

			internal_w = result_width or 0
		end
	end

	-- Primary dimension fill resolve

	local primary_fills = {}

	if layout.growth == "horizontal" then
		if width_miss_count ~= 0 then
			if w then
				local vacant_space = w - layout.padding[1] - layout.padding[3] - math.max(layout_object_count - 1, 0) * layout.gap

				for _, objsize in ipairs(object_sizes) do
					if objsize[1] then
						vacant_space = vacant_space - objsize[1]
					end
				end
				
				local fill_pool = {}
				local fill_base = math.floor(vacant_space / width_miss_count)
				local ostatok = vacant_space % width_miss_count

				for i = 1, width_miss_count do
					fill_pool[i] = fill_base + ((i <= ostatok) and 1 or 0)
				end

				for i, objsize in ipairs(object_sizes) do
					if not objsize[1] and not objsize.ignore then
						primary_fills[i] = fill_pool[1]
						table.remove(fill_pool, 1)
					end
				end
			end
		end
	elseif layout.growth == "vertical" then
		if height_miss_count ~= 0 then
			if h then
				local vacant_space = h - layout.padding[2] - layout.padding[4] - math.max(layout_object_count - 1, 0) * layout.gap

				for _, objsize in ipairs(object_sizes) do
					if objsize[2] then
						vacant_space = vacant_space - objsize[2]
					end
				end
				
				local fill_pool = {}
				local fill_base = math.floor(vacant_space / height_miss_count)
				local ostatok = vacant_space % height_miss_count

				for i = 1, height_miss_count do
					fill_pool[i] = fill_base + ((i <= ostatok) and 1 or 0)
				end

				for i, objsize in ipairs(object_sizes) do
					if not objsize[2] and not objsize.ignore then
						primary_fills[i] = fill_pool[1]
						table.remove(fill_pool, 1)
					end
				end
			end
		end
	end

	-- Second pass
	if layout.growth == "horizontal" then
		for i, object in ipairs(self.objects) do
			if object:canLayout() then
				local ow, oh = object:autolayout(primary_fills[i], internal_h)

				object_sizes[i] = {ow, oh}
			else
				object_sizes[i] = {ignore = true}
			end
		end
	elseif layout.growth == "vertical" then
		for i, object in ipairs(self.objects) do
			if object:canLayout() then
				local ow, oh = object:autolayout(internal_w, primary_fills[i])

				object_sizes[i] = {ow, oh}
			else
				object_sizes[i] = {ignore = true}
			end
		end
	end

	-- Dimensions calculation
	if not w then
		if layout.w == "hug" then
			if layout.growth == "horizontal" then
				w = layout.padding[1] + layout.padding[3] + math.max(layout_object_count - 1, 0) * layout.gap

				for _, osize in ipairs(object_sizes) do
					if osize[1] then
						w = w + osize[1]
					end
				end
			elseif layout.growth == "vertical" then
				w = internal_w + layout.padding[1] + layout.padding[3]
			end
		end
	end

	if not h then
		if layout.h == "hug" then
			if layout.growth == "vertical" then
				h = layout.padding[2] + layout.padding[4] + math.max(layout_object_count - 1, 0) * layout.gap

				for _, osize in ipairs(object_sizes) do
					if osize[2] then
						h = h + osize[2]
					end
				end
			elseif layout.growth == "horizontal" then
				h = internal_h + layout.padding[2] + layout.padding[4]
			end
		end
	end

	if w and h then
		if w ~= self.w or h ~= self.h then
			self:resize(w, h)
		end

		self:layout_deploy()
	end

	return w, h
end

function CompositeObject:layout_deploy()
	local layout = self.layout

	local horizontal = layout.horizontal
	local vertical = layout.vertical
	local gap = layout.gap

	if layout.growth == "horizontal" then
		local offset

		if horizontal == "left" then
			offset = layout.padding[1]
		elseif horizontal == "center" or horizontal == "right" then
			local content_length = 0

			local layout_objects = 0
			for _, object in ipairs(self.objects) do
				if object:canLayout() then
					content_length = content_length + object.w

					layout_objects = layout_objects + 1
				end
			end

			content_length = content_length + math.max(layout_objects - 1, 0) * gap

			if horizontal == "center" then
				offset = layout.padding[1] + math.floor((self.w - layout.padding[1] - layout.padding[3] - content_length)/2 + .5)
			elseif horizontal == "right" then
				offset = self.w - layout.padding[3] - content_length
			end
		end

		if vertical == "top" then
			for _, object in ipairs(self.objects) do
				if object:canLayout() then
					object:move(offset, layout.padding[2])

					offset = offset + object.w + gap
				end
			end
		elseif vertical == "center" then
			local container_half = (self.h - layout.padding[2] - layout.padding[4])/2

			for _, object in ipairs(self.objects) do
				if object:canLayout() then
					object:move(offset, layout.padding[2] + math.floor(container_half - object.h/2 + .5))

					offset = offset + object.w + gap
				end
			end
		elseif vertical == "bottom" then
			for _, object in ipairs(self.objects) do
				if object:canLayout() then
					object:move(offset, self.h - layout.padding[4] - object.h)

					offset = offset + object.w + gap
				end
			end
		end
	elseif layout.growth == "vertical" then
		local offset

		if vertical == "top" then
			offset = layout.padding[2]
		elseif vertical == "center" or vertical == "bottom" then
			local content_length = 0

			local layout_objects = 0
			for _, object in ipairs(self.objects) do
				if object:canLayout() then
					content_length = content_length + object.h

					layout_objects = layout_objects + 1
				end
			end

			content_length = content_length + math.max(layout_objects - 1, 0) * gap

			if vertical == "center" then
				offset = layout.padding[2] + math.floor((self.h - layout.padding[2] - layout.padding[4] - content_length)/2 + .5)
			elseif vertical == "bottom" then
				offset = self.h - layout.padding[4] - content_length
			end
		end

		if horizontal == "left" then
			for _, object in ipairs(self.objects) do
				if object:canLayout() then
					object:move(layout.padding[1], offset)

					offset = offset + object.h + gap
				end
			end
		elseif horizontal == "center" then
			local container_half = (self.w - layout.padding[1] - layout.padding[3])/2

			for _, object in ipairs(self.objects) do
				if object:canLayout() then
					object:move(layout.padding[1] + math.floor(container_half - object.w/2 + .5), offset)

					offset = offset + object.h + gap
				end
			end
		elseif vertical == "right" then
			for _, object in ipairs(self.objects) do
				if object:canLayout() then
					object:move(self.w - layout.padding[3] - object.w, offset)

					offset = offset + object.h + gap
				end
			end
		end
	end
end

--#endregion

---Create new CompositeObject
function CompositeObject:new()
    self.objects = {}

	self.fill_flag = self.palette.main and true or false
	self.border_flag = self.palette.border and true or false
end

return CompositeObject