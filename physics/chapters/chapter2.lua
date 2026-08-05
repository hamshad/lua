-- ============================================================
-- CHAPTER 2: Newton's Laws — F = ma in the Game Loop
-- ============================================================
-- The full physics pipeline every frame:
--   1. Collect forces (gravity, drag, spring)
--   2. Acceleration: a = F/m
--   3. Velocity:     v = v + a*dt   (semi-implicit Euler)
--   4. Position:     p = p + v*dt
--
-- Dummy walkthrough (one frame, dt = 1/60, m = 2.0 kg):
--   Gravity: F = m*g = 2.0 * 294.3 = 588.6 N downward
--   a = 588.6/2.0 = 294.3 px/s²,  vy = 0 + 294.3*(1/60) = 4.9
--   y = 100 + 4.9*(1/60) = 100.08
--   After 1s: vy ≈ 294.3, y ≈ 247
--
-- Drag:   F_drag = -k*|v|*v  (k=0.005, |v|=100 → -50 N)
-- Spring: F_spring = -k*x    (Hooke's law, k=50, x=100 → -5000 N)
--
-- KEYS: G toggle gravity, D toggle drag, S toggle spring
-- MOUSE: click to teleport the ball (stops it)

local utils = require("utils")
local fmt = utils.fmt
local drawVector = utils.drawVector
local drawTextBox = utils.drawTextBox

local M = {}

local GRAVITY = 9.81 * 30  -- pixels/s²
local ball = {}
local forces = {}
local trail = {}
local dtLog = {}

function M.init()
    world = love.physics.newWorld(0, GRAVITY, true)

    ball = {
        x = 100, y = 100,
        vx = 0, vy = 0,
        mass = 2.0,
        radius = 12,
    }

    forces = {gravity = true, drag = true, spring = false}
    trail = {}
    dtLog = {}
end

function M.update()
    local b = ball
    local dt = FIXED_DT  -- 1/60 s per physics step

    -- ============================================================
    -- STEP 1: COLLECT FORCES (the "F" in F=ma)
    -- ============================================================
    local fx, fy = 0, 0

    -- Gravity: F = m*g. Always points down (+y in LÖVE).
    if forces.gravity then
        fy = fy + b.mass * GRAVITY
    end

    -- Air drag: F = -k*|v|*v, opposes motion.
    -- At terminal velocity, drag equals gravity and a = 0.
    if forces.drag then
        local speed = math.sqrt(b.vx^2 + b.vy^2)
        if speed > 0.1 then
            local k = 0.005
            local drag = k * speed * speed
            fx = fx - drag * (b.vx / speed)
            fy = fy - drag * (b.vy / speed)
        end
    end

    -- Spring (Hooke's Law): F = -k*x, pulls back toward rest.
    if forces.spring then
        local k = 50
        local restY = 400
        local displacement = b.y - restY
        fy = fy - k * displacement
    end

    -- ============================================================
    -- STEP 2: ACCELERATION  a = F/m
    -- ============================================================
    local ax = fx / b.mass
    local ay = fy / b.mass

    -- ============================================================
    -- STEP 3: UPDATE VELOCITY (semi-implicit Euler)
    -- ============================================================
    -- "Semi-implicit" = use the NEW velocity for position. This is
    -- a symplectic integrator: it conserves energy for oscillation.
    b.vx = b.vx + ax * dt
    b.vy = b.vy + ay * dt

    -- ============================================================
    -- STEP 4: UPDATE POSITION
    -- ============================================================
    b.x = b.x + b.vx * dt
    b.y = b.y + b.vy * dt

    -- ============================================================
    -- COLLISION RESPONSE (simple ground/wall/ceiling)
    -- ============================================================
    if b.y + b.radius > 700 then
        b.y = 700 - b.radius
        b.vy = -b.vy * 0.7  -- restitution
        b.vx = b.vx * 0.98  -- friction
    end
    if b.x - b.radius < 10 then b.x = 10 + b.radius; b.vx = math.abs(b.vx) * 0.7 end
    if b.x + b.radius > 1014 then b.x = 1014 - b.radius; b.vx = -math.abs(b.vx) * 0.7 end
    if b.y - b.radius < 40 then b.y = 40 + b.radius; b.vy = math.abs(b.vy) * 0.7 end

    -- Record trail (fading line of past positions)
    table.insert(trail, {b.x, b.y})
    if #trail > 300 then table.remove(trail, 1) end

    -- Log this frame's state for the live panel
    table.insert(dtLog, {
        t = #dtLog * dt,
        x = b.x, y = b.y,
        vx = b.vx, vy = b.vy,
        ax = ax, ay = ay,
        fx = fx, fy = fy,
        ke = 0.5 * b.mass * (b.vx^2 + b.vy^2),
        pe = b.mass * GRAVITY * (700 - b.y),
    })
    if #dtLog > 200 then table.remove(dtLog, 1) end
end

function M.draw()
    local b = ball

    -- Ground
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, 700, 1024, 68)

    -- Trail
    if #trail > 1 then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        for i = 1, #trail - 1 do
            love.graphics.line(trail[i][1], trail[i][2], trail[i+1][1], trail[i+1][2])
        end
    end

    -- Ball
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.circle("fill", b.x, b.y, b.radius)
    love.graphics.setColor(1, 1, 1)

    -- Velocity vector (green), scaled 0.05 to fit the screen
    drawVector(b.x, b.y, b.vx * 0.05, b.vy * 0.05, 1, {0, 1, 0})

    -- Gravity force (blue)
    if forces.gravity then
        drawVector(b.x, b.y, 0, 20, 1, {0, 0, 1})
        love.graphics.setColor(0, 0, 1)
        love.graphics.print("F_g = m*g = " .. fmt(b.mass) .. " * 9.81*30 = " .. fmt(b.mass * GRAVITY), b.x + 25, b.y - 10)
    end

    -- Spring force (yellow)
    if forces.spring then
        local disp = b.y - 400
        local springF = -50 * disp
        drawVector(b.x, b.y, 0, springF * 0.01, 1, {1, 1, 0})
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("F_s = -k*x = -50 * " .. fmt(disp) .. " = " .. fmt(springF), b.x + 25, b.y + 10)
    end

    -- Drag force (orange)
    if forces.drag then
        local speed = math.sqrt(b.vx^2 + b.vy^2)
        if speed > 0.1 then
            local drag = 0.005 * speed * speed
            local dx = -drag * (b.vx / speed) * 0.01
            local dy = -drag * (b.vy / speed) * 0.01
            drawVector(b.x, b.y, dx, dy, 1, {1, 0.5, 0})
            love.graphics.setColor(1, 0.5, 0)
            love.graphics.print("F_d = -k*|v|*v = -0.005 * " .. fmt(speed) .. "² = " .. fmt(drag), b.x + 25, b.y + 25)
        end
    end

    -- Live values panel
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 400, 200, "", {0, 0, 0, 0.8})

    -- a = F/m recomputed for display
    local ax, ay = 0, 0
    if forces.gravity then ay = ay + GRAVITY end
    if forces.drag then
        local speed = math.sqrt(b.vx^2 + b.vy^2)
        if speed > 0.1 then
            local drag = 0.005 * speed * speed
            ax = ax - drag * (b.vx / speed) / b.mass
            ay = ay - drag * (b.vy / speed) / b.mass
        end
    end
    if forces.spring then
        ay = ay - 50 * (b.y - 400) / b.mass
    end

    local netFx, netFy = 0, 0
    if forces.gravity then netFy = netFy + b.mass * GRAVITY end
    if forces.drag then
        local speed = math.sqrt(b.vx^2 + b.vy^2)
        if speed > 0.1 then
            local drag = 0.005 * speed * speed
            netFx = netFx - drag * (b.vx / speed)
            netFy = netFy - drag * (b.vy / speed)
        end
    end
    if forces.spring then netFy = netFy - 50 * (b.y - 400) end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES (semi-implicit Euler)", px + 5, py + 2)
    love.graphics.print("Position:  (" .. fmt(b.x) .. ", " .. fmt(b.y) .. ")", px + 5, py + 18)
    love.graphics.print("Velocity:  (" .. fmt(b.vx) .. ", " .. fmt(b.vy) .. ")  |v| = " .. fmt(math.sqrt(b.vx^2 + b.vy^2)), px + 5, py + 34)
    love.graphics.print("Acceleration: (" .. fmt(ax) .. ", " .. fmt(ay) .. ")", px + 5, py + 50)
    love.graphics.print("Net Force: (" .. fmt(netFx) .. ", " .. fmt(netFy) .. ")", px + 5, py + 66)
    love.graphics.print("Kinetic Energy:  KE = ½ * " .. b.mass .. " * |v|² = " .. fmt(0.5 * b.mass * (b.vx^2 + b.vy^2)), px + 5, py + 82)
    love.graphics.print("Potential Energy: PE = mgh = " .. fmt(b.mass * GRAVITY * (700 - b.y)), px + 5, py + 98)
    love.graphics.print("Total Energy:    E = KE + PE = " .. fmt(0.5 * b.mass * (b.vx^2 + b.vy^2) + b.mass * GRAVITY * (700 - b.y)), px + 5, py + 114)
    love.graphics.print("Momentum: p = m*v = " .. fmt(b.mass) .. " * (" .. fmt(b.vx) .. ", " .. fmt(b.vy) .. ")", px + 5, py + 130)

    -- Feynman explanation
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: F = ma is the engine of all physics. Every frame, we sum forces, divide by mass,", px, py + 150)
    love.graphics.print("integrate to get velocity, integrate again to get position. Semi-implicit (symplectic) Euler", px, py + 164)
    love.graphics.print("updates velocity BEFORE position, preserving energy for oscillations (see Appendix D.3, D.4).", px, py + 178)

    -- Controls hint
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("SPACE=reset  G=toggle gravity  D=toggle drag  S=toggle spring", 10, 680)
    love.graphics.setColor(1, 1, 1)
end

function M.mousepressed(x, y, button)
    -- Click to teleport the ball and stop it.
    if button == 1 then
        ball.x = x
        ball.y = y
        ball.vx = 0
        ball.vy = 0
    end
end

function M.keypressed(key)
    if key == "g" then forces.gravity = not forces.gravity end
    if key == "d" then forces.drag = not forces.drag end
    if key == "s" then forces.spring = not forces.spring end
end

return M
