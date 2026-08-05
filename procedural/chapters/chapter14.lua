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

local M = {}

local GROUND_Y = 600
local MOUSE = { x = 700, y = 250 }

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
local camX, camY = 400, 400

-- Secondary-motion tail
local N = 8
local tail = {}
for i = 1, N do tail[i] = { x = 0, y = 0 } end

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

function M.update(dt)
    creature.breathT = creature.breathT + dt
    creature.hop = math.max(0, creature.hop - dt)

    -- Walk input
    local dir = 0
    if love.keyboard.isDown("left") then dir = -1 end
    if love.keyboard.isDown("right") then dir = 1 end
    creature.vx = utils.damp(creature.vx, 130 * dir, 10, dt)
    if math.abs(creature.vx) > 5 then creature.facing = creature.vx > 0 and 1 or -1 end
    creature.x = utils.clamp(creature.x + creature.vx * dt, 40, 984)

    -- Walk phase cadence from speed
    creature.walkT = creature.walkT + 1.6 * (math.abs(creature.vx) / 130) * dt

    -- Gravity + ground
    creature.vy = creature.vy + 1500 * dt
    creature.y = creature.y + creature.vy * dt
    if creature.y + 20 >= GROUND_Y then
        if not creature.grounded and creature.vy > 0 then
            -- Landing: squash + tiny hit-stop + shake feel
            creature.squash = math.min(0.4, creature.squash + creature.vy * 0.0005)
            creature.hop = 0.15
        end
        creature.y = GROUND_Y - 20
        creature.vy = 0
        creature.grounded = true
    else
        creature.grounded = false
    end

    -- Stretch from fall speed, squash from landings
    creature.stretch = utils.damp(creature.stretch, math.min(0.3, math.abs(creature.vy) * 0.0003), 15, dt)
    creature.squash = utils.damp(creature.squash, 0, 20, dt)

    -- Secondary tail: springs down the chain
    tail[1].x = utils.damp(tail[1].x, creature.x - creature.facing * 10, 14, dt)
    tail[1].y = utils.damp(tail[1].y, creature.y - 20, 14, dt)
    for i = 2, N do
        tail[i].x = utils.damp(tail[i].x, tail[i - 1].x, 14, dt)
        tail[i].y = utils.damp(tail[i].y, tail[i - 1].y, 14, dt)
    end

    -- Camera follows with damp (a mechanic in itself)
    camX = utils.damp(camX, creature.x, 8, dt)
    camY = utils.damp(camY, creature.y - 60, 8, dt)
end

function M.keypressed(key)
    if key == " " and creature.grounded then
        creature.vy = -420
        creature.grounded = false
        creature.squash = 0.12   -- anticipation on the way up
    end
end

function M.mousepressed(x, y, button)
    if button == 1 then MOUSE.x, MOUSE.y = x, y end
end

function M.draw()
    -- Screen shake from hop landing
    local shake = creature.hop > 0 and 6 * (creature.hop / 0.15) or 0
    love.graphics.push()
    love.graphics.translate((love.math.random() * 2 - 1) * shake, (love.math.random() * 2 - 1) * shake)

    utils.drawGrid()
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, GROUND_Y, 1024, 200)

    -- Tail
    for i = N, 2, -1 do
        love.graphics.setColor(0.75, 0.45, 0.2, 0.35 + 0.6 * (N - i + 1) / N)
        love.graphics.setLineWidth(9 - 6 * (N - i + 1) / N)
        love.graphics.line(tail[i - 1].x, tail[i - 1].y, tail[i].x, tail[i].y)
    end
    love.graphics.setLineWidth(1)

    local c = creature
    local bob = math.abs(math.sin(c.walkT * 2 * math.pi)) * 6
    local bodyY = c.y - 44 - bob + c.squash * 14

    -- Squash/stretch applied to torso
    local sx = 1 + c.stretch + c.squash * 1.2
    local sy = 1 - c.stretch - c.squash
    love.graphics.push()
    love.graphics.translate(c.x, bodyY + 40)
    love.graphics.scale(sx, sy)

    -- Torso + legs
    love.graphics.setColor(0.62, 0.25, 0.25)
    love.graphics.rectangle("fill", -22, -20, 44, 78)
    -- Legs (two sines)
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

    -- Head: aims at the mouse with a lazy spring (look-ahead lag).
    local headX, headY = c.x + c.facing * 8, bodyY - 10
    local wantA = math.atan2(MOUSE.y - headY, MOUSE.x - headX)
    local headA = wantA   -- clamped toward facing
    local diff = (wantA - (c.facing > 0 and 0 or math.pi) + math.pi) % (2 * math.pi) - math.pi
    diff = utils.clamp(diff, -1.0, 1.0)
    headA = (c.facing > 0 and 0 or math.pi) + diff

    love.graphics.push()
    love.graphics.translate(headX, headY)
    love.graphics.rotate(headA)
    love.graphics.setColor(0.92, 0.82, 0.72)
    love.graphics.circle("fill", 0, 0, 17)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", 12, 0, 4)   -- nose toward mouse
    love.graphics.pop()

    -- Idle breath: chest scale with a slow sine
    local breath = 0.05 * math.sin(c.breathT * 2 * math.pi * 0.25)
    love.graphics.setColor(0.7, 0.9, 0.7, 0.6)
    love.graphics.ellipse("line", c.x, bodyY + 24, 34 + breath * 40, 34)

    -- Noise tremble dot on the nose
    local tr = love.math.noise(c.breathT * 3) - 0.5
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", headX + math.cos(headA) * 12 + tr * 2, headY + math.sin(headA) * 12 + tr * 2, 2)

    love.graphics.pop()   -- end shake

    -- Live panel
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