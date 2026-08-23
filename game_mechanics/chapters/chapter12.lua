-- ============================================================
-- CHAPTER 12: Screen Management — Menus, Pauses, Transitions
-- ============================================================
-- Games have more than just gameplay. They have title screens,
-- pause menus, game-over screens, and transitions. This chapter
-- builds a game with multiple screens managed by a state stack.
--
-- INTERACTION: Enter to start, P to pause, ESC to go back.
-- Click to interact with menu buttons.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local gameState = "TITLE" -- TITLE, PLAYING, PAUSED, GAMEOVER
local stateStack = {}
local player = {x = 512, y = 384, w = 22, h = 22, hp = 100, maxHp = 100, speed = 220}
local enemies = {}
local bullets = {}
local cooldown = 0
local score = 0
local gameTime = 0
local buttons = {}

function pushState(state)
    table.insert(stateStack, gameState)
    gameState = state
end

function popState()
    if #stateStack > 0 then
        gameState = table.remove(stateStack)
    end
end

function spawnEnemy()
    local side = math.random(1, 4)
    local x, y
    if side == 1 then x = -20; y = math.random(0, 768)
    elseif side == 2 then x = 1044; y = math.random(0, 768)
    elseif side == 3 then x = math.random(0, 1024); y = -20
    else x = math.random(0, 1024); y = 788 end
    table.insert(enemies, {
        x = x, y = y, w = 20, h = 20,
        hp = 20, speed = 70 + math.random() * 40,
    })
end

function M.init()
    gameState = "TITLE"
    stateStack = {}
    player = {x = 512, y = 384, w = 22, h = 22, hp = 100, maxHp = 100, speed = 220}
    enemies = {}
    bullets = {}
    cooldown = 0
    score = 0
    gameTime = 0
    buttons = {
        {x = 412, y = 350, w = 200, h = 40, label = "START GAME", action = function()
            gameState = "PLAYING"
            for i = 1, 5 do spawnEnemy() end
        end},
        {x = 412, y = 410, w = 200, h = 40, label = "QUIT", action = function()
            love.event.quit()
        end},
    }
end

function M.update(dt)
    if gameState ~= "PLAYING" then return end

    gameTime = gameTime + dt

    -- Player movement
    local dx, dy = 0, 0
    if love.keyboard.isDown("left") then dx = dx - 1 end
    if love.keyboard.isDown("right") then dx = dx + 1 end
    if love.keyboard.isDown("up") then dy = dy - 1 end
    if love.keyboard.isDown("down") then dy = dy + 1 end
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        player.x = player.x + (dx / len) * player.speed * dt
        player.y = player.y + (dy / len) * player.speed * dt
    end
    player.x = utils.clamp(player.x, 0, 1024 - player.w)
    player.y = utils.clamp(player.y, 0, 768 - player.h)

    -- Enemies
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        local ecx, ecy = e.x + e.w / 2, e.y + e.h / 2
        local pcx, pcy = player.x + player.w / 2, player.y + player.h / 2
        local edx, edy = pcx - ecx, pcy - ecy
        local dist = math.sqrt(edx * edx + edy * edy)
        if dist > 0 then
            e.x = e.x + (edx / dist) * e.speed * dt
            e.y = e.y + (edy / dist) * e.speed * dt
        end
        if utils.aabbOverlap(player.x, player.y, player.w, player.h, e.x, e.y, e.w, e.h) then
            player.hp = player.hp - 40 * dt
            if player.hp <= 0 then
                pushState("GAMEOVER")
            end
        end
    end

    -- Bullets
    if cooldown > 0 then cooldown = cooldown - dt end
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.y < -10 or b.x < -10 or b.x > 1034 then
            table.remove(bullets, i)
        else
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if utils.aabbOverlap(b.x - 3, b.y - 3, 6, 6, e.x, e.y, e.w, e.h) then
                    e.hp = e.hp - 10
                    table.remove(bullets, i)
                    if e.hp <= 0 then
                        table.remove(enemies, j)
                        score = score + 100
                        spawnEnemy()
                    end
                    break
                end
            end
        end
    end
end

function M.mousepressed(x, y, button)
    if button == 1 then
        if gameState == "TITLE" or gameState == "GAMEOVER" then
            for _, btn in ipairs(buttons) do
                if utils.pointInRect(x, y, btn.x, btn.y, btn.w, btn.h) then
                    btn.action()
                end
            end
        elseif gameState == "PLAYING" and cooldown <= 0 then
            local pcx = player.x + player.w / 2
            local pcy = player.y
            local dx, dy = x - pcx, y - pcy
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0 then
                table.insert(bullets, {
                    x = pcx, y = pcy,
                    vx = dx / len * 400, vy = dy / len * 400,
                })
                cooldown = 0.12
            end
        end
    end
end

function M.keypressed(key)
    if key == "p" and gameState == "PLAYING" then
        pushState("PAUSED")
    elseif key == "p" and gameState == "PAUSED" then
        popState()
    elseif key == "escape" then
        if gameState == "PAUSED" or gameState == "PLAYING" then
            popState()
        end
    elseif key == "return" then
        if gameState == "TITLE" then
            gameState = "PLAYING"
            for i = 1, 5 do spawnEnemy() end
        elseif gameState == "GAMEOVER" then
            popState()
            popState()
            gameState = "TITLE"
        end
    end
end

function M.draw()
    if gameState == "TITLE" then
        drawTitleScreen()
    elseif gameState == "PLAYING" then
        drawGameplay()
    elseif gameState == "PAUSED" then
        drawGameplay()
        drawPauseOverlay()
    elseif gameState == "GAMEOVER" then
        drawGameplay()
        drawGameOverOverlay()
    end
end

function drawTitleScreen()
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, 1024, 768)
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.print("GAME MECHANICS", 380, 200)
    love.graphics.setFont(fontMedium)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("A Feynman Guide to Game Development", 310, 240)
    for _, btn in ipairs(buttons) do
        love.graphics.setColor(0.2, 0.2, 0.3)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h)
        love.graphics.setColor(1, 1, 1)
        local tw = fontMedium:getWidth(btn.label)
        love.graphics.print(btn.label, btn.x + (btn.w - tw) / 2, btn.y + 10)
    end
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Press ENTER to start", 430, 500)
end

function drawGameplay()
    utils.drawGrid()
    for _, e in ipairs(enemies) do
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.rectangle("fill", e.x, e.y, e.w, e.h)
    end
    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 1, 0.3)
        love.graphics.circle("fill", b.x, b.y, 3)
    end
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
    -- HUD
    drawBar(10, 10, 200, 16, player.hp / player.maxHp, {0.2, 0.8, 0.2})
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. fmt(player.hp), 215, 12)
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.print("SCORE: " .. score, 800, 10)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("[P] Pause  [ESC] Back", 10, 745)
end

function drawPauseOverlay()
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 1024, 768)
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("PAUSED", 460, 350)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Press P to resume  |  ESC to quit to title", 370, 390)
end

function drawGameOverOverlay()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 1024, 768)
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.print("GAME OVER", 440, 300)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 460, 340)
    love.graphics.print("Time: " .. fmt(gameTime, 1) .. "s", 460, 370)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("ENTER to restart  |  ESC for title", 370, 420)
end

return M
