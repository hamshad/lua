_G.love = require("love")

-- install love executable file from https://github.com/love2d/love/releases/download/11.5/love-11.5-win32.zip
-- save it in enviroment path variable and run this code using the `love .` command

speed = 100

function love.load()
    love.window.setFullscree = true
    _G.Number = 0
    _G.dx, _G.dy = 10, 10
end

function love.keypressed(key, scancode, unicode)
    if scancode == "space" then
        speed = 260
    end
end

function love.keyreleased(key, scancode, unicode)
    if scancode == "space" then
        speed = 100
    end
end

function love.update(dt)
    Number = Number + 1
    local isScancodeDown = love.keyboard.isScancodeDown
    if isScancodeDown('w') then dy = dy - dt * speed end
    if isScancodeDown('s') then dy = dy + dt * speed end
    if isScancodeDown('a') then dx = dx - dt * speed end
    if isScancodeDown('d') then dx = dx + dt * speed end
end

function love.draw()
    love.graphics.setColor(75 / 255, 148 / 255, 10 / 255, 1)
    love.graphics.rectangle("fill", dx, dy, 100, 100)
    love.graphics.setColor(0, 13, 255)
    love.graphics.print("watch this - " .. Number, 400, 500)
end
