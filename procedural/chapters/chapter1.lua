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

local M = {}

local t = 0                 -- chapter clock, seconds
local hits = {}             -- recorded event times

local PERIOD = 2.0          -- seconds per full cycle

local function xFromP(p)
    return lerp(80, 944, p)
end

function M.init()
    t = 0
    hits = {}
end

function M.update(dt)
    t = t + dt
end

function M.mousepressed(x, y, button)
    if button == 1 then
        table.insert(hits, t)
        if #hits > 14 then table.remove(hits, 1) end
    end
end

function M.keypressed(key)
    if key == "r" then
        hits = {}
    end
end

function M.draw()
    utils.drawGrid()

    -- Timeline ruler (the raw clock, drawn once a second)
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", 60, 520, 900, 30)
    love.graphics.setColor(0.35, 0.35, 0.35)
    for s = 0, 14 do
        love.graphics.print(s, 60 + s * 60, 552)
    end

    -- Event stamps on the timeline
    for _, h in ipairs(hits) do
        local x = 60 + (h % 15) * 60
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.line(x, 516, x, 552)
    end

    -- Triangle-wave ball: bounces off both edges
    local pTri = math.abs((t % PERIOD) / PERIOD - 0.5) * 2
    local xTri = xFromP(pTri)
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.circle("fill", xTri, 200, 22)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    love.graphics.print("triangle: p = " .. fmt(pTri) .. "  x = " .. fmt(xTri), xTri - 90, 232)

    -- Sawtooth ball: runs right, snaps back to left
    local pSaw = (t % PERIOD) / PERIOD
    local xSaw = xFromP(pSaw)
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.circle("fill", xSaw, 320, 22)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("sawtooth: p = " .. fmt(pSaw) .. "  x = " .. fmt(xSaw), xSaw - 90, 352)

    -- Same position on the ruler each tick
    local marker = 60 + (t % 15) * 60
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", marker - 2, 512, 4, 40)

    -- Live panel
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