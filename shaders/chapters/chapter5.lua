-- ============================================================
-- CHAPTER 5: Textures and Sampling — Reading Images in Shaders
-- ============================================================
-- A texture is just a grid of colors stored on the GPU. When you
-- draw an image, the shader reads texels (texture pixels) using
-- UV coordinates: (0,0) = bottom-left, (1,1) = top-right.
--
-- Texel fetching:
--   vec4 pixel = Texel(tex, uv);  // LÖVE2D GLSL
--   pixel.r, pixel.g, pixel.b, pixel.a  →  0.0 to 1.0
--
-- The texture is bound to the "tex" uniform automatically.
-- texcoord comes from the vertex shader — it interpolates across
-- the quad you draw.
--
-- Dummy walk-through at uv = (0.5, 0.5) on a 64x64 texture:
--   texel position = (32, 32) — center of the texture
--   Texel returns the color at that point
--
-- MOUSE: uv coordinates shown live
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local canvas = nil
local liveLines = {}
local mode = 1

local fragSrc = [[
    uniform float time;
    uniform int mode;

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec4 pixel = Texel(tex, texcoord);

        if (mode == 1) {
            return pixel;
        }
        else if (mode == 2) {
            float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
            return vec4(vec3(gray), pixel.a);
        }
        else if (mode == 3) {
            return vec4(pixel.r, 0.0, 0.0, pixel.a);
        }
        else if (mode == 4) {
            vec2 uv = texcoord;
            uv.x = fract(uv.x * 4.0);
            uv.y = fract(uv.y * 4.0);
            vec4 p2 = Texel(tex, uv);
            return p2;
        }
        else if (mode == 5) {
            vec2 uv = texcoord;
            float wave = sin(uv.y * 20.0 + time * 3.0) * 0.02;
            uv.x += wave;
            return Texel(tex, uv);
        }
        return pixel;
    }
]]

local labels = {"Original", "Grayscale", "Red Only", "Tile 4x4", "Wave Distort"}

function M.init()
    shader = love.graphics.newShader(fragSrc)
    mode = 1
    canvas = love.graphics.newCanvas(256, 256)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.1, 0.1, 0.15)
    for i = 0, 15 do
        for j = 0, 15 do
            local r = (i / 15) * 0.8 + 0.1
            local g = (j / 15) * 0.8 + 0.1
            local b = 0.3 + 0.4 * math.sin((i + j) * 0.5)
            love.graphics.setColor(r, g, b, 1)
            love.graphics.rectangle("fill", i * 16, j * 16, 16, 16)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontLarge)
    love.graphics.printf("TEXTURE", 0, 110, 256, "center")
    love.graphics.setFont(fontSmall)
    love.graphics.printf("256 x 256", 0, 145, 256, "center")
    love.graphics.setCanvas()
end

function M.update(dt)
    shader:send("time", love.timer.getTime())
    shader:send("mode", mode)
    local mx, my = love.mouse.getPosition()
    local u = mx / 1024
    local v = my / 768
    liveLines = {
        "texcoord = (" .. utils.fmt(u) .. ", " .. utils.fmt(v) .. ")",
        "mode = " .. mode .. " (" .. labels[mode] .. ")",
        "Texel(tex, uv) samples the texture",
        "uv (0,0)=bot-left  (1,1)=top-right",
    }
end

function M.draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader(shader)
    love.graphics.draw(canvas, 0, 40, 0, 1024 / 256, 728 / 256)
    love.graphics.setShader()

    for i = 1, #labels do
        local bw = 120
        local bx = 10 + (i - 1) * (bw + 6)
        utils.drawButton(bx, 50, bw, 28, "[" .. i .. "] " .. labels[i], i == mode)
    end

    local mx, my = love.mouse.getPosition()
    if mx < 1024 and my > 40 then
        local u = mx / 1024
        local v = (my - 40) / 728
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.print("uv(" .. utils.fmt(u, 2) .. ", " .. utils.fmt(v, 2) .. ")", mx + 10, my - 10)
    end

    utils.drawTextBox(10, 40, 320, 90, liveLines)
    utils.drawFeynman(
        "Feynman: A texture is a paint-by-numbers grid. UV coordinates are\n" ..
        "the instructions: go 30% right, 60% up, pick that color. Texel()\n" ..
        "is the lookup function. The GPU does billions of these per second."
    )
end

function M.keypressed(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= #labels then
        mode = num
    end
end

function M.mousepressed(x, y, button) end

return M
