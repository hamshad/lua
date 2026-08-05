-- ============================================================
-- CHAPTER 9: Inverse Kinematics — Reaching the Target
-- ============================================================
-- FK drives from the root; IK works backwards — you want the HAND
-- (end of the arm) on a target, and you SOLVE the joint angles that
-- make that true. This is how arms reach, legs step, and spiders
-- plant feet.
--
-- Two-bone IK: shoulder → elbow → hand. With both segment lengths
-- fixed, the reachable region is an annulus. The law of cosines
-- gives the elbow angle directly:
--
--   cos(γ) = (L1² + d² - L2²) / (2·L1·d)
--
-- where d is the shoulder→target distance. If |cos|>1 the target
-- is out of reach: clamp d to the reach and stretch straight.
--
-- MOUSE: aim the hand   [E] flip elbow side (left/right handed)

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local shoulder = { x = 300, y = 560 }
local L1, L2 = 160, 140      -- upper arm, forearm
local elbowSide = 1          -- +1 = elbow down/left, -1 = flip

local hand = { x = 500, y = 400 }

local function solve()
    local dx = hand.x - shoulder.x
    local dy = hand.y - shoulder.y
    local d = math.sqrt(dx * dx + dy * dy)

    -- Clamp to the annulus of reach
    local maxReach = L1 + L2
    local minReach = math.abs(L1 - L2)
    d = utils.clamp(d, minReach + 0.01, maxReach)

    local nx, ny = dx / (d + 0.0001), dy / (d + 0.0001)

    -- Law of cosines: angle at the shoulder (between arm and target dir)
    local cosG = (L1 * L1 + d * d - L2 * L2) / (2 * L1 * d)
    cosG = utils.clamp(cosG, -1, 1)
    local gamma = math.acos(cosG)

    -- Shoulder angle = target direction ± gamma
    local base = math.atan2(ny, nx)
    local shoulderAngle = base + elbowSide * gamma

    -- Elbow position from shoulder angle
    local elbow = {
        x = shoulder.x + L1 * math.cos(shoulderAngle),
        y = shoulder.y + L1 * math.sin(shoulderAngle),
    }

    -- Forearm points from elbow to hand
    local handAngle = math.atan2(hand.y - elbow.y, hand.x - elbow.x)

    return shoulderAngle, elbow, handAngle, d
end

function M.init()
    hand.x, hand.y = 500, 400
    elbowSide = 1
end

function M.update(dt)
    -- mouse target already set; nothing to integrate
end

function M.mousepressed(x, y, button)
    if button == 1 then hand.x, hand.y = x, y end
end

function M.keypressed(key)
    if key == "e" then elbowSide = -elbowSide end
end

function M.draw()
    utils.drawGrid()

    local shoulderAngle, elbow, handAngle, d = solve()

    -- Reach annulus (faint)
    love.graphics.setColor(0.14, 0.14, 0.18)
    love.graphics.circle("fill", shoulder.x, shoulder.y, L1 + L2)
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.circle("fill", shoulder.x, shoulder.y, math.abs(L1 - L2))

    -- Arm segments
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.setLineWidth(8)
    love.graphics.line(shoulder.x, shoulder.y, elbow.x, elbow.y)
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.line(elbow.x, elbow.y, hand.x, hand.y)
    love.graphics.setLineWidth(1)

    -- Joints
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", shoulder.x, shoulder.y, 12)
    love.graphics.circle("fill", elbow.x, elbow.y, 9)
    love.graphics.circle("fill", hand.x, hand.y, 8)

    -- Target
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("line", hand.x, hand.y, 16)

    -- Live panel
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 90, 560, 120, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 92)
    love.graphics.print("target dist d = " .. fmt(d), 15, 108)
    love.graphics.print("shoulder angle = " .. fmt(math.deg(shoulderAngle), 1) .. " deg", 15, 124)
    love.graphics.print("elbow angle    = " .. fmt(math.deg(handAngle - shoulderAngle), 1) .. " deg", 15, 140)
    love.graphics.print("elbow side     = " .. (elbowSide == 1 and "right" or "left"), 15, 156)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: with two fixed sticks there are exactly two poses that reach a point —", 10, 700)
    love.graphics.print("one with the elbow this way, one the other. The law of cosines picks the triangle;", 10, 714)
    love.graphics.print("the sign of the root picks the pose. Out of reach? The annulus clamps and the", 10, 728)
    love.graphics.print("arm locks straight — read the reach, don't break the arm.  [E] flips the elbow.", 10, 742)
end

return M