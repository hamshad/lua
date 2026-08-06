-- ============================================================
-- CHAPTER 10: Noise — Organic Imperfection
-- ============================================================
-- Sines are periodic; life is not. Perlin noise is a smooth,
-- non-repeating value — love.math.noise(x, t) returns one. Sample
-- it along space to get a wavy line, sample it along time to get
-- a tremble that never quite repeats.
--
-- Three uses at once:
--   1D: a wobbling line (noise along x)
--   2D: a trembling cloud of motes (noise in x, y, t)
--   time: the line's base drift
--
-- UP/DOWN: noise speed   LEFT/RIGHT: amplitude   [R] new seed

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua.
local M = {}

-- t: the chapter clock in seconds; feeds the time dimension of the
-- noise samples so the scene drifts frame by frame.
local t = 0
-- amp: how far the line and the motes can wander, in pixels.
--   Example: amp=60 → line swings ±60 px around its base height.
local amp = 60.0
-- speed: how fast the noise field advances along time.
--   Example: speed=0.8 → slow drift; speed=4 → frantic tremble.
local speed = 0.8
-- seed: the noise's identity. Same seed → same wander, forever.
--   Example: seed=42 and seed=43 give two different, both smooth,
--            non-repeating patterns.
local seed = 0

-- motes: 60 fixed base positions the 2D noise wobbles around.
-- Each mote = {x, y}, then noise pushes it up to 40 px away.
local motes = {}
for i = 1, 60 do
    motes[i] = { x = love.math.random() * 900 + 60, y = love.math.random() * 500 + 60 }
end

-- M.init(): reset the clock and amp, pick a fresh seed, and scatter
-- the motes to new base positions.
function M.init()
    t = 0
    amp = 60.0
    seed = love.math.random(1000)
    motes = {}
    for i = 1, 60 do
        motes[i] = { x = love.math.random() * 900 + 60, y = love.math.random() * 500 + 60 }
    end
end

-- M.update(dt): just advance the clock; all motion is read from
-- love.math.noise inside draw.
function M.update(dt)
    t = t + dt
end

-- M.keypressed(key): arrows tune speed/amplitude, [R] re-seeds.
function M.keypressed(key)
    if key == "up" then speed = math.min(4, speed + 0.2) end
    if key == "down" then speed = math.max(0.1, speed - 0.2) end
    if key == "right" then amp = math.min(160, amp + 10) end
    if key == "left" then amp = math.max(10, amp - 10) end
    if key == "r" then seed = love.math.random(1000) end
end

-- M.draw(): render the 1D noise line, the 2D-noise mote field, the
-- live panel, and the Feynman footer.
function M.draw()
    utils.drawGrid()

    -- 1D noise line: y(x) = 300 + amp·noise(x). One sample per 4 px,
    -- stitched into a polyline. `n` lives in [0,1], so (n-0.5)·2 maps
    -- it to [-1,1] around the base 300.
    --   Example: x=0, n=0.62, amp=60 → y = 300 + 60·0.24 = 314.
    love.graphics.setColor(0.3, 0.8, 0.5)
    local pts = {}
    for x = 0, 1024, 4 do
        local n = love.math.noise(seed + x * 0.005, t * speed)
        table.insert(pts, x)
        table.insert(pts, 300 + amp * (n - 0.5) * 2)
    end
    love.graphics.line(pts)

    -- Motes drifting on 2D noise: each mote reads two noise samples
    -- (x-offset and y-offset) at its OWN spatial coordinates, so two
    -- motes never drift in lockstep. The seed in one axis per sample
    -- decorrelates ox from oy.
    --   Example: mote at (300,200), noise ≈ 0.55 → offset 0.05·40 = 2 px.
    love.graphics.setColor(0.9, 0.8, 0.4, 0.7)
    for _, m in ipairs(motes) do
        local ox = love.math.noise(seed + m.x * 0.02, m.y * 0.02, t * speed) - 0.5
        local oy = love.math.noise(m.x * 0.02, seed + m.y * 0.02, t * speed) - 0.5
        love.graphics.circle("fill", m.x + ox * 40, m.y + oy * 40, 2.5)
    end

    -- Live panel: current speed, amplitude, and seed.
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 620, 1000, 90, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 622)
    love.graphics.print("noise(seed,x,t) sampled 1D along x and 2D over the mote field", 15, 638)
    love.graphics.print("speed=" .. fmt(speed, 2) .. "  amp=" .. fmt(amp) .. "  seed=" .. seed, 15, 654)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: sine repeats, noise wanders. Same seed → same wander (deterministic),", 10, 700)
    love.graphics.print("so noise is still a function of t — just a bumpier one. Games use it for camera", 10, 714)
    love.graphics.print("drift, idle trembles, leaves, hair, and anything that must feel alive but never", 10, 728)
    love.graphics.print("mechanical. The 2D sample is why two motes never drift the same way.", 10, 742)
end

return M