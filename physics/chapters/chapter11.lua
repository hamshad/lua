-- ============================================================
-- CHAPTER 11: Raycasting, Sensors, and Queries
-- ============================================================
-- Raycasting: cast an invisible line, get what it hits first.
--   Returns hit point, normal, and fraction (0=start, 1=end).
--   Used for line-of-sight, shooting, visibility checks.
--
-- Sensors: fixtures that detect overlap but give NO collision
--   response. Used for trigger zones, pickup detection, proximity.
--   setSensor(true) → only begin/endContact fire.
--
-- Ray from (100,384) to (900,384): hits box at y=384 only if a
--   box crosses that line. Return fraction from the callback to
--   keep searching for the closest hit.
--
-- MOUSE: left-click = ray END, right-click = ray START

local utils = require("utils")
local fmt = utils.fmt
local drawVector = utils.drawVector
local drawTextBox = utils.drawTextBox
local createGround = utils.createGround
local createWall = utils.createWall

local M = {}

local ray = {x1 = 100, y1 = 384, x2 = 900, y2 = 384}
local sensors = {}
local bodies = {}
local rayHits = {}
local overlapBodies = {}

-- A fixture entered the sensor zone: add the other dynamic body.
local function beginContact(a, b, contact)
    local udA, udB = a:getUserData(), b:getUserData()
    if udA == "sensor" or udB == "sensor" then
        local otherFixture = (udA == "sensor") and b or a
        local otherBody = otherFixture:getBody()
        if otherBody:getType() == "dynamic" then
            table.insert(overlapBodies, otherBody)
        end
    end
end

-- A fixture left the sensor zone: remove the other body.
local function endContact(a, b, contact)
    local udA, udB = a:getUserData(), b:getUserData()
    if udA == "sensor" or udB == "sensor" then
        local otherBody = (udA == "sensor") and b:getBody() or a:getBody()
        for i, body in ipairs(overlapBodies) do
            if body == otherBody then
                table.remove(overlapBodies, i)
                break
            end
        end
    end
end

function M.init()
    overlapBodies = {}
    rayHits = {}
    world = love.physics.newWorld(0, 9.81 * 30, true)
    createGround(1024, 20, 0.5, 0.3)
    createWall(100, 384, 20, 300, 0.5, 0.3)
    createWall(900, 384, 20, 300, 0.5, 0.3)

    -- Box 1 (orange) and Box 2 (green)
    local box1 = {
        body = love.physics.newBody(world, 300, 300, "dynamic"),
        shape = love.physics.newRectangleShape(30, 30),
        radius = 0, label = "Box 1", color = {1, 0.5, 0},
    }
    box1.fixture = love.physics.newFixture(box1.body, box1.shape, 1)
    box1.fixture:setFriction(0.3)
    box1.fixture:setRestitution(0.3)

    local box2 = {
        body = love.physics.newBody(world, 700, 300, "dynamic"),
        shape = love.physics.newRectangleShape(30, 30),
        radius = 0, label = "Box 2", color = {0.5, 1, 0},
    }
    box2.fixture = love.physics.newFixture(box2.body, box2.shape, 1)
    box2.fixture:setFriction(0.3)
    box2.fixture:setRestitution(0.3)

    -- Sensor: static circle, radius 80, no physical response
    local sensorBody = love.physics.newBody(world, 512, 384, "static")
    local sensorShape = love.physics.newCircleShape(80)
    local sensorFixture = love.physics.newFixture(sensorBody, sensorShape, 1)
    sensorFixture:setSensor(true)
    sensorFixture:setUserData("sensor")

    sensors = {{body = sensorBody, shape = sensorShape, label = "Sensor Zone (r=80m)"}}
    bodies = {box1, box2}
    overlapBodies = {}

    world:setCallbacks(beginContact, endContact, nil, nil)
end

function M.update()
    world:update(FIXED_DT)

    -- Ray cast: collect every hit, keep searching for closest
    rayHits = {}
    world:rayCast(ray.x1, ray.y1, ray.x2, ray.y2,
        function(fixture, x, y, nx, ny, fraction)
            table.insert(rayHits, {x = x, y = y, normal = {x = nx, y = ny}, fraction = fraction, fixture = fixture})
            return fraction
        end)
end

function M.draw()
    -- Sensor zone (green, semi-transparent)
    for _, s in ipairs(sensors) do
        love.graphics.setColor(0, 1, 0, 0.2)
        love.graphics.circle("fill", s.body:getX(), s.body:getY(), 80)
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.circle("line", s.body:getX(), s.body:getY(), 80)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(s.label, s.body:getX() - 70, s.body:getY() - 95)
    end

    -- Bodies
    for _, b in ipairs(bodies) do
        love.graphics.setColor(b.color)
        love.graphics.polygon("fill", b.body:getWorldPoints(unpack({b.shape:getPoints()})))
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(b.label, b.body:getX() - 20, b.body:getY() - 40)

        local overlapping = false
        for _, ob in ipairs(overlapBodies) do
            if ob == b.body then overlapping = true; break end
        end
        if overlapping then
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("IN SENSOR!", b.body:getX() - 25, b.body:getY() - 55)
            love.graphics.setColor(1, 1, 1)
        end
    end

    -- Ray (dashed yellow)
    love.graphics.setColor(1, 1, 0)
    love.graphics.setLineStyle("rough")
    love.graphics.line(ray.x1, ray.y1, ray.x2, ray.y2)
    love.graphics.setLineStyle("smooth")

    -- Hit points (red) + normals (cyan arrows)
    for _, hit in ipairs(rayHits) do
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", hit.x, hit.y, 5)
        drawVector(hit.x, hit.y, hit.normal.x * 20, hit.normal.y * 20, 1, {0, 1, 1})
    end
    love.graphics.setColor(1, 1, 1)

    love.graphics.print("Ray: (" .. ray.x1 .. ", " .. ray.y1 .. ") → (" .. ray.x2 .. ", " .. ray.y2 .. ")", ray.x1, ray.y1 - 15)

    -- Live values panel
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 480, 180, "", {0, 0, 0, 0.8})

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("RAYCASTING & SENSORS — LIVE VALUES", px + 5, py + 2)

    love.graphics.print("Ray hits: " .. #rayHits, px + 5, py + 18)
    for i, hit in ipairs(rayHits) do
        love.graphics.print("  Hit " .. i .. ": (" .. fmt(hit.x) .. ", " .. fmt(hit.y) .. ")  fraction=" .. fmt(hit.fraction) .. "  normal=(" .. fmt(hit.normal.x) .. ", " .. fmt(hit.normal.y) .. ")", px + 5, py + 34 + (i - 1) * 18)
    end

    love.graphics.print("Bodies in sensor zone: " .. #overlapBodies, px + 5, py + 18 + #rayHits * 18 + 10)
    for _, b in ipairs(overlapBodies) do
        love.graphics.print("  " .. b:getType() .. " at (" .. fmt(b:getX()) .. ", " .. fmt(b:getY()) .. ")", px + 5, py + 34 + #rayHits * 18 + 28)
    end

    -- Feynman
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Raycasting casts an invisible line and reports what it hits. Sensors detect overlap", px, py + 100)
    love.graphics.print("without physical response — perfect for trigger zones, proximity detection, and line of sight.", px, py + 114)
    love.graphics.print("Box2D raycasts return the fixture, intersection point, surface normal, and a 0-1 fraction", px, py + 128)
    love.graphics.print("along the ray (LÖVE docs: World:rayCast). R = start→mouse, held to sweep.", px, py + 142)
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