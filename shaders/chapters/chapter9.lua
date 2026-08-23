-- ============================================================
-- CHAPTER 9: Color Theory in Shaders — Palettes and Mixing
-- ============================================================
-- Colors in shaders are just vec3 (r, g, b) with values 0.0-1.0.
-- The real art is in HOW you combine them.
--
-- HSV (Hue, Saturation, Value):
--   Hue:        0.0-1.0 around the color wheel (0=red, 0.33=green, 0.66=blue)
--   Saturation: 0.0=gray, 1.0=vivid
--   Value:      0.0=black, 1.0=bright
--
-- Palette function (Inigo Quilez's cosine palette):
--   color(t) = a + b * cos(2π(c*t + d))
--   a = offset, b = amplitude, c = frequency, d = phase
--   Tweak d to get completely different palettes from the same formula.
--
-- Dummy walk-through for palette at t=0.25, d=(0, 0.1, 0.2):
--   cos(2π * (0.25 + 0)) = cos(π/2) = 0   → r = 0.5 + 0.5*0 = 0.5
--   cos(2π * (0.25 + 0.1)) = cos(0.7π) ≈ -0.59 → g ≈ 0.5 - 0.3 = 0.2
--   cos(2π * (0.25 + 0.2)) = cos(0.9π) ≈ -0.81 → b ≈ 0.5 - 0.4 = 0.1
--
-- KEYS: [1-4] palette presets
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local liveLines = {}
local paletteMode = 1

local fragSrc = [[
    uniform float time;
    uniform int paletteMode;

    vec3 hsv2rgb(vec3 c) {
        vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
        vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    vec3 palette(float t, int mode) {
        if (mode == 1) {
            vec3 a = vec3(0.5, 0.5, 0.5);
            vec3 b = vec3(0.5, 0.5, 0.5);
            vec3 c = vec3(1.0, 1.0, 1.0);
            vec3 d = vec3(0.00, 0.10, 0.20);
            return a + b * cos(6.28318 * (c * t + d));
        }
        else if (mode == 2) {
            vec3 a = vec3(0.5, 0.5, 0.5);
            vec3 b = vec3(0.5, 0.5, 0.5);
            vec3 c = vec3(1.0, 1.0, 1.0);
            vec3 d = vec3(0.30, 0.20, 0.20);
            return a + b * cos(6.28318 * (c * t + d));
        }
        else if (mode == 3) {
            vec3 a = vec3(0.5, 0.5, 0.5);
            vec3 b = vec3(0.5, 0.5, 0.5);
            vec3 c = vec3(2.0, 1.0, 0.0);
            vec3 d = vec3(0.50, 0.20, 0.25);
            return a + b * cos(6.28318 * (c * t + d));
        }
        else {
            return hsv2rgb(vec3(t, 0.8, 1.0));
        }
    }

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec2 uv = pixcoord / vec2(1024.0, 768.0);

        vec3 col = palette(uv.x + time * 0.1, paletteMode);

        float bands = sin(uv.y * 20.0 + time) * 0.5 + 0.5;
        col *= 0.5 + 0.5 * bands;

        float vignette = 1.0 - length(uv - 0.5) * 0.8;
        col *= vignette;

        return vec4(col, 1.0);
    }
]]

local labels = {"Cosine Warm", "Cosine Cool", "Cosine Wild", "HSV Rainbow"}

function M.init()
    shader = love.graphics.newShader(fragSrc)
    paletteMode = 1
end

function M.update(dt)
    shader:send("time", love.timer.getTime())
    shader:send("paletteMode", paletteMode)
    liveLines = {
        "Palette: " .. labels[paletteMode],
        "cos(2π(c*t + d)) — Iq's cosine palette",
        "t = uv.x + time * 0.1",
        "HSV: h=hue wheel, s=saturation, v=brightness",
    }
end

function M.draw()
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 40, 1024, 728)
    love.graphics.setShader()

    for i = 1, 4 do
        utils.drawButton(10 + (i - 1) * 150, 50, 140, 28, "[" .. i .. "] " .. labels[i], i == paletteMode)
    end

    local mx = love.mouse.getX()
    local t = mx / 1024
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print("t = " .. utils.fmt(t, 2), mx + 10, 80)

    utils.drawTextBox(10, 40, 320, 90, liveLines)
    utils.drawFeynman(
        "Feynman: Color is just three numbers. The cosine palette trick:\n" ..
        "a + b * cos(2π(c*t + d)) — change d, get a whole new mood.\n" ..
        "Warm sunset, cold ocean, neon cyberpunk — same formula, different d."
    )
end

function M.keypressed(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= 4 then
        paletteMode = num
    end
end

function M.mousepressed(x, y, button) end

return M
