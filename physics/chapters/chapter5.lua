-- ============================================================
-- CHAPTER 5: Kinematics — Projectile Motion
-- ============================================================
-- Projectile motion is the superposition of two independent motions:
--   Horizontal: constant velocity (no acceleration)
--   Vertical:   constant acceleration (gravity)
-- The path is a parabola.
--
--   x(t) = x₀ + vx₀ * t
--   y(t) = y₀ + vy₀ * t + ½*g*t²
--   Range:       R = v₀² * sin(2θ) / g
--   Max height:  H = v₀² * sin²(θ) / (2g)
--   Time of flight: T = 2*v₀*sin(θ)/g
--
-- Launch at 400 px/s, 45°:
--   vx₀ = vy₀ = 400 * 0.707 ≈ 283 px/s
--   From y=650 with g=294.3: hits ground (y=700) at t ≈ 0.56s
--
-- MOUSE: click to launch the ball toward the cursor

local utils = require("utils")
local fmt = utils.fmt
local drawVector = utils.drawVector
local drawTextBox = utils.drawTextBox
local createGround = utils.createGround

local M = {}

local GRAVITY = 9.81 * 30  -- pixels/s²
local LAUNCH_POWER = 400   -- px/s
local projectile = {}
local trail = {}
local targets = {}
local landed = false
local time = 0

function M.init()
    world = love.physics.newWorld(0, GRAVITY, true)
    createGround(1024, 20, 0.5, 0.3)

    -- Target rectangle to hit
    local tBody = love.physics.newBody(world, 700, 680, "static")
    local tShape = love.physics.newRectangleShape(40, 20)
    local tFixture = love.physics.newFixture(tBody, tShape, 1)
    tFixture:setFriction(0.5)
    tFixture:setRestitution(0.3)
    targets = {{body = tBody, shape = tShape, label = "Target"}}

    -- Projectile ball
    projectile = {
        body = love.physics.newBody(world, 100, 650, "dynamic"),
        shape = love.physics.newCircleShape(8),
        radius = 8,
        launched = false,
        vx0 = 0, vy0 = 0,
    }
    projectile.fixture = love.physics.newFixture(projectile.body, projectile.shape, 1)
    projectile.fixture:setRestitution(0.3)
    projectile.fixture:setFriction(0.2)

    trail = {}
    landed = false
    time = 0
end

function M.update()
    world:update(FIXED_DT)

    local b = projectile
    if b.launched then
        time = time + FIXED_DT

        table.insert(trail, {b.body:getX(), b.body:getY()})
        if #trail > 500 then table.remove(trail, 1) end

        -- Landed = near ground AND barely moving
        local vx, vy = b.body:getLinearVelocity()
        if b.body:getY() > 690 and math.abs(vy) < 5 then
            b.launched = false
            landed = true
        end
    end
end

function M.draw()
    local b = projectile

    -- Trail
    if #trail > 1 then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        for i = 1, #trail - 1 do
            love.graphics.line(trail[i][1], trail[i][2], trail[i+1][1], trail[i+1][2])
        end
    end

    -- Target
    love.graphics.setColor(1, 0, 0)
    love.graphics.polygon("fill", targets[1].body:getWorldPoints(unpack({targets[1].shape:getPoints()})))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("TARGET", 690, 660)

    -- Projectile
    if b.launched or landed then
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.circle("fill", b.body:getX(), b.body:getY(), b.radius)
        love.graphics.setColor(1, 1, 1)
    end

    -- Predicted trajectory (yellow dots) via the kinematic equations
    if b.launched and b.vx0 ~= 0 then
        love.graphics.setColor(1, 1, 0, 0.5)
        local px, py = b.body:getX(), b.body:getY()
        local pvx, pvy = b.body:getLinearVelocity()
        for i = 1, 100 do
            local t = i * 0.05
            local tx = px + pvx * t
            local ty = py + pvy * t + 0.5 * GRAVITY * t * t
            if ty > 700 then break end
            love.graphics.circle("fill", tx, ty, 2)
        end
        love.graphics.setColor(1, 1, 1)
    end

    -- Live calculations panel
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 480, 180, "", {0, 0, 0, 0.8})

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("PROJECTILE MOTION — LIVE CALCULATIONS", px + 5, py + 2)

    if b.launched or landed then
        local vx, vy = b.body:getLinearVelocity()
        local speed = math.sqrt(vx^2 + vy^2)
        local height = math.max(0, 680 - b.body:getY())

        love.graphics.print("t = " .. fmt(time) .. "s", px + 5, py + 18)
        love.graphics.print("Position: (" .. fmt(b.body:getX()) .. ", " .. fmt(b.body:getY()) .. ")", px + 5, py + 34)
        love.graphics.print("Velocity: (" .. fmt(vx) .. ", " .. fmt(vy) .. ")  |v| = " .. fmt(speed), px + 5, py + 50)
        love.graphics.print("Height: " .. fmt(height) .. "px", px + 5, py + 66)
        love.graphics.print("KE = ½mv² = " .. fmt(0.5 * 1 * speed^2), px + 5, py + 82)
        love.graphics.print("PE = mgh = " .. fmt(1 * GRAVITY * height), px + 5, py + 98)
        love.graphics.print("E_total = " .. fmt(0.5 * speed^2 + GRAVITY * height), px + 5, py + 114)

        if b.vx0 ~= 0 then
            local v0 = math.sqrt(b.vx0^2 + b.vy0^2)
            local angle = math.deg(math.atan2(-b.vy0, b.vx0))
            local range = v0^2 * math.sin(2 * math.rad(angle)) / GRAVITY
            local maxH = v0^2 * math.sin(math.rad(angle))^2 / (2 * GRAVITY)
            love.graphics.print("Launch: v₀=" .. fmt(v0) .. "  θ=" .. fmt(angle) .. "°", px + 5, py + 130)
            love.graphics.print("Predicted range: " .. fmt(range) .. "px  Max height: " .. fmt(maxH) .. "px", px + 5, py + 146)
        end
    else
        love.graphics.print("Click to launch the projectile!", px + 5, py + 18)
        love.graphics.print("The trajectory is a parabola:", px + 5, py + 34)
        love.graphics.print("  x(t) = x₀ + vx₀*t", px + 5, py + 50)
        love.graphics.print("  y(t) = y₀ + vy₀*t + ½*g*t²", px + 5, py + 66)
        love.graphics.print("  Range: R = v₀²*sin(2θ)/g", px + 5, py + 82)
        love.graphics.print("  Max Height: H = v₀²*sin²(θ)/(2g)", px + 5, py + 98)
    end

    -- Feynman explanation
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Projectile motion is the superposition of two independent motions:", px, py + 155)
    love.graphics.print("horizontal (constant velocity) and vertical (constant acceleration). The path is a parabola.", px, py + 169)
    love.graphics.print("Range R = v₀²·sin(2θ)/g peaks at 45° (full derivation: Appendix D.7).", px, py + 183)
end

function M.mousepressed(x, y, button)
    if button == 1 and not projectile.launched then
        projectile.body:setTransform(100, 650, 0)
        projectile.body:setLinearVelocity(0, 0)
        trail = {}
        time = 0
        landed = false
        projectile.launched = true

        -- Aim toward the click, fixed power. Negate dy: LÖVE y is flipped.
        local dx = x - 100
        local dy = -(y - 650)
        local dirLen = math.sqrt(dx^2 + dy^2)
        projectile.body:setLinearVelocity(dx / dirLen * LAUNCH_POWER, dy / dirLen * LAUNCH_POWER)
        projectile.vx0 = dx / dirLen * LAUNCH_POWER
        projectile.vy0 = dy / dirLen * LAUNCH_POWER
    end
end

return M
