-- ============================================================
-- CHAPTER 3: Uniforms — Talking to the Shader from Lua
-- ============================================================
-- A uniform is a variable you send FROM your Lua code TO the shader.
-- "Uniform" means: every pixel gets the SAME value.
-- Unlike pixcoord (which changes per pixel), a uniform is... uniform.
--
-- In Lua:  shader:send("uniformName", value)
-- In GLSL: uniform float uniformName;
--
-- Types you can send:
--   float:  shader:send("speed", 3.14)
--   vec2:   shader:send("mouse", {mx, my})
--   vec3:   shader:send("color", {1.0, 0.0, 0.0})
--   vec4:   shader:send("color", {1.0, 0.0, 0.0, 1.0})
--   int:    shader:send("mode", 2)
--   Image:  shader:send("tex", myTexture)
--
-- Dummy walk-through:
--   Lua sends:  shader:send("mouse", {512.0, 384.0})
--   GLSL gets:  uniform vec2 mouse;  → mouse = vec2(512.0, 384.0)
--
-- MOUSE: position sent as uniform "mouse"
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local liveLines = {}
local pointLight = false

local fragSrc = [[
    uniform vec2 mouse;
    uniform float radius;

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec2 diff = pixcoord - mouse;
        float dist = length(diff);
        float glow = smoothstep(radius, 0.0, dist);
        vec3 warm = mix(vec3(0.05, 0.05, 0.12), vec3(1.0, 0.6, 0.1), glow);
        return vec4(warm, 1.0);
    }
]]

function M.init()
    shader = love.graphics.newShader(fragSrc)
    pointLight = false
end

function M.update(dt)
    local mx, my = love.mouse.getPosition()
    shader:send("mouse", {mx, my})
    shader:send("radius", pointLight and 200.0 or 120.0)
    liveLines = {
        "uniform vec2 mouse = (" .. utils.fmt(mx, 0) .. ", " .. utils.fmt(my, 0) .. ")",
        "uniform float radius = " .. utils.fmt(pointLight and 200.0 or 120.0, 0),
        "shader:send(\"mouse\", {mx, my})",
        "distance = length(pixcoord - mouse)",
    }
end

function M.draw()
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 40, 1024, 728)
    love.graphics.setShader()

    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.circle("line", mx, my, 8)
    love.graphics.setColor(1, 0.8, 0.3, 0.4)
    love.graphics.circle("line", mx, my, pointLight and 200 or 120)

    utils.drawButton(800, 50, 200, 28, "[SPACE] Toggle radius", pointLight)

    utils.drawTextBox(10, 40, 340, 90, liveLines)
    utils.drawFeynman(
        "Feynman: A uniform is like telling every worker the same rumor.\n" ..
        "\"Hey, the mouse is at (512, 384).\" Every pixel hears it.\n" ..
        "But pixcoord is different for each worker — that's their own address."
    )
end

function M.keypressed(key)
    if key == "space" then
        pointLight = not pointLight
    end
end

function M.mousepressed(x, y, button) end

return M
