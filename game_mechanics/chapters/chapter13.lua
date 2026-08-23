-- ============================================================
-- CHAPTER 13: Putting It All Together — A Complete Game
-- ============================================================
-- Everything from the previous chapters combined into one
-- playable game: movement, input, collision, health, scoring,
-- state machines, spawning, particles, power-ups, HUD, and
-- screen management.
--
-- INTERACTION: arrow keys to move, click to shoot, collect
-- green orbs, dodge red enemies, grab power-ups.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox
local drawBar = utils.drawBar

local M = {}

local gameState = "TITLE"
local stateStack = {}
local score = 0
local gameTime = 0
local killCount = 0
local wave = 0
local enemiesRemaining = 0
local spawnTimer = 0
local spawnInterval = 1.0
local waveDelay = 0

local player = {}
local bullets = {}
local cooldown = 0
local particles = {}
local damageNumbers = {}
local pickups = {}
local activeEffects = {}
local orbs = {}
local enemies = {}

local WORLD_W = 1024
local WORLD_H = 768
local WAVE_BASE = 4
local WAVE_GROWTH = 2

function pushState(s)
    table.insert(stateStack, gameState)
    gameState = s
end

function popState()
    if #stateStack > 0 then
        gameState = table.remove(stateStack)
    end
end

function emitParticles(x, y, count, color, speed, life)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = speed * (0.5 + math.random())
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = life * (0.5 + math.random() * 0.5),
            maxLife = life,
            size = 2 + math.random() * 3,
            color = color,
        })
    end
end

function addDamageNumber(x, y, text, color)
    table.insert(damageNumbers, {
        x = x, y = y, text = tostring(text),
        color = color or {1, 0.3, 0.3}, life = 1.0,
    })
end

function spawnEnemy()
    local side = math.random(1, 4)
    local x, y
    if side == 1 then x = -20; y = math.random(0, WORLD_H)
    elseif side == 2 then x = WORLD_W + 20; y = math.random(0, WORLD_H)
    elseif side == 3 then x = math.random(0, WORLD_W); y = -20
    else x = math.random(0, WORLD_W); y = WORLD_H + 20 end
    table.insert(enemies, {
        x = x, y = y, w = 20, h = 20,
        hp = 20 + wave * 5, maxHp = 20 + wave * 5,
        speed = 60 + math.random() * 40 + wave * 3,
        color = {0.8 + math.random() * 0.2, 0.2, 0.2},
    })
end

function startWave()
    wave = wave + 1
    enemiesRemaining = WAVE_BASE + WAVE_GROWTH * (wave - 1)
    spawnInterval = math.max(0.3, 1.0 - wave * 0.04)
    spawnTimer = 0
end

function spawnOrb()
    table.insert(orbs, {
        x = math.random(40, WORLD_W - 40),
        y = math.random(40, WORLD_H - 40),
        r = 8, pulse = math.random() * math.pi * 2,
    })
end

function spawnPickup()
    local types = {
        {type = "speed", color = {0.2, 1, 0.3}, duration = 5},
        {type = "heal", color = {1, 0.3, 0.3}, duration = 0},
    }
    local t = types[math.random(1, #types)]
    table.insert(pickups, {
        x = math.random(50, WORLD_W - 50),
        y = math.random(50, WORLD_H - 50),
        r = 10, type = t.type, color = t.color,
        duration = t.duration, pulse = 0,
    })
end

function resetGame()
    player = {
        x = WORLD_W / 2, y = WORLD_H / 2, w = 22, h = 22,
        hp = 100, maxHp = 100, speed = 220, baseSpeed = 220,
    }
    bullets = {}
    particles = {}
    damageNumbers = {}
    pickups = {}
    activeEffects = {}
    orbs = {}
    enemies = {}
    cooldown = 0
    score = 0
    gameTime = 0
    killCount = 0
    wave = 0
    enemiesRemaining = 0
    waveDelay = 1.5
    startWave()
    for i = 1, 5 do spawnOrb() end
    for i = 1, 3 do spawnPickup() end
end

function M.init()
    gameState = "TITLE"
    stateStack = {}
end

function M.update(dt)
    if gameState ~= "PLAYING" then return end
    gameTime = gameTime + dt

    if waveDelay > 0 then waveDelay = waveDelay - dt; return end

    if enemiesRemaining > 0 then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnInterval then
            spawnTimer = spawnTimer - spawnInterval
            spawnEnemy()
            enemiesRemaining = enemiesRemaining - 1
        end
    end

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
            player.hp = player.hp - 30 * dt
            if player.hp <= 0 then pushState("GAMEOVER") end
        end
    end

    if cooldown > 0 then cooldown = cooldown - dt end
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.y < -10 or b.x < -10 or b.x > WORLD_W + 10 then
            table.remove(bullets, i)
        else
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if utils.aabbOverlap(b.x - 3, b.y - 3, 6, 6, e.x, e.y, e.w, e.h) then
                    e.hp = e.hp - 10
                    table.remove(bullets, i)
                    addDamageNumber(e.x + e.w / 2, e.y, 15)
                    emitParticles(e.x + e.w / 2, e.y + e.h / 2, 5, {1, 0.5, 0.2}, 60, 0.5)
                    if e.hp <= 0 then
                        table.remove(enemies, j)
                        score = score + 100
                        killCount = killCount + 1
                        emitParticles(e.x + e.w / 2, e.y + e.h / 2, 15, {1, 0.3, 0.2}, 100, 0.8)
                    end
                    break
                end
            end
        end
    end

    local pcx = player.x + player.w / 2
    local pcy = player.y + player.h / 2
    for i = #orbs, 1, -1 do
        local o = orbs[i]
        local dx2, dy2 = pcx - o.x, pcy - o.y
        if dx2 * dx2 + dy2 * dy2 < (player.w / 2 + o.r) ^ 2 then
            score = score + 25
            emitParticles(o.x, o.y, 8, {0.3, 1, 0.3}, 50, 0.4)
            table.remove(orbs, i)
            spawnOrb()
        end
    end

    for i = #pickups, 1, -1 do
        local p = pickups[i]
        local dx2, dy2 = pcx - p.x, pcy - p.y
        if dx2 * dx2 + dy2 * dy2 < (player.w / 2 + p.r) ^ 2 then
            if p.type == "speed" then
                player.speed = player.baseSpeed * 2
                table.insert(activeEffects, {type = "speed", timer = p.duration, maxTimer = p.duration})
            elseif p.type == "heal" then
                player.hp = math.min(player.hp + 40, player.maxHp)
            end
            emitParticles(p.x, p.y, 12, p.color, 80, 0.6)
            table.remove(pickups, i)
            spawnPickup()
        end
    end

    for i = #activeEffects, 1, -1 do
        local e = activeEffects[i]
        e.timer = e.timer - dt
        if e.timer <= 0 then
            if e.type == "speed" then player.speed = player.baseSpeed end
            table.remove(activeEffects, i)
        end
    end

    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i)
        else p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt; p.size = p.size * 0.98 end
    end

    for i = #damageNumbers, 1, -1 do
        local d = damageNumbers[i]
        d.life = d.life - dt; d.y = d.y - 25 * dt
        if d.life <= 0 then table.remove(damageNumbers, i) end
    end

    for _, o in ipairs(orbs) do o.pulse = o.pulse + dt * 3 end
    for _, p in ipairs(pickups) do p.pulse = p.pulse + dt * 4 end

    if enemiesRemaining == 0 and #enemies == 0 then
        waveDelay = 2.0; startWave()
    end
end

function M.mousepressed(x, y, button)
    if button == 1 then
        if gameState == "TITLE" then
            if utils.pointInRect(x, y, 412, 380, 200, 40) then resetGame() end
        elseif gameState == "GAMEOVER" then
            if utils.pointInRect(x, y, 412, 430, 200, 40) then
                popState(); popState(); gameState = "TITLE"
            end
        elseif gameState == "PLAYING" and cooldown <= 0 then
            local pcx = player.x + player.w / 2
            local pcy = player.y
            local dx, dy = x - pcx, y - pcy
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0 then
                table.insert(bullets, {x = pcx, y = pcy, vx = dx / len * 400, vy = dy / len * 400})
                cooldown = 0.1
                emitParticles(pcx, pcy, 3, {1, 1, 0.5}, 40, 0.2)
            end
        end
    end
end

function M.keypressed(key)
    if key == "p" and gameState == "PLAYING" then pushState("PAUSED")
    elseif key == "p" and gameState == "PAUSED" then popState()
    elseif key == "escape" then
        if gameState == "PAUSED" then popState()
        elseif gameState == "PLAYING" then pushState("PAUSED") end
    elseif key == "return" then
        if gameState == "TITLE" then resetGame()
        elseif gameState == "GAMEOVER" then popState(); popState(); gameState = "TITLE" end
    end
end

function M.draw()
    if gameState == "TITLE" then drawTitle()
    elseif gameState == "PLAYING" then drawGame()
    elseif gameState == "PAUSED" then drawGame(); drawPause()
    elseif gameState == "GAMEOVER" then drawGame(); drawGameOver() end
end

function drawTitle()
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, 1024, 768)
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.print("CHAPTER 13: THE COMPLETE GAME", 280, 200)
    love.graphics.setFont(fontMedium)
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Movement + Input + Collision + Health + Scoring +", 270, 260)
    love.graphics.print("State Machines + Spawning + Particles + Power-ups +", 270, 285)
    love.graphics.print("HUD + Screen Management = A GAME", 340, 310)
    love.graphics.setColor(0.2, 0.4, 0.2)
    love.graphics.rectangle("fill", 412, 380, 200, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("START GAME", 455, 390)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Arrow keys + mouse  |  P: pause  |  ENTER: start", 330, 460)
end

function drawGame()
    love.graphics.setColor(0.06, 0.06, 0.08)
    love.graphics.rectangle("fill", 0, 0, 1024, 768)
    utils.drawGrid()
    for _, o in ipairs(orbs) do
        local s = 1 + 0.1 * math.sin(o.pulse)
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.circle("fill", o.x, o.y, o.r * s)
    end
    for _, p in ipairs(pickups) do
        local s = 1 + 0.1 * math.sin(p.pulse)
        love.graphics.setColor(p.color)
        love.graphics.circle("fill", p.x, p.y, p.r * s)
    end
    for _, e in ipairs(enemies) do
        love.graphics.setColor(e.color)
        love.graphics.rectangle("fill", e.x, e.y, e.w, e.h)
        drawBar(e.x, e.y - 6, e.w, 4, e.hp / e.maxHp, {1, 0.3, 0.3})
    end
    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 1, 0.3)
        love.graphics.circle("fill", b.x, b.y, 3)
    end
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
    for _, p in ipairs(particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    love.graphics.setFont(fontSmall)
    for _, d in ipairs(damageNumbers) do
        love.graphics.setColor(d.color[1], d.color[2], d.color[3], d.life)
        love.graphics.print(d.text, d.x, d.y)
    end
    drawBar(10, 10, 200, 16, player.hp / player.maxHp, {0.2, 0.8, 0.2})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. fmt(player.hp), 215, 12)
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.print("SCORE: " .. score, 430, 10)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 0.5, 0.1)
    love.graphics.print("WAVE " .. wave, 460, 35)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("[P] Pause  [ESC] Back", 10, 745)
end

function drawPause()
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 1024, 768)
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("PAUSED", 460, 350)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Press P to resume  |  ESC to quit to title", 370, 390)
end

function drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 1024, 768)
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.print("GAME OVER", 440, 300)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 460, 340)
    love.graphics.print("Wave: " .. wave .. "  Kills: " .. killCount, 410, 370)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 412, 430, 200, 40)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("BACK TO TITLE", 445, 440)
end

return M
