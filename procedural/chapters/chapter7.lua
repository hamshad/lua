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

local M = {}

local aim = { x = 0, y = 0 }
local base = { x = 512, y = 560 }

local angle = 0.0            -- current barrel angle (rad)
local barrel = { x = 512, y = 560, v = 0 }   -- springy barrel pos
local constraintOn = true
local lagOn = true
local errorDeg = 0.0         -- current aim error in degrees

local CONE_HALF = math.rad(70)   -- ±70° from straight up

-- Clamp an angle to the cone centered on "up" (-90°).
local function clampToCone(a)
    local center = -math.pi / 2
    local diff = (a - center + math.pi) % (2 * math.pi) - math.pi
    return center + utils.clamp(diff, -CONE_HALF, CONE_HALF)
end

function M.init()
    aim.x, aim.y = 700, 300
    barrel.x, barrel.y = 512, 560
    barrel.v = 0
    constraintOn = true
    lagOn = true
end

function M.update(dt)
    -- Desired aim angle.
    local dx = aim.x - barrel.x
    local dy = aim.y - barrel.y
    local desired = math.atan2(dy, dx)
    if constraintOn then desired = clampToCone(desired) end

    -- Springy lag toward the desired angle.
    if lagOn then
        local diff = (desired - angle + math.pi) % (2 * math.pi) - math.pi
        local a = 60 * diff - 12 * barrel.v
        barrel.v = barrel.v + a * dt
        angle = angle + barrel.v * dt
    else
        angle = desired
    end

    local diff = (desired - angle + math.pi) % (2 * math.pi) - math.pi
    errorDeg = math.deg(diff)
end

function M.mousepressed(x, y, button)
    if button == 1 then aim.x, aim.y = x, y end
end

function M.keypressed(key)
    if key == "c" then constraintOn = not constraintOn end
    if key == "s" then lagOn = not lagOn end
end

function M.draw()
    utils.drawGrid()

    -- Allowed cone visualization
    love.graphics.setColor(0.25, 0.2, 0.2)
    love.graphics.polygon("fill", base.x, base.y,
        base.x + 600 * math.cos(-math.pi / 2 - CONE_HALF), base.y + 600 * math.sin(-math.pi / 2 - CONE_HALF),
        base.x + 600 * math.cos(-math.pi / 2 + CONE_HALF), base.y + 600 * math.sin(-math.pi / 2 + CONE_HALF))
    love.graphics.setColor(0.4, 0.3, 0.3)
    love.graphics.setLineStyle("rough")
    love.graphics.line(base.x, base.y, base.x + 900 * math.cos(-math.pi / 2 - CONE_HALF), base.y + 900 * math.sin(-math.pi / 2 - CONE_HALF))
    love.graphics.line(base.x, base.y, base.x + 900 * math.cos(-math.pi / 2 + CONE_HALF), base.y + 900 * math.sin(-math.pi / 2 + CONE_HALF))
    love.graphics.setLineStyle("smooth")

    -- Aim line (desired) and barrel (actual)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.line(base.x, base.y, aim.x, aim.y)
    local cx = math.cos(angle)
    local sy = math.sin(angle)
    love.graphics.setColor(0.9, 0.3, 0.2)
    love.graphics.setLineWidth(6)
    love.graphics.line(base.x, base.y, base.x + 200 * cx, base.y + 200 * sy)
    love.graphics.setLineWidth(1)
    love.graphics.circle("fill", base.x + 200 * cx, base.y + 200 * sy, 8)

    -- Base
    love.graphics.setColor(0.55, 0.55, 0.55)
    love.graphics.circle("fill", base.x, base.y, 40)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.circle("fill", base.x, base.y, 24)

    -- Mouse target dot
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", aim.x, aim.y, 5)

    -- Live panel
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