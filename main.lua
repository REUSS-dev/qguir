function love.load()
    io.stdout:setvbuf("no")
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";src/?.lua")

    local gui = require("stellargui").hook()
    gui.loadExternalObjects()
end

function love.update(dt)
    
end

function love.draw()
    
end