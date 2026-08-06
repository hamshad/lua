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

-- M: the module table exported to main.lua.
local M = {}

-- target: the point both balls chase. Moved by clicking the mouse.
--   Example: click at (400, 300) → target = {x=400, y=300}.
local target = {x = 700, y = 250}

-- damped: the critically-damped ball's position. It uses utils.damp,
-- so it approaches the target smoothly and NEVER overshoots.
--   Example: damped = {x=200, y=250} at rest; target moves right →
--            it glides after, always on the near side of the target.
local damped = {x = 200, y = 250}

-- spring: the mass-spring ball's state. Besides position it keeps a
-- VELOCITY (vx, vy), which is what lets it overshoot and ring.
--   Example: after overshooting, spring.vx stays positive a moment,
--            pulling it past the target before the damping drags it back.
local spring = {x = 200, y = 550, vx = 0, vy = 0}

-- lambda: the current chase rate (1/seconds) for the damped ball.
--   Example: lambda=20 → the gap closes to 99% in about 5/20 = 0.25 s.
local lambda = 12.0

-- presets: the lambda values you can cycle through with the arrows.
-- presets[presetIdx] is the active one.
local presets = {8, 12, 20, 60}
local presetIdx = 2

-- k: spring stiffness — how hard the spring pulls toward the target.
--   Example: k=45 → a 100-px displacement pulls with F = 4500.
local k = 45.0
-- c: spring damping — the force opposing velocity. LOW c (like 4)
-- keeps the spring underdamped, so it oscillates instead of settling.
--   Example: c=4 → at v=50 the opposing force is -200; small enough
--            to let the ball carry past the target.
local c = 4.0

-- M.init(): reset both balls, lambda, and the preset index.
function M.init()
    damped = {x = 200, y = 250}
    spring = {x = 200, y = 550, vx = 0, vy = 0}
    lambda = 12.0
    presetIdx = 2
end

-- M.update(dt): step both chase styles one fixed step.
function M.update(dt)
    -- Critically damped chase: no velocity state, so no overshoot.
    --   Example: x=200, target=700, λ=12, dt=1/60
    --            1 - exp(-12/60) = 0.1813 → x = 200 + 500·0.1813 = 290.6
    damped.x = utils.damp(damped.x, target.x, lambda, dt)
    damped.y = utils.damp(damped.y, target.y, lambda, dt)

    -- Mass-spring: F = k·(target - pos) - c·vel, then integrate.
    --   ax: horizontal acceleration this step.
    --   Example: x=200, vx=0, target=700 → ax = 45·500 - 4·0 = 22500
    --            vx becomes 22500/60 = 375; x becomes 200 + 375/60 = 206.3.
    local ax = k * (target.x - spring.x) - c * spring.vx
    local ay = k * (target.y - spring.y) - c * spring.vy
    spring.vx = spring.vx + ax * dt
    spring.vy = spring.vy + ay * dt
    spring.x = spring.x + spring.vx * dt
    spring.y = spring.y + spring.vy * dt
end

-- M.mousepressed(x, y, button): move the shared target to the click.
function M.mousepressed(x, y, button)
    if button == 1 then target.x, target.y = x, y end
end

-- M.keypressed(key): LEFT/RIGHT cycle the lambda preset (with wrap).
--   Example: presetIdx=2 → press RIGHT → 3 → lambda = 20.
function M.keypressed(key)
    if key == "right" then
        presetIdx = (presetIdx % #presets) + 1   -- wrap forward
        lambda = presets[presetIdx]
    elseif key == "left" then
        presetIdx = presetIdx - 1
        if presetIdx < 1 then presetIdx = #presets end  -- wrap backward
        lambda = presets[presetIdx]
    end
end

-- M.draw(): render the grid, target, both balls, the approach-curve
-- sketch, and the live values panel.
function M.draw()
    utils.drawGrid()

    -- Target: ring + dot at the click point.
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("line", target.x, target.y, 10)
    love.graphics.circle("fill", target.x, target.y, 3)

    -- Damped ball (blue) + its readouts.
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.circle("fill", damped.x, damped.y, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    love.graphics.print("damp()   critically damped — no overshoot", 60, 160)
    love.graphics.print("λ = " .. fmt(lambda) .. "   gap = " .. fmt(math.sqrt((damped.x - target.x)^2 + (damped.y - target.y)^2)), 60, 176)

    -- Spring ball (orange) + its readouts.
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.circle("fill", spring.x, spring.y, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("mass-spring  k=" .. fmt(k) .. " c=" .. fmt(c) .. " — overshoots & rings", 60, 460)
    love.graphics.print("gap = " .. fmt(math.sqrt((spring.x - target.x)^2 + (spring.y - target.y)^2)), 60, 476)

    -- Approach-curve sketch: plots the theoretical gap decay of the
    -- damped chase, 100 → 0, against time at the current λ.
    --   Example: λ=12, t=0.25 s → gap = 100·exp(-12·0.25) = 4.98.
    love.graphics.setColor(0.3, 0.6, 1)
    local pts = {}
    for i = 0, 60 do
        local dtc = i / 60        -- time in seconds, 0..1
        table.insert(pts, 700 + i * 4)                -- x across the screen
        table.insert(pts, 100 + 150 * math.exp(-lambda * dtc))  -- y = shrinking gap
    end
    love.graphics.line(pts)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("gap decay 100→0 over time, λ=" .. fmt(lambda), 700, 70)

    -- Live values panel.
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