-- ============================================================
-- CHAPTER 9: Collision Response and Impulse
-- ============================================================
-- The impulse-momentum theorem. A heavy ball (5kg) hits a light
-- ball (1kg) head-on.
--
--   Impulse:  j = -(1+e) * (v_rel · n) / (1/m₁ + 1/m₂)
--
-- Heavy (5kg, vx=150) hits Light (1kg, vx=0), e=1.0:
--   reduced mass = (5*1)/(5+1) = 5/6 ≈ 0.833
--   j = -2 * 150 / (0.2 + 1) = -300 / 1.2 = -250 N·s
--   After: heavy slows 150→100, light flies 0→250 px/s.
--   The light ball shoots off at 2.5× the heavy ball's speed.

local utils = require("utils")
local fmt = utils.fmt
local drawVector = utils.drawVector
local drawTextBox = utils.drawTextBox
local createGround = utils.createGround

local M = {}

local balls = {}
local impulses = {}

-- Record an approximate impulse from relative velocity at contact.
-- Box2D 11.5 exposes no getNormalImpulses, so we estimate.
local function beginContact(a, b, contact)
    local body1 = a:getBody()
    local body2 = b:getBody()
    local vx1, vy1 = body1:getLinearVelocity()
    local vx2, vy2 = body2:getLinearVelocity()
    local m1 = body1:getMass()
    local m2 = body2:getMass()
    local relVx = vx1 - vx2
    local imp = math.abs(relVx * m1 * m2 / (m1 + m2))
    if imp > 0.1 then
        table.insert(impulses, {impulse = imp, life = 1.0})
    end
end

function M.init()
    balls = {}
    impulses = {}
    world = love.physics.newWorld(0, 9.81 * 30, true)
    createGround(1024, 20, 0.5, 0.3)

    -- Heavy ball (5kg density), moving right
    local heavy = {
        body = love.physics.newBody(world, 250, 200, "dynamic"),
        shape = love.physics.newCircleShape(15),
        radius = 15, color = {1, 0.3, 0.3}, label = "Heavy (5kg)",
    }
    heavy.fixture = love.physics.newFixture(heavy.body, heavy.shape, 5)
    heavy.fixture:setRestitution(1.0)
    heavy.fixture:setFriction(0.0)
    heavy.body:setLinearVelocity(150, 0)

    -- Light ball (1kg density), stationary
    local light = {
        body = love.physics.newBody(world, 600, 200, "dynamic"),
        shape = love.physics.newCircleShape(15),
        radius = 15, color = {0.3, 0.3, 1}, label = "Light (1kg)",
    }
    light.fixture = love.physics.newFixture(light.body, light.shape, 1)
    light.fixture:setRestitution(1.0)
    light.fixture:setFriction(0.0)

    balls = {heavy, light}
    impulses = {}

    world:setCallbacks(beginContact, nil, nil, nil)
end

function M.update()
    world:update(FIXED_DT)

    -- Decay impulse flashes
    for i = #impulses, 1, -1 do
        impulses[i].life = impulses[i].life - FIXED_DT
        if impulses[i].life <= 0 then
            table.remove(impulses, i)
        end
    end
end

function M.draw()
    for _, b in ipairs(balls) do
        love.graphics.setColor(b.color)
        love.graphics.circle("fill", b.body:getX(), b.body:getY(), b.radius)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(b.label, b.body:getX() - 35, b.body:getY() - b.radius - 15)

        local vx, vy = b.body:getLinearVelocity()
        drawVector(b.body:getX(), b.body:getY(), vx * 0.02, vy * 0.02, 1, {1, 1, 0})
    end

    -- Impulse flashes: yellow circles, radius ∝ impulse
    for _, imp in ipairs(impulses) do
        love.graphics.setColor(1, 1, 0, math.max(0, imp.life))
        love.graphics.circle("fill", 512, 350, 3 + math.abs(imp.impulse) * 0.5)
    end
    love.graphics.setColor(1, 1, 1)

    -- Live values panel
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 480, 180, "", {0, 0, 0, 0.8})

    local h = balls[1]
    local l = balls[2]
    local hvx, hvy = h.body:getLinearVelocity()
    local lvx, lvy = l.body:getLinearVelocity()
    local hMass = h.body:getMass()
    local lMass = l.body:getMass()

    local vRel = hvx - lvx
    local e = 1.0
    local reducedMass = (hMass * lMass) / (hMass + lMass)
    local impulseMag = -(1 + e) * vRel / (1/hMass + 1/lMass)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("IMPULSE-MOMENTUM THEOREM — LIVE VALUES", px + 5, py + 2)

    love.graphics.print("Before collision:", px + 5, py + 18)
    love.graphics.print("  Heavy: v=" .. fmt(hvx) .. " m/s  p=" .. fmt(hMass * hvx) .. " kg·m/s", px + 5, py + 34)
    love.graphics.print("  Light: v=" .. fmt(lvx) .. " m/s  p=" .. fmt(lMass * lvx) .. " kg·m/s", px + 5, py + 50)

    love.graphics.print("Impulse formula:", px + 5, py + 68)
    love.graphics.print("  j = -(1+e) * v_rel / (1/m₁ + 1/m₂)", px + 5, py + 84)
    love.graphics.print("  j = -(1+" .. e .. ") * " .. fmt(vRel) .. " / (1/" .. fmt(hMass) .. " + 1/" .. fmt(lMass) .. ")", px + 5, py + 100)
    love.graphics.print("  j = " .. fmt(impulseMag) .. " N·s", px + 5, py + 116)

    -- Predicted post-collision velocities from the impulse-momentum theorem
    local v1After = (hMass * hvx - impulseMag) / hMass
    local v2After = (lMass * lvx + impulseMag) / lMass
    love.graphics.print("After collision (predicted):", px + 5, py + 132)
    love.graphics.print("  Heavy: v'=" .. fmt(v1After) .. " m/s", px + 5, py + 148)
    love.graphics.print("  Light: v'=" .. fmt(v2After) .. " m/s", px + 5, py + 164)

    -- Feynman
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Impulse = change in momentum. J = Δp = mΔv. A heavy ball hitting a light one", px, py + 150)
    love.graphics.print("transfers most of its momentum. The light ball flies off at nearly twice the heavy ball's speed.", px, py + 164)
end

return M