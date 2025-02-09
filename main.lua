function love.load()
    io.stdout:setvbuf("no")
    love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";src/?.lua")
    love.keyboard.setKeyRepeat(true)

    local gui = require("stellargui").hook()
    gui.loadExternalObjects()

    exampleA = gui.Button{x = "center", y = 100, w = 300, h = 200, text = "Я памятник себе воздвиг нерукотворный,\
К нему не зарастет народная тропа,\
Вознесся выше он главою непокорной\
Александрийского столпа.\
Нет, весь я не умру — душа в заветной лире\
Мой прах переживет и тленья убежит —\
И славен буду я, доколь в подлунном мире\
Жив будет хоть один пиит.", action = function() print("kurwo!!!") end, font = love.graphics.newFont("font.ttf", 16)}

    local exampleB = gui.DataGrid{x = "center", y = 400, font = love.graphics.newFont("font.ttf", 16)}

    for i = 1, 5 do
        for j = 1, 5 do
            exampleB:set(i, j, math.random(1, 100))
        end
    end

    gui.register(exampleA)
    gui.register(exampleB)
end

totaldt = 0

function love.update(dt)
    totaldt = totaldt + dt*5

    --exampleA:move(100 + 50*math.cos(totaldt), 100 + 50*math.sin(totaldt))
end

function love.draw()
    love.graphics.setColor(1,1,1, 1)
    love.graphics.print(keyp or "", 300, 380)
end