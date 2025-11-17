local gui

function love.load()
    io.stdout:setvbuf("no")
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";src/?.lua;src/?/init.lua")
    love.keyboard.setKeyRepeat(true)

    gui = require("init").hook()
    gui.loadExternalObjects("classes")

    exampleA = gui.Button{x = -10, y = 100, w = 100, h = 300, text = "Я памятник себе воздвиг нерукотворный,\
К нему не зарастет народная тропа,\
Вознесся выше он главою непокорной\
Александрийского столпа.\
Нет, весь я не умру — душа в заветной лире\
Мой прах переживет и тленья убежит —\
И славен буду я, доколь в подлунном мире\
Жив будет хоть один пиит.", action = function() print("kurwo!!!") end, font = love.graphics.newFont("font.ttf", 16)}

    exampleB = gui.TextField{x = "center", y = 50, font = love.graphics.newFont("font.ttf", 16), w = 350, h = 200, text = love.filesystem.read("war.txt")}

    exampleC = gui.Selector{y = 400, default = 0.5}

    --exampleA:hide()
    gui.register(exampleA)
    gui.register(exampleB)
    gui.register(exampleC)
end

totaldt = 0

function love.update(dt)
    totaldt = totaldt + dt*5

    --exampleA:move(100 + 50*math.cos(totaldt), 100 + 50*math.sin(totaldt))
end

function love.draw()
    gui.drawMousePosition()
end

function love.keypressed(key)
    if key == "a" then
        exampleB:resize(exampleB.gridDataPlain.gridSize[1] - 1, exampleB.gridDataPlain.gridSize[1] - 1)
    elseif key == "s" then
        exampleB:resize(exampleB.gridDataPlain.gridSize[1] + 1, exampleB.gridDataPlain.gridSize[1] + 1)
    end
end