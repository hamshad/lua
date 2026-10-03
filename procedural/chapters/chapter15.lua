-- ============================================================
-- CHAPTER 15: Velocity, Momentum, Kinetic Energy
-- ============================================================
-- Kinematics is values; KINETICS is why they move. Every puck has
-- mass m, velocity v, momentum p = m·v, energy KE = ½·m·|v|².
-- Same push moves a light puck fast, a heavy puck slow — force
-- makes acceleration (F = m·a), not velocity. Friction bleeds
-- energy every frame, so pucks glide then die.
--
-- CLICK: spawn puck   ARROWS: push selected   TAB: select next
-- [Z/X]: lighter/heavier   [V]: toggle vectors   [C]: clear

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua.
local M = {}

-- GROUND friction mu (1/s) and wall bounce restitution.
--   Example: mu=0.6 → speed halves roughly every 1.15 s.
local MU, REST = 0.6, 0.85
-- pucks: point masses. Each is {x,y,vx,vy,m,r}.
local pucks = {}
-- sel: index of the pushed puck. showVec: draw p/v arrows.
local sel, showVec = 1, true

-- spawn(x, y, m): add a puck; radius grows with mass so weight reads.
--   Example: spawn(512, 384, 3) → r = 12+3·5 = 27 px.
local function spawn(x, y, m)
    m = m or (1 + love.math.random() * 3)
    pucks[#pucks + 1] = { x = x, y = y, vx = 0, vy = 0, m = m, r = 12 + m * 5 }
    sel = #pucks
end

-- M.init(): three starter pucks — light, medium, heavy.
function M.init()
    pucks, sel, showVec = {}, 1, true
    spawn(350, 350, 1)
    spawn(512, 384, 2.5)
    spawn(680, 420, 4)
    pucks[1].vx, pucks[1].vy = 160, -60
    pucks[2].vx = -120
end

-- M.update(dt): push force on selected, integrate, friction, walls.
function M.update(dt)
    local p = pucks[sel]
    if p then
        -- Push: F = 900 px·mass/s² so accel F/m is mass-independent-ish.
        --   Example: F=900, m=1 → a=900 px/s²; m=4 → a=225 px/s².
        local F = 900 * p.m
        if love.keyboard.isDown("left") then p.vx = p.vx - (F / p.m) * dt end
        if love.keyboard.isDown("right") then p.vx = p.vx + (F / p.m) * dt end
        if love.keyboard.isDown("up") then p.vy = p.vy - (F / p.m) * dt end
        if love.keyboard.isDown("down") then p.vy = p.vy + (F / p.m) * dt end
    end
    for _, q in ipairs(pucks) do
        -- Friction: exponential decay, frame-rate independent.
        local k = math.exp(-MU * dt)
        q.vx, q.vy = q.vx * k, q.vy * k
        q.x, q.y = q.x + q.vx * dt, q.y + q.vy * dt
        -- Walls: bounce with restitution, clamp inside.
        if q.x - q.r < 0 then q.x = q.r q.vx = -q.vx * REST end
        if q.x + q.r > 1024 then q.x = 1024 - q.r q.vx = -q.vx * REST end
        if q.y - q.r < 40 then q.y = 40 + q.r q.vy = -q.vy * REST end
        if q.y + q.r > 748 then q.y = 748 - q.r q.vy = -q.vy * REST end
    end
end

-- M.mousepressed(x, y): spawn a puck where clicked.
function M.mousepressed(x, y, button)
    if button == 1 then spawn(x, y) end
end

-- M.keypressed(key): select, resize mass, toggle, clear.
function M.keypressed(key)
    if key == "tab" and #pucks > 0 then
        sel = sel % #pucks + 1
    elseif key == "z" and pucks[sel] then
        local q = pucks[sel] q.m = math.max(0.5, q.m - 0.5) q.r = 12 + q.m * 5
    elseif key == "x" and pucks[sel] then
        local q = pucks[sel] q.m = math.min(6, q.m + 0.5) q.r = 12 + q.m * 5
    elseif key == "v" then
        showVec = not showVec
    elseif key == "c" then
        pucks, sel = {}, 0
    end
end

-- M.draw(): pucks, momentum/velocity arrows, live p + KE panel.
function M.draw()
    utils.drawGrid()
    for i, q in ipairs(pucks) do
        -- Color: selected is warm orange, rest steel blue.
        if i == sel then love.graphics.setColor(1, 0.6, 0.2)
        else love.graphics.setColor(0.45, 0.65, 0.9) end
        love.graphics.circle("fill", q.x, q.y, q.r)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("line", q.x, q.y, q.r)
        love.graphics.setFont(fontSmall)
        love.graphics.print("m=" .. fmt(q.m, 1), q.x - 20, q.y - 6)
        if showVec then
            -- Green = velocity v; yellow = momentum p = m·v (longer).
            utils.drawVector(q.x, q.y, q.vx, q.vy, 0.15, {0.4, 1, 0.4})
            utils.drawVector(q.x, q.y, q.vx * q.m, q.vy * q.m, 0.06, {1, 1, 0.3})
        end
    end

    local q = pucks[sel]
    local ptxt, ktxt = "p=—", "KE=—"
    if q then
        local px, py = q.m * q.vx, q.m * q.vy
        ptxt = "p=(" .. fmt(px, 0) .. "," .. fmt(py, 0) .. ") |p|=" .. fmt(math.sqrt(px * px + py * py), 0)
        ktxt = "KE=" .. fmt(0.5 * q.m * (q.vx * q.vx + q.vy * q.vy), 0)
    end
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 620, 1000, 100, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES  (F=ma: same push, heavy puck accelerates less)", 15, 622)
    love.graphics.print("selected=" .. sel .. "/" .. #pucks .. "  " .. ptxt .. "  " .. ktxt, 15, 638)
    love.graphics.print("green arrow = velocity v   yellow arrow = momentum p = m·v", 15, 654)
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: mass is reluctance. Push light + heavy equally — light flies, heavy shrugs.", 10, 700)
    love.graphics.print("Momentum p=mv is what a wall must absorb; energy ½mv² is what friction must burn.", 10, 714)
    love.graphics.print("Push with ARROWS, spawn with CLICK, TAB selects. Feel F=ma in your fingers.", 10, 728)
end

return M
