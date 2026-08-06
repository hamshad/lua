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

-- M: the module table exported to main.lua.
local M = {}

-- t: the chapter clock in seconds. Drives the bobber (time) and
-- implicitly the drawn curve (the curve is static in x).
--   Example: after 3 seconds, t = 3.0.
local t = 0
-- A: the amplitude, in pixels — how far the wave swings above and
-- below the center line y=320.
--   Example: A=80 → the curve ranges y ∈ [240, 400].
local A = 80.0
-- f: the frequency in hertz — how many full cycles per second.
--   Example: f=1 → one full up-and-down per second; period 1/f = 1 s.
local f = 1.0
-- phase: the cycle start offset in radians. 0 keeps the wave starting
-- at the center; π/2 would start it at its peak.
local phase = 0.0

-- waveY(x): the sine curve's height at horizontal position x. The
-- "time" axis is x/60 so the curve can be drawn across the screen
-- (x in pixels ↔ t in 1/60 s units).
--   Example: A=80, f=1, x=0  → 320 + 80·sin(0) = 320
--            x=15 → 320 + 80·sin(2π·1·15/60) = 320 + 80·sin(π/2) = 400 (peak)
--            x=30 → 320 + 80·sin(π) = 320 (back to center)
local function waveY(x)
    return 320 + A * math.sin(2 * math.pi * f * x / 60 + phase)
end

-- M.init(): reset the clock, amplitude, and frequency.
function M.init()
    t = 0
    A = 80.0
    f = 1.0
end

-- M.update(dt): advance the clock by one fixed step.
function M.update(dt)
    t = t + dt   -- Example: t=1.983 + 1/60 → t = 1.9997
end

-- M.keypressed(key): the arrow keys tweak the two dials, and 1/2
-- snap to recognizable presets (a breath and a heartbeat).
function M.keypressed(key)
    -- UP: louder swing. A=80 → A=90. DOWN: quieter, floored at 10.
    if key == "up" then A = A + 10 end
    if key == "down" then A = math.max(10, A - 10) end
    -- RIGHT: faster cycles, capped at 4 Hz. LEFT: slower, floored at 0.1.
    if key == "right" then f = math.min(4, f + 0.1) end
    if key == "left" then f = math.max(0.1, f - 0.1) end
    -- Presets: [1] a human breath (one full cycle every 4 s),
    -- [2] a heartbeat (~72 bpm → 1.2 Hz).
    if key == "1" then f, A = 0.25, 40 end
    if key == "2" then f, A = 1.2, 30 end
end

-- M.draw(): render the grid, center line, the sine curve, the
-- bobber riding it in time, the amplitude bracket, and the live panel.
function M.draw()
    utils.drawGrid()

    -- Center line: the wave's zero axis at y=320.
    love.graphics.setColor(0.25, 0.25, 0.25)
    love.graphics.line(0, 320, 1024, 320)

    -- The sine curve: sampled every 2 px into one polyline of
    -- alternating x/y coordinates, then drawn as a single line.
    --   pts = {x0, y0, x1, y1, x2, y2, ...} across the screen.
    love.graphics.setColor(0.3, 0.8, 0.4)
    local pts = {}
    for x = 0, 1024, 2 do
        table.insert(pts, x)
        table.insert(pts, waveY(x))
    end
    love.graphics.line(pts)

    -- The bobber: rides the SAME sine, but driven by time t instead
    -- of screen x — it is the wave "lived" rather than drawn.
    --   Example: t=0.25, f=1 → y = 320 + 80·sin(π/2) = 400 (bottom of swing).
    local bobX = 300
    local bobY = 320 + A * math.sin(2 * math.pi * f * t + phase)
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.circle("fill", bobX, bobY, 24)
    -- Drop-line from the bobber to the center, showing its offset.
    love.graphics.line(bobX, bobY, bobX, 320)

    -- Amplitude bracket: the yellow bar from center up to the peak,
    -- labeled "A". Its length is exactly the amplitude.
    --   Example: A=80 → the bar spans y ∈ [240, 320].
    love.graphics.setColor(1, 1, 0)
    love.graphics.line(bobX, 320, bobX, 320 - A)
    love.graphics.print("A", bobX + 6, 320 - A - 14)

    -- Live panel: reports the two dials and the computed period.
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