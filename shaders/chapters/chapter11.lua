-- ============================================================
-- CHAPTER 11: Vertex Shaders — Deforming Geometry
-- ============================================================
-- So far we've only written fragment shaders (per-pixel color).
-- Vertex shaders run per VERTEX and control WHERE each vertex goes.
--
-- LÖVE2D vertex shader signature:
--   position, color = love_main_shader(image, position)
--
-- position: vec4(x, y, z, w) — the vertex position
-- color:    vec4(r, g, b, a) — passed to fragment shader
-- image:    the texture being drawn (optional)
--
-- You return new position. The GPU interpolates between vertices
-- to fill the triangles (rasterization).
--
-- Dummy walk-through for a vertex at (100, 200):
--   position = vec4(100.0, 200.0, 0.0, 1.0)
--   New position = vec4(100.0, 200.0 + sin(100.0*0.05)*20.0, 0.0, 1.0)
--   = vec4(100.0, 200.0 + 19.18, 0.0, 1.0)
--   = vec4(100.0, 219.18, 0.0, 1.0) — vertex moved down by 19px
--
-- KEYS: [1-4] deformation modes
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local liveLines = {}
local mode = 1
local mesh = nil

local vertSrc = [[
    uniform float time;
    uniform int mode;

    vec4 position(mat4 transformProjection, vec4 vertexPosition) {
        vec2 pos = vertexPosition.xy;

        if (mode == 1) {
            pos.y += sin(pos.x * 0.03 + time * 2.0) * 30.0;
            pos.x += cos(pos.y * 0.02 + time * 1.5) * 15.0;
        }
        else if (mode == 2) {
            vec2 center = vec2(512.0, 384.0);
            vec2 d = pos - center;
            float dist = length(d);
            float angle = atan(d.y, d.x);
            float twist = dist * 0.005 * sin(time);
            angle += twist;
            pos = center + vec2(cos(angle), sin(angle)) * dist;
        }
        else if (mode == 3) {
            vec2 center = vec2(512.0, 384.0);
            vec2 d = pos - center;
            float dist = length(d);
            float wave = sin(dist * 0.02 - time * 3.0) * 20.0;
            pos += normalize(d) * wave;
        }
        else if (mode == 4) {
            vec2 center = vec2(512.0, 384.0);
            vec2 d = pos - center;
            float r = length(d);
            float a = atan(d.y, d.x);
            float pulse = 1.0 + 0.3 * sin(a * 5.0 + time * 2.0) * sin(r * 0.01 - time);
            pos = center + d * pulse;
        }

        return transformProjection * vec4(pos, vertexPosition.zw);
    }
]]

local fragSrc = [[
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        return color;
    }
]]

local labels = {"Wave", "Twist", "Ripple", "Pulse"}

function M.init()
    shader = love.graphics.newShader(vertSrc, fragSrc)
    mode = 1
    buildMesh()
end

function buildMesh()
    local step = 16
    local verts = {}
    for y = 0, 768 - step, step do
        for x = 0, 1024 - step, step do
            local u0 = x / 1024
            local v0 = y / 768
            local u1 = (x + step) / 1024
            local v1 = (y + step) / 768

            local r = 0.3 + 0.4 * u0
            local g = 0.3 + 0.4 * v0
            local b = 0.5 + 0.3 * math.sin((u0 + v0) * 3.14)

            table.insert(verts, {x, y, u0, v0, r, g, b, 1})
            table.insert(verts, {x + step, y, u1, v0, r, g, b, 1})
            table.insert(verts, {x, y + step, u0, v1, r, g, b, 1})

            table.insert(verts, {x + step, y, u1, v0, r, g, b, 1})
            table.insert(verts, {x + step, y + step, u1, v1, r, g, b, 1})
            table.insert(verts, {x, y + step, u0, v1, r, g, b, 1})
        end
    end

    local format = {
        {"VertexPosition", "float", 2},
        {"VertexTexCoord", "float", 2},
        {"VertexColor", "float", 4},
    }
    mesh = love.graphics.newMesh(format, verts, "triangles")
end

function M.update(dt)
    shader:send("time", love.timer.getTime())
    shader:send("mode", mode)
    liveLines = {
        "Mode: " .. labels[mode],
        "Vertex shader runs per VERTEX, not per pixel",
        "position() transforms vertex location",
        "GPU rasterizes between transformed vertices",
    }
end

function M.draw()
    love.graphics.setShader(shader)
    love.graphics.draw(mesh, 0, 0)
    love.graphics.setShader()

    for i = 1, 4 do
        utils.drawButton(10 + (i - 1) * 100, 50, 90, 28, "[" .. i .. "] " .. labels[i], i == mode)
    end

    utils.drawTextBox(10, 40, 340, 90, liveLines)
    utils.drawFeynman(
        "Feynman: Fragment shaders paint pixels. Vertex shaders move vertices.\n" ..
        "Think of stretching a rubber sheet — the vertex shader grabs corners\n" ..
        "and pulls them. The GPU fills in the stretched surface. Per-vertex\n" ..
        "means fewer calculations than per-pixel — that's the performance win."
    )
end

function M.keypressed(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= 4 then
        mode = num
    end
end

function M.mousepressed(x, y, button) end

return M
