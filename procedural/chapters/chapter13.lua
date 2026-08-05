-- ============================================================
-- CHAPTER 13: The Procedural Walker — Locomotion from Sine
-- ============================================================
-- Walking is the crown jewel of procedural animation. No keyframes,
-- no art: two legs driven by two sines, counter-swinging arms, a
-- body bob — and the result is an alive walker.
--
-- The trick is FOOT PLANT: while one foot swings forward the other
-- must be planted on the ground. Two legs with opposite phase (180°)
-- guarantee one foot is always planted:
--
--   footA = A·sin(2π·f·t)      footB = A·sin(2π·f·t + π)
--
-- The cadence f comes from INPUT: the faster the character moves,
-- the faster the legs cycle. Motion follows mechanics.
--
-- ARROWS: walk faster/change facing   SPACE: plant feedback (hop)

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local AMP = 0.55            -- foot swing amplitude (rad)
local MAX_CADENCE = 1.6     -- steps/sec at full speed
local FOOT_LEN = 46
local TORSO_H = 80
local GROUND_Y = 600

local char = {
    x = 512, y = GROUND_Y - 20,
    facing = 1,
    speed = 0,
    walkT = 0,
}
local footprints = {}

function M.init()
    char.x, char.y = 512, GROUND_Y - 20
    char.facing, char.speed = 1, 0
    char.walkT = 0
    footprints = {}
end

function M.update(dt)
    -- Input: horizontal aim, damped toward a target speed.
    local dir = 0
    if love.keyboard.isDown("left") then dir = -1 end
    if love.keyboard.isDown("right") then dir = 1 end
    local targetSpeed = 120 * dir
    char.speed = utils.damp(char.speed, targetSpeed, 8, dt)
    if math.abs(char.speed) > 1 then char.facing = char.speed > 0 and 1 or -1 end

    -- Cadence tied to speed; advance the walk phase.
    char.walkT = char.walkT + MAX_CADENCE * (math.abs(char.speed) / 120) * dt

    char.x = utils.clamp(char.x + char.speed * dt, 60, 964)
end

function M.keypressed(key)
    if key == " " then
        table.insert(footprints, { x = char.x, y = GROUND_Y })
        if #footprints > 80 then table.remove(footprints, 1) end
    end
end

function M.draw()
    utils.drawGrid()

    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, GROUND_Y, 1024, 200)

    -- Footprints
    love.graphics.setColor(0.6, 0.55, 0.5)
    for _, f in ipairs(footprints) do
        love.graphics.ellipse("line", f.x, f.y, 15, 5)
    end

    -- Legs: two sines, opposite phase.
    local phase = char.walkT * 2 * math.pi
    local swing = AMP * (math.abs(char.speed) > 1 and 1 or 0)
    local angA = swing * math.sin(phase)
    local angB = swing * math.sin(phase + math.pi)

    local hipX, hipY = char.x, char.y
    local footA = { x = hipX + char.facing * FOOT_LEN * math.cos(angA), y = hipY + FOOT_LEN * math.sin(angA) }
    local footB = { x = hipX + char.facing * FOOT_LEN * math.cos(angB), y = hipY + FOOT_LEN * math.sin(angB) }

    -- Legs
    love.graphics.setColor(0.45, 0.45, 0.5)
    love.graphics.setLineWidth(6)
    love.graphics.line(hipX, hipY, footA.x, footA.y)
    love.graphics.line(hipX, hipY, footB.x, footB.y)
    love.graphics.setLineWidth(1)

    -- Arms counter-swing (opposite to the same-side leg).
    local swingArm = swing * 0.9
    local handA = { x = char.x + char.facing * FOOT_LEN * 0.7 * math.cos(-angB - math.pi), y = char.y - 20 + FOOT_LEN * 0.7 * math.sin(-angB - math.pi) }
    local handB = { x = char.x + char.facing * FOOT_LEN * 0.7 * math.cos(-angA - math.pi), y = char.y - 20 + FOOT_LEN * 0.7 * math.sin(-angA - math.pi) }
    love.graphics.setColor(0.45, 0.45, 0.5)
    love.graphics.setLineWidth(5)
    love.graphics.line(char.x - 12, char.y - 34, handA.x - 12, handA.y)
    love.graphics.line(char.x + 12, char.y - 34, handB.x + 12, handB.y)
    love.graphics.setLineWidth(1)

    -- Body bob: rises between steps, twice the cadence.
    local bob = math.abs(math.sin(phase)) * 8
    local bodyY = char.y - 40 - bob

    love.graphics.setColor(0.62, 0.25, 0.25)
    love.graphics.rectangle("fill", char.x - 24, bodyY, 48, TORSO_H)
    love.graphics.setColor(0.92, 0.82, 0.72)
    love.graphics.circle("fill", char.x + char.facing * 6, bodyY - 12, 18)

    -- Little bobbing shadow
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.ellipse("fill", char.x, GROUND_Y + 6, 34 - bob, 8)

    -- Live panel
    love.graphics.setFont(fontSmall)
    drawTextBox(560, 60, 460, 130, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 565, 62)
    love.graphics.print("speed     = " .. fmt(char.speed) .. " px/s", 565, 78)
    love.graphics.print("facing    = " .. (char.facing > 0 and "right" or "left"), 565, 94)
    love.graphics.print("cadence   = " .. fmt(MAX_CADENCE * math.abs(char.speed) / 120, 2) .. " Hz", 565, 110)
    love.graphics.print("foot A    angle = " .. fmt(math.deg(angA), 1) .. " deg", 565, 126)
    love.graphics.print("foot B    angle = " .. fmt(math.deg(angB), 1) .. " deg", 565, 142)
    love.graphics.print("body bob   = " .. fmt(bob) .. " px", 565, 158)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: walking is two sines half a cycle apart — one foot travels while the", 10, 700)
    love.graphics.print("other plants, and the chords read as a stride. The bob is a third sine at twice", 10, 714)
    love.graphics.print("the cadence. That IS the animation: no art, no keyframes, just phase, amplitude", 10, 728)
    love.graphics.print("and t. INPUT (speed) sets cadence — the motion follows the mechanics.", 10, 742)
end

return M