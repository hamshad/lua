-- ============================================================
-- CHAPTER 7: Noise and Randomness — Organic Patterns
-- ============================================================
-- Pure math gives you smooth, predictable patterns. Nature is messy.
-- Noise functions give you controlled randomness — structured chaos.
--
-- Value noise: random values at grid points, interpolated between.
--   noise(vec2 p) returns 0.0 to 1.0 for any coordinate p.
--   Same input → same output (deterministic).
--
-- Fractal Brownian Motion (fBM): layer noise at different scales.
--   sum += amplitude * noise(pos);
--   pos *= 2.0;        // double frequency
--   amplitude *= 0.5;  // halve amplitude
--   This gives you natural-looking terrain, clouds, marble, wood.
--
-- Dummy walk-through for fBM at pos = (1.5, 2.3), 4 octaves:
--   Oct 1: noise(1.5, 2.3) * 1.0  ≈ 0.65
--   Oct 2: noise(3.0, 4.6) * 0.5  ≈ 0.38
--   Oct 3: noise(6.0, 9.2) * 0.25 ≈ 0.11
--   Oct 4: noise(12., 18.4)* 0.125≈ 0.04
--   Total ≈ 1.18, normalized to ~0.59
--
-- KEYS: [1-4] octaves  [R] regenerate seed
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local liveLines = {}
local octaves = 4
local seed = 0.0

local fragSrc = [[
    uniform float time;
    uniform int octaves;
    uniform float seed;

    float hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
    }

    float noise(vec2 p) {
        vec2 i = floor(p);
        vec2 f = fract(p);
        f = f * f * (3.0 - 2.0 * f);

        float a = hash(i);
        float b = hash(i + vec2(1.0, 0.0));
        float c = hash(i + vec2(0.0, 1.0));
        float d = hash(i + vec2(1.0, 1.0));

        return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
    }

    float fbm(vec2 p) {
        float value = 0.0;
        float amplitude = 0.5;
        float frequency = 1.0;
        for (int i = 0; i < 8; i++) {
            if (i >= octaves) break;
            value += amplitude * noise(p * frequency + seed);
            frequency *= 2.0;
            amplitude *= 0.5;
        }
        return value;
    }

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec2 uv = pixcoord / vec2(1024.0, 768.0);
        vec2 pos = uv * 4.0;

        float n = fbm(pos + time * 0.1);

        vec3 col = mix(vec3(0.05, 0.1, 0.2), vec3(0.8, 0.4, 0.1), n);
        col = mix(col, vec3(0.95, 0.9, 0.8), n * n);

        float detail = noise(pos * 8.0 + time * 0.5) * 0.1;
        col += detail;

        return vec4(col, 1.0);
    }
]]

function M.init()
    shader = love.graphics.newShader(fragSrc)
    octaves = 4
    seed = 0.0
end

function M.update(dt)
    shader:send("time", love.timer.getTime())
    shader:send("octaves", octaves)
    shader:send("seed", seed)
    liveLines = {
        "fBM octaves = " .. octaves,
        "seed = " .. utils.fmt(seed),
        "noise(p) → 0.0 to 1.0",
        "Each octave: 2x freq, 0.5x amplitude",
    }
end

function M.draw()
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 40, 1024, 728)
    love.graphics.setShader()

    for i = 1, 4 do
        utils.drawButton(10 + (i - 1) * 90, 50, 80, 28, "[" .. i .. "] " .. i .. " oct", i == octaves)
    end
    utils.drawButton(380, 50, 120, 28, "[R] Seed: " .. utils.fmt(seed, 1), false)

    utils.drawTextBox(10, 40, 280, 90, liveLines)
    utils.drawFeynman(
        "Feynman: Noise is not random — it's pseudorandom. Same input,\n" ..
        "same output, always. But it looks random because the hash function\n" ..
        "scrambles coordinates. fBM stacks noise at different scales like\n" ..
        "layers of paint — big shapes first, fine details last."
    )
end

function M.keypressed(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= 4 then
        octaves = num
    elseif key == "r" then
        seed = seed + 1.0
    end
end

function M.mousepressed(x, y, button) end

return M
