-- ============================================================
-- CHAPTER 13: Springs and Hooke's Law
-- ============================================================
-- Unlike the distance joint (a rigid constraint), a spring applies
-- Hooke's law as a continuous force every frame:
--   F_spring = -k * x        (x = displacement from rest length)
--   F_damp   = -c * v        (damping, simulates energy loss)
-- Together they produce oscillation that decays toward equilibrium.
--
-- Mass at (100,300), anchor at (100,100) [rest length 200]:
--   displacement 100 → F = -50*100 = -5000 N toward anchor
--   damping opposes velocity, gradually stopping the swing
--
-- MOUSE: click to reposition the mass
-- KEYS: S = restart the spring demo

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local springs = {}

function M.init()
    world = love.physics.newWorld(0, 9.81 * 30, true)
    springs = {}
    M.createSpringDemo()
end

function M.createSpringDemo()
    for _, b in ipairs(springs) do if b.body then b.body:destroy() end end
    springs = {}

    -- Anchor (static)
    local anchor = love.physics.newBody(world, 100, 100, "static")
    table.insert(springs, {body = anchor, label = "Anchor", type = "static", color = {0.5, 0.5, 0.5}})

    -- Mass on spring
    local mass = {
        body = love.physics.newBody(world, 100, 300, "dynamic"),
        shape = love.physics.newCircleShape(15),
        radius = 15,
        label = "Mass on Spring",
        color = {1, 0.5, 0},
        restLength = 200,
        stiffness = 50,
        damping = 2,
        anchorX = 100,
        anchorY = 100,
    }
    mass.fixture = love.physics.newFixture(mass.body, mass.shape, 1)
    mass.fixture:setFriction(0.3)
    mass.fixture:setRestitution(0.2)
    table.insert(springs, mass)

    local joint = love.physics.newDistanceJoint(
        anchor, mass.body,
        100, 100, 100, 300,
        false
    )
    joint:setLength(200)
end

function M.update()
    world:update(FIXED_DT)

    -- Apply spring + damping forces to the mass
    if #springs >= 2 then
        local mass = springs[2]
        if mass and mass.body then
            local bx, by = mass.body:getPosition()
            local vx, vy = mass.body:getLinearVelocity()

            -- Hooke's law, directed from mass toward anchor
            local dx = bx - mass.anchorX
            local dy = by - mass.anchorY
            local dist = math.sqrt(dx^2 + dy^2)
            local displacement = dist - mass.restLength

            local springFx = -mass.stiffness * displacement * dx / (dist + 0.001)
            local springFy = -mass.stiffness * displacement * dy / (dist + 0.001)

            -- Damping opposes velocity
            local dampFx = -mass.damping * vx
            local dampFy = -mass.damping * vy

            mass.body:applyForce(springFx + dampFx, springFy + dampFy)
        end
    end
end

function M.draw()
    for _, s in ipairs(springs) do
        if s.type == "static" then
            love.graphics.setColor(s.color)
            love.graphics.circle("fill", s.body:getX(), s.body:getY(), 5)
        else
            love.graphics.setColor(s.color)
            love.graphics.circle("fill", s.body:getX(), s.body:getY(), s.radius)

            -- Spring line + coil zigzag to the anchor
            if s.anchorX then
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.line(s.anchorX, s.anchorY, s.body:getX(), s.body:getY())
                local dx = s.body:getX() - s.anchorX
                local dy = s.body:getY() - s.anchorY
                local dist = math.sqrt(dx^2 + dy^2)
                local coils = 8
                for i = 1, coils do
                    local t = i / (coils + 1)
                    local cx = s.anchorX + dx * t
                    local cy = s.anchorY + dy * t
                    local perpX = -dy / (dist + 0.001) * 5 * math.sin(i * math.pi / coils)
                    local perpY = dx / (dist + 0.001) * 5 * math.cos(i * math.pi / coils)
                    love.graphics.circle("fill", cx + perpX, cy + perpY, 2)
                end
            end
        end
    end
    love.graphics.setColor(1, 1, 1)

    -- Live values panel
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 480, 200, "", {0, 0, 0, 0.8})

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SPRING PHYSICS — LIVE VALUES", px + 5, py + 2)

    if #springs >= 2 then
        local mass = springs[2]
        local bx, by = mass.body:getPosition()
        local vx, vy = mass.body:getLinearVelocity()
        local dx = bx - mass.anchorX
        local dy = by - mass.anchorY
        local dist = math.sqrt(dx^2 + dy^2)
        local displacement = dist - mass.restLength
        local speed = math.sqrt(vx^2 + vy^2)

        local springFx = -mass.stiffness * displacement * dx / (dist + 0.001)
        local springFy = -mass.stiffness * displacement * dy / (dist + 0.001)
        local dampFx = -mass.damping * vx
        local dampFy = -mass.damping * vy

        love.graphics.print("Position: (" .. fmt(bx) .. ", " .. fmt(by) .. ")", px + 5, py + 18)
        love.graphics.print("Velocity: (" .. fmt(vx) .. ", " .. fmt(vy) .. ")  |v| = " .. fmt(speed), px + 5, py + 34)
        love.graphics.print("Displacement from rest: " .. fmt(displacement) .. " px", px + 5, py + 50)
        love.graphics.print("Spring force: F = -k*x = -" .. mass.stiffness .. " * " .. fmt(displacement) .. " = " .. fmt(springFx) .. " N", px + 5, py + 66)
        love.graphics.print("Damping force: F = -c*v = -" .. mass.damping .. " * " .. fmt(speed) .. " = " .. fmt(dampFx) .. " N", px + 5, py + 82)
        love.graphics.print("Total force: (" .. fmt(springFx + dampFx) .. ", " .. fmt(springFy + dampFy) .. ") N", px + 5, py + 98)

        local ke = 0.5 * mass.body:getMass() * speed^2
        local pe = 0.5 * mass.stiffness * displacement^2 / 30
        love.graphics.print("KE = ½mv² = " .. fmt(ke), px + 5, py + 114)
        love.graphics.print("PE = ½kx² = " .. fmt(pe), px + 5, py + 130)
        love.graphics.print("Total E = KE + PE = " .. fmt(ke + pe), px + 5, py + 146)
    end

    -- Feynman
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Hooke's Law F = -kx is a linear approximation. Real springs deviate at large displacements.", px, py + 155)
    love.graphics.print("Damping (-cv) simulates energy loss (friction, air resistance). Angular frequency ω = √(k/m),", px, py + 169)
    love.graphics.print("undamped period T = 2π√(m/k). Damping ratio ζ = c/(2√(km)); ζ<1 underdamped, ζ=1 critical", px, py + 183)
    love.graphics.print("(fastest return, no overshoot), ζ>1 overdamped (slow). Full math: Appendix D.11, D.12.", px, py + 197)
end

function M.mousepressed(x, y, button)
    -- Move the mass; observe the spring pull it back
    if button == 1 and #springs >= 2 then
        local mass = springs[2]
        mass.body:setPosition(x, y)
        mass.body:setLinearVelocity(0, 0)
    end
end

function M.keypressed(key)
    if key == "s" then M.createSpringDemo() end
end

return M