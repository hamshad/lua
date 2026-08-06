-- ============================================================
-- CHAPTER 14: Putting It All Together — A Living Character
-- ============================================================
-- Every technique from the book, one creature, one game object.
-- It walks (Ch13 sine legs + cadence from input), breathes while
-- idle (Ch3 sine), aims its head at the mouse (Ch7 atan2 + lag),
-- squashes on landing (Ch6), trembles with noise (Ch10), and drags
-- a tail of secondary motion behind it (Ch11 springs). The camera
-- follows with damp (Ch4). Hit-stop and shake (Ch12) fire on the
-- hop landing — this is a GAME object, not a drawing.
--
-- ARROWS: walk   SPACE: hop   MOUSE: aim head

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua.
local M = {}

-- GROUND_Y: the floor the creature stands on, in pixels.
local GROUND_Y = 600
-- MOUSE: the aim target for the head, set by clicks.
--   Example: click at (700,250) → MOUSE = {x=700, y=250}.
local MOUSE = { x = 700, y = 250 }

-- creature: the full game-object state. Every field is one technique
-- from the book, all integrated into one physics+feel update.
--   Example: {x=400, y=570, vx=0, vy=0, grounded=true, squash=0}.
local creature = {
    x = 400, y = GROUND_Y - 30,
    vx = 0, vy = 0, vGround = 0,
    facing = 1,
    speed = 0,
    walkT = 0,
    grounded = true,
    breathT = 0,
    squash = 0, stretch = 0,
    hop = 0,                -- hop timer for hit-stop/shake feel
}
-- camX/camY: the camera focus, damped toward the creature each frame.
--   Example: creature at x=700 → camX eases 400 → 700 over ~0.5 s.
local camX, camY = 400, 400

-- Secondary-motion tail: N spring links, each chasing the previous.
local N = 8
local tail = {}
for i = 1, N do tail[i] = { x = 0, y = 0 } end

-- M.init(): reset the creature, camera, and lay the tail out flat.
function M.init()
    creature.x, creature.y = 400, GROUND_Y - 30
    creature.vx, creature.vy = 0, 0
    creature.speed, creature.walkT = 0, 0
    creature.grounded, creature.breathT = true, 0
    creature.squash, creature.stretch = 0, 0
    creature.hop = 0
    camX, camY = 400, 400
    for i = 1, N do
        tail[i].x, tail[i].y = creature.x - i * 22, creature.y - 20
    end
end

-- M.update(dt): the creature's whole life per frame — breathe, walk,
-- fall, land, recover, drag the tail, and let the camera chase.
function M.update(dt)
    creature.breathT = creature.breathT + dt   -- idle breathing clock
    creature.hop = math.max(0, creature.hop - dt)   -- feel timer decays

    -- Walk input: damp horizontal velocity toward the key direction.
    --   Example: holding right → vx eases toward 130 px/s (λ=10).
    local dir = 0
    if love.keyboard.isDown("left") then dir = -1 end
    if love.keyboard.isDown("right") then dir = 1 end
    creature.vx = utils.damp(creature.vx, 130 * dir, 10, dt)
    if math.abs(creature.vx) > 5 then creature.facing = creature.vx > 0 and 1 or -1 end
    creature.x = utils.clamp(creature.x + creature.vx * dt, 40, 984)

    -- Walk phase cadence from speed (Ch13): legs cycle faster when
    -- moving. At 130 px/s the phase advances 1.6 cycles/s.
    creature.walkT = creature.walkT + 1.6 * (math.abs(creature.vx) / 130) * dt

    -- Gravity + ground: plain Euler integration of the vertical axis.
    --   Example: falling at vy=500 → vy gains 1500·dt each second.
    creature.vy = creature.vy + 1500 * dt
    creature.y = creature.y + creature.vy * dt
    if creature.y + 20 >= GROUND_Y then
        if not creature.grounded and creature.vy > 0 then
            -- Landing: squash + tiny hit-stop + shake feel (Ch12).
            -- The faster the impact, the deeper the squash.
            creature.squash = math.min(0.4, creature.squash + creature.vy * 0.0005)
            creature.hop = 0.15
        end
        creature.y = GROUND_Y - 20
        creature.vy = 0
        creature.grounded = true
    else
        creature.grounded = false
    end

    -- Stretch from fall speed, squash from landings. Both relax back
    -- to 0 via damp, so the deformations are momentary, not permanent.
    --   Example: falling at vy=800 → stretch target = 0.3·... capped.
    creature.stretch = utils.damp(creature.stretch, math.min(0.3, math.abs(creature.vy) * 0.0003), 15, dt)
    creature.squash = utils.damp(creature.squash, 0, 20, dt)

    -- Secondary tail: springs down the chain (Ch11). Link 1 chases a
    -- point just behind the creature; each link chases the last.
    tail[1].x = utils.damp(tail[1].x, creature.x - creature.facing * 10, 14, dt)
    tail[1].y = utils.damp(tail[1].y, creature.y - 20, 14, dt)
    for i = 2, N do
        tail[i].x = utils.damp(tail[i].x, tail[i - 1].x, 14, dt)
        tail[i].y = utils.damp(tail[i].y, tail[i - 1].y, 14, dt)
    end

    -- Camera follows with damp (Ch4): a mechanic in itself. The camera
    -- trails the creature instead of locking on, which reads as smooth.
    camX = utils.damp(camX, creature.x, 8, dt)
    camY = utils.damp(camY, creature.y - 60, 8, dt)
end

-- M.keypressed(key): [SPACE] on the ground launches a hop, with a
-- squash as the anticipation (Ch12) before take-off.
function M.keypressed(key)
    if key == " " and creature.grounded then
        creature.vy = -420
        creature.grounded = false
        creature.squash = 0.12   -- anticipation on the way up
    end
end

-- M.mousepressed(x, y, button): remember where the head should aim.
function M.mousepressed(x, y, button)
    if button == 1 then MOUSE.x, MOUSE.y = x, y end
end

-- M.draw(): render the whole scene — shake, grid, ground, tail, body
-- (squash/stretch), legs, aimed head, breath ellipse, tremble dot —
-- then the live panel and footer.
function M.draw()
    -- Screen shake from hop landing (Ch12): fades as the hop timer
    -- dies. 6 px at impact, 0 when hop=0.
    local shake = creature.hop > 0 and 6 * (creature.hop / 0.15) or 0
    love.graphics.push()
    love.graphics.translate((love.math.random() * 2 - 1) * shake, (love.math.random() * 2 - 1) * shake)

    utils.drawGrid()
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, GROUND_Y, 1024, 200)

    -- Tail: tapered, base thick/full, tip thin/faint (Ch11 secondary).
    for i = N, 2, -1 do
        love.graphics.setColor(0.75, 0.45, 0.2, 0.35 + 0.6 * (N - i + 1) / N)
        love.graphics.setLineWidth(9 - 6 * (N - i + 1) / N)
        love.graphics.line(tail[i - 1].x, tail[i - 1].y, tail[i].x, tail[i].y)
    end
    love.graphics.setLineWidth(1)

    local c = creature
    -- Bob from the walk phase, plus the squash lifting the body.
    --   Example: walking → bob up to 6 px; landing → squash adds 14·squash.
    local bob = math.abs(math.sin(c.walkT * 2 * math.pi)) * 6
    local bodyY = c.y - 44 - bob + c.squash * 14

    -- Squash/stretch applied to torso: scale >1 along x = wider (squash),
    -- scale <1 along y = flatter. Sum stays near 1 (volume preserved).
    local sx = 1 + c.stretch + c.squash * 1.2
    local sy = 1 - c.stretch - c.squash
    love.graphics.push()
    love.graphics.translate(c.x, bodyY + 40)
    love.graphics.scale(sx, sy)

    -- Torso + legs (two sines, opposite phase, Ch13).
    --   Example: swing=0.5 → legs stride; swing=0.08 → gentle shuffle.
    love.graphics.setColor(0.62, 0.25, 0.25)
    love.graphics.rectangle("fill", -22, -20, 44, 78)
    local phase = c.walkT * 2 * math.pi
    local swing = math.abs(c.vx) > 5 and 0.5 or 0.08
    local fa = swing * math.sin(phase)
    local fb = swing * math.sin(phase + math.pi)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.setLineWidth(6)
    love.graphics.line(0, 58, 26 * math.cos(fa), 58 + 30 * math.sin(fa))
    love.graphics.line(0, 58, 26 * math.cos(fb), 58 + 30 * math.sin(fb))
    love.graphics.setLineWidth(1)
    love.graphics.pop()

    -- Head: aims at the mouse (Ch7 atan2) but clamped to a cone facing
    -- the walk direction, so the neck does not spin 360°. diff wraps
    -- the angle difference into [-π, π], then clamps to ±1 rad.
    --   Example: mouse straight up while facing right → diff=1 (max tilt).
    local headX, headY = c.x + c.facing * 8, bodyY - 10
    local wantA = math.atan2(MOUSE.y - headY, MOUSE.x - headX)
    local headA = wantA   -- clamped toward facing
    local diff = (wantA - (c.facing > 0 and 0 or math.pi) + math.pi) % (2 * math.pi) - math.pi
    diff = utils.clamp(diff, -1.0, 1.0)
    headA = (c.facing > 0 and 0 or math.pi) + diff

    -- Draw the head rotated toward the aim, nose pointing the way.
    love.graphics.push()
    love.graphics.translate(headX, headY)
    love.graphics.rotate(headA)
    love.graphics.setColor(0.92, 0.82, 0.72)
    love.graphics.circle("fill", 0, 0, 17)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", 12, 0, 4)   -- nose toward mouse
    love.graphics.pop()

    -- Idle breath: chest scale with a slow sine (Ch3). A 0.25 Hz wave
    -- → one breath every 4 s; ±0.05 scale on the ellipse width.
    local breath = 0.05 * math.sin(c.breathT * 2 * math.pi * 0.25)
    love.graphics.setColor(0.7, 0.9, 0.7, 0.6)
    love.graphics.ellipse("line", c.x, bodyY + 24, 34 + breath * 40, 34)

    -- Noise tremble dot on the nose (Ch10): an organic jitter that
    -- never repeats, unlike a sine. ±1 px at the nose tip.
    local tr = love.math.noise(c.breathT * 3) - 0.5
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", headX + math.cos(headA) * 12 + tr * 2, headY + math.sin(headA) * 12 + tr * 2, 2)

    love.graphics.pop()   -- end shake

    -- Live panel: physics + feel readouts.
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 620, 1000, 100, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 622)
    love.graphics.print("vx=" .. fmt(c.vx) .. "  vy=" .. fmt(c.vy) .. "  grounded=" .. tostring(c.grounded), 15, 638)
    love.graphics.print("squash=" .. fmt(c.squash) .. "  stretch=" .. fmt(c.stretch) .. "  hop=" .. fmt(c.hop, 2), 15, 654)
    love.graphics.print("head aim = " .. fmt(math.deg(headA), 0) .. " deg   breath = " .. fmt(breath, 3), 15, 670)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: nothing here is drawn by hand. Every motion falls out of a number and", 10, 700)
    love.graphics.print("a law — sine for breath, atan2 for aim, springs for the tail, damp for the camera,", 10, 714)
    love.graphics.print("noise for the tremble, cadence for the stride. That is the whole book in one", 10, 728)
    love.graphics.print("creature. When you can make a character this way, you build games, not poses.", 10, 742)
end

return M