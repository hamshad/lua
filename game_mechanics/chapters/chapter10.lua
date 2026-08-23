-- ============================================================
-- CHAPTER 10: Power-ups and Pickups — Tiny Rewards, Big Joy
-- ============================================================
-- Power-ups are items that temporarily change player properties.
-- This chapter shows the pattern: define an effect, apply it
-- with a timer, remove it when time expires.
--
-- INTERACTION: move with arrow keys, collect pickups.
-- Watch the active effects panel and timers count down.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox
local drawBar = utils.drawBar

local M = {}

local player = {
    x = 512, y = 384, w = 22, h = 22,
    speed = 200, baseSpeed = 200,
    hp = 100, maxHp = 100,
    color = {0.3, 0.8, 1},
    baseColor = {0.3, 0.8, 1},
}
local pickups = {}
local activeEffects = {}
local score = 0

local PICKUP_TYPES = {
    {type = "speed", color = {0.2, 1, 0.3}, label = "SPEED x2", duration = 5, effect = function(p) p.speed = p.baseSpeed * 2 end},
    {type = "heal", color = {1, 0.3, 0.3}, label = "HEAL +50", duration = 0, effect = function(p) p.hp = math.min(p.hp + 50, p.maxHp) end},
    {type = "shield", color = {0.2, 0.6, 1}, label = "SHIELD", duration = 8, effect = function(p) p.color = {0.4, 0.8, 1} end},
    {type = "mini", color = {1, 0.8, 0.2}, label = "MINI", duration = 6, effect = function(p) p.w = 12; p.h = 12 end},
}

function spawnPickup()
    local t = PICKUP_TYPES[math.random(1, #PICKUP_TYPES)]
    table.insert(pickups, {
        x = math.random(50, 970),
        y = math.random(50, 700),
        r = 12,
        type = t.type,
        color = t.color,
        label = t.label,
        duration = t.duration,
        effect = t.effect,
        pulse = math.random() * math.pi * 2,
    })
end

function applyEffect(pickup)
    pickup.effect(player)
    if pickup.duration > 0 then
        table.insert(activeEffects, {
            type = pickup.type,
            timer = pickup.duration,
            maxTimer = pickup.duration,
            label = pickup.label,
        })
    end
end

function M.init()
    player = {
        x = 512, y = 384, w = 22, h = 22,
        speed = 200, baseSpeed = 200,
        hp = 100, maxHp = 100,
        color = {0.3, 0.8, 1},
        baseColor = {0.3, 0.8, 1},
    }
    pickups = {}
    activeEffects = {}
    score = 0
    for i = 1, 8 do spawnPickup() end
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

    -- Collect pickups
    local pcx = player.x + player.w / 2
    local pcy = player.y + player.h / 2
    for i = #pickups, 1, -1 do
        local p = pickups[i]
        local dx2 = pcx - p.x
        local dy2 = pcy - p.y
        if dx2 * dx2 + dy2 * dy2 < (player.w / 2 + p.r) ^ 2 then
            applyEffect(p)
            score = score + 50
            table.remove(pickups, i)
            spawnPickup()
        end
    end

    -- Tick down active effects
    for i = #activeEffects, 1, -1 do
        local e = activeEffects[i]
        e.timer = e.timer - dt
        if e.timer <= 0 then
            -- Remove effect: restore defaults
            if e.type == "speed" then player.speed = player.baseSpeed end
            if e.type == "shield" then player.color = player.baseColor end
            if e.type == "mini" then player.w = 22; player.h = 22 end
            table.remove(activeEffects, i)
        end
    end

    -- Pulse pickups
    for _, p in ipairs(pickups) do
        p.pulse = p.pulse + dt * 4
    end
end

function M.draw()
    utils.drawGrid()

    -- Pickups
    for _, p in ipairs(pickups) do
        local s = 1 + 0.1 * math.sin(p.pulse)
        love.graphics.setColor(p.color)
        love.graphics.circle("fill", p.x, p.y, p.r * s)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontSmall)
        love.graphics.print(p.label, p.x - 20, p.y + p.r + 4)
    end

    -- Player
    love.graphics.setColor(player.color)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    -- Active effects (top right)
    love.graphics.setFont(fontSmall)
    for i, e in ipairs(activeEffects) do
        love.graphics.setColor(1, 1, 0.3)
        love.graphics.print(e.label .. " " .. fmt(e.timer, 1) .. "s", 800, 10 + (i - 1) * 18)
        drawBar(800, 10 + (i - 1) * 18 + 14, 180, 4, e.timer / e.maxTimer, {0.3, 1, 0.3})
    end

    -- Score
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.print("SCORE: " .. score, 10, 10)

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 400, 110, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    love.graphics.print("speed      = " .. fmt(player.speed) .. " (base: " .. player.baseSpeed .. ")", px + 5, py + 18)
    love.graphics.print("hp         = " .. fmt(player.hp) .. " / " .. player.maxHp, px + 5, py + 34)
    love.graphics.print("effects    = " .. #activeEffects, px + 5, py + 50)
    love.graphics.print("pickups    = " .. #pickups, px + 5, py + 66)
    love.graphics.print("[ARROW] move  collect the glowing orbs", px + 5, py + 82)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: A power-up is just: set a timer, change a property, restore", px, py + 104)
    love.graphics.print("when the timer hits zero. Duration = timer. Effect = assignment.", px, py + 118)
end

return M
