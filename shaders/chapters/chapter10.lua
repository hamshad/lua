-- ============================================================
-- CHAPTER 10: Post-Processing Effects — Screen-Space Magic
-- ============================================================
-- Post-processing = draw the scene first, then run a shader over
-- the result. You read the existing pixels and transform them.
--
-- Workflow:
--   1. Set canvas: love.graphics.setCanvas(myCanvas)
--   2. Draw your scene normally
--   3. Set canvas back: love.graphics.setCanvas()
--   4. Draw canvas with post-processing shader applied
--
-- This chapter demonstrates 5 classic effects:
--   Blur:        average neighboring pixels (kernel convolution)
--   Bloom:       extract bright pixels, blur, blend back
--   Vignette:    darken edges (distance from center)
--   Chromatic Aberration: offset R, G, B channels
--   Scanlines:   dark horizontal lines (retro TV feel)
--
-- Dummy walk-through for vignette at pixel (800, 600):
--   uv = (0.781, 0.781), center = (0.5, 0.5)
--   dist = length(0.281, 0.281) = 0.397
--   vignette = 1.0 - 0.397 * 0.8 = 0.682
--   pixel *= 0.682 → darker at edges
--
-- KEYS: [1-5] effect modes  [B] toggle bloom on/off
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local canvas = nil
local liveLines = {}
local mode = 1
local bloomOn = true

local fragSrc = [[
    uniform int mode;
    uniform float time;
    uniform float bloom;

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec4 pixel = Texel(tex, texcoord);
        vec2 uv = texcoord;
        vec2 texel = vec2(1.0 / 1024.0, 1.0 / 768.0);

        if (mode == 1) {
            vec4 sum = vec4(0.0);
            for (int x = -2; x <= 2; x++) {
                for (int y = -2; y <= 2; y++) {
                    sum += Texel(tex, uv + vec2(float(x), float(y)) * texel * 2.0);
                }
            }
            return sum / 25.0;
        }
        else if (mode == 2) {
            vec4 sum = vec4(0.0);
            for (int x = -3; x <= 3; x++) {
                for (int y = -3; y <= 3; y++) {
                    vec4 s = Texel(tex, uv + vec2(float(x), float(y)) * texel * 3.0);
                    float brightness = dot(s.rgb, vec3(0.2126, 0.7152, 0.0722));
                    if (brightness > 0.7) {
                        sum += s;
                    }
                }
            }
            vec4 blurred = sum / 49.0;
            return pixel + blurred * bloom;
        }
        else if (mode == 3) {
            float dist = length(uv - 0.5);
            float vig = 1.0 - dist * 1.2;
            vig = clamp(vig, 0.0, 1.0);
            vig = smoothstep(0.0, 0.7, vig);
            return pixel * vig;
        }
        else if (mode == 4) {
            float offset = 4.0 * texel.x;
            float r = Texel(tex, uv + vec2(offset, 0.0)).r;
            float g = pixel.g;
            float b = Texel(tex, uv - vec2(offset, 0.0)).b;
            return vec4(r, g, b, pixel.a);
        }
        else if (mode == 5) {
            float scanline = sin(uv.y * 768.0 * 1.5) * 0.04;
            pixel.rgb -= scanline;
            float flicker = sin(time * 8.0) * 0.01;
            pixel.rgb += flicker;
            return pixel;
        }

        return pixel;
    }
]]

local labels = {"Blur", "Bloom", "Vignette", "Chroma", "Scanlines"}

function M.init()
    shader = love.graphics.newShader(fragSrc)
    canvas = love.graphics.newCanvas(1024, 768)
    mode = 1
    bloomOn = true
end

function M.update(dt)
    shader:send("mode", mode)
    shader:send("time", love.timer.getTime())
    shader:send("bloom", bloomOn and 1.0 or 0.0)
    liveLines = {
        "Effect: " .. labels[mode],
        "Canvas → draw scene → shader → screen",
        mode == 2 and "Bloom: " .. (bloomOn and "ON" or "OFF") or "",
        mode == 4 and "Offset: 4 texels (chromatic shift)" or "",
    }
end

function M.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.05, 0.05, 0.12)
    drawScene()
    love.graphics.setCanvas()

    love.graphics.setShader(shader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, 0, 0)
    love.graphics.setShader()

    for i = 1, 5 do
        utils.drawButton(10 + (i - 1) * 100, 50, 90, 28, "[" .. i .. "] " .. labels[i], i == mode)
    end
    if mode == 2 then
        utils.drawButton(520, 50, 100, 28, "[B] Bloom: " .. (bloomOn and "ON" or "OFF"), bloomOn)
    end

    utils.drawTextBox(10, 40, 300, 90, liveLines)
    utils.drawFeynman(
        "Feynman: Post-processing is like looking at a painting through\n" ..
        "different camera lenses. Same scene, but blur it and it's dreamy,\n" ..
        "darken the edges and it's cinematic, offset the colors and it's retro."
    )
end

function drawScene()
    love.graphics.setColor(0.2, 0.3, 0.6)
    love.graphics.rectangle("fill", 100, 200, 200, 300, 12, 12)
    love.graphics.setColor(0.8, 0.3, 0.2)
    love.graphics.circle("fill", 500, 350, 80)
    love.graphics.setColor(0.3, 0.7, 0.4)
    love.graphics.polygon("fill", 700, 200, 850, 500, 550, 500)
    love.graphics.setColor(0.9, 0.8, 0.2)
    love.graphics.ellipse("fill", 350, 600, 150, 40)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(fontLarge)
    love.graphics.printf("Post-Processing", 0, 80, 1024, "center")
    love.graphics.setFont(fontSmall)
    love.graphics.printf("Draw scene → Apply shader → Screen", 0, 120, 1024, "center")
end

function M.keypressed(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= 5 then
        mode = num
    elseif key == "b" and mode == 2 then
        bloomOn = not bloomOn
    end
end

function M.mousepressed(x, y, button) end

return M
