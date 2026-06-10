local gui

function love.load()
    io.stdout:setvbuf("no")
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";src/?.lua;src/?/init.lua")
    love.keyboard.setKeyRepeat(true)

    gui = require("init").hook()
    gui.loadExternalObjects("classes/objects")

	gui.getCanvas().layout.growth = "horizontal"
	gui.getCanvas().layout.padding[2] = 80

    local box1 = gui.Image{w = "fill", h = "fill", image = love.graphics.newImage("test.png"), display = "limit"}

	local box2 = gui.Container{w = "fill", h = "fill"}

	local left_container = gui.Container{
		w = 300,
		h = "fill",
		padding = {0, 100, 0, 50},
		growth = "vertical",
		gap = 0
	}

	left_container:add(box1)
	left_container:add(box2)

	local main_container = gui.Container{
		w = "fill",
		h = "fill",
		growth = "vertical",
		horizontal = "right",
		vertical = "top",
		colors = {
			fill = {0.5, 0, 0, 0.5},
			border = {0.5, 0.5, 1, 0.5}
		},
		border_size = 10,
		r = 40
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