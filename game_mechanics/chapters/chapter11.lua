-- ============================================================
-- CHAPTER 11: UI and HUD — Talking to the Player
-- ============================================================
-- The HUD is the player's window into the game state. This
-- chapter builds a complete HUD: HP bar, score, minimap,
-- tooltip, and damage numbers.
--
-- INTERACTION: arrow keys move, click to shoot. Watch the HUD
-- elements update in real time.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox
local drawBar = utils.drawBar

local M = {}

local player = {x = 512, y = 384, w = 22, h = 22, hp = 80, maxHp = 100, speed = 220}
local enemies = {}
local bullets = {}
local damageNumbers = {}
local cooldown = 0
local score = 0
local tooltip = {text = "Move with arrows, click to shoot!", timer = 5}

-- Minimap data
local WORLD_W = 1024
local WORLD_H = 768
local MINIMAP_SCALE = 0.12

function spawnEnemy()
    table.insert(enemies, {
        x = math.random(50, 970), y = math.random(50, 700),
        w = 18, h = 18, hp = 30, maxHp = 30, speed = 60,
    })
end

function addDamageNumber(x, y, amount, color)
    table.insert(damageNumbers, {
        x = x, y = y,
        text = "-" .. amount,
        color = color or {1, 0.3, 0.3},
        life = 1.0,
    })
end

function M.init()
    player = {x = 512, y = 384, w = 22, h = 22, hp = 80, maxHp = 100, speed = 220}
    enemies = {}
    bullets = {}
    damageNumbers = {}
    cooldown = 0
    score = 0
    tooltip = {text = "Move with arrows, click to shoot!", timer = 5}
    for i = 1, 6 do spawnEnemy() end
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
    player.x = utils.clamp(player.x, 0, WORLD_W - player.w)
    player.y = utils.clamp(player.y, 0, WORLD_H - player.h)

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
        -- Enemy damages player
        if utils.aabbOverlap(player.x, player.y, player.w, player.h, e.x, e.y, e.w, e.h) then
            player.hp = player.hp - 20 * dt
            if player.hp <= 0 then
                player.hp = player.maxHp
                player.x = 512; player.y = 384
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
                    e.hp = e.hp - 15
                    table.remove(bullets, i)
                    addDamageNumber(e.x + e.w / 2, e.y, 15)
                    if e.hp <= 0 then
                        table.remove(enemies, j)
                        score = score + 100
                        spawnEnemy()
                        addDamageNumber(e.x + e.w / 2, e.y - 10, "KILL", {1, 1, 0.3})
                    end
                    break
                end
            end
        end
    end

    -- Damage numbers
    for i = #damageNumbers, 1, -1 do
        local d = damageNumbers[i]
        d.life = d.life - dt
        d.y = d.y - 30 * dt
        if d.life <= 0 then table.remove(damageNumbers, i) end
    end

    -- Tooltip timer
    if tooltip.timer > 0 then tooltip.timer = tooltip.timer - dt end
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
                vx = dx / len * 400, vy = dy / len * 400,
            })
            cooldown = 0.12
        end
    end
end

function M.draw()
    utils.drawGrid()

    -- World objects
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

    -- Damage numbers (world space)
    love.graphics.setFont(fontSmall)
    for _, d in ipairs(damageNumbers) do
        local alpha = d.life
        if type(d.color) == "table" then
            love.graphics.setColor(d.color[1], d.color[2], d.color[3], alpha)
        else
            love.graphics.setColor(1, 1, 1, alpha)
        end
        love.graphics.print(d.text, d.x, d.y)
    end

    -- === HUD ELEMENTS (screen space) ===

    -- 1. HP Bar (top left)
    drawBar(10, 10, 200, 18, player.hp / player.maxHp, {0.2, 0.8, 0.2})
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. fmt(player.hp) .. " / " .. player.maxHp, 215, 12)

    -- 2. Score (top center)
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.print("SCORE: " .. score, 430, 10)

    -- 3. Minimap (top right)
    local mmx, mmy = 870, 10
    local mmw, mmh = 140, 100
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", mmx, mmy, mmw, mmh)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", mmx, mmy, mmw, mmh)
    -- Player on minimap
    love.graphics.setColor(0.3, 0.8, 1)
    local mpx = mmx + (player.x / WORLD_W) * mmw
    local mpy = mmy + (player.y / WORLD_H) * mmh
    love.graphics.rectangle("fill", mpx, mpy, 3, 3)
    -- Enemies on minimap
    love.graphics.setColor(1, 0.3, 0.3)
    for _, e in ipairs(enemies) do
        local mex = mmx + (e.x / WORLD_W) * mmw
        local mey = mmy + (e.y / WORLD_H) * mmh
        love.graphics.rectangle("fill", mex, mey, 2, 2)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("MAP", mmx + 55, mmy + mmh + 2)

    -- 4. Tooltip (bottom center, fades out)
    if tooltip.timer > 0 then
        local alpha = utils.clamp(tooltip.timer, 0, 1)
        love.graphics.setColor(1, 1, 0.5, alpha)
        love.graphics.setFont(fontMedium)
        local tw = fontMedium:getWidth(tooltip.text)
        love.graphics.print(tooltip.text, (1024 - tw) / 2, 730)
    end

    -- 5. Enemy count (bottom left)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Enemies: " .. #enemies, 10, 740)

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 400, 90, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    love.graphics.print("hp          = " .. fmt(player.hp) .. " / " .. player.maxHp, px + 5, py + 18)
    love.graphics.print("score       = " .. score, px + 5, py + 34)
    love.graphics.print("enemies     = " .. #enemies, px + 5, py + 50)
    love.graphics.print("dmg numbers = " .. #damageNumbers, px + 5, py + 66)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: A HUD is just numbers drawn on top of the game. HP bar = ratio.", px, py + 90)
    love.graphics.print("Minimap = tiny world. Damage number = text with a death timer.", px, py + 104)
end

return M
