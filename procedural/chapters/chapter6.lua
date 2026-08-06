-- ============================================================
-- CHAPTER 6: Squash and Stretch — Elasticity & Game Feel
-- ============================================================
-- The single most powerful game-feel tool. Nothing physical
-- stretches, but cartoons do: a falling ball stretches as it falls,
-- squashes on impact, stretches again as it launches, and springs
-- back to rest. The player READS it as weight and energy.
--
-- Rules of thumb:
--   stretch ∝ velocity     along the direction of motion
--   squash  ∝ impact       (set on ground contact)
--   always return to scale 1 (damp it back)
--
-- SPACE: jump   (first squash — anticipation, then stretch — launch)
-- Click: teleport the ball high and let it fall
--
-- Simple manual physics: gravity + ground restitution. No Box2D —
-- the point is the VISUAL, not the solver.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua.
local M = {}

-- ball: all the state of the bouncing ball.
--   x, y:    position (center of the ball), in pixels.
--   vx, vy:  velocity, in pixels/second. vy>0 means falling (y grows).
--   r:       rest radius in pixels.
--   scaleX/Y: the squash-and-stretch scales drawn on the ellipse.
--   squash:   the impact "splat" amount (0..0.45), decayed each step.
--   grounded: true when the ball sits on the ground.
--   GR:       gravity, px/s². 1200 → vy grows by 1200/60 = 20 px/s each step.
--   e:        restitution — the fraction of speed kept on a bounce.
--             e=0.78 → bounce up at 78% of the fall speed.
--   stretch:  the persistent velocity-stretch amount (0..0.35).
local ball = {
    x = 512, y = 200, vx = 0, vy = 0,
    r = 30,
    scaleX = 1, scaleY = 1,  -- squash/stretch scales
    squash = 0,              -- impact energy to decay
    grounded = false,
    GR = 1200,               -- gravity px/s²
    e = 0.78,                -- restitution
    stretch = 0.0,           -- velocity stretch (persistent)
}

-- GROUND_Y: the y-position of the floor's top surface, in pixels.
-- The ball center rests at GROUND_Y - r when grounded.
local GROUND_Y = 660

-- M.init(): reset the ball to rest on the ground at a fresh spot.
function M.init()
    ball.x, ball.y = 360, 200
    ball.vx, ball.vy = 0, 0
    ball.scaleX, ball.scaleY = 1, 1
    ball.squash = 0
    ball.stretch = 0
    ball.grounded = false
end

-- M.update(dt): step the manual physics AND the two feel effects.
function M.update(dt)
    -- Physics: gravity accelerates vy, velocity moves the ball.
    --   Example: vy=200, GR=1200, dt=1/60 → vy = 200 + 20 = 220;
    --            y += 220/60 = 3.67 px this step.
    ball.vy = ball.vy + ball.GR * dt
    ball.y = ball.y + ball.vy * dt
    ball.x = ball.x + ball.vx * dt

    -- Ground bounce: detect the floor, then react.
    if ball.y + ball.r >= GROUND_Y then
        ball.y = GROUND_Y - ball.r      -- snap onto the surface
        if ball.vy > 0 then             -- only when actually falling
            -- Impact! Set the squash (stronger when falling faster),
            -- then reverse velocity with restitution.
            --   Example: vy=400 → squash += 400·0.0006 = 0.24;
            --            vy = -400·0.78 = -312 (bounces up).
            ball.squash = math.min(0.45, ball.squash + ball.vy * 0.0006)
            ball.vy = -ball.vy * ball.e
            -- Floor friction kills horizontal drift (slides stop).
            ball.vx = ball.vx * 0.8
        end
        ball.grounded = true
    else
        ball.grounded = false
    end

    -- Velocity stretch: more speed → more stretch, capped at 0.35.
    --   Example: speed 600 px/s → targetStretch = min(0.35, 0.30) = 0.30.
    local speed = math.sqrt(ball.vx^2 + ball.vy^2)
    local targetStretch = math.min(0.35, speed * 0.0005)
    ball.stretch = utils.damp(ball.stretch, targetStretch, 15, dt)

    -- Combine squash + stretch into the two draw scales. Roughly
    -- volume-conserving: when one axis grows the other shrinks.
    --   Example: squash=0.24, stretch=0.20
    --            scaleY = 1 - 0.24 + 0.20 = 0.96
    --            scaleX = 1 + 0.24·1.1 - 0.20·0.8 = 1.10
    local squashNow = ball.squash
    ball.scaleY = 1 - squashNow + ball.stretch
    ball.scaleX = 1 + squashNow * 1.1 - ball.stretch * 0.8
    -- Never let a scale go negative (a degenerate ellipse).
    ball.scaleX = math.max(0.3, ball.scaleX)
    ball.scaleY = math.max(0.3, ball.scaleY)

    -- The impact squash decays back to rest — that springy recovery
    -- is what makes it read as material instead of a morph.
    ball.squash = utils.damp(ball.squash, 0, 22, dt)
end

-- M.mousepressed(x, y, button):
--   left click (1): drop the ball from high up for a big fall.
--   right click (2): fling it upward with an immediate squash.
function M.mousepressed(x, y, button)
    if button == 1 then
        ball.y = 120    -- teleport near the top
        ball.vy = 0     -- start the fall from rest
    elseif button == 2 then
        ball.vy = -560      -- strong upward launch
        ball.squash = 0.25  -- anticipation squash on the way up
    end
end

-- M.keypressed(key): SPACE jumps (only while grounded), with a small
-- anticipation squash set at the same instant.
function M.keypressed(key)
    if key == " " and ball.grounded then
        ball.vy = -580
        ball.squash = 0.2
    end
end

-- M.draw(): render the grid, ground, velocity arrow, the scaled
-- ellipse, the rest-size ring, and the live panel.
function M.draw()
    utils.drawGrid()

    -- Ground: a grey slab filling the bottom of the screen.
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, GROUND_Y, 1024, 200)

    -- Velocity arrow (yellow), only when moving visibly.
    --   Example: falling at vy=400 → a 24-px arrow pointing down.
    local sp = math.sqrt(ball.vx^2 + ball.vy^2)
    if sp > 5 then
        utils.drawVector(ball.x, ball.y, ball.vx, ball.vy, 0.06, {1, 1, 0})
    end

    -- The squash-and-stretch draw: an ellipse with independent x/y
    -- radii, ROTATED to align its long axis with the velocity. The
    -- stretch bulges along the direction of travel; the squash
    -- flattens across it.
    --   Example: r=30, scaleX=1.10, scaleY=0.96 → rx=33, ry=28.8.
    local rx = ball.r * ball.scaleX
    local ry = ball.r * ball.scaleY
    local angle = math.atan2(ball.vy, ball.vx)

    love.graphics.push()
    love.graphics.translate(ball.x, ball.y)
    love.graphics.rotate(angle)
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.ellipse("fill", 0, 0, rx, ry)
    love.graphics.pop()

    -- Rest-size ring: a faint circle at the ball's unstressed size,
    -- so the stretch/squash is visible as a deviation from it.
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.circle("line", ball.x, ball.y, ball.r)

    -- Live panel.
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 100, 560, 150, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 102)
    love.graphics.print("vy = " .. fmt(ball.vy) .. " px/s   stretch = " .. fmt(ball.stretch), 15, 118)
    love.graphics.print("scaleX = " .. fmt(ball.scaleX) .. "  scaleY = " .. fmt(ball.scaleY), 15, 134)
    love.graphics.print("impact squash = " .. fmt(ball.squash), 15, 150)
    love.graphics.print("physics: vy+=g·dt, ground e=" .. fmt(ball.e), 15, 166)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: squash & stretch is a LIE that tells the truth. Volume is roughly conserved", 10, 690)
    love.graphics.print("(stretch one axis, squeeze the other), so the eye buys the energy transfer.", 10, 704)
    love.graphics.print("Controls: [SPACE] jump with anticipation, [left-click] drop high, [right-click] fling up.", 10, 718)
end

return M