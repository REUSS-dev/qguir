function love.load()
    io.stdout:setvbuf("no")
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";src/?.lua")

    local gui = require("stellargui").hook()
    gui.loadExternalObjects()

    local exampleA = gui.Button{x = "center", y = 100, w = 300, h = 200, text = "Я памятник себе воздвиг нерукотворный, к нему не зарастёт народная тропа", action = function() print("kurwo!!!") end, font = love.graphics.newFont("font.ttf", 16)}

    local exampleB = gui.Button{x = "center", y = 400, color = {0.5,1,1}}

    gui.register(exampleA)
    gui.register(exampleB)
end

function love.update(dt)
    
end

function love.draw()
    
end