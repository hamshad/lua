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

-- M: the module table exported to main.lua.
local M = {}

-- shoulder: the fixed pivot the arm grows from, in pixels.
local shoulder = { x = 300, y = 560 }
-- L1: the upper-arm length (shoulder → elbow), in pixels.
-- L2: the forearm length (elbow → hand), in pixels.
--   Example: L1+L2 = 300 → max reach; |L1-L2| = 20 → min reach.
local L1, L2 = 160, 140
-- elbowSide: which side of the shoulder→hand line the elbow sits.
--   +1 = "right-handed", -1 = "left-handed". Flipped with [E].
--   Example: elbowSide=-1 mirrors the arm through the shoulder.
local elbowSide = 1

-- hand: the target the hand is trying to reach (the mouse).
--   Example: mouse at (600, 300) → hand = {x=600, y=300}.
local hand = { x = 500, y = 400 }

-- solve(): compute the arm angles that put the hand on the target.
-- Returns shoulderAngle, the elbow position, handAngle, and the
-- (clamped) target distance d.
local function solve()
    -- d: straight-line distance from shoulder to target.
    --   Example: hand at (500,400), shoulder at (300,560):
    --            d = sqrt(200² + (-160)²) = sqrt(65600) ≈ 256.
    local dx = hand.x - shoulder.x
    local dy = hand.y - shoulder.y
    local d = math.sqrt(dx * dx + dy * dy)

    -- Clamp into the reachable annulus: if the target is too far the
    -- arm locks straight; if too close it bunches to its tightest.
    --   Example: target 500 px away, maxReach 300 → d forced to 300.
    local maxReach = L1 + L2
    local minReach = math.abs(L1 - L2)
    d = utils.clamp(d, minReach + 0.01, maxReach)

    -- (nx, ny): the unit vector from shoulder toward the target.
    --   Example: d=256, dx=200 → nx = 200/256 = 0.781.
    local nx, ny = dx / (d + 0.0001), dy / (d + 0.0001)

    -- Law of cosines: the bend angle at the shoulder. |cosG|>1 would
    -- mean out of reach, so clamp it to [-1,1] before acos.
    --   Example: L1=160, L2=140, d=256
    --            cosG = (25600 + 65536 - 19600)/(2·160·256) ≈ 0.874
    --            gamma = acos(0.874) ≈ 0.508 rad ≈ 29°.
    local cosG = (L1 * L1 + d * d - L2 * L2) / (2 * L1 * d)
    cosG = utils.clamp(cosG, -1, 1)
    local gamma = math.acos(cosG)

    -- Shoulder angle = the target direction, rotated ±gamma. The sign
    -- of elbowSide picks which of the two mirror poses we get.
    --   Example: base = atan2(-160, 200) = -0.675 rad.
    --            right-handed → -0.675 + 0.508 = -0.167 rad.
    local base = math.atan2(ny, nx)
    local shoulderAngle = base + elbowSide * gamma

    -- Elbow position: one upper-arm step from the shoulder.
    --   Example: shoulderAngle=-0.167 → elbow = (300+160·cos, 560+160·sin).
    local elbow = {
        x = shoulder.x + L1 * math.cos(shoulderAngle),
        y = shoulder.y + L1 * math.sin(shoulderAngle),
    }

    -- The forearm points from the elbow straight to the hand.
    --   Example: angle between forearm and upper arm (the "elbow
    --            bend") = handAngle - shoulderAngle.
    local handAngle = math.atan2(hand.y - elbow.y, hand.x - elbow.x)

    return shoulderAngle, elbow, handAngle, d
end

-- M.init(): reset the hand target and the elbow side.
function M.init()
    hand.x, hand.y = 500, 400
    elbowSide = 1
end

-- M.update(dt): nothing to integrate — IK is solved from state each
-- frame (the target is set by the mouse handler).
function M.update(dt)
end

-- M.mousepressed(x, y, button): reach the hand toward the click.
function M.mousepressed(x, y, button)
    if button == 1 then hand.x, hand.y = x, y end
end

-- M.keypressed(key): [E] flips which side the elbow points.
function M.keypressed(key)
    if key == "e" then elbowSide = -elbowSide end
end

-- M.draw(): solve the arm, then render the reach annulus, the two
-- arm segments, the joints, the target ring, and the live panel.
function M.draw()
    utils.drawGrid()

    local shoulderAngle, elbow, handAngle, d = solve()

    -- Reach annulus: the big faint disk is ALL reachable space; the
    -- inner darker disk (radius |L1-L2|) is the unreachable hole.
    --   Example: any target inside the outer circle and outside the
    --            inner one can be reached exactly.
    love.graphics.setColor(0.14, 0.14, 0.18)
    love.graphics.circle("fill", shoulder.x, shoulder.y, L1 + L2)
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.circle("fill", shoulder.x, shoulder.y, math.abs(L1 - L2))

    -- Arm segments: blue upper arm, red forearm.
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.setLineWidth(8)
    love.graphics.line(shoulder.x, shoulder.y, elbow.x, elbow.y)
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.line(elbow.x, elbow.y, hand.x, hand.y)
    love.graphics.setLineWidth(1)

    -- Joints: shoulder (big), elbow (medium), hand (small).
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", shoulder.x, shoulder.y, 12)
    love.graphics.circle("fill", elbow.x, elbow.y, 9)
    love.graphics.circle("fill", hand.x, hand.y, 8)

    -- Target ring around the hand.
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("line", hand.x, hand.y, 16)

    -- Live panel: the solved numbers that came out of solve().
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