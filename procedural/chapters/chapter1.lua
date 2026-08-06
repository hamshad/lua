-- ============================================================
-- CHAPTER 1: Time — The Raw Material of Motion
-- ============================================================
-- Animation is just a number that changes with time. Everything
-- procedural follows from this: pick a value, drive it with t.
--
-- Here one ball walks a sawtooth path (teleports back), and one
-- walks a triangle path (ping-pongs). Both are pure functions of
-- t — the only difference is how we reshape the clock.
--
--   sawtooth:  p = (t mod PERIOD) / PERIOD      0→1, snap back
--   triangle:  p = |(t mod PERIOD)/PERIOD - 0.5|*2   0→1→0 bounce
--
-- MOUSE: click to stamp a "hit event" on the timeline below.
-- A game is just events happening at times; animating an event
-- means shaping the t between its start and its end.

local utils = require("utils")
local fmt = utils.fmt
local lerp = utils.lerp
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua. main.lua calls M.init,
-- M.update(dt), M.draw, and the optional event handlers.
local M = {}

-- t: the chapter clock in seconds. It counts up forever — every
-- animation in this chapter is a pure function of t.
--   Example: after 5 seconds at 60 fps, t = 5.0.
local t = 0
-- hits: the recorded "event" times. Each mouse click appends the
-- current clock time; the red stamps on the timeline are these.
--   Example: clicking at t=2.3 and t=5.1 → hits = {2.3, 5.1}.
local hits = {}

-- PERIOD: the cycle length in seconds. Both balls complete one
-- full back-and-forth (or teleport) every 2 seconds.
--   Example: t=0 → phase 0; t=1 → phase 0.5; t=2 → back to 0.
local PERIOD = 2.0

-- xFromP(p): map a normalized phase p (0..1) to a screen x position
-- between x=80 (left) and x=944 (right).
--   Example: xFromP(0)   = lerp(80, 944, 0)   = 80
--            xFromP(0.5) = lerp(80, 944, 0.5) = 512
--            xFromP(1)   = lerp(80, 944, 1)   = 944
local function xFromP(p)
    return lerp(80, 944, p)
end

-- M.init(): reset the chapter to a clean state. Called by main.lua
-- whenever this chapter is opened or SPACE is pressed.
function M.init()
    t = 0      -- restart the clock
    hits = {}  -- forget all stamped events
end

-- M.update(dt): advance the clock by one fixed step (dt = 1/60 s).
function M.update(dt)
    t = t + dt   -- Example: t was 2.983, dt=1/60 → t = 2.9997
end

-- M.mousepressed(x, y, button): stamp a "hit event" at the current
-- clock time when the left button (1) is clicked. Keeps at most the
-- newest 14 stamps so the list can't grow forever.
function M.mousepressed(x, y, button)
    if button == 1 then
        table.insert(hits, t)
        if #hits > 14 then table.remove(hits, 1) end
    end
end

-- M.keypressed(key): 'r' clears all stamped events.
function M.keypressed(key)
    if key == "r" then
        hits = {}
    end
end

-- M.draw(): render the whole scene — grid, timeline ruler, event
-- stamps, the two phase balls, the cursor marker, and the live panel.
function M.draw()
    utils.drawGrid()

    -- Timeline ruler: a dark strip spanning seconds 0..14, with a
    -- tick label at each integer second (60, 120, 180... in x).
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", 60, 520, 900, 30)
    love.graphics.setColor(0.35, 0.35, 0.35)
    for s = 0, 14 do
        love.graphics.print(s, 60 + s * 60, 552)
    end

    -- Event stamps: for each recorded event time h, place a red tick
    -- at x = 60 + (h mod 15)*60 (seconds wrap every 15).
    --   Example: h=2.3 → x = 60 + 2.3*60 = 198
    for _, h in ipairs(hits) do
        local x = 60 + (h % 15) * 60
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.line(x, 516, x, 552)
    end

    -- Triangle-wave ball (blue): phase bounces 0→1→0 each period.
    --   pTri = |(t mod 2)/2 - 0.5|·2
    --   Example: t=0 → 0 (left edge); t=1 → 1 (right edge); t=2 → 0.
    local pTri = math.abs((t % PERIOD) / PERIOD - 0.5) * 2
    local xTri = xFromP(pTri)
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.circle("fill", xTri, 200, 22)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    love.graphics.print("triangle: p = " .. fmt(pTri) .. "  x = " .. fmt(xTri), xTri - 90, 232)

    -- Sawtooth ball (orange): phase 0→1, then snaps back to 0.
    --   pSaw = (t mod 2)/2
    --   Example: t=0 → 0 (left); t=1 → 0.5 (mid); t=1.999 → 0.999 (right);
    --            then t=2 → 0 again (teleport).
    local pSaw = (t % PERIOD) / PERIOD
    local xSaw = xFromP(pSaw)
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.circle("fill", xSaw, 320, 22)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("sawtooth: p = " .. fmt(pSaw) .. "  x = " .. fmt(xSaw), xSaw - 90, 352)

    -- Marker: the current clock position on the ruler (yellow).
    --   Example: t=3.2 → marker x = 60 + 3.2*60 = 252.
    local marker = 60 + (t % 15) * 60
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", marker - 2, 512, 4, 40)

    -- Live panel: a text box reporting the clock, the cycle phase,
    -- and how many events have been stamped.
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 400, 420, 96, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 402)
    love.graphics.print("t (seconds)   = " .. fmt(t, 3), 15, 418)
    love.graphics.print("cycle phase   = " .. fmt(t % PERIOD, 3) .. "  of " .. PERIOD .. "s", 15, 434)
    love.graphics.print("events stamped: " .. #hits .. "   [R] clear", 15, 450)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Motion is a function of the clock. Given t, position is determined —", 10, 580)
    love.graphics.print("nothing random. Games are the same: every animation is a path from one event", 10, 594)
    love.graphics.print("to the next, and t is the distance you have travelled along it.", 10, 608)
end

return M