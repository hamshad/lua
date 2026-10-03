-- ============================================================
-- CHAPTER 17: Collisions and Impulse — Bouncing Honestly
-- ============================================================
-- Two balls meet: split velocities along the impact normal, swap
-- the normal parts by mass (elastic), keep the tangential parts.
-- Restitution e scales the bounce: e=1 perfect, e=0 dead thud.
-- Then push the balls apart so they never sink — position fix.
--
-- CLICK: spawn + fling   DRAG: aim fling   [F]: restitution preset
-- [C]: clear   [G]: gravity toggle

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua.
local M = {}

-- balls: {x,y,vx,vy,m,r}. e: restitution. grav: gravity on/off.
local balls, e, grav = {}, 0.9, false
-- drag: fling gesture {x0,y0,x1,y1,active}.
local drag = { active = false, x0 = 0, y0 = 0, x1 = 0, y1 = 0 }
-- hits: recent impact flashes {x,y,t}. GRAV: px/s² when enabled.
local hits, GRAV = {}, 900

-- spawn(x, y, vx, vy): random-mass ball.
local function spawn(x, y, vx, vy)
    local m = 1 + love.math.random() * 3
    balls[#balls + 1] = { x = x, y = y, vx = vx or 0, vy = vy or 0, m = m, r = 12 + m * 5 }
end

-- M.init(): a pair on collision course + a heavy bystander.
function M.init()
    balls, e, grav, hits = {}, 0.9, false, {}
    drag.active = false
    spawn(300, 350, 260, 0)
    spawn(700, 350, -260, 0)
    spawn(512, 520, 0, 0)
end

-- resolve(a, b): impulse + positional correction for one pair.
--   Example: equal mass head-on → velocities swap exactly.
local function resolve(a, b)
    local dx, dy = b.x - a.x, b.y - a.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d == 0 or d >= a.r + b.r then return end
    -- Normal n, positional de-overlap split by inverse mass.
    local nx, ny = dx / d, dy / d
    local overlap = (a.r + b.r) - d
    local ima, imb = 1 / a.m, 1 / b.m
    local sum = ima + imb
    a.x, a.y = a.x - nx * overlap * (ima / sum), a.y - ny * overlap * (ima / sum)
    b.x, b.y = b.x + nx * overlap * (imb / sum), b.y + ny * overlap * (imb / sum)
    -- Relative velocity along normal; skip if separating.
    local rvx, rvy = b.vx - a.vx, b.vy - a.vy
    local vn = rvx * nx + rvy * ny
    if vn > 0 then return end
    -- Impulse j = -(1+e)·vn / (1/ma + 1/mb). Tangential untouched.
    local j = -(1 + e) * vn / sum
    a.vx, a.vy = a.vx - j * nx * ima, a.vy - j * ny * ima
    b.vx, b.vy = b.vx + j * nx * imb, b.vy + j * ny * imb
    if #hits < 24 then hits[#hits + 1] = { x = (a.x + b.x) / 2, y = (a.y + b.y) / 2, t = 0.3 } end
end

-- M.update(dt): gravity, integrate, walls, all-pairs collide.
function M.update(dt)
    for _, b in ipairs(balls) do
        if grav then b.vy = b.vy + GRAV * dt end
        b.x, b.y = b.x + b.vx * dt, b.y + b.vy * dt
        if b.x - b.r < 0 then b.x = b.r b.vx = -b.vx * e end
        if b.x + b.r > 1024 then b.x = 1024 - b.r b.vx = -b.vx * e end
        if b.y - b.r < 40 then b.y = 40 + b.r b.vy = -b.vy * e end
        if b.y + b.r > 748 then b.y = 748 - b.r b.vy = -b.vy * e end
    end
    for i = 1, #balls do
        for k = i + 1, #balls do resolve(balls[i], balls[k]) end
    end
    for i = #hits, 1, -1 do
        hits[i].t = hits[i].t - dt
        if hits[i].t <= 0 then table.remove(hits, i) end
    end
end

-- M.mousepressed/mousereleased: drag to aim a fling, release to fire.
function M.mousepressed(x, y, button)
    if button == 1 then drag = { active = true, x0 = x, y0 = y, x1 = x, y1 = y } end
end

function M.mousereleased(x, y, button)
    if button == 1 and drag.active then
        -- Fling velocity = drag vector × 4. Long drag = fast ball.
        spawn(drag.x0, drag.y0, (drag.x0 - x) * 4, (drag.y0 - y) * 4)
        drag.active = false
    end
end

-- M.keypressed(key): restitution presets, gravity, clear.
function M.keypressed(key)
    if key == "f" then
        e = e >= 1 and 0 or math.min(1, e + 0.25)
    elseif key == "g" then
        grav = not grav
    elseif key == "c" then
        balls, hits = {}, {}
    end
end

-- M.draw(): balls with mass labels, fling band, flashes, panel.
function M.draw()
    utils.drawGrid()
    if drag.active then
        local mx, my = love.mouse.getPosition()
        drag.x1, drag.y1 = mx, my
        love.graphics.setColor(1, 1, 0, 0.7)
        love.graphics.line(drag.x0, drag.y0, drag.x1, drag.y1)
        love.graphics.circle("line", drag.x0, drag.y0, 8)
    end
    for _, b in ipairs(balls) do
        love.graphics.setColor(0.5, 0.7, 1)
        love.graphics.circle("fill", b.x, b.y, b.r)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("line", b.x, b.y, b.r)
        love.graphics.setFont(fontSmall)
        love.graphics.print(fmt(b.m, 1), b.x - 10, b.y - 6)
        utils.drawVector(b.x, b.y, b.vx, b.vy, 0.1, {0.4, 1, 0.4})
    end
    for _, h in ipairs(hits) do
        love.graphics.setColor(1, 0.5, 0.2, h.t / 0.3)
        love.graphics.circle("line", h.x, h.y, 14 + (0.3 - h.t) * 60)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 620, 1000, 100, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 622)
    love.graphics.print("balls=" .. #balls .. "  restitution e=" .. fmt(e, 2) .. "  gravity=" .. tostring(grav), 15, 638)
    love.graphics.print("j = -(1+e)·vn / (1/ma+1/mb) along the impact normal; tangent kept", 15, 654)
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: a bounce is an exchange. Normal parts trade by mass, sideways parts ignore", 10, 700)
    love.graphics.print("each other. e=1 keeps every joule; e=0 eats the approach. F cycles e, G drops them.", 10, 714)
end

return M
