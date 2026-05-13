local gui

function love.load()
    io.stdout:setvbuf("no")
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";src/?.lua;src/?/init.lua")
    love.keyboard.setKeyRepeat(true)

    gui = require("init").hook()
    gui.loadExternalObjects("classes")

	DEBUG = true

	gui.getCanvas().layout.growth = "horizontal"
	gui.getCanvas().layout.padding[2] = 80

    local box1 = gui.CompositeObject{w = "fill", h = 75}

	local box2 = gui.CompositeObject{w = "fill", h = "fill"}

	local left_container = gui.CompositeObject{
		w = 300,
		h = "fill",
		padding = {0, 100, 0, 50},
		growth = "vertical",
		gap = 0
	}

	left_container:add(box1)
	left_container:add(box2)

	local main_container = gui.CompositeObject{
		w = "fill",
		h = "fill",
		growth = "vertical",
		horizontal = "right",
		vertical = "top"
	}
	
	gui.add(left_container)
	gui.add(main_container)
end

totaldt = 0

function love.update(dt)
    totaldt = totaldt + dt*5
end

function love.draw()
    gui.drawMousePosition()
end

function love.keypressed(key)
end