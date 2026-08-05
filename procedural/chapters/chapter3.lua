-- ============================================================
-- CHAPTER 3: Sine Waves — The Breath of Motion
-- ============================================================
-- sin(t) is the atom of organic motion. It produces the smooth
-- back-and-forth that bobbing, breathing, swinging, and swaying
-- all share. One sine has only three dials:
--
--   amplitude A  — how far from center it swings
--   frequency f  — how many cycles per second (Hz)
--   phase φ      — where in the cycle it starts
--
--   y(t) = center + A * sin(2π * f * t + φ)
--
-- The curve below is exactly this. The ball rides it.
--
-- LEFT/RIGHT: change frequency   UP/DOWN: change amplitude
-- 1/2:        jump to presets (breath ≈ 0.25 Hz, heartbeat ≈ 1.2 Hz)

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local t = 0
local A = 80.0          -- amplitude (px)
local f = 1.0           -- frequency (Hz)
local phase = 0.0

local function waveY(x)
    -- y as a function of horizontal position x, sampled in space.
    -- Same sin, but the "time" axis is x/60 so we can draw it.
    return 320 + A * math.sin(2 * math.pi * f * x / 60 + phase)
end

function M.init()
    t = 0
    A = 80.0
    f = 1.0
end

function M.update(dt)
    t = t + dt
end

function M.keypressed(key)
    if key == "up" then A = A + 10 end
    if key == "down" then A = math.max(10, A - 10) end
    if key == "right" then f = math.min(4, f + 0.1) end
    if key == "left" then f = math.max(0.1, f - 0.1) end
    if key == "1" then f, A = 0.25, 40 end   -- breath
    if key == "2" then f, A = 1.2, 30 end    -- heartbeat
end

function M.draw()
    utils.drawGrid()

    -- Center line
    love.graphics.setColor(0.25, 0.25, 0.25)
    love.graphics.line(0, 320, 1024, 320)

    -- The sine curve, sampled densely
    love.graphics.setColor(0.3, 0.8, 0.4)
    local pts = {}
    for x = 0, 1024, 2 do
        table.insert(pts, x)
        table.insert(pts, waveY(x))
    end
    love.graphics.line(pts)

    -- The bobber riding the wave in TIME (t drives x)
    local bobX = 300
    local bobY = 320 + A * math.sin(2 * math.pi * f * t + phase)
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.circle("fill", bobX, bobY, 24)
    love.graphics.line(bobX, bobY, bobX, 320)

    -- Visualizing amplitude on the curve: bracket from center
    love.graphics.setColor(1, 1, 0)
    love.graphics.line(bobX, 320, bobX, 320 - A)
    love.graphics.print("A", bobX + 6, 320 - A - 14)

    -- Live panel
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 480, 460, 120, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 482)
    love.graphics.print("amplitude A  = " .. fmt(A) .. " px", 15, 498)
    love.graphics.print("frequency f  = " .. fmt(f, 2) .. " Hz", 15, 514)
    love.graphics.print("period       = " .. fmt(1 / f, 2) .. " s/cycle", 15, 530)
    love.graphics.print("phase φ      = " .. fmt(math.deg(phase), 1) .. " deg", 15, 546)
    love.graphics.print("bobber y     = 320 + " .. fmt(A) .. "*sin(2π*" .. fmt(f, 2) .. "*t) = " .. fmt(bobY), 15, 562)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: a sine is just circular motion viewed edge-on — the shadow of a wheel", 10, 620)
    love.graphics.print("rolling at frequency f. Game characters breathe, idle, swing, and bob with sines.", 10, 634)
    love.graphics.print("The idle-breath of a character is a sine at ~0.25 Hz; a heartbeat ~1.2 Hz.", 10, 648)
    love.graphics.print("Controls: LEFT/RIGHT frequency, UP/DOWN amplitude, [1] breath, [2] heartbeat.", 10, 662)
end

return M