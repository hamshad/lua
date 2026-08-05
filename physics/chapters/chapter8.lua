-- ============================================================
-- CHAPTER 8: Collision Detection — The Maths Under the Hood
-- ============================================================
-- Two circles collide when: distance(centers) < rA + rB
--   Collision normal:  n = (B - A) / |B - A|
--   Penetration depth: d = (rA + rB) - distance(A, B)
--
-- A at (300,200) r=20, B at (500,200) r=20:
--   distance = sqrt(200²) = 200, sum = 40 → 200 > 40: NOT colliding
--   A moves right; at dist 40 → touching, at 35 → colliding (penetration 5)
--
-- MOUSE: left-click moves ray END, right-click moves ray START

local utils = require("utils")
local fmt = utils.fmt
local drawVector = utils.drawVector
local drawTextBox = utils.drawTextBox
local createGround = utils.createGround

local M = {}

local circles = {}
local ray = {x1 = 100, y1 = 400, x2 = 900, y2 = 400}
local rayResult = nil
local collisionPoints = {}

-- Fired when two fixtures start overlapping. We record the midpoint
-- of the two bodies as a yellow flash (Box2D 11.5 has no getWorldManifold).
local function beginContact(a, b, contact)
    local body1 = a:getBody()
    local body2 = b:getBody()
    local x1, y1 = body1:getPosition()
    local x2, y2 = body2:getPosition()
    table.insert(collisionPoints, {x = (x1 + x2) / 2, y = (y1 + y2) / 2, life = 1.0})
end

function M.init()
    world = love.physics.newWorld(0, 9.81 * 30, true)
    createGround(1024, 20, 0.5, 0.3)

    -- Circle A: red, moving right toward B
    local c1 = {
        body = love.physics.newBody(world, 300, 200, "dynamic"),
        shape = love.physics.newCircleShape(20),
        radius = 20, color = {1, 0, 0}, label = "Circle A (r=20)",
    }
    c1.fixture = love.physics.newFixture(c1.body, c1.shape, 1)
    c1.fixture:setRestitution(0.8)
    c1.fixture:setFriction(0.3)
    c1.body:setLinearVelocity(100, 0)

    -- Circle B: blue, stationary, gets hit ~2s in
    local c2 = {
        body = love.physics.newBody(world, 500, 200, "dynamic"),
        shape = love.physics.newCircleShape(20),
        radius = 20, color = {0, 0, 1}, label = "Circle B (r=20)",
    }
    c2.fixture = love.physics.newFixture(c2.body, c2.shape, 1)
    c2.fixture:setRestitution(0.8)
    c2.fixture:setFriction(0.3)

    circles = {c1, c2}
    ray = {x1 = 100, y1 = 400, x2 = 900, y2 = 400}
    rayResult = nil
    collisionPoints = {}

    world:setCallbacks(beginContact, nil, nil, nil)
end

function M.update()
    world:update(FIXED_DT)

    -- Decay collision flashes
    for i = #collisionPoints, 1, -1 do
        collisionPoints[i].life = collisionPoints[i].life - FIXED_DT
        if collisionPoints[i].life <= 0 then
            table.remove(collisionPoints, i)
        end
    end

    -- Ray cast: return fraction to keep searching for the closest hit
    rayResult = world:rayCast(ray.x1, ray.y1, ray.x2, ray.y2,
        function(fixture, x, y, normal, fraction)
            return fraction
        end)
end

function M.draw()
    for _, c in ipairs(circles) do
        love.graphics.setColor(c.color)
        love.graphics.circle("fill", c.body:getX(), c.body:getY(), c.radius)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(c.label, c.body:getX() - 30, c.body:getY() - c.radius - 15)

        local vx, vy = c.body:getLinearVelocity()
        drawVector(c.body:getX(), c.body:getY(), vx * 0.02, vy * 0.02, 1, {1, 1, 0})
    end

    -- Ray (dashed yellow)
    love.graphics.setColor(1, 1, 0)
    love.graphics.setLineStyle("rough")
    love.graphics.line(ray.x1, ray.y1, ray.x2, ray.y2)
    love.graphics.setLineStyle("smooth")
    love.graphics.print("Ray: (" .. ray.x1 .. ", " .. ray.y1 .. ") → (" .. ray.x2 .. ", " .. ray.y2 .. ")", ray.x1, ray.y1 - 15)

    -- Collision flash points (fade over 1s)
    for _, p in ipairs(collisionPoints) do
        love.graphics.setColor(1, 1, 0, math.max(0, p.life))
        love.graphics.circle("fill", p.x, p.y, 5)
    end
    love.graphics.setColor(1, 1, 1)

    -- Collision math panel
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 480, 180, "", {0, 0, 0, 0.8})

    local c1, c2 = circles[1], circles[2]
    local dx = c2.body:getX() - c1.body:getX()
    local dy = c2.body:getY() - c1.body:getY()
    local dist = math.sqrt(dx^2 + dy^2)
    local minDist = c1.radius + c2.radius
    local overlap = minDist - dist

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("COLLISION DETECTION MATH", px + 5, py + 2)
    love.graphics.print("Circle A center: (" .. fmt(c1.body:getX()) .. ", " .. fmt(c1.body:getY()) .. ")", px + 5, py + 18)
    love.graphics.print("Circle B center: (" .. fmt(c2.body:getX()) .. ", " .. fmt(c2.body:getY()) .. ")", px + 5, py + 34)
    love.graphics.print("Distance: d = sqrt(" .. fmt(dx)^2 .. " + " .. fmt(dy)^2 .. ") = " .. fmt(dist), px + 5, py + 50)
    love.graphics.print("Sum of radii: r₁ + r₂ = " .. c1.radius .. " + " .. c2.radius .. " = " .. minDist, px + 5, py + 66)
    love.graphics.print("Colliding: " .. (dist < minDist and "YES (overlap=" .. fmt(overlap) .. ")" or "NO"), px + 5, py + 82)
    love.graphics.print("Collision normal: n = (dx/d, dy/d) = (" .. fmt(dx/dist) .. ", " .. fmt(dy/dist) .. ")", px + 5, py + 98)
    love.graphics.print("Relative velocity: v_rel = v₁ - v₂", px + 5, py + 114)
    love.graphics.print("Approach speed: v_rel · n (dot product)", px + 5, py + 130)

    -- Feynman
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Box2D uses a two-phase approach. Broad-phase (AABB tree) quickly eliminates", px, py + 150)
    love.graphics.print("non-overlapping pairs. Narrow-phase uses SAT for convex polygons, distance for circles,", px, py + 164)
    love.graphics.print("and CCD (Continuous Collision Detection) to stop tunneling at high speeds (Appendix E, Ch.8).", px, py + 178)
end

function M.mousepressed(x, y, button)
    if button == 1 then
        ray.x2 = x
        ray.y2 = y
    elseif button == 2 then
        ray.x1 = x
        ray.y1 = y
    end
end

return M