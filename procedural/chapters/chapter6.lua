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

local M = {}

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

local GROUND_Y = 660

function M.init()
    ball.x, ball.y = 360, 200
    ball.vx, ball.vy = 0, 0
    ball.scaleX, ball.scaleY = 1, 1
    ball.squash = 0
    ball.stretch = 0
    ball.grounded = false
end

function M.update(dt)
    -- Physics
    ball.vy = ball.vy + ball.GR * dt
    ball.y = ball.y + ball.vy * dt
    ball.x = ball.x + ball.vx * dt

    -- Ground bounce
    if ball.y + ball.r >= GROUND_Y then
        ball.y = GROUND_Y - ball.r
        if ball.vy > 0 then
            -- Impact! Set the squash, bounce up.
            ball.squash = math.min(0.45, ball.squash + ball.vy * 0.0006)
            ball.vy = -ball.vy * ball.e
            -- tiny floor friction kills horizontal drift
            ball.vx = ball.vx * 0.8
        end
        ball.grounded = true
    else
        ball.grounded = false
    end

    -- Velocity stretch: energy along motion → stretch it.
    local speed = math.sqrt(ball.vx^2 + ball.vy^2)
    local targetStretch = math.min(0.35, speed * 0.0005)
    ball.stretch = utils.damp(ball.stretch, targetStretch, 15, dt)

    -- Combine: squash eats stretch, and vice versa.
    -- Total deviation is bounded so the ball keeps roughly its area.
    local squashNow = ball.squash
    ball.scaleY = 1 - squashNow + ball.stretch
    ball.scaleX = 1 + squashNow * 1.1 - ball.stretch * 0.8
    -- Never go negative
    ball.scaleX = math.max(0.3, ball.scaleX)
    ball.scaleY = math.max(0.3, ball.scaleY)

    -- Decay the impact squash back to 0.
    ball.squash = utils.damp(ball.squash, 0, 22, dt)
end

function M.mousepressed(x, y, button)
    if button == 1 then
        -- Teleport up: gives a fall to look at
        ball.y = 120
        ball.vy = 0
    elseif button == 2 then
        ball.vy = -560
        ball.squash = 0.25
    end
end

function M.keypressed(key)
    if key == " " and ball.grounded then
        -- Jump with a tiny anticipation squash first.
        ball.vy = -580
        ball.squash = 0.2
    end
end

function M.draw()
    utils.drawGrid()

    -- Ground
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, GROUND_Y, 1024, 200)

    -- Velocity arrow
    local sp = math.sqrt(ball.vx^2 + ball.vy^2)
    if sp > 5 then
        utils.drawVector(ball.x, ball.y, ball.vx, ball.vy, 0.06, {1, 1, 0})
    end

    -- The squash-and-stretch draw: an ellipse scaled independently.
    local rx = ball.r * ball.scaleX
    local ry = ball.r * ball.scaleY
    local angle = math.atan2(ball.vy, ball.vx)

    love.graphics.push()
    love.graphics.translate(ball.x, ball.y)
    love.graphics.rotate(angle)
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.ellipse("fill", 0, 0, rx, ry)
    love.graphics.pop()

    -- Rest-size reference ring
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.circle("line", ball.x, ball.y, ball.r)

    -- Live panel
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