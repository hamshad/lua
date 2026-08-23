-- ============================================================
-- CHAPTER 4: Health, Damage, and Death — The Fragility of Digital Life
-- ============================================================
-- Every entity that can be hurt needs: current hp, max hp, a way
-- to take damage, and a way to die. This chapter shows the pattern
-- that every action RPG, shooter, and platformer uses.
--
-- INTERACTION: click to shoot enemies. Enemies chase you.
-- Watch HP bars drain. Enemies respawn when killed.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox
local drawBar = utils.drawBar

local M = {}

local player = {x = 512, y = 500, w = 24, h = 24, hp = 100, maxHp = 100, speed = 200}
local enemies = {}
local bullets = {}
local cooldown = 0
local killCount = 0

function spawnEnemy()
    local side = math.random(1, 4)
    local x, y
    if side == 1 then x = -30; y = math.random(0, 768)
    elseif side == 2 then x = 1054; y = math.random(0, 768)
    elseif side == 3 then x = math.random(0, 1024); y = -30
    else x = math.random(0, 1024); y = 798 end

    table.insert(enemies, {
        x = x, y = y, w = 22, h = 22,
        hp = 30, maxHp = 30,
        speed = 80 + math.random() * 60,
        color = {0.8 + math.random() * 0.2, 0.2, 0.2},
    })
end

function M.init()
    player = {x = 512, y = 500, w = 24, h = 24, hp = 100, maxHp = 100, speed = 200}
    enemies = {}
    bullets = {}
    cooldown = 0
    killCount = 0
    for i = 1, 5 do spawnEnemy() end
end

function M.update(dt)
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

    -- Enemies chase player
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        local ecx = e.x + e.w / 2
        local ecy = e.y + e.h / 2
        local pcx = player.x + player.w / 2
        local pcy = player.y + player.h / 2
        local edx = pcx - ecx
        local edy = pcy - ecy
        local dist = math.sqrt(edx * edx + edy * edy)
        if dist > 0 then
            e.x = e.x + (edx / dist) * e.speed * dt
            e.y = e.y + (edy / dist) * e.speed * dt
        end

        -- Enemy damages player on contact
        if utils.aabbOverlap(player.x, player.y, player.w, player.h, e.x, e.y, e.w, e.h) then
            player.hp = player.hp - 30 * dt
            if player.hp <= 0 then
                player.hp = 0
                player.x = 512; player.y = 500
                player.hp = player.maxHp
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
            -- Bullet vs enemies
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if utils.aabbOverlap(b.x - 3, b.y - 3, 6, 6, e.x, e.y, e.w, e.h) then
                    e.hp = e.hp - 10
                    table.remove(bullets, i)
                    if e.hp <= 0 then
                        table.remove(enemies, j)
                        killCount = killCount + 1
                        spawnEnemy()
                    end
                    break
                end
            end
        end
    end

    -- Respawn if all dead
    if #enemies == 0 then
        for i = 1, 5 do spawnEnemy() end
    end
end

function M.mousepressed(x, y, button)
    if button == 1 and cooldown <= 0 then
        local pcx = player.x + player.w / 2
        local pcy = player.y
        local dx, dy = x - pcx, y - pcy
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            table.insert(bullets, {
                x = pcx, y = pcy,
                vx = dx / len * 400,
                vy = dy / len * 400,
            })
            cooldown = 0.12
        end
    end
end

function M.draw()
    utils.drawGrid()

    -- Enemies with HP bars
    for _, e in ipairs(enemies) do
        love.graphics.setColor(e.color)
        love.graphics.rectangle("fill", e.x, e.y, e.w, e.h)
        -- HP bar above enemy
        drawBar(e.x, e.y - 8, e.w, 5, e.hp / e.maxHp, {1, 0.2, 0.2})
    end

    -- Player
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    -- Player HP bar
    drawBar(10, 10, 200, 16, player.hp / player.maxHp, {0.2, 0.8, 0.2})

    -- Bullets
    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 1, 0.3)
        love.graphics.circle("fill", b.x, b.y, 3)
    end

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 380, 100, "", {0, 0, 0, 0.8})
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    love.graphics.print("player hp  = " .. fmt(player.hp) .. " / " .. player.maxHp, px + 5, py + 18)
    love.graphics.print("enemies    = " .. #enemies, px + 5, py + 34)
    love.graphics.print("kills      = " .. killCount, px + 5, py + 50)
    love.graphics.print("bullets    = " .. #bullets, px + 5, py + 66)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: HP is just a number that goes down. Death is when it hits zero.", px, py + 90)
    love.graphics.print("The pattern: clamp hp to [0, maxHp], check <= 0 each frame.", px, py + 104)
end

return M
