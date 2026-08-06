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

-- M: the module table exported to main.lua.
local M = {}

-- AMP: the swing amplitude of each leg, in radians.
--   Example: AMP=0.55 → a foot swings up to 0.55 rad ≈ 32° from rest.
local AMP = 0.55
-- MAX_CADENCE: the stride frequency at full speed, in steps per second.
--   Example: 1.6 Hz at 120 px/s → the legs cycle 1.6 times per second.
local MAX_CADENCE = 1.6
-- FOOT_LEN: the leg length from hip to foot, in pixels.
local FOOT_LEN = 46
-- TORSO_H: the drawn torso height, in pixels (pure art, no physics).
local TORSO_H = 80
-- GROUND_Y: the y of the floor the walker stands on.
local GROUND_Y = 600

-- char: the walker's state — position, facing, speed, and walk phase.
--   Example: char = {x=512, y=580, facing=1, speed=0, walkT=0} at rest.
local char = {
    x = 512, y = GROUND_Y - 20,
    facing = 1,
    speed = 0,
    walkT = 0,
}
-- footprints: a rolling list of {x, y} marks dropped with [SPACE],
-- capped at 80 so the trail cannot grow forever.
local footprints = {}

-- M.init(): reset the walker to rest and clear the footprints.
function M.init()
    char.x, char.y = 512, GROUND_Y - 20
    char.facing, char.speed = 1, 0
    char.walkT = 0
    footprints = {}
end

-- M.update(dt): read input, ease speed toward it, convert speed to a
-- leg cadence, and advance the walk phase.
function M.update(dt)
    -- Input: horizontal aim, damped toward a target speed. dir∈{-1,0,1}.
    --   Example: holding right → dir=1 → targetSpeed=120 px/s.
    local dir = 0
    if love.keyboard.isDown("left") then dir = -1 end
    if love.keyboard.isDown("right") then dir = 1 end
    local targetSpeed = 120 * dir
    char.speed = utils.damp(char.speed, targetSpeed, 8, dt)
    -- Facing follows the direction of travel (ignores tiny drifts).
    if math.abs(char.speed) > 1 then char.facing = char.speed > 0 and 1 or -1 end

    -- Cadence tied to speed; advance the walk phase. At full speed the
    -- phase advances MAX_CADENCE cycles per second; at rest it freezes.
    --   Example: at 60 px/s the phase advances at 0.8 cycles/s.
    char.walkT = char.walkT + MAX_CADENCE * (math.abs(char.speed) / 120) * dt

    char.x = utils.clamp(char.x + char.speed * dt, 60, 964)
end

-- M.keypressed(key): [SPACE] drops a footprint at the current spot.
function M.keypressed(key)
    if key == " " then
        table.insert(footprints, { x = char.x, y = GROUND_Y })
        if #footprints > 80 then table.remove(footprints, 1) end
    end
end

-- M.draw(): draw the ground, footprints, legs, arms, bobbed body and
-- shadow, then the live panel and footer.
function M.draw()
    utils.drawGrid()

    -- Ground: the dark floor slab under the walker.
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, GROUND_Y, 1024, 200)

    -- Footprints: a flat ellipse per mark, fading nothing (rolling cap).
    love.graphics.setColor(0.6, 0.55, 0.5)
    for _, f in ipairs(footprints) do
        love.graphics.ellipse("line", f.x, f.y, 15, 5)
    end

    -- Legs: two sines, opposite phase. phase = walkT in radians.
    -- swing is 0 at rest (no step) and AMP while moving, so a stopped
    -- walker stands still instead of shuffling in place.
    --   Example: phase=π/2 → footA fully forward, footB fully back.
    local phase = char.walkT * 2 * math.pi
    local swing = AMP * (math.abs(char.speed) > 1 and 1 or 0)
    local angA = swing * math.sin(phase)
    local angB = swing * math.sin(phase + math.pi)

    local hipX, hipY = char.x, char.y
    -- Foot positions: one FOOT_LEN along each swing angle, mirrored by
    -- facing. sin(angle) gives the vertical lift of the travelling foot.
    local footA = { x = hipX + char.facing * FOOT_LEN * math.cos(angA), y = hipY + FOOT_LEN * math.sin(angA) }
    local footB = { x = hipX + char.facing * FOOT_LEN * math.cos(angB), y = hipY + FOOT_LEN * math.sin(angB) }

    -- Legs: thick lines hip→foot.
    love.graphics.setColor(0.45, 0.45, 0.5)
    love.graphics.setLineWidth(6)
    love.graphics.line(hipX, hipY, footA.x, footA.y)
    love.graphics.line(hipX, hipY, footB.x, footB.y)
    love.graphics.setLineWidth(1)

    -- Arms counter-swing (opposite to the same-side leg): hand A is
    -- driven by -angB (the other leg), flipped by π so it swings back.
    love.graphics.setColor(0.45, 0.45, 0.5)
    love.graphics.setLineWidth(5)
    local handA = { x = char.x + char.facing * FOOT_LEN * 0.7 * math.cos(-angB - math.pi), y = char.y - 20 + FOOT_LEN * 0.7 * math.sin(-angB - math.pi) }
    local handB = { x = char.x + char.facing * FOOT_LEN * 0.7 * math.cos(-angA - math.pi), y = char.y - 20 + FOOT_LEN * 0.7 * math.sin(-angA - math.pi) }
    love.graphics.line(char.x - 12, char.y - 34, handA.x - 12, handA.y)
    love.graphics.line(char.x + 12, char.y - 34, handB.x + 12, handB.y)
    love.graphics.setLineWidth(1)

    -- Body bob: rises between steps, twice the cadence. |sin| peaks
    -- twice per cycle, so the body lifts on each foot plant transition.
    --   Example: phase=π/2 → bob=8 px; phase=0 → bob=0 px.
    local bob = math.abs(math.sin(phase)) * 8
    local bodyY = char.y - 40 - bob

    -- Torso + head: drawn offset up from the hips by the bob.
    love.graphics.setColor(0.62, 0.25, 0.25)
    love.graphics.rectangle("fill", char.x - 24, bodyY, 48, TORSO_H)
    love.graphics.setColor(0.92, 0.82, 0.72)
    love.graphics.circle("fill", char.x + char.facing * 6, bodyY - 12, 18)

    -- Little bobbing shadow: squashes as the body rises (inverse bob).
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.ellipse("fill", char.x, GROUND_Y + 6, 34 - bob, 8)

    -- Live panel: speed, facing, cadence, leg angles, body bob.
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