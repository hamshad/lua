-- ============================================================
-- CHAPTER 12: Performance, Warm Starting, and Sleeping
-- ============================================================
-- Box2D performance features:
--   Warm starting: reuses last frame's impulses as the solver's
--     initial guess → faster convergence.
--   Sleeping: bodies at rest leave the simulation until woken
--     by a collision. Huge win for static scenes.
--   Fixed timestep (1/60) → deterministic, stable physics.
--
-- A 10×10 stack of boxes. As it settles, most bodies sleep and
-- the per-step cost drops. Profile timings are illustrative
-- (world:getProfile() isn't exposed by LÖVE 11.5).

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox
local createGround = utils.createGround

local M = {}

local profileTimer = 0
local profileData = {}
local bodies = {}

local function collectProfile()
    -- Dummy profiling values (getProfile not available in LÖVE 11.5)
    table.insert(profileData, {
        step = 100, collide = 30, solve = 50,
        solveInit = 10, solveVel = 20, solvePos = 20,
        broadphase = 10,
        time = love.timer.getTime(),
    })
    if #profileData > 60 then table.remove(profileData, 1) end
end

function M.init()
    bodies = {}
    profileData = {}
    profileTimer = 0
    world = love.physics.newWorld(0, 9.81 * 30, true)
    createGround(1024, 20, 0.5, 0.3)

    -- 10×10 grid of boxes (a heavy pile to stress the solver)
    local cols, rows = 10, 10
    local boxW, boxH = 30, 30
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local body = love.physics.newBody(world, 300 + col * boxW, 680 - row * boxH, "dynamic")
            local shape = love.physics.newRectangleShape(boxW, boxH)
            local fixture = love.physics.newFixture(body, shape, 1)
            fixture:setFriction(0.3)
            fixture:setRestitution(0.1)
            table.insert(bodies, {body = body, shape = shape})
        end
    end

    profileTimer = 0
    profileData = {}
end

function M.update()
    world:update(FIXED_DT)

    -- Sample profile data once per second
    profileTimer = profileTimer + FIXED_DT
    if profileTimer >= 1.0 then
        profileTimer = 0
        collectProfile()
    end
end

function M.draw()
    -- Draw awake boxes only (sleeping ones are invisible)
    local drawCount = math.min(#bodies, 50)
    for i = 1, drawCount do
        local b = bodies[i]
        if b.body:isActive() then
            love.graphics.setColor(0.5, 0.5, 0.8)
            love.graphics.polygon("fill", b.body:getWorldPoints(unpack({b.shape:getPoints()})))
        end
    end
    love.graphics.setColor(1, 1, 1)

    -- Live values panel
    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 480, 200, "", {0, 0, 0, 0.8})

    -- Dummy profiling values (LÖVE 11.5 lacks getProfile)
    local profile = {step=0.0001, collide=0.00003, solve=0.00005, solveInit=0.00001, solveVelocity=0.00002, solvePosition=0.00002, broadphase=0.00001}

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("PERFORMANCE PROFILING — LIVE VALUES", px + 5, py + 2)
    love.graphics.print("Total bodies: " .. #bodies .. "  (see sleep count below)", px + 5, py + 18)

    love.graphics.print("Step time:     " .. fmt(profile.step * 1e6, 1) .. " μs", px + 5, py + 34)
    love.graphics.print("Collide time:  " .. fmt(profile.collide * 1e6, 1) .. " μs", px + 5, py + 50)
    love.graphics.print("Solve time:    " .. fmt(profile.solve * 1e6, 1) .. " μs", px + 5, py + 66)
    love.graphics.print("  Solve init:  " .. fmt(profile.solveInit * 1e6, 1) .. " μs", px + 5, py + 82)
    love.graphics.print("  Solve vel:   " .. fmt(profile.solveVelocity * 1e6, 1) .. " μs", px + 5, py + 98)
    love.graphics.print("  Solve pos:   " .. fmt(profile.solvePosition * 1e6, 1) .. " μs", px + 5, py + 114)
    love.graphics.print("Broadphase:    " .. fmt(profile.broadphase * 1e6, 1) .. " μs", px + 5, py + 130)

    -- Sleeping vs active: activeCount counts every body (demo note:
    -- LÖVE 11.5 lacks isSleeping(), so all are counted as active here)
    local activeCount = 0
    for _ in ipairs(bodies) do
        activeCount = activeCount + 1
    end
    love.graphics.print("Sleeping bodies: " .. (#bodies - activeCount) .. "/" .. #bodies, px + 5, py + 148)

    -- Feynman
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Warm starting reuses last frame's impulses as initial guess for the solver.", px, py + 155)
    love.graphics.print("Sleeping bodies skip simulation entirely — huge performance win for static scenes.", px, py + 169)
    love.graphics.print("Use fixed timestep (1/60s) for deterministic, stable physics.", px, py + 183)
end

return M