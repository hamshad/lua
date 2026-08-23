-- ============================================================
-- CHAPTER 8: Spawning and Waves — Populating the Void
-- ============================================================
-- Games need to create things at the right time and place.
-- This chapter builds a wave system: enemies spawn in waves,
-- each wave harder than the last.
--
-- INTERACTION: arrow keys + click to shoot. Survive the waves.
-- Watch the wave counter and spawn timer.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox
local drawBar = utils.drawBar

local M = {}

local player = {x = 512, y = 500, w = 22, h = 22, hp = 100, maxHp = 100, speed = 220}
local enemies = {}
local bullets = {}
local cooldown = 0

local wave = 0
local enemiesRemaining = 0
local spawnTimer = 0
local spawnInterval = 1.0
local waveDelay = 0
local killCount = 0
local WAVE_BASE = 5
local WAVE_GROWTH = 3

function startWave()
    wave = wave + 1
    enemiesRemaining = WAVE_BASE + WAVE_GROWTH * (wave - 1)
    spawnInterval = math.max(0.3, 1.0 - wave * 0.05)
    spawnTimer = 0
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
        hp = 20 + wave * 5,
        maxHp = 20 + wave * 5,
        speed = 70 + math.random() * 40 + wave * 5,
    })
end

function M.init()
    player = {x = 512, y = 500, w = 22, h = 22, hp = 100, maxHp = 100, speed = 220}
    enemies = {}
    bullets = {}
    cooldown = 0
    wave = 0
    killCount = 0
    waveDelay = 1.0
    startWave()
end

function M.update(dt)
    -- Wave delay
    if waveDelay > 0 then
        waveDelay = waveDelay - dt
        return
    end

    -- Spawn enemies from current wave
    if enemiesRemaining > 0 then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnInterval then
            spawnTimer = spawnTimer - spawnInterval
            spawnEnemy()
            enemiesRemaining = enemiesRemaining - 1
        end
    end

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

    -- Enemies chase
    for _, e in ipairs(enemies) do
        local ecx, ecy = e.x + e.w / 2, e.y + e.h / 2
        local pcx, pcy = player.x + player.w / 2, player.y + player.h / 2
        local edx, edy = pcx - ecx, pcy - ecy
        local dist = math.sqrt(edx * edx + edy * edy)
        if dist > 0 then
            e.x = e.x + (edx / dist) * e.speed * dt
            e.y = e.y + (edy / dist) * e.speed * dt
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
                        killCount = killCount + 1
                    end
                    break
                end
            end
        end
    end

    -- Next wave?
    if enemiesRemaining == 0 and #enemies == 0 then
        waveDelay = 2.0
        startWave()
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
                vx = dx / len * 450, vy = dy / len * 450,
            })
            cooldown = 0.1
        end
    end
end

function M.draw()
    utils.drawGrid()

    -- Enemies
    for _, e in ipairs(enemies) do
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.rectangle("fill", e.x, e.y, e.w, e.h)
        drawBar(e.x, e.y - 6, e.w, 4, e.hp / e.maxHp, {1, 0.3, 0.3})
    end

    -- Player
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    -- Bullets
    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 1, 0.3)
        love.graphics.circle("fill", b.x, b.y, 3)
    end

    -- Wave indicator
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 0.5, 0.1)
    love.graphics.print("WAVE " .. wave, 460, 10)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("remaining: " .. enemiesRemaining + #enemies, 460, 35)

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 400, 100, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    love.graphics.print("wave            = " .. wave, px + 5, py + 18)
    love.graphics.print("enemies alive   = " .. #enemies, px + 5, py + 34)
    love.graphics.print("to spawn        = " .. enemiesRemaining, px + 5, py + 50)
    love.graphics.print("spawn interval  = " .. fmt(spawnInterval, 2) .. " s", px + 5, py + 66)
    love.graphics.print("kills           = " .. killCount, px + 5, py + 82)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: A wave is a queue of enemies + a timer. Timer hits zero,", px, py + 104)
    love.graphics.print("spawn one. Queue empty + all dead = next wave. That's the whole loop.", px, py + 118)
end

return M
