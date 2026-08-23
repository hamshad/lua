-- ============================================================
-- CHAPTER 2: Your First Shader — Anatomy of gl_FragColor
-- ============================================================
-- The fragment shader function signature in LÖVE2D is:
--
--   vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
--
-- color:    the tint color set by love.graphics.setColor()
-- tex:      the texture being drawn (or a 1x1 white pixel if none)
-- texcoord: UV coordinates (0,0) to (1,1) across the texture
-- pixcoord: pixel position on screen (like gl_FragCoord)
--
-- Return value: vec4(r, g, b, a) — the final pixel color.
--
-- LÖVE2D simplifies things: you don't write "gl_FragColor = ..."
-- you just RETURN the color from the effect() function.
--
-- Dummy walk-through at pixel (256, 512):
--   color    = (1, 1, 1, 1)  (white, no tint)
--   texcoord = (0.25, 0.667)
--   pixcoord = (256.0, 512.0)
--   Return (1.0, 0.0, 0.0, 1.0) → pixel turns red
--
-- KEYS: [1-3] switch color modes
-- ============================================================

local M = {}
local utils = require("utils")

local mode = 1
local liveLines = {}

local shaderSolid = [[
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        return vec4(1.0, 0.2, 0.2, 1.0);
    }
]]

local shaderGradient = [[
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        float r = pixcoord.x / 1024.0;
        float g = pixcoord.y / 768.0;
        return vec4(r, g, 0.5, 1.0);
    }
]]

local shaderChecker = [[
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        float cx = floor(pixcoord.x / 64.0);
        float cy = floor(pixcoord.y / 64.0);
        float checker = mod(cx + cy, 2.0);
        return vec4(vec3(checker * 0.6 + 0.2), 1.0);
    }
]]

local shaders = {}
local labels = {"Solid Red", "Gradient", "Checkerboard"}

function M.init()
    mode = 1
    shaders[1] = love.graphics.newShader(shaderSolid)
    shaders[2] = love.graphics.newShader(shaderGradient)
    shaders[3] = love.graphics.newShader(shaderChecker)
end

function M.update(dt)
    liveLines = {
        "Mode: " .. labels[mode],
        "shader = love.graphics.newShader(fragSrc)",
        "love.graphics.setShader(shader)",
        "love.graphics.rectangle(\"fill\", ...)",
    }
end

function M.draw()
    love.graphics.setShader(shaders[mode])
    love.graphics.rectangle("fill", 0, 40, 1024, 728)
    love.graphics.setShader()

    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", 350, 300, 340, 100, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontLarge)
    love.graphics.printf("Chapter 2", 350, 310, 340, "center")
    love.graphics.setFont(fontSmall)
    love.graphics.printf("Your First Shader", 350, 345, 340, "center")

    for i = 1, 3 do
        utils.drawButton(750 + (i - 1) * 90, 50, 80, 28, "[" .. i .. "] " .. labels[i]:sub(1, 4), i == mode)
    end

    utils.drawTextBox(10, 40, 320, 90, liveLines)
    utils.drawFeynman(
        "Feynman: The effect() function is your contract with the GPU.\n" ..
        "You get some inputs, you return a color. No magic, no side effects.\n" ..
        "Just: here's where I am, here's what color I should be. Done."
    )
end

function M.keypressed(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= 3 then
        mode = num
    end
end

function M.mousepressed(x, y, button) end

return M
