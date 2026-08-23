local utils = require("utils")

chapters = {}
currentChapter = 1
totalChapters = 13
fontSmall = nil
fontMedium = nil
fontLarge = nil

local function loadChapter(n)
    if world then
        world = nil
    end
    local ok, mod = pcall(require, "chapters.chapter" .. n)
    if ok then
        chapters[n] = mod
        mod.init()
    else
        print("Failed to load chapter " .. n .. ": " .. tostring(mod))
    end
end

function love.load()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.12)
    fontSmall = love.graphics.newFont(13)
    fontMedium = love.graphics.newFont(18)
    fontLarge = love.graphics.newFont(28)
    loadChapter(currentChapter)
end

function love.update(dt)
    if chapters[currentChapter] and chapters[currentChapter].update then
        chapters[currentChapter].update(dt)
    end
end

function love.draw()
    if chapters[currentChapter] and chapters[currentChapter].draw then
        chapters[currentChapter].draw()
    end
    drawNav()
end

function drawNav()
    local navY = 4
    local navH = 26
    love.graphics.setFont(fontSmall)
    for i = 1, totalChapters do
        local label = tostring(i)
        local bw = 30
        local bx = 10 + (i - 1) * (bw + 4)
        utils.drawButton(bx, navY, bw, navH, label, i == currentChapter)
    end
    local info = "Chapter " .. currentChapter .. "/" .. totalChapters
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.print(info, 10 + totalChapters * 34 + 10, navY + 5)
    love.graphics.print("[LEFT/RIGHT] navigate", 10 + totalChapters * 34 + 10, navY + 5)
end

function love.keypressed(key)
    if key == "right" then
        currentChapter = math.min(totalChapters, currentChapter + 1)
        loadChapter(currentChapter)
    elseif key == "left" then
        currentChapter = math.max(1, currentChapter - 1)
        loadChapter(currentChapter)
    end
    if chapters[currentChapter] and chapters[currentChapter].keypressed then
        chapters[currentChapter].keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    local navY = 4
    local navH = 26
    if y <= navY + navH then
        for i = 1, totalChapters do
            local bw = 30
            local bx = 10 + (i - 1) * (bw + 4)
            if utils.inRect(x, y, bx, navY, bw, navH) then
                currentChapter = i
                loadChapter(currentChapter)
                return
            end
        end
    end
    if chapters[currentChapter] and chapters[currentChapter].mousepressed then
        chapters[currentChapter].mousepressed(x, y, button)
    end
end
