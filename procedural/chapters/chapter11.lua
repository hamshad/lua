-- ============================================================
-- CHAPTER 11: Secondary Motion — Inertia and Follow-Through
-- ============================================================
-- A body stops; the hair, cape, tail, and jiggle keep going. That
-- trailing "lag" is secondary motion, and it is what sells WEIGHT.
-- You never animate it by hand — you build it with springs: each
-- link of the tail chases the link ahead of it with damp().
--
--   link[i].x = damp(link[i].x, link[i-1].x, λ, dt)
--
-- The head moves (arrow keys), the tail is pure consequence.
-- Change λ and the tail goes from stiff to dripping.
--
-- ARROWS: move the head   LEFT/RIGHT with [SHIFT]: λ presets
-- 1/2/3: λ = 8 (drippy), 20 (springy), 60 (stiff)

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local head = { x = 512, y = 300, vx = 0, vy = 0 }
local lambda = 12.0
local N = 10
local SEG = 30
local links = {}

local function rebuild()
    links = {}
    for i = 1, N do
        links[i] = { x = head.x - i * SEG, y = head.y }
    end
end

function M.init()
    head.x, head.y = 512, 300
    head.vx, head.vy = 0, 0
    lambda = 12.0
    rebuild()
end

function M.update(dt)
    -- Head follows arrow keys (accel + velocity for real inertia).
    local ax, ay = 0, 0
    if love.keyboard.isDown("left") then ax = -900 end
    if love.keyboard.isDown("right") then ax = 900 end
    if love.keyboard.isDown("up") then ay = -900 end
    if love.keyboard.isDown("down") then ay = 900 end
    head.vx = utils.clamp(head.vx + ax * dt, -260, 260)
    head.vy = utils.clamp(head.vy + ay * dt, -260, 260)
    head.x = utils.clamp(head.x + head.vx * dt, 30, 994)
    head.y = utils.clamp(head.y + head.vy * dt, 30, 560)

    -- Tail: each link chases the one before it.
    links[1].x = utils.damp(links[1].x, head.x, lambda, dt)
    links[1].y = utils.damp(links[1].y, head.y, lambda, dt)
    for i = 2, N do
        links[i].x = utils.damp(links[i].x, links[i - 1].x, lambda, dt)
        links[i].y = utils.damp(links[i].y, links[i - 1].y, lambda, dt)
    end

    -- Enforce segment length so the tail does not stretch forever.
    for i = N, 2, -1 do
        local dx = links[i].x - links[i - 1].x
        local dy = links[i].y - links[i - 1].y
        local d = math.sqrt(dx * dx + dy * dy)
        if d > SEG * 1.4 then
            local nx, ny = dx / d, dy / d
            links[i].x = links[i - 1].x + nx * SEG
            links[i].y = links[i - 1].y + ny * SEG
        end
    end
end

function M.keypressed(key)
    if key == "1" then lambda = 8 end
    if key == "2" then lambda = 20 end
    if key == "3" then lambda = 60 end
end

function M.draw()
    utils.drawGrid()

    -- Tail
    for i = N, 2, -1 do
        local a, b = links[i - 1], links[i]
        local intensity = (N - i + 1) / N
        love.graphics.setColor(0.8, 0.4, 0.2, 0.5 + 0.5 * intensity)
        love.graphics.setLineWidth(10 - 7 * intensity)
        love.graphics.line(a.x, a.y, b.x, b.y)
    end
    love.graphics.setLineWidth(1)

    -- Head
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", head.x, head.y, 22)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.circle("fill", head.x - 6, head.y - 5, 3)
    love.graphics.circle("fill", head.x + 6, head.y - 5, 3)

    -- Motion trail of the head
    utils.drawVector(head.x, head.y, head.vx * 0.05, head.vy * 0.05, 1, {1, 1, 0})

    -- Live panel
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 620, 1000, 100, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 622)
    love.graphics.print("λ = " .. fmt(lambda) .. "   head v=(" .. fmt(head.vx) .. ", " .. fmt(head.vy) .. ")", 15, 638)
    love.graphics.print("tail tip lag = " .. fmt(math.sqrt((links[N].x - head.x)^2 + (links[N].y - head.y)^2)) .. " px from head", 15, 654)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: secondary motion is consequence, not design. Each link chases the one", 10, 700)
    love.graphics.print("ahead with a spring, so the tail remembers where the head WAS. Stop the head and", 10, 714)
    love.graphics.print("the tail keeps going — that overshoot IS the weight players feel. Low λ, more lag.", 10, 728)
    love.graphics.print("Controls: ARROWS move head, [1/2/3] λ presets (drippy/springy/stiff).", 10, 742)
end

return M