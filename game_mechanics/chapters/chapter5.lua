-- ============================================================
-- CHAPTER 5: Scoring and Progression — Why Points Matter
-- ============================================================
-- Points are the language of reward. This chapter builds a
-- scoring system: collectibles give points, combo multipliers
-- reward skill, and the score persists across deaths.
--
-- INTERACTION: move with arrow keys, collect the yellow orbs.
-- Collect quickly for combo multipliers. Press R to reset.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox
local drawBar = utils.drawBar

local M = {}

local player = {x = 512, y = 384, w = 20, h = 20, speed = 220}
local orbs = {}
local score = 0
local combo = 1
local comboTimer = 0
local COMBO_WINDOW = 2.0
local totalCollected = 0

function spawnOrb()
    table.insert(orbs, {
        x = math.random(40, 980),
        y = math.random(40, 700),
        r = 10,
        alive = true,
        pulse = math.random() * math.pi * 2,
    })
end

function M.init()
    player = {x = 512, y = 384, w = 20, h = 20, speed = 220}
    orbs = {}
    score = 0
    combo = 1
    comboTimer = 0
    totalCollected = 0
    for i = 1, 12 do spawnOrb() end
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

    -- Combo timer counts down
    if comboTimer > 0 then
        comboTimer = comboTimer - dt
        if comboTimer <= 0 then
            combo = 1
        end
    end

    -- Collect orbs
    local pcx = player.x + player.w / 2
    local pcy = player.y + player.h / 2
    for i = #orbs, 1, -1 do
        local o = orbs[i]
        local dx2 = pcx - o.x
        local dy2 = pcy - o.y
        if dx2 * dx2 + dy2 * dy2 < (player.w / 2 + o.r) ^ 2 then
            -- Score: base 100 * combo multiplier
            local points = math.floor(100 * combo)
            score = score + points
            totalCollected = totalCollected + 1

            -- Combo increases, timer resets
            combo = math.min(combo + 1, 10)
            comboTimer = COMBO_WINDOW

            table.remove(orbs, i)
            spawnOrb()
        end
    end

    -- Pulse animation
    for _, o in ipairs(orbs) do
        o.pulse = o.pulse + dt * 3
    end
end

function M.keypressed(key)
    if key == "r" then
        score = 0
        combo = 1
        comboTimer = 0
    end
end

function M.draw()
    utils.drawGrid()

    -- Orbs with pulse
    for _, o in ipairs(orbs) do
        local scale = 1 + 0.15 * math.sin(o.pulse)
        local r = o.r * scale
        love.graphics.setColor(1, 0.9, 0.2)
        love.graphics.circle("fill", o.x, o.y, r)
        love.graphics.setColor(1, 1, 0.5)
        love.graphics.circle("fill", o.x, o.y, r * 0.5)
    end

    -- Player
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    -- Score display (top right)
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.print("SCORE: " .. score, 800, 10)

    -- Combo display
    if combo > 1 then
        love.graphics.setColor(1, 0.5, 0.1)
        love.graphics.print("COMBO x" .. combo, 800, 35)
    end

    -- Combo bar
    if comboTimer > 0 then
        drawBar(800, 60, 200, 8, comboTimer / COMBO_WINDOW, {1, 0.6, 0.1})
    end

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 400, 110, "", {0, 0, 0, 0.8})
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    love.graphics.print("score         = " .. score, px + 5, py + 18)
    love.graphics.print("combo         = x" .. combo, px + 5, py + 34)
    love.graphics.print("combo timer   = " .. fmt(comboTimer, 2) .. " / " .. COMBO_WINDOW, px + 5, py + 50)
    love.graphics.print("collected     = " .. totalCollected, px + 5, py + 66)
    love.graphics.print("[R] reset score", px + 5, py + 82)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: A combo is a countdown. Collect before time runs out or the", px, py + 104)
    love.graphics.print("multiplier resets. Simple timer + counter = the core of every scoring system.", px, py + 118)
end

return M
