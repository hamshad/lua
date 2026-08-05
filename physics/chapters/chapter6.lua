-- ============================================================
-- CHAPTER 6: Dynamics — F=ma with Forces Visualization
-- ============================================================
-- Visualize all forces on a box in real time. The net force
-- determines acceleration → velocity → position.
--
-- One frame with right arrow held (m=1kg):
--   F_applied = 3000 N, gravity = 294.3 N down, normal = 294.3 up
--   F_net = (3000, 0),  a = (3000, 0) px/s²
--   vx = 0 + 3000/60 = 50 px/s,  x = 200 + 50/60 = 200.83 px
--
-- Arrows: gravity=blue, normal=green, applied=red, net=yellow
-- KEYS: arrow keys apply force  |  MOUSE: kick toward cursor

local utils = require("utils")
local fmt = utils.fmt
local drawVector = utils.drawVector
local drawTextBox = utils.drawTextBox
local createGround = utils.createGround

local M = {}

local GRAVITY = 9.81 * 30  -- pixels/s²
local box = {}
local forcesList = {}
local appliedForce = {fx = 0, fy = 0}

function M.init()
    world = love.physics.newWorld(0, GRAVITY, true)
    createGround(1024, 20, 0.5, 0.3)

    -- 40x40 dynamic box, mass ≈ 1 kg
    box = {
        body = love.physics.newBody(world, 200, 650, "dynamic"),
        shape = love.physics.newRectangleShape(40, 40),
        mass = 1,
        radius = 0,
    }
    box.fixture = love.physics.newFixture(box.body, box.shape, 1)
    box.fixture:setFriction(0.4)
    box.fixture:setRestitution(0.2)

    forcesList = {}
    appliedForce = {fx = 0, fy = 0}
end

function M.update()
    world:update(FIXED_DT)

    local b = box
    local vx, vy = b.body:getLinearVelocity()

    -- Apply user force (from arrow keys / click)
    if appliedForce.fx ~= 0 or appliedForce.fy ~= 0 then
        b.body:applyForce(appliedForce.fx, appliedForce.fy)
    end

    -- Display acceleration: gravity always present
    local mass = b.body:getMass()
    local ax = appliedForce.fx / mass
    local ay = appliedForce.fy / mass + GRAVITY

    table.insert(forcesList, {
        t = #forcesList * FIXED_DT,
        fx = appliedForce.fx, fy = appliedForce.fy,
        ax = ax, ay = ay,
        vx = vx, vy = vy,
        px = b.body:getX(), py = b.body:getY(),
        ke = 0.5 * mass * (vx^2 + vy^2),
    })
    if #forcesList > 300 then table.remove(forcesList, 1) end
end

function M.draw()
    local b = box
    local px, py = b.body:getX(), b.body:getY()

    -- Ground and box
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, 700, 1024, 68)
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.rectangle("fill", px - 20, py - 20, 40, 40)
    love.graphics.setColor(1, 1, 1)

    -- Applied force (red)
    if appliedForce.fx ~= 0 or appliedForce.fy ~= 0 then
        drawVector(px, py, appliedForce.fx * 0.005, appliedForce.fy * 0.005, 1, {1, 0, 0})
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("F_applied = (" .. fmt(appliedForce.fx) .. ", " .. fmt(appliedForce.fy) .. ")", px + 20, py - 20)
    end

    -- Gravity (blue)
    local weight = b.body:getMass() * GRAVITY
    drawVector(px, py, 0, weight * 0.005, 1, {0, 0, 1})
    love.graphics.setColor(0, 0, 1)
    love.graphics.print("F_gravity = m*g = " .. fmt(b.body:getMass()) .. " * 9.81*30 = " .. fmt(weight), px + 20, py)

    -- Normal force (green) — cancels gravity while on the ground
    if b.body:getY() > 680 then
        drawVector(px, py, 0, -weight * 0.005, 1, {0, 1, 0})
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("F_normal = -F_gravity = " .. fmt(-weight), px + 20, py + 18)
    end

    -- Net force (yellow)
    local netFx = appliedForce.fx
    local netFy = appliedForce.fy + weight
    if b.body:getY() > 680 then netFy = appliedForce.fy end
    drawVector(px, py, netFx * 0.005, netFy * 0.005, 1, {1, 1, 0})
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("F_net = (" .. fmt(netFx) .. ", " .. fmt(netFy) .. ")", px + 20, py + 36)

    -- Live values panel
    local pxx, pyy = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(pxx, pyy, 460, 180, "", {0, 0, 0, 0.8})

    local vx, vy = b.body:getLinearVelocity()
    local mass = b.body:getMass()
    local ax = netFx / mass
    local ay = netFy / mass

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("F = ma — LIVE VALUES", pxx + 5, pyy + 2)
    love.graphics.print("mass = " .. fmt(mass) .. " kg", pxx + 5, pyy + 18)
    love.graphics.print("F_net = (" .. fmt(netFx) .. ", " .. fmt(netFy) .. ") N", pxx + 5, pyy + 34)
    love.graphics.print("a = F/m = (" .. fmt(ax) .. ", " .. fmt(ay) .. ") m/s²", pxx + 5, pyy + 50)
    love.graphics.print("v = (" .. fmt(vx) .. ", " .. fmt(vy) .. ") m/s  |v| = " .. fmt(math.sqrt(vx^2 + vy^2)), pxx + 5, pyy + 66)
    love.graphics.print("p = (" .. fmt(b.body:getX()) .. ", " .. fmt(b.body:getY()) .. ") m", pxx + 5, pyy + 82)
    love.graphics.print("KE = ½ * " .. fmt(mass) .. " * " .. fmt(vx^2 + vy^2) .. " = " .. fmt(0.5 * mass * (vx^2 + vy^2)) .. " J", pxx + 5, pyy + 98)
    love.graphics.print("Work = F·d = " .. fmt(netFx * (b.body:getX() - 200)) .. " J (from start)", pxx + 5, pyy + 114)

    -- Feynman explanation
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: F = ma. Force causes acceleration. Acceleration changes velocity. Velocity changes", pxx, pyy + 130)
    love.graphics.print("position. That's the entire chain of Newtonian mechanics. Every game physics engine does this.", pxx, pyy + 144)
    love.graphics.print("The net force is the vector sum of ALL forces: gravity + applied + normal + friction.", pxx, pyy + 158)

    -- Controls
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Arrow keys: apply force  |  SPACE: reset", 10, 680)
    love.graphics.setColor(1, 1, 1)
end

function M.mousepressed(x, y, button)
    -- Kick the box toward the click point
    local px, py = box.body:getPosition()
    local dx = x - px
    local dy = -(y - py)  -- flip y: LÖVE y points down
    local force = 5000
    local dirLen = math.sqrt(dx^2 + dy^2 + 0.001)
    appliedForce.fx = dx / dirLen * force
    appliedForce.fy = dy / dirLen * force
end

function M.keypressed(key)
    local f = 3000
    if key == "right" then appliedForce.fx = appliedForce.fx + f end
    if key == "left" then appliedForce.fx = appliedForce.fx - f end
    if key == "up" then appliedForce.fy = appliedForce.fy - f end
    if key == "down" then appliedForce.fy = appliedForce.fy + f end
end

return M
