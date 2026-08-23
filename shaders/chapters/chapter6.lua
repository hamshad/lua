-- ============================================================
-- CHAPTER 6: Coordinate Systems — Screen, Normalized, and UV
-- ============================================================
-- There are THREE coordinate systems you'll work with:
--
-- 1. Screen space: pixels, (0,0) top-left, (1024,768) bottom-right
--    This is pixcoord. Used for pixel-perfect effects.
--
-- 2. Normalized Device Coordinates (NDC): (-1,-1) to (1,1)
--    Center is (0,0). Used for vertex shaders and math.
--    Convert: ndc = (pixcoord / screenResolution) * 2.0 - 1.0
--
-- 3. UV space: (0,0) to (1,1), bottom-left to top-right
--    This is texcoord. Used for texture lookups.
--    Convert from screen: uv = pixcoord / screenResolution
--
-- Dummy walk-through at pixel (512, 384):
--   Screen: (512, 384)
--   UV:     (512/1024, 384/768) = (0.5, 0.5) — center
--   NDC:    (0.5*2-1, 0.5*2-1) = (0.0, 0.0) — also center
--
-- KEYS: [1-3] switch coordinate system visualization
-- MOUSE: see all three coordinate values live
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local liveLines = {}
local mode = 1

local fragSrc = [[
    uniform int mode;

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec2 screen = pixcoord;
        vec2 uv = pixcoord / vec2(1024.0, 768.0);
        vec2 ndc = uv * 2.0 - 1.0;

        vec3 col = vec3(0.05, 0.05, 0.12);

        if (mode == 1) {
            float gx = fract(pixcoord.x / 128.0);
            float gy = fract(pixcoord.y / 128.0);
            float grid = smoothstep(0.02, 0.0, min(gx, gy));
            col += vec3(grid * 0.3);

            float majorX = fract(pixcoord.x / 512.0);
            float majorY = fract(pixcoord.y / 384.0);
            float majorGrid = smoothstep(0.01, 0.0, min(majorX, majorY));
            col += vec3(majorGrid * 0.5);

            col += vec3(0.3, 0.0, 0.0) * (1.0 - uv.y);
            col += vec3(0.0, 0.0, 0.3) * (1.0 - uv.x);
        }
        else if (mode == 2) {
            float gx = fract(uv.x * 10.0);
            float gy = fract(uv.y * 7.5);
            float grid = smoothstep(0.02, 0.0, min(gx, gy));
            col += vec3(grid * 0.4);

            col += vec3(0.0, 0.4, 0.0) * (1.0 - uv.y);
            col += vec3(0.0, 0.0, 0.4) * uv.y;

            float center = length(uv - 0.5);
            col += vec3(0.3, 0.3, 0.0) * (1.0 - smoothstep(0.01, 0.02, center - 0.3));
        }
        else if (mode == 3) {
            float gx = fract((ndc.x + 1.0) * 5.0);
            float gy = fract((ndc.y + 1.0) * 3.75);
            float grid = smoothstep(0.02, 0.0, min(gx, gy));
            col += vec3(grid * 0.4);

            col += vec3(0.4, 0.0, 0.0) * max(0.0, -ndc.x);
            col += vec3(0.0, 0.4, 0.0) * max(0.0, ndc.x);
            col += vec3(0.0, 0.0, 0.4) * max(0.0, ndc.y);

            float axisX = smoothstep(0.005, 0.0, abs(ndc.y));
            float axisY = smoothstep(0.005, 0.0, abs(ndc.x));
            col += vec3(1.0, 1.0, 0.0) * (axisX + axisY) * 0.6;
        }

        return vec4(col, 1.0);
    }
]]

local labels = {"Screen (px)", "UV (0-1)", "NDC (-1 to 1)"}

function M.init()
    shader = love.graphics.newShader(fragSrc)
    mode = 1
end

function M.update(dt)
    shader:send("mode", mode)
    local mx, my = love.mouse.getPosition()
    local uv_x = mx / 1024
    local uv_y = my / 768
    local ndc_x = uv_x * 2 - 1
    local ndc_y = uv_y * 2 - 1
    liveLines = {
        "Screen: (" .. utils.fmt(mx, 0) .. ", " .. utils.fmt(my, 0) .. ") px",
        "UV:     (" .. utils.fmt(uv_x) .. ", " .. utils.fmt(uv_y) .. ")",
        "NDC:    (" .. utils.fmt(ndc_x) .. ", " .. utils.fmt(ndc_y) .. ")",
        "Mode: " .. labels[mode],
    }
end

function M.draw()
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 40, 1024, 728)
    love.graphics.setShader()

    local mx, my = love.mouse.getPosition()
    local uv_x = mx / 1024
    local uv_y = my / 768
    local ndc_x = uv_x * 2 - 1
    local ndc_y = uv_y * 2 - 1

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setFont(fontSmall)
    local panelX = 600
    local panelY = 50
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", panelX, panelY, 400, 80, 6, 6)
    love.graphics.setColor(1, 0.5, 0.5, 1)
    love.graphics.print("Screen: " .. utils.fmt(mx, 0) .. ", " .. utils.fmt(my, 0) .. " px", panelX + 10, panelY + 8)
    love.graphics.setColor(0.5, 1, 0.5, 1)
    love.graphics.print("UV:     " .. utils.fmt(uv_x) .. ", " .. utils.fmt(uv_y), panelX + 10, panelY + 28)
    love.graphics.setColor(0.5, 0.5, 1, 1)
    love.graphics.print("NDC:    " .. utils.fmt(ndc_x) .. ", " .. utils.fmt(ndc_y), panelX + 10, panelY + 48)

    for i = 1, 3 do
        utils.drawButton(10 + (i - 1) * 140, 50, 130, 28, "[" .. i .. "] " .. labels[i], i == mode)
    end

    utils.drawTextBox(10, 40, 350, 90, liveLines)
    utils.drawFeynman(
        "Feynman: Three names for the same point. Screen is inches on a ruler.\n" ..
        "UV is a fraction of the way across. NDC is distance from center,\n" ..
        "where left is -1 and right is +1. Same point, different languages."
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
