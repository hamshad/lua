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

-- M: the module table exported to main.lua.
local M = {}

-- target: the point both balls are trying to reach. Moved by
-- clicking the mouse.
--   Example: click at (600, 300) → target = {x=600, y=300}.
local target = {x = 700, y = 400}

-- tl: the "timeline lerp" ball's state.
--   x, y:     its current position.
--   fromX/Y:  where the current trip started (set on click).
--   t:        progress 0..1 of the current 1-second trip.
--   DUR:      how long a trip lasts, in seconds.
--   Example: click at t=0 → from=(200,400), t goes 0→1 over 1 s,
--            x = lerp(200, 600, t).
local tl = {x = 200, y = 400, fromX = 200, fromY = 400, t = 0, DUR = 1.0}

-- pf: the "per-frame lerp" ball's state.
--   x, y:    its current position.
--   factor:  the fraction of the remaining gap swallowed per step
--            (0.06 = 6% per fixed step). Never reaches the target.
local pf = {x = 800, y = 400, factor = 0.06}

-- distance(a, b): the straight-line distance between two points,
-- via Pythagoras.
--   Example: distance({x=0,y=0}, {x=3,y=4}) = sqrt(9+16) = 5
local function distance(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end

-- M.init(): reset both balls and the target to their home positions.
function M.init()
    tl = {x = 200, y = 400, fromX = 200, fromY = 400, t = 0, DUR = 1.0}
    pf = {x = 800, y = 400, factor = 0.06}
    target = {x = 700, y = 400}
end

-- M.update(dt): advance both interpolation styles one fixed step.
function M.update(dt)
    -- Timeline ball: advance t by (step / duration), clamped to 1.
    --   Example: t=0.4, dt=1/60, DUR=1.0 → t = min(1, 0.4167).
    if tl.t < 1 then
        tl.t = math.min(1, tl.t + dt / tl.DUR)
    end
    -- Position = lerp(from, target, t). At t=1 this is EXACTLY target.
    --   Example: lerp(200, 600, 0.5) = 400.
    tl.x = lerp(tl.fromX, target.x, tl.t)
    tl.y = lerp(tl.fromY, target.y, tl.t)

    -- Per-frame ball: swallow 6% of whatever gap remains, each step.
    --   Example: pf.x=400, target.x=600 → 400 + 200*0.06 = 412.
    pf.x = lerp(pf.x, target.x, pf.factor)
    pf.y = lerp(pf.y, target.y, pf.factor)
end

-- M.mousepressed(x, y, button): on left click, re-aim the timeline
-- ball from its CURRENT position (so the new trip starts where it
-- is) and move the target to the click point.
function M.mousepressed(x, y, button)
    if button == 1 then
        tl.fromX, tl.fromY = tl.x, tl.y   -- new trip starts here
        tl.t = 0                          -- restart the 1-second clock
        target.x, target.y = x, y         -- new destination
    end
end

-- M.draw(): render the grid, both balls, their gap bars, and the
-- live values panel.
function M.draw()
    utils.drawGrid()

    -- Target marker: a ring + dot at the click point.
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("line", target.x, target.y, 12)
    love.graphics.circle("fill", target.x, target.y, 3)

    -- Timeline ball (blue) + its readouts.
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.circle("fill", tl.x, tl.y, 18)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    love.graphics.print("timeline lerp", 120, 330)
    love.graphics.print("t = " .. fmt(tl.t, 3), 120, 346)
    love.graphics.print("gap = " .. fmt(distance(tl, target)), 120, 362)

    -- Per-frame ball (orange) + its readouts.
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.circle("fill", pf.x, pf.y, 18)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("per-frame lerp", 620, 330)
    love.graphics.print("factor = " .. fmt(pf.factor, 3), 620, 346)
    love.graphics.print("gap = " .. fmt(distance(pf, target)), 620, 362)

    -- Gap bars: each bar's length = 200 minus the remaining gap, so
    -- a FULL bar means "arrived". The timeline bar hits full; the
    -- per-frame bar asymptotes below full forever.
    --   Example: gap 50 px → bar width = clamp(200-50, 0, 200) = 150.
    local distTl = distance(tl, target)
    local distPf = distance(pf, target)
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.rectangle("fill", 120, 440, clamp(200 - distTl, 0, 200), 10)
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.rectangle("fill", 620, 440, clamp(200 - distPf, 0, 200), 10)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("remaining gap (full bar = arrived)", 120, 458)
    love.graphics.print("remaining gap (never reaches zero)", 620, 458)

    -- Live panel: explains the two gaps and their fate.
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