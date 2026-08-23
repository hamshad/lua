-- ============================================================
-- CHAPTER 9: Particle Effects — Making Things Look Cool
-- ============================================================
-- Particles are tiny sprites that live for a short time, drift
-- with velocity, fade with alpha, and die. A particle emitter
-- is just a loop that creates them.
--
-- INTERACTION: click to explode. Move mouse to aim the emitter.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local particles = {}
local emitterX, emitterY = 512, 384
local emitTimer = 0
local emitRate = 0.02
local totalEmitted = 0

function emit(x, y, count, config)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = config.minSpeed + math.random() * (config.maxSpeed - config.minSpeed)
        local life = config.minLife + math.random() * (config.maxLife - config.minLife)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = life,
            maxLife = life,
            size = config.minSize + math.random() * (config.maxSize - config.minSize),
            color = config.color,
            gravity = config.gravity or 0,
        })
        totalEmitted = totalEmitted + 1
    end
end

function M.init()
    particles = {}
    emitterX, emitterY = 512, 384
    emitTimer = 0
    totalEmitted = 0
end

function M.update(dt)
    -- Continuous emitter follows mouse loosely
    local mx, my = love.mouse.getPosition()
    emitterX = utils.damp(emitterX, mx, 10, dt)
    emitterY = utils.damp(emitterY, my, 10, dt)

    -- Emit continuously
    emitTimer = emitTimer + dt
    while emitTimer >= emitRate do
        emitTimer = emitTimer - emitRate
        emit(emitterX, emitterY, 2, {
            minSpeed = 30, maxSpeed = 120,
            minLife = 0.3, maxLife = 1.2,
            minSize = 2, maxSize = 6,
            color = {1, 0.6, 0.1},
            gravity = 40,
        })
    end

    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            p.vy = p.vy + p.gravity * dt
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.size = p.size * 0.99
        end
    end
end

function M.mousepressed(x, y, button)
    if button == 1 then
        -- Burst explosion
        emit(x, y, 50, {
            minSpeed = 50, maxSpeed = 250,
            minLife = 0.5, maxLife = 2.0,
            minSize = 2, maxSize = 8,
            color = {1, 0.3, 0.2},
            gravity = 60,
        })
    elseif button == 2 then
        -- Fountain burst (upward)
        emit(x, y, 30, {
            minSpeed = 100, maxSpeed = 200,
            minLife = 0.8, maxLife = 1.5,
            minSize = 3, maxSize = 7,
            color = {0.2, 0.6, 1},
            gravity = 120,
        })
    end
end

function M.draw()
    utils.drawGrid()

    -- Particles (draw newest on top)
    for _, p in ipairs(particles) do
        local alpha = p.life / p.maxLife
        local r, g, b = p.color[1], p.color[2], p.color[3]
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end

    -- Emitter cursor
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.circle("line", emitterX, emitterY, 15)

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 400, 100, "", {0, 0, 0, 0.8})
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    love.graphics.print("active particles = " .. #particles, px + 5, py + 18)
    love.graphics.print("total emitted    = " .. totalEmitted, px + 5, py + 34)
    love.graphics.print("emit rate        = " .. fmt(1 / emitRate, 0) .. " /s", px + 5, py + 50)
    love.graphics.print("[LMB] explosion  [RMB] fountain  particles follow mouse", px + 5, py + 66)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: A particle is just a value with a death timer. Each frame:", px, py + 90)
    love.graphics.print("move it, shrink it, fade it, check if dead. That's the entire system.", px, py + 104)
end

return M
