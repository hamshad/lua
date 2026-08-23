-- ============================================================
-- CHAPTER 1: The Pixel Pipeline — What Shaders Actually Are
-- ============================================================
-- Every pixel on screen is a tiny worker. A shader is the instruction
-- manual you give that worker. The GPU runs your shader ONCE PER PIXEL,
-- in parallel, thousands at a time.
--
-- A fragment shader receives one input: the pixel's position (gl_FragCoord).
-- It produces one output: the pixel's color (gl_FragColor).
--
-- That's it. That's the whole idea.
--
-- gl_FragCoord: (x, y) in pixels, bottom-left origin
--   At pixel (512, 384): x=512.0, y=384.0
--   At pixel (0, 0):    x=0.0,   y=0.0
--
-- gl_FragColor: (r, g, b, a) each 0.0 to 1.0
--   Red:   (1.0, 0.0, 0.0, 1.0)
--   White: (1.0, 1.0, 1.0, 1.0)
--
-- MOUSE: move to see pixel coordinates
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local liveLines = {}

local fragSrc = [[
    varying vec2 coord;
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        return color;
    }
]]

local fragSrc2 = [[
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        float r = pixcoord.x / 1024.0;
        float g = pixcoord.y / 768.0;
        return vec4(r, g, 0.3, 1.0);
    }
]]

function M.init()
    shader = love.graphics.newShader(fragSrc2)
end

function M.update(dt)
    local mx, my = love.mouse.getPosition()
    liveLines = {
        "gl_FragCoord.x = " .. utils.fmt(mx, 1),
        "gl_FragCoord.y = " .. utils.fmt(my, 1),
        "r = x/1024 = " .. utils.fmt(mx / 1024),
        "g = y/768  = " .. utils.fmt(my / 768),
    }
end

function M.draw()
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 0, 1024, 768)
    love.graphics.setShader()

    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(1, 1, 0, 0.8)
    love.graphics.circle("line", mx, my, 12)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("(" .. utils.fmt(mx, 0) .. ", " .. utils.fmt(my, 0) .. ")", mx + 16, my - 6)

    utils.drawTextBox(10, 40, 280, 90, liveLines)
    utils.drawFeynman(
        "Feynman: Think of the GPU as a factory with a million workers.\n" ..
        "Each worker gets one pixel and asks: what color should I be?\n" ..
        "Your shader is the answer key. Run it per pixel. That's all."
    )
end

function M.mousepressed(x, y, button) end
function M.keypressed(key) end

return M
