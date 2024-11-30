function love.load()
    io.stdout:setvbuf("no")
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";src/?.lua")

    local gui = require("stellargui").hook()
    gui.loadExternalObjects()

    local exampleA = gui.Button_L{x = "center", y = 100}

    local exampleB = gui.Button_L{x = "center", y = 400}
    gui.register(exampleA)
    gui.register(exampleB)
end

function love.update(dt)
    
end

function love.draw()
    
end