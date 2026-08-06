-- ============================================================
-- CHAPTER 7: Angles, Look-At, and Aiming
-- ============================================================
-- Aiming is a GAME MECHANIC, not just drawing. The core math is one
-- line: the angle from a point to the mouse is atan2(dy, dx).
--
-- This turret shows three lessons at once:
--   1. Facing: barrel angle = atan2(target - position)
--   2. Constraint: real turrets cannot spin freely — clamp the
--      angle into a cone of allowed fire.
--   3. Weight: a springy aim that lags behind the target feels
--      like a heavy machine, not a laser pointer.
--
-- MOUSE: aim   [C] toggle cone constraint   [S] toggle lag

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua.
local M = {}

-- aim: the point the turret is trying to aim at (the mouse).
--   Example: mouse at (600, 300) → aim = {x=600, y=300}.
local aim = { x = 0, y = 0 }

-- base: the turret's pivot (its center of rotation), in pixels.
-- The barrel spins around this point.
local base = { x = 512, y = 560 }

-- angle: the barrel's CURRENT aim angle, in radians from +x axis.
--   Example: angle = -π/2 → pointing straight up.
local angle = 0.0
-- barrel: the springy barrel's rotation state.
--   x, y:   redundant copy of the pivot (kept for clarity).
--   v:      angular velocity (rad/s) — the memory that causes lag.
--   Example: chasing a fast target, barrel.v stays large so the
--            barrel swings PAST the target before settling back.
local barrel = { x = 512, y = 560, v = 0 }
-- constraintOn: whether the cone clamp is active. When off, the
-- barrel spins freely through the body (correct math, wrong design).
local constraintOn = true
-- lagOn: whether the springy lag is active. When off, the barrel
-- snaps instantly to the target (a weightless laser pointer).
local lagOn = true
-- errorDeg: the current aim error in degrees — how far the actual
-- barrel is from where it wants to be. The space where skill lives.
--   Example: perfectly aimed → 0; swinging → 12.4.
local errorDeg = 0.0

-- CONE_HALF: half the width of the allowed firing cone, in radians.
-- ±70° means the barrel may swing 70° either side of straight up.
local CONE_HALF = math.rad(70)

-- clampToCone(a): pull an arbitrary angle into the cone centered on
-- "up" (-90° = -π/2). Wraps the difference into [-π, π] first so the
-- clamp works across the 0/2π seam.
--   Example: a = -160° → diff = -160 - (-90) = -70° → allowed (edge).
--            a = -180° → diff = -90° → clamped to -70° off center.
local function clampToCone(a)
    local center = -math.pi / 2
    -- diff: the wrapped offset of a from center, in [-π, π].
    local diff = (a - center + math.pi) % (2 * math.pi) - math.pi
    return center + utils.clamp(diff, -CONE_HALF, CONE_HALF)
end

-- M.init(): reset aim, barrel, and the two toggles.
function M.init()
    aim.x, aim.y = 700, 300
    barrel.x, barrel.y = 512, 560
    barrel.v = 0
    constraintOn = true
    lagOn = true
end

-- M.update(dt): compute the desired aim, apply the cone, then lag.
function M.update(dt)
    -- Desired aim angle from the pivot to the mouse.
    --   Example: mouse at (700,300), base at (512,560):
    --            dx=188, dy=-260 → desired = atan2(-260, 188) = -0.94 rad.
    local dx = aim.x - barrel.x
    local dy = aim.y - barrel.y
    local desired = math.atan2(dy, dx)
    if constraintOn then desired = clampToCone(desired) end

    -- Springy lag: accelerate the angular velocity toward the desired
    -- angle (stiffness 60), opposed by its own velocity (damping 12).
    --   Example: diff=0.5 rad → a = 60·0.5 - 12·0 = 30 rad/s².
    if lagOn then
        -- diff: wrapped shortest-path error between desired and angle.
        local diff = (desired - angle + math.pi) % (2 * math.pi) - math.pi
        local a = 60 * diff - 12 * barrel.v
        barrel.v = barrel.v + a * dt
        angle = angle + barrel.v * dt
    else
        angle = desired    -- snap: no lag
    end

    -- Recompute the error for the live readout.
    --   Example: desired=-0.94, angle=-1.1 → diff = 0.16 rad ≈ 9.2°.
    local diff = (desired - angle + math.pi) % (2 * math.pi) - math.pi
    errorDeg = math.deg(diff)
end

-- M.mousepressed(x, y, button): aim at the clicked point.
function M.mousepressed(x, y, button)
    if button == 1 then aim.x, aim.y = x, y end
end

-- M.keypressed(key): [C] toggles the cone, [S] toggles the lag.
function M.keypressed(key)
    if key == "c" then constraintOn = not constraintOn end
    if key == "s" then lagOn = not lagOn end
end

-- M.draw(): render the grid, the cone wedge, the aim line + barrel,
-- the base, the mouse dot, and the live panel.
function M.draw()
    utils.drawGrid()

    -- Allowed cone: a dark wedge drawn from the base, bounded by the
    -- two cone edge lines (±CONE_HALF around straight up).
    love.graphics.setColor(0.25, 0.2, 0.2)
    love.graphics.polygon("fill", base.x, base.y,
        base.x + 600 * math.cos(-math.pi / 2 - CONE_HALF), base.y + 600 * math.sin(-math.pi / 2 - CONE_HALF),
        base.x + 600 * math.cos(-math.pi / 2 + CONE_HALF), base.y + 600 * math.sin(-math.pi / 2 + CONE_HALF))
    -- The cone's two boundary lines, extended to the screen edge.
    love.graphics.setColor(0.4, 0.3, 0.3)
    love.graphics.setLineStyle("rough")
    love.graphics.line(base.x, base.y, base.x + 900 * math.cos(-math.pi / 2 - CONE_HALF), base.y + 900 * math.sin(-math.pi / 2 - CONE_HALF))
    love.graphics.line(base.x, base.y, base.x + 900 * math.cos(-math.pi / 2 + CONE_HALF), base.y + 900 * math.sin(-math.pi / 2 + CONE_HALF))
    love.graphics.setLineStyle("smooth")

    -- Aim line (grey): where the turret WANTS to point.
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.line(base.x, base.y, aim.x, aim.y)
    -- Barrel (red): where it ACTUALLY points, from `angle`.
    --   cx, sy: unit vector of the barrel direction.
    local cx = math.cos(angle)
    local sy = math.sin(angle)
    love.graphics.setColor(0.9, 0.3, 0.2)
    love.graphics.setLineWidth(6)
    love.graphics.line(base.x, base.y, base.x + 200 * cx, base.y + 200 * sy)
    love.graphics.setLineWidth(1)
    love.graphics.circle("fill", base.x + 200 * cx, base.y + 200 * sy, 8)

    -- Base: two concentric circles (the turret housing).
    love.graphics.setColor(0.55, 0.55, 0.55)
    love.graphics.circle("fill", base.x, base.y, 40)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.circle("fill", base.x, base.y, 24)

    -- Mouse target dot.
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", aim.x, aim.y, 5)

    -- Live panel: the two angles and the aim error.
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 90, 620, 130, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 92)
    love.graphics.print("aim angle  = " .. fmt(math.deg(math.atan2(aim.y - base.y, aim.x - base.x)), 1) .. " deg", 15, 108)
    love.graphics.print("barrel     = " .. fmt(math.deg(angle), 1) .. " deg", 15, 124)
    love.graphics.print("error      = " .. fmt(errorDeg, 1) .. " deg", 15, 140)
    love.graphics.print("constraint: " .. tostring(constraintOn) .. "   lag: " .. tostring(lagOn), 15, 156)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: angle = atan2(dy, dx) — one line and the turret always faces its prey.", 10, 700)
    love.graphics.print("The cone is a constraint: without it the barrel spins freely through the body.", 10, 714)
    love.graphics.print("Lag is weight: heavy turrets take a beat to respond — players feel the mass.", 10, 728)
end

return M