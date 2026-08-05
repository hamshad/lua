-- ============================================================
-- CHAPTER 3: First LÖVE2D World — love.physics
-- ============================================================
-- love.physics is LÖVE2D's Box2D wrapper.
--   World:   container that holds bodies and runs the simulation
--   Body:    position, velocity, mass
--     "static"    → infinite mass, never moves (floors, walls)
--     "dynamic"   → fully simulated (balls, crates)
--     "kinematic" → moved by code, ignores forces (moving platforms)
--   Shape:   collision geometry (circle, rectangle, polygon)
--   Fixture: attaches shape to body, holds material properties
--     density     → mass = density * area
--     friction    → surface grip (0 = ice, 1 = rough)
--     restitution → bounciness (0 = none, 1 = perfect)
--
-- Restitution walkthrough (drop from y=100 to ground y=700):
--   Drop height = 600px
--   Impact speed = sqrt(2*g*h) = sqrt(2*294.3*600) ≈ 594 px/s
--   e=0.7 → bounce speed = 594*0.7 = 416 px/s
--   Bounce height = 416²/(2*294.3) ≈ 293px ≈ 49% (0.7² = 0.49)
--
-- MOUSE: click to spawn a ball with random velocity

local utils = require("utils")
local fmt = utils.fmt
local drawVector = utils.drawVector
local drawTextBox = utils.drawTextBox
local createGround = utils.createGround
local createWall = utils.createWall
local createBall = utils.createBall

local M = {}

local bodies = {}

-- beginContact/endContact are Box2D callbacks fired when two fixtures
-- start/stop overlapping. In a real game you'd play sounds, spawn
-- particles, or apply damage here. This demo lets Box2D handle physics.
local function beginContact(a, b, contact)
end

local function endContact(a, b, contact)
end

function M.init()
    bodies = {}
    world = love.physics.newWorld(0, 9.81 * 30, true)
    world:setCallbacks(beginContact, endContact, nil, nil)

    -- Static ground and walls contain the scene
    local gBody, gShape = createGround(1024, 20, 0.5, 0.3)
    table.insert(bodies, {body = gBody, shape = gShape, type = "ground", label = "Static Ground"})
    local lBody, lShape = createWall(10, 380, 20, 760, 0.5, 0.3)
    table.insert(bodies, {body = lBody, shape = lShape, type = "ground", label = "Left Wall"})
    local rBody, rShape = createWall(1014, 380, 20, 760, 0.5, 0.3)
    table.insert(bodies, {body = rBody, shape = rShape, type = "ground", label = "Right Wall"})

    -- Four dynamic balls, one per restitution value
    local configs = {
        {x=200, y=100, r=15, density=1.0, friction=0.3, restitution=0.7, color={1,0,0}, label="Red Ball (e=0.7)"},
        {x=400, y=100, r=15, density=1.0, friction=0.3, restitution=0.2, color={0,1,0}, label="Green Ball (e=0.2)"},
        {x=600, y=100, r=15, density=1.0, friction=0.3, restitution=1.0, color={0,0,1}, label="Blue Ball (e=1.0)"},
        {x=800, y=100, r=15, density=3.0, friction=0.5, restitution=0.5, color={1,1,0}, label="Yellow Ball (mass=3, e=0.5)"},
    }
    for _, cfg in ipairs(configs) do
        local body, shape, radius = createBall(cfg.x, cfg.y, cfg.r, cfg.density, cfg.friction, cfg.restitution)
        table.insert(bodies, {
            body = body, shape = shape, radius = radius,
            type = "dynamic", label = cfg.label, color = cfg.color,
            density = cfg.density, restitution = cfg.restitution,
        })
    end
end

function M.update()
    -- One physics step: collision detection → impulse solving →
    -- position correction → integration. ~0.1ms for a scene like this.
    world:update(FIXED_DT)
end

function M.draw()
    for _, b in ipairs(bodies) do
        if b.type == "ground" then
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.polygon("fill", b.body:getWorldPoints(unpack({b.shape:getPoints()})))
        else
            love.graphics.setColor(b.color)
            love.graphics.circle("fill", b.body:getX(), b.body:getY(), b.radius)
            love.graphics.setColor(1, 1, 1)

            -- Velocity vector (yellow)
            local vx, vy = b.body:getLinearVelocity()
            if math.abs(vx) + math.abs(vy) > 1 then
                drawVector(b.body:getX(), b.body:getY(), vx * 0.02, vy * 0.02, 1, {1, 1, 0})
            end
        end
    end

    -- Live values panel
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 420, 180, "", {0, 0, 0, 0.8})

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES (Box2D Simulation)", px + 5, py + 2)

    local idx = 1
    for _, b in ipairs(bodies) do
        if b.type == "dynamic" then
            local vx, vy = b.body:getLinearVelocity()
            local speed = math.sqrt(vx^2 + vy^2)
            local ke = 0.5 * b.body:getMass() * speed^2

            love.graphics.print(b.label .. ":", px + 5, py + 18 + idx * 22)
            love.graphics.print("  pos=(" .. fmt(b.body:getX()) .. ", " .. fmt(b.body:getY()) .. ")  vel=(" .. fmt(vx) .. ", " .. fmt(vy) .. ")", px + 5, py + 32 + idx * 22)
            love.graphics.print("  speed=" .. fmt(speed) .. "  KE=" .. fmt(ke) .. "  mass=" .. fmt(b.body:getMass()) .. "  e=" .. b.restitution, px + 5, py + 46 + idx * 22)
            idx = idx + 1
        end
    end

    -- Feynman explanation
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: All collisions conserve momentum. With restitution e=1, kinetic energy is also", px, py + 150)
    love.graphics.print("conserved (elastic). With e=0, objects stick together (perfectly inelastic). With e=0.7,", px, py + 164)
    love.graphics.print("the ball bounces back to 49% of its drop height (0.7² = 0.49).", px, py + 178)
end

function M.mousepressed(x, y, button)
    if button == 1 then
        -- Spawn a ball with a random upward-ish velocity
        local body = love.physics.newBody(world, x, y, "dynamic")
        local shape = love.physics.newCircleShape(10)
        local fixture = love.physics.newFixture(body, shape, 1)
        fixture:setFriction(0.3)
        fixture:setRestitution(0.5)
        body:setLinearVelocity((math.random() - 0.5) * 200, -math.random() * 200)
        table.insert(bodies, {
            body = body, shape = shape, radius = 10, type = "dynamic",
            label = "User Ball", color = {math.random(), math.random(), math.random()},
            density = 1, restitution = 0.5,
        })
    end
end

return M
