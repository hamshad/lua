-- ============================================================
-- CHAPTER 10: Joints and Constraints
-- ============================================================
-- Joints connect bodies and constrain their relative motion.
--   Distance joint: enforces a fixed length — a rigid arm or rope
--   Revolute joint: hinge (rotation around a point)
--   Prismatic joint: linear sliding along an axis
-- The constraint solver iterates each frame to satisfy all joints.
--
-- Pendulum: pivot at (512,100), bob at (512,300), arm = 200px ≈ 6.67m
--   Period T = 2π√(L/g) = 2π√(6.67/9.81) ≈ 5.18s
--
-- KEYS: P = pendulum, C = chain
-- MOUSE: click to kick the bob

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local joints = {}
local bodies = {}

function M.init()
    world = love.physics.newWorld(0, 9.81 * 30, true)
    joints = {}
    bodies = {}
    M.createPendulum()
end

-- Pendulum: static pivot + dynamic bob joined by a distance joint
function M.createPendulum()
    local pivot = love.physics.newBody(world, 512, 100, "static")
    table.insert(bodies, {body = pivot, label = "Pivot", type = "static"})

    local bob = {
        body = love.physics.newBody(world, 512, 300, "dynamic"),
        shape = love.physics.newCircleShape(15),
        radius = 15,
        label = "Pendulum Bob",
        color = {1, 0.5, 0},
        type = "dynamic",
    }
    bob.fixture = love.physics.newFixture(bob.body, bob.shape, 1)
    bob.fixture:setFriction(0.3)
    bob.fixture:setRestitution(0.2)
    table.insert(bodies, bob)

    -- Distance joint = massless rigid arm of fixed length 200px
    local joint = love.physics.newDistanceJoint(
        pivot, bob.body,
        512, 100, 512, 300,
        false
    )
    joint:setLength(200)
    table.insert(joints, {joint = joint, label = "Distance Joint (arm length=200)", bodyA = pivot, bodyB = bob.body})
end

-- Chain: 8 links connected end-to-end, hanging from a static anchor
function M.createChain()
    for _, b in ipairs(bodies) do if b.body then b.body:destroy() end end
    for _, j in ipairs(joints) do if j.joint then j.joint:destroy() end end
    bodies = {}
    joints = {}

    local numLinks = 8
    local linkLength = 30
    local startX, startY = 512, 100

    local anchor = love.physics.newBody(world, startX, startY, "static")
    table.insert(bodies, {body = anchor, label = "Anchor", type = "static"})

    local prevBody = anchor
    for i = 1, numLinks do
        local body = love.physics.newBody(world, startX, startY + i * linkLength, "dynamic")
        local shape = love.physics.newCircleShape(8)
        local fixture = love.physics.newFixture(body, shape, 1)
        fixture:setFriction(0.3)
        fixture:setRestitution(0.2)
        table.insert(bodies, {body = body, label = "Link " .. i, type = "dynamic", color = {0.5, 0.5, 1}})

        local joint = love.physics.newDistanceJoint(
            prevBody, body,
            startX, startY + (i - 1) * linkLength,
            startX, startY + i * linkLength,
            false
        )
        joint:setLength(linkLength)
        table.insert(joints, {joint = joint, label = "Link " .. i .. " joint", bodyA = prevBody, bodyB = body})

        prevBody = body
    end
end

function M.update()
    world:update(FIXED_DT)
end

function M.draw()
    for _, b in ipairs(bodies) do
        if b.type == "static" then
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.circle("fill", b.body:getX(), b.body:getY(), 5)
        else
            love.graphics.setColor(b.color or {1, 1, 1})
            love.graphics.circle("fill", b.body:getX(), b.body:getY(), b.radius or 8)
        end
        love.graphics.setColor(1, 1, 1)
    end

    -- Draw each joint as a line between its two bodies
    for _, j in ipairs(joints) do
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.line(j.bodyA:getX(), j.bodyA:getY(), j.bodyB:getX(), j.bodyB:getY())
    end
    love.graphics.setColor(1, 1, 1)

    -- Live values panel
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 480, 180, "", {0, 0, 0, 0.8})

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("JOINTS & CONSTRAINTS — LIVE VALUES", px + 5, py + 2)

    if #bodies > 1 then
        local bob = bodies[#bodies]
        if bob.type == "dynamic" then
            local vx, vy = bob.body:getLinearVelocity()
            local angle = math.deg(bob.body:getAngle())
            local speed = math.sqrt(vx^2 + vy^2)

            love.graphics.print("Bob position: (" .. fmt(bob.body:getX()) .. ", " .. fmt(bob.body:getY()) .. ")", px + 5, py + 18)
            love.graphics.print("Velocity: (" .. fmt(vx) .. ", " .. fmt(vy) .. ")  |v| = " .. fmt(speed), px + 5, py + 34)
            love.graphics.print("Angle: " .. fmt(angle) .. "°  Angular velocity: " .. fmt(bob.body:getAngularVelocity()), px + 5, py + 50)
            love.graphics.print("KE = ½mv² = " .. fmt(0.5 * bob.body:getMass() * speed^2), px + 5, py + 66)

            -- T = 2π√(L/g); L = 200px / 30px/m ≈ 6.67m
            local L = 200 / 30
            local T = 2 * math.pi * math.sqrt(L / 9.81)
            love.graphics.print("Pendulum period: T = 2π√(L/g) = 2π√(" .. fmt(L) .. "/9.81) ≈ " .. fmt(T) .. "s", px + 5, py + 82)
        end
    end

    -- Feynman
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Joints are constraints. A distance joint enforces a fixed length between two points.", px, py + 100)
    love.graphics.print("A revolute joint allows rotation around a point (like a hinge). Chains of distance joints", px, py + 114)
    love.graphics.print("simulate ropes, chains, and soft bodies. The solver iterates to satisfy all constraints.", px, py + 128)
    love.graphics.print("A pendulum's period T = 2π√(L/g) is independent of mass and amplitude (Appendix D.10).", px, py + 142)

    -- Controls
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("P=Pendulum  C=Chain  Click=apply impulse to bob", 10, 680)
    love.graphics.setColor(1, 1, 1)
end

function M.mousepressed(x, y, button)
    if button == 1 and #bodies > 0 then
        -- Kick the first dynamic body toward the click
        local bob = nil
        for _, b in ipairs(bodies) do
            if b.type == "dynamic" then bob = b; break end
        end
        if bob then
            bob.body:applyLinearImpulse((x - bob.body:getX()) * 5, (y - bob.body:getY()) * 5)
        end
    end
end

function M.keypressed(key)
    if key == "p" then M.createPendulum() end
    if key == "c" then M.createChain() end
end

return M