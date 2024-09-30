function love.load()
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";src/?.lua")

    local gui = require("stellargui").hook()
end

function love.update(dt)
    
end

function love.draw()
    
end