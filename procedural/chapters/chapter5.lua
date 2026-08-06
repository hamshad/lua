-- ============================================================
-- CHAPTER 5: Easing Curves — The Language of Feel
-- ============================================================
-- A tween is a trip from A to B over a duration. The EASING curve
-- reshapes the normalized t (0→1) so the trip does not feel linear:
-- it can start slow and rush (ease-in), rush then settle
-- (ease-out), both (ease-in-out), or overshoot the end (back).
--
-- Five boxes travel the same distance in the same 1.5 seconds.
-- Only their easing curve differs — and the FEEL is completely
-- different. This is game feel: identical mechanics, different
-- emotion.
--
-- SPACE: replay the tween

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua.
local M = {}

-- DUR: how long each tween trip lasts, in seconds. All five boxes
-- share the same duration so the ONLY difference is the easing.
local DUR = 1.5
-- t: the raw normalized progress, 0..1, shared by every box.
--   Example: mid-trip at t = 0.5 → each box has travelled half the
--            raw timeline (but a different EASED distance).
local t = 0
-- playing: true while the tween is still running, false once t=1.
-- SPACE flips it back to true to replay.
local playing = true

-- curves: the five easing curves being compared. Each entry pairs a
-- display name with its easing function from utils.
--   Example: curves[3] = {name="inQuad", fn=utils.easeInQuad}.
local curves = {
    { name = "linear",       fn = utils.easeLinear },
    { name = "outQuad",      fn = utils.easeOutQuad },
    { name = "inQuad",       fn = utils.easeInQuad },
    { name = "inOutCubic",   fn = utils.easeInOutCubic },
    { name = "outBack",      fn = utils.easeOutBack },
}

-- X0, X1: the left and right screen edges of every travel line, in
-- pixels. All five boxes run between these.
local X0, X1 = 60, 960
-- ROWS: the y-position (row) for each of the five boxes, top to
-- bottom, matching the order of `curves`.
local ROWS = { 80, 190, 300, 410, 520 }

-- M.init(): reset the tween to the start and replay.
function M.init()
    t = 0
    playing = true
end

-- M.update(dt): advance raw t toward 1 at a fixed rate of one full
-- trip per DUR seconds, then stop when done.
--   Example: t=0.4, dt=1/60, DUR=1.5 → t = min(1, 0.4 + 0.0111) = 0.4111.
function M.update(dt)
    if playing then
        t = math.min(1, t + dt / DUR)
        if t >= 1 then playing = false end
    end
end

-- M.keypressed(key): SPACE replays the whole race.
function M.keypressed(key)
    if key == " " then
        t = 0
        playing = true
    end
end

-- M.draw(): render the grid, one row per curve (line + eased box +
-- progress ticks), the raw-t marker, and the live panel.
function M.draw()
    utils.drawGrid()

    -- One row per easing curve.
    for i, c in ipairs(curves) do
        local y = ROWS[i]        -- this curve's row
        local e = c.fn(t)        -- the eased progress at raw t
        --   Example: i=2 (outQuad), t=0.5 → e = 1-(1-0.5)² = 0.75.

        -- Travel line: the full track from X0 to X1.
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.line(X0, y, X1, y)

        -- The box at its eased position along the track.
        --   Example: e=0.75 → x = 60 + 900·0.75 = 735.
        local x = X0 + (X1 - X0) * e
        local color = {i / 6, 0.5, 1 - i / 6}
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", x - 14, y - 14, 28, 28)

        -- Label + current eased value.
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontSmall)
        love.graphics.print(c.name .. "  eased=" .. fmt(e, 2), X0, y + 22)

        -- Progress ticks: where the box sits at every 10% of raw t.
        -- Spacing between ticks reveals the curve's speed profile:
        -- crowded ticks = slow there, sparse ticks = fast there.
        for p = 1, 9 do
            local tx = p / 10
            local ex = c.fn(tx)
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.circle("fill", X0 + (X1 - X0) * ex, y, 2)
        end
    end

    -- Raw-t marker: the yellow vertical bar at the SHARED raw time,
    -- so you can compare where each box is at the same raw moment.
    --   Example: t=0.5 → bar at x = 60 + 900·0.5 = 510.
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", X0 + (X1 - X0) * t - 2, 60, 4, 560)

    -- Live panel.
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 640, 1000, 90, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 642)
    love.graphics.print("t = " .. fmt(t, 3) .. "  of 1.0   duration = " .. DUR .. "s   [SPACE] replay", 15, 658)
    love.graphics.print("outBack overshoots the target, then settles back — beloved for UI pop.", 15, 674)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: easing does not change the motion, it changes the TIME-EXCHANGE — it", 10, 744)
    love.graphics.print("spends t slowly where the eye needs reading time and quickly where it does not.", 10, 758)
end

return M