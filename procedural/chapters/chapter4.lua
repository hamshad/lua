-- ============================================================
-- CHAPTER 4: Damping and Springs — Following Targets
-- ============================================================
-- The workhorse of procedural animation is not the timeline; it is
-- CHASING. Every frame you nudge a value toward a target. Done with
-- the right formula it is frame-rate independent and never overshoots:
--
--   value += (target - value) * (1 - exp(-λ * dt))
--
-- λ (lambda) is the chase rate. Bigger λ = tighter follow.
--   λ ≈ 8   rubbery, laggy — tails, weight, slowness
--   λ ≈ 20  responsive   — camera, aim-assist
--   λ ≈ 60  snappy       — recoil returns, snap-back
--
-- A TRUE spring (bottom) keeps momentum, so it can OVERSHOOT and
-- oscillate. Same target, very different character.
--
-- Two balls chase the mouse: TOP uses damp() (critically damped),
-- BOTTOM uses a mass-spring (underdamped). Arrows switch λ presets.

local utils = require("utils")
local fmt = utils.fmt
local lerp = utils.lerp
local clamp = utils.clamp
local drawTextBox = utils.drawTextBox

local M = {}

local target = {x = 700, y = 250}

local damped = {x = 200, y = 250}
local spring = {x = 200, y = 550, vx = 0, vy = 0}
local lambda = 12.0

local presets = {8, 12, 20, 60}
local presetIdx = 2

local k = 45.0    -- spring stiffness
local c = 4.0     -- spring damping (momentum retained → overshoot)

function M.init()
    damped = {x = 200, y = 250}
    spring = {x = 200, y = 550, vx = 0, vy = 0}
    lambda = 12.0
    presetIdx = 2
end

function M.update(dt)
    -- Critically damped chase: exponential, no overshoot.
    damped.x = utils.damp(damped.x, target.x, lambda, dt)
    damped.y = utils.damp(damped.y, target.y, lambda, dt)

    -- Mass-spring: F = k*(target-pos) - c*vel, integrate.
    local ax = k * (target.x - spring.x) - c * spring.vx
    local ay = k * (target.y - spring.y) - c * spring.vy
    spring.vx = spring.vx + ax * dt
    spring.vy = spring.vy + ay * dt
    spring.x = spring.x + spring.vx * dt
    spring.y = spring.y + spring.vy * dt
end

function M.mousepressed(x, y, button)
    if button == 1 then target.x, target.y = x, y end
end

function M.keypressed(key)
    if key == "right" then
        presetIdx = (presetIdx % #presets) + 1
        lambda = presets[presetIdx]
    elseif key == "left" then
        presetIdx = presetIdx - 1
        if presetIdx < 1 then presetIdx = #presets end
        lambda = presets[presetIdx]
    end
end

function M.draw()
    utils.drawGrid()

    -- Target
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("line", target.x, target.y, 10)
    love.graphics.circle("fill", target.x, target.y, 3)

    -- Damped ball (critically damped)
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.circle("fill", damped.x, damped.y, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    love.graphics.print("damp()   critically damped — no overshoot", 60, 160)
    love.graphics.print("λ = " .. fmt(lambda) .. "   gap = " .. fmt(math.sqrt((damped.x - target.x)^2 + (damped.y - target.y)^2)), 60, 176)

    -- Spring ball (underdamped — overshoots)
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.circle("fill", spring.x, spring.y, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("mass-spring  k=" .. fmt(k) .. " c=" .. fmt(c) .. " — overshoots & rings", 60, 460)
    love.graphics.print("gap = " .. fmt(math.sqrt((spring.x - target.x)^2 + (spring.y - target.y)^2)), 60, 476)

    -- Approach curve sketch: exponential decay of the gap
    love.graphics.setColor(0.3, 0.6, 1)
    local pts = {}
    for i = 0, 60 do
        local dtc = i / 60
        table.insert(pts, 700 + i * 4)
        table.insert(pts, 100 + 150 * math.exp(-lambda * dtc))
    end
    love.graphics.line(pts)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("gap decay 100→0 over time, λ=" .. fmt(lambda), 700, 70)

    drawTextBox(10, 620, 1000, 110, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 622)
    love.graphics.print("λ preset: " .. presetIdx .. "/" .. #presets .. "  (" .. lambda .. ")   [LEFT/RIGHT] switch", 15, 638)
    love.graphics.print("damped gap = " .. fmt(math.sqrt((damped.x - target.x)^2 + (damped.y - target.y)^2)) .. " px", 15, 654)
    love.graphics.print("spring gap  = " .. fmt(math.sqrt((spring.x - target.x)^2 + (spring.y - target.y)^2)) .. " px", 15, 670)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: 1-exp(-λdt) makes the chase rate INDEPENDENT of frame rate — λ=12 looks", 15, 720)
    love.graphics.print("identical at 30fps and 600fps. A spring remembers its velocity, so it overshoots;", 15, 734)
    love.graphics.print("damp() forgets it, so it cannot. Games choose: cameras damp, physics bob springs.", 15, 748)
end

return M