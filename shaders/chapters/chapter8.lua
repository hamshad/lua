-- ============================================================
-- CHAPTER 8: Mathematical Shapes — SDFs and Distance Fields
-- ============================================================
-- A Signed Distance Function (SDF) tells you HOW FAR a point is
-- from a shape's surface. Negative inside, positive outside, zero
-- on the boundary.
--
-- Circle:  sdf = length(p - center) - radius
-- Box:     sdf = length(max(abs(p - center) - halfSize, 0.0))
-- Line:    sdf = length(p - a) - length(p - b) ... (simplified)
--
-- The magic: smoothstep(edge0, edge1, sdf) gives you antialiased edges.
--   smoothstep(0.0, 1.0, sdf) → soft boundary
--   smoothstep(0.0, 0.01, sdf) → sharp but antialiased boundary
--
-- Dummy walk-through for circle at pixel (600, 400), center=(512,384), r=50:
--   diff = (600-512, 400-384) = (88, 16)
--   sdf = length(88, 16) - 50 = 89.4 - 50 = 39.4 (outside)
--
-- MOUSE: moves the circle center
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local liveLines = {}
local shapeMode = 1

local fragSrc = [[
    uniform vec2 center;
    uniform int shapeMode;

    float sdCircle(vec2 p, vec2 c, float r) {
        return length(p - c) - r;
    }

    float sdBox(vec2 p, vec2 c, vec2 b) {
        vec2 d = abs(p - c) - b;
        return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    }

    float sdLine(vec2 p, vec2 a, vec2 b) {
        vec2 pa = p - a, ba = b - a;
        float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
        return length(pa - ba * h);
    }

    float sdTriangle(vec2 p, vec2 a, vec2 b, vec2 c) {
        vec2 e0 = b - a, e1 = c - b, e2 = a - c;
        vec2 v0 = p - a, v1 = p - b, v2 = p - c;
        vec2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
        vec2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
        vec2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
        float s = sign(e0.x * e2.y - e0.y * e2.x);
        vec2 d = min(min(vec2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)),
                         vec2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x))),
                         vec2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x)));
        return -sqrt(d.x) * sign(d.y);
    }

    float sdHexagon(vec2 p, vec2 c, float r) {
        vec2 q = abs(p - c);
        float k = sqrt(3.0);
        float d = dot(vec2(k * 0.5, 0.5), q);
        d = max(d, q.x);
        d = max(d, dot(vec2(-k * 0.5, 0.5), q));
        return d - r;
    }

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec2 uv = pixcoord;
        float sdf = 0.0;

        if (shapeMode == 1) {
            sdf = sdCircle(uv, center, 80.0);
        } else if (shapeMode == 2) {
            sdf = sdBox(uv, center, vec2(100.0, 60.0));
        } else if (shapeMode == 3) {
            vec2 a = center + vec2(-80.0, 50.0);
            vec2 b = center + vec2(0.0, -60.0);
            vec2 c = center + vec2(80.0, 50.0);
            sdf = sdTriangle(uv, a, b, c);
        } else if (shapeMode == 4) {
            sdf = sdHexagon(uv, center, 70.0);
        }

        vec3 col = vec3(0.05, 0.05, 0.12);

        vec3 inner = vec3(0.2, 0.5, 0.8);
        vec3 outer = vec3(0.1, 0.1, 0.15);
        vec3 edge = vec3(1.0, 0.8, 0.2);

        col = mix(inner, outer, smoothstep(-1.0, 1.0, sdf));
        float edgeGlow = exp(-abs(sdf) * 0.05);
        col += edge * edgeGlow * 0.6;

        float contour = abs(fract(sdf * 0.05) - 0.5) * 2.0;
        contour = smoothstep(0.95, 1.0, contour);
        col += vec3(0.3) * contour * 0.5;

        return vec4(col, 1.0);
    }
]]

local labels = {"Circle", "Box", "Triangle", "Hexagon"}

function M.init()
    shader = love.graphics.newShader(fragSrc)
    shapeMode = 1
end

function M.update(dt)
    local mx, my = love.mouse.getPosition()
    shader:send("center", {mx, my})
    shader:send("shapeMode", shapeMode)
    liveLines = {
        "Shape: " .. labels[shapeMode],
        "center = (" .. utils.fmt(mx, 0) .. ", " .. utils.fmt(my, 0) .. ")",
        "SDF: neg=inside, 0=edge, pos=outside",
        "smoothstep(0, 0.01, sdf) = antialiased edge",
    }
end

function M.draw()
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 40, 1024, 728)
    love.graphics.setShader()

    for i = 1, 4 do
        utils.drawButton(10 + (i - 1) * 100, 50, 90, 28, "[" .. i .. "] " .. labels[i], i == shapeMode)
    end

    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.circle("fill", mx, my, 3)

    utils.drawTextBox(10, 40, 320, 90, liveLines)
    utils.drawFeynman(
        "Feynman: An SDF is a topographic map. Positive = you're on a hill\n" ..
        "outside the shape. Negative = you're in a valley inside. Zero = the\n" ..
        "shoreline. smoothstep makes the shore smooth instead of jagged."
    )
end

function M.keypressed(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= 4 then
        shapeMode = num
    end
end

function M.mousepressed(x, y, button) end

return M
