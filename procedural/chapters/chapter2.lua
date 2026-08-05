-- ============================================================
-- CHAPTER 2: Lerp and Interpolation
-- ============================================================
-- Interpolation = walking between two values. lerp(a, b, t) with
-- t from 0 to 1 gives a straight-line trip from a to b.
--
-- Two balls both chase the mouse (click to place a target).
--   LEFT:  "timeline lerp" — t advances 0→1 over a fixed duration,
--          so the trip ALWAYS takes exactly 1 second and arrives.
--   RIGHT: "per-frame lerp" — pos = lerp(pos, target, 0.06) each
--          frame. It rushes 6% of the remaining gap forever: it
--          asymptotes, never quite arriving.
--
-- The lesson: a duration-based t makes motion PREDICTABLE (game
-- designers love this: animations that must finish on time). A
-- per-frame factor makes motion ORGANIC (nobody knows when it ends).
-- Choose per use case.

local utils = require("utils")
local fmt = utils.fmt
local lerp = utils.lerp
local clamp = utils.clamp
local drawTextBox = utils.drawTextBox

local M = {}

local target = {x = 700, y = 400}

-- Timeline-based ball
local tl = {x = 200, y = 400, fromX = 200, fromY = 400, t = 0, DUR = 1.0}

-- Per-frame ball
local pf = {x = 800, y = 400, factor = 0.06}

local function distance(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end

function M.init()
    tl = {x = 200, y = 400, fromX = 200, fromY = 400, t = 0, DUR = 1.0}
    pf = {x = 800, y = 400, factor = 0.06}
    target = {x = 700, y = 400}
end

function M.update(dt)
    -- Timeline ball: advance t each fixed step; at t>=1 arrive.
    if tl.t < 1 then
        tl.t = math.min(1, tl.t + dt / tl.DUR)
    end
    tl.x = lerp(tl.fromX, target.x, tl.t)
    tl.y = lerp(tl.fromY, target.y, tl.t)

    -- Per-frame ball: swallow a fixed fraction of the gap.
    pf.x = lerp(pf.x, target.x, pf.factor)
    pf.y = lerp(pf.y, target.y, pf.factor)
end

function M.mousepressed(x, y, button)
    if button == 1 then
        -- Re-aim the timeline ball from where it currently sits.
        tl.fromX, tl.fromY = tl.x, tl.y
        tl.t = 0
        target.x, target.y = x, y
    end
end

function M.draw()
    utils.drawGrid()

    -- Target marker
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("line", target.x, target.y, 12)
    love.graphics.circle("fill", target.x, target.y, 3)

    -- Timeline ball
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.circle("fill", tl.x, tl.y, 18)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    love.graphics.print("timeline lerp", 120, 330)
    love.graphics.print("t = " .. fmt(tl.t, 3), 120, 346)
    love.graphics.print("gap = " .. fmt(distance(tl, target)), 120, 362)

    -- Per-frame ball
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.circle("fill", pf.x, pf.y, 18)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("per-frame lerp", 620, 330)
    love.graphics.print("factor = " .. fmt(pf.factor, 3), 620, 346)
    love.graphics.print("gap = " .. fmt(distance(pf, target)), 620, 362)

    -- Gap readout bars under each ball
    local distTl = distance(tl, target)
    local distPf = distance(pf, target)
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.rectangle("fill", 120, 440, clamp(200 - distTl, 0, 200), 10)
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.rectangle("fill", 620, 440, clamp(200 - distPf, 0, 200), 10)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("remaining gap (full bar = arrived)", 120, 458)
    love.graphics.print("remaining gap (never reaches zero)", 620, 458)

    -- Live panel
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 500, 1000, 90, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 502)
    love.graphics.print("timeline gap: " .. fmt(distTl) .. " px   (hits 0 at t=1.0 — arrival is GUARANTEED)", 15, 518)
    love.graphics.print("per-frame gap: " .. fmt(distPf) .. " px   (after 60s still " .. fmt(distPf * 0.94, 1) .. " px away, roughly)", 15, 534)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: lerp is a straight line in value-space. A fixed-duration t guarantees arrival;", 15, 600)
    love.graphics.print("a per-frame factor never quite arrives but always keeps moving — each eats half the", 15, 614)
    love.graphics.print("remaining distance, forever. Games use duration-lerp for tween timelines and", 15, 628)
    love.graphics.print("per-frame-lerp for follow cameras, where arrival time is less important than smoothness.", 15, 642)
end

return M