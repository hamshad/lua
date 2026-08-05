-- ============================================================
-- CHAPTER 7: Gravity, Friction, and Restitution
-- ============================================================
-- Three surfaces side by side comparing μ and e:
--   Ice    (μ=0.1, e=0.1): slippery, no bounce
--   Rubber (μ=0.8, e=0.3): grippy, slight bounce
--   Bouncy (μ=0.5, e=0.9): moderate friction, high bounce
--
-- Drop from y=100 to surface y=680 (height 580):
--   Impact speed = sqrt(2*294.3*580) ≈ 584 px/s
--   Ice:    bounce 58 px/s  → ~6px  bounce (e² = 0.01)
--   Rubber: bounce 175 px/s → ~52px bounce (e² = 0.09)
--   Bouncy: bounce 526 px/s → ~469px bounce (e² = 0.81)

local utils = require("utils")
local fmt = utils.fmt
local drawVector = utils.drawVector
local drawTextBox = utils.drawTextBox

local M = {}

local balls = {}
local surfaces = {}

function M.init()
    balls = {}
    surfaces = {}
    world = love.physics.newWorld(0, 9.81 * 30, true)

    local defs = {
        {x=150, y=680, w=250, h=20, friction=0.1, restitution=0.1, color={0.2, 0.2, 0.8}, label="Ice (μ=0.1, e=0.1)"},
        {x=420, y=680, w=250, h=20, friction=0.8, restitution=0.3, color={0.2, 0.8, 0.2}, label="Rubber (μ=0.8, e=0.3)"},
        {x=690, y=680, w=250, h=20, friction=0.5, restitution=0.9, color={0.8, 0.2, 0.2}, label="Bouncy (μ=0.5, e=0.9)"},
    }

    for _, s in ipairs(defs) do
        local body = love.physics.newBody(world, s.x, s.y, "static")
        local shape = love.physics.newRectangleShape(s.w, s.h)
        local fixture = love.physics.newFixture(body, shape, 1)
        fixture:setFriction(s.friction)
        fixture:setRestitution(s.restitution)
        table.insert(surfaces, {body=body, shape=shape, label=s.label, friction=s.friction, restitution=s.restitution, color=s.color, x=s.x, y=s.y})
    end

    -- One ball per surface, dropped from the same height
    for i, s in ipairs(defs) do
        local ball = {
            body = love.physics.newBody(world, s.x - 100 + (i - 1) * 100, 100, "dynamic"),
            shape = love.physics.newCircleShape(12),
            radius = 12,
            surfaceIdx = i,
            bounceCount = 0,
            startY = 100,
        }
        ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
        ball.fixture:setFriction(s.friction)
        ball.fixture:setRestitution(s.restitution)
        table.insert(balls, ball)
    end
end

function M.update()
    world:update(FIXED_DT)

    -- Approximate bounce counter: ball moving up while above the surface
    for _, ball in ipairs(balls) do
        local vx, vy = ball.body:getLinearVelocity()
        if vy < -50 and ball.body:getY() < 670 then
            ball.bounceCount = ball.bounceCount + 1
        end
    end
end

function M.draw()
    for _, s in ipairs(surfaces) do
        love.graphics.setColor(s.color)
        love.graphics.polygon("fill", s.body:getWorldPoints(unpack({s.shape:getPoints()})))
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(s.label, s.x - 80, s.y - 15)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("μ=" .. s.friction .. "  e=" .. s.restitution, s.x - 60, s.y + 5)
        love.graphics.setColor(1, 1, 1)
    end

    for _, ball in ipairs(balls) do
        local s = surfaces[ball.surfaceIdx]
        love.graphics.setColor(s.color)
        love.graphics.circle("fill", ball.body:getX(), ball.body:getY(), ball.radius)
        love.graphics.setColor(1, 1, 1)

        local vx, vy = ball.body:getLinearVelocity()
        if math.abs(vx) + math.abs(vy) > 1 then
            drawVector(ball.body:getX(), ball.body:getY(), vx * 0.02, vy * 0.02, 1, {1, 1, 0})
        end
    end

    -- Live values panel
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 480, 180, "", {0, 0, 0, 0.8})

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SURFACE COMPARISON — LIVE VALUES", px + 5, py + 2)

    local yOff = 18
    for i, ball in ipairs(balls) do
        local s = surfaces[ball.surfaceIdx]
        local vx, vy = ball.body:getLinearVelocity()
        local speed = math.sqrt(vx^2 + vy^2)
        local height = math.max(0, 680 - ball.body:getY())
        local ke = 0.5 * ball.body:getMass() * speed^2
        local pe = ball.body:getMass() * 9.81 * 30 * height

        love.graphics.print("Surface " .. i .. " (" .. s.label .. "):", px + 5, py + yOff)
        love.graphics.print("  pos=(" .. fmt(ball.body:getX()) .. ", " .. fmt(ball.body:getY()) .. ")  vel=(" .. fmt(vx) .. ", " .. fmt(vy) .. ")", px + 5, py + yOff + 16)
        love.graphics.print("  speed=" .. fmt(speed) .. "  height=" .. fmt(height) .. "  KE=" .. fmt(ke) .. "  PE=" .. fmt(pe), px + 5, py + yOff + 30)
        love.graphics.print("  bounces=" .. ball.bounceCount .. "  e=" .. s.restitution .. "  μ=" .. s.friction, px + 5, py + yOff + 44)
        yOff = yOff + 62
    end

    -- Feynman explanation
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Restitution e determines bounce height. After one bounce, the ball returns to e² of", px, py + 150)
    love.graphics.print("its drop height (h' = e²·h); after n bounces hₙ = e²ⁿ·h. So e=0.9 → 81%, e=0.5 → 25%.", px, py + 164)
    love.graphics.print("Friction μ caps tangential force: F_f ≤ μ·F_normal (Coulomb). Ice μ≈0.1, rubber μ≈0.8.", px, py + 178)
end

return M