-- ============================================================
-- CHAPTER 4: Bodies, Shapes, and Fixtures
-- ============================================================
--   Shape   = collision geometry (circle, rectangle, polygon)
--   Fixture = material attached to a shape
--     density     → mass = density * area
--       Circle r=25:    area = π*25² ≈ 1963, mass ≈ 1963
--       Rect 40x40:     area = 1600, mass ≈ 1600
--     friction    → Coulomb friction: F_friction ≤ μ*F_normal
--     restitution → e=0.9 bounces to 0.9² = 81% of drop height
--
-- MOUSE: click to spawn a circle

local utils = require("utils")
local fmt = utils.fmt
local drawVector = utils.drawVector
local drawTextBox = utils.drawTextBox
local createGround = utils.createGround

local M = {}

local shapes = {}

function M.init()
    shapes = {}
    world = love.physics.newWorld(0, 9.81 * 30, true)

    local gBody, gShape = createGround(1024, 20, 0.5, 0.3)
    table.insert(shapes, {body = gBody, shape = gShape, type = "ground", label = "Ground"})

    -- Five shapes mixing different friction / restitution
    local defs = {
        {type="circle", x=150, y=150, r=25, density=1, friction=0.1, restitution=0.9, color={1,0,0}, label="Circle: low friction, high bounce"},
        {type="circle", x=300, y=150, r=25, density=1, friction=1.0, restitution=0.0, color={0,1,0}, label="Circle: high friction, no bounce"},
        {type="rect", x=500, y=150, w=40, h=40, density=1, friction=0.3, restitution=0.5, color={0,0,1}, label="Rectangle: medium all"},
        {type="rect", x=700, y=150, w=60, h=20, density=1, friction=0.3, restitution=0.5, color={1,1,0}, label="Wide rectangle (flat)"},
        {type="polygon", x=900, y=150, density=1, friction=0.3, restitution=0.5, color={1,0,1}, label="Hexagon"},
    }

    for _, def in ipairs(defs) do
        local body, shape, fixture

        if def.type == "circle" then
            body = love.physics.newBody(world, def.x, def.y, "dynamic")
            shape = love.physics.newCircleShape(def.r)
            fixture = love.physics.newFixture(body, shape, def.density)

        elseif def.type == "rect" then
            body = love.physics.newBody(world, def.x, def.y, "dynamic")
            shape = love.physics.newRectangleShape(def.w, def.h)
            fixture = love.physics.newFixture(body, shape, def.density)

        elseif def.type == "polygon" then
            -- Hexagon: 6 vertices evenly spaced on a circle of radius 25
            body = love.physics.newBody(world, def.x, def.y, "dynamic")
            local pts = {}
            for i = 0, 5 do
                local a = 2 * math.pi * i / 6
                table.insert(pts, 25 * math.cos(a))
                table.insert(pts, 25 * math.sin(a))
            end
            shape = love.physics.newPolygonShape(pts)
            fixture = love.physics.newFixture(body, shape, def.density)
        end

        fixture:setFriction(def.friction)
        fixture:setRestitution(def.restitution)
        table.insert(shapes, {body = body, shape = shape, type = "dynamic", label = def.label, color = def.color, r = def.r or 0})
    end

    -- Static triangle: grippy (μ=0.8), barely bounces (e=0.1)
    local triBody = love.physics.newBody(world, 100, 500, "static")
    local triShape = love.physics.newPolygonShape(0, -30, 30, 30, -30, 30)
    local triFixture = love.physics.newFixture(triBody, triShape, 1)
    triFixture:setFriction(0.8)
    triFixture:setRestitution(0.1)
    table.insert(shapes, {body = triBody, shape = triShape, type = "ground", label = "Triangle (static)"})
end

function M.update()
    world:update(FIXED_DT)
end

function M.draw()
    for _, s in ipairs(shapes) do
        if s.type == "ground" then
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.polygon("fill", s.body:getWorldPoints(unpack({s.shape:getPoints()})))
        else
            love.graphics.setColor(s.color)
            if s.shape:getType() == "circle" then
                love.graphics.circle("fill", s.body:getX(), s.body:getY(), s.r or 25)
            else
                -- Rectangles/polygons: apply body transform to vertices
                local worldPts = {s.body:getWorldPoints(unpack({s.shape:getPoints()}))}
                love.graphics.polygon("fill", unpack(worldPts))
            end
            love.graphics.setColor(1, 1, 1)

            local vx, vy = s.body:getLinearVelocity()
            if math.abs(vx) + math.abs(vy) > 1 then
                drawVector(s.body:getX(), s.body:getY(), vx * 0.02, vy * 0.02, 1, {1, 1, 0})
            end
        end
    end

    -- Live values panel: verify mass = density * area
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 440, 180, "", {0, 0, 0, 0.8})

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES — Shape & Material Properties", px + 5, py + 2)

    local yOff = 18
    for _, s in ipairs(shapes) do
        if s.type == "dynamic" then
            local mass = s.body:getMass()
            local vx, vy = s.body:getLinearVelocity()

            -- Compute area from the shape type
            local area = 0
            local t = s.shape:getType()
            if t == "circle" then
                area = math.pi * (s.r or 25)^2
            elseif t == "polygon" then
                local ppts = {s.shape:getPoints()}
                local pa = 0
                local pn = #ppts / 2
                for i = 1, pn do
                    local j = (i % pn) + 1
                    pa = pa + ppts[2 * i - 1] * ppts[2 * j] - ppts[2 * j - 1] * ppts[2 * i]
                end
                area = math.abs(pa) / 2
            elseif t == "rectangle" then
                local w, h = s.shape:getDimensions()
                area = w * h
            end

            love.graphics.print(s.label, px + 5, py + yOff)
            love.graphics.print("  mass=" .. fmt(mass) .. "kg  area=" .. fmt(area) .. "m²  density=" .. fmt(mass / (area + 0.001)) .. "  vel=(" .. fmt(vx) .. "," .. fmt(vy) .. ")", px + 5, py + yOff + 12)
            yOff = yOff + 26
        end
    end

    -- Feynman explanation
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: A circle and a hexagon of the same area have the same mass if density is equal.", px, py + 150)
    love.graphics.print("But their collision behavior differs — circles roll, polygons can interlock. Mass is the", px, py + 164)
    love.graphics.print("inertia against linear motion; moment of inertia resists rotation (see Appendix E, Ch.4).", px, py + 178)
end

function M.mousepressed(x, y, button)
    if button == 1 then
        local body = love.physics.newBody(world, x, y, "dynamic")
        local shape = love.physics.newCircleShape(12)
        local fixture = love.physics.newFixture(body, shape, 1)
        fixture:setFriction(0.3)
        fixture:setRestitution(0.5)
        table.insert(shapes, {body = body, shape = shape, type = "dynamic", label = "User Circle", color = {math.random(), math.random(), math.random()}, r = 12})
    end
end

return M
