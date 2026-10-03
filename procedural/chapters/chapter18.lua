-- ============================================================
-- CHAPTER 18: Pendulums, Torque, and Orbits
-- ============================================================
-- A pendulum is gravity making torque: τ = -g/L·sin(θ). Small
-- swings tick like a clock (T ≈ 2π√(L/g)); big swings linger at
-- the edges. The orbiter is the same gravity turned sideways —
-- fall forever, miss forever. One law, clock and planet.
--
-- DRAG bob: throw it   SPACE: kick   [G]: gravity up/down
-- [O]: orbiter reset   UP/DOWN: rod length

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua.
local M = {}

-- Pendulum state: anchor, rod length L, angle th, angular vel w.
local ax, ay = 512, 180
local L, th, w = 260, 0.9, 0
-- grav: px/s². held: mouse dragging the bob.
local grav, held = 900, false
-- Orbiter: planet at p, ship s with velocity; trail history.
local planet = { x = 800, y = 520 }
local ship = { x = 800, y = 300, vx = 170, vy = 0, trail = {} }

-- bobPos(): the bob's pixels from the angle.
--   Example: th=0 → bob hangs straight down at (ax, ay+L).
local function bobPos()
    return ax + L * math.sin(th), ay + L * math.cos(th)
end

-- M.init(): hang right, park the orbiter for a near-circle.
function M.init()
    L, th, w, grav, held = 260, 0.9, 0, 900, false
    ship = { x = 800, y = 300, vx = 170, vy = 0, trail = {} }
end

-- M.update(dt): pendulum torque integrate + orbiter gravity.
function M.update(dt)
    if love.keyboard.isDown("up") then L = math.max(120, L - 120 * dt) end
    if love.keyboard.isDown("down") then L = math.min(420, L + 120 * dt) end
    if not held then
        -- Torque form: alpha = -(g/L)·sin(th). Semi-implicit Euler.
        --   Example: L=260, g=900, th=0.9 → alpha ≈ -2.71 rad/s².
        local alpha = -(grav / L) * math.sin(th)
        w, th = w + alpha * dt, th + w * dt
    end
    -- Orbiter: a = GM·r̂/r² toward planet. GM tuned for slow loop.
    local GM = 900 * 260 * 260 * 0.55
    local dx, dy = planet.x - ship.x, planet.y - ship.y
    local d2 = dx * dx + dy * dy
    local d = math.max(40, math.sqrt(d2))
    ship.vx, ship.vy = ship.vx + (GM * dx / (d * d2)) * dt, ship.vy + (GM * dy / (d * d2)) * dt
    ship.x, ship.y = ship.x + ship.vx * dt, ship.y + ship.vy * dt
    ship.trail[#ship.trail + 1] = { x = ship.x, y = ship.y }
    if #ship.trail > 220 then table.remove(ship.trail, 1) end
end

-- M.mousepressed: grab bob if near, else fling orbiter.
function M.mousepressed(x, y, button)
    if button ~= 1 then return end
    local bx, by = bobPos()
    if math.sqrt((x - bx) ^ 2 + (y - by) ^ 2) < 40 then held = true
    else ship.x, ship.y, ship.vx, ship.vy, ship.trail = x, y, 170, 0, {} end
end

function M.mousereleased(x, y, button)
    if button == 1 and held then
        -- Release: angle from cursor, velocity zeroed (clean throw = 0).
        held = false
        th = math.atan2(x - ax, y - ay)
        w = 0
    end
end

-- M.keypressed(key): kick, gravity presets, orbiter reset.
function M.keypressed(key)
    if key == " " then w = w + 1.6
    elseif key == "g" then grav = grav >= 900 and 300 or 900
    elseif key == "o" then ship = { x = 800, y = 300, vx = 170, vy = 0, trail = {} } end
end

-- M.draw(): rod + bob, energy bars, planet + orbit trail.
function M.draw()
    utils.drawGrid()
    if held then
        local mx, my = love.mouse.getPosition()
        th = math.atan2(mx - ax, my - ay)
    end
    local bx, by = bobPos()
    -- Rod + anchor + bob. Bob speed tints it: fast = hot.
    love.graphics.setColor(0.5, 0.5, 0.55)
    love.graphics.line(ax, ay, bx, by)
    love.graphics.setColor(0.7, 0.7, 0.75)
    love.graphics.circle("fill", ax, ay, 6)
    local speed = math.abs(w * L)
    love.graphics.setColor(0.4 + math.min(0.6, speed / 900), 0.65, 1)
    love.graphics.circle("fill", bx, by, 22)
    utils.drawVector(bx, by, w * L * math.cos(th), -w * L * math.sin(th), 0.12, {0.4, 1, 0.4})

    -- Energies: KE = ½(Lw)², PE = g·h above rest. Watch them trade.
    local h = L * (1 - math.cos(th))
    local ke, pe = 0.5 * (w * L) ^ 2, grav * h
    love.graphics.setColor(0.4, 1, 0.4)
    love.graphics.rectangle("fill", 60, 640, math.min(300, ke / 40), 12)
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.rectangle("fill", 60, 656, math.min(300, pe / 40), 12)

    -- Planet, orbiter, fading trail.
    love.graphics.setColor(1, 0.55, 0.25)
    love.graphics.circle("fill", planet.x, planet.y, 20)
    for j, t in ipairs(ship.trail) do
        love.graphics.setColor(0.5, 0.8, 1, j / #ship.trail * 0.8)
        love.graphics.circle("fill", t.x, t.y, 2)
    end
    love.graphics.setColor(0.6, 0.9, 1)
    love.graphics.circle("fill", ship.x, ship.y, 7)

    -- Theory period small-angle T = 2π√(L/g).
    local T = 2 * math.pi * math.sqrt(L / grav)
    love.graphics.setFont(fontSmall)
    drawTextBox(380, 620, 632, 100, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 385, 622)
    love.graphics.print("th=" .. fmt(math.deg(th), 0) .. "deg  w=" .. fmt(w, 2) .. "  L=" .. fmt(L, 0) .. "  T~" .. fmt(T, 2) .. "s", 385, 638)
    love.graphics.print("KE=" .. fmt(ke, 0) .. " (green)   PE=" .. fmt(pe, 0) .. " (yellow)", 385, 654)
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: torque is gravity with leverage. Pendulum swaps KE↔PE; orbiter never lands —", 10, 700)
    love.graphics.print("it falls around. Drag the bob, SPACE kicks, G changes gravity, CLICK rethrows the ship.", 10, 714)
end

return M
