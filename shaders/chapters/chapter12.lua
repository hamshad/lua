-- ============================================================
-- CHAPTER 12: Multi-Pass Rendering — Framebuffers and Ping-Pong
-- ============================================================
-- Sometimes one shader isn't enough. You need to feed the OUTPUT
-- of one shader as the INPUT to the next. This is multi-pass.
--
-- The technique: Ping-Pong rendering.
--   Pass 1: Draw scene → Canvas A (using shader 1)
--   Pass 2: Read Canvas A → Canvas B (using shader 2)
--   Pass 3: Read Canvas B → Screen (using shader 3, or just display)
--
-- Why? Because you can't read and write to the same texture at once.
-- So you alternate: A→B, then B→A, back and forth like ping-pong.
--
-- This chapter chains 3 passes:
--   Pass 1: Generate a procedural pattern (waves + noise)
--   Pass 2: Apply directional blur (horizontal + vertical)
--   Pass 3: Color grade with vignette + tint
--
-- Dummy walk-through for pass 2 blur at pixel (512, 384):
--   Read 5 taps from Canvas A: positions 510, 511, 512, 513, 514
--   Weight: [0.06, 0.24, 0.40, 0.24, 0.06] (Gaussian-ish)
--   Sum = 0.06*p[510] + 0.24*p[511] + 0.40*p[512] + ...
--
-- KEYS: [1-4] view different passes  [B] toggle blur
-- ============================================================

local M = {}
local utils = require("utils")

local shader1 = nil
local shader2 = nil
local shader3 = nil
local canvasA = nil
local canvasB = nil
local liveLines = {}
local viewMode = 1
local blurOn = true
local time = 0

local frag1 = [[
    uniform float time;
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec2 uv = pixcoord / vec2(1024.0, 768.0);

        vec3 col = vec3(0.0);

        for (int i = 0; i < 5; i++) {
            float fi = float(i);
            vec2 pos = uv + vec2(
                sin(uv.y * 8.0 + time * 2.0 + fi * 0.5) * 0.1,
                cos(uv.x * 6.0 + time * 1.5 + fi * 0.3) * 0.08
            );
            col += 0.2 * vec3(
                sin(pos.x * 12.0 + time),
                cos(pos.y * 10.0 + time * 0.7),
                sin((pos.x + pos.y) * 8.0 + time * 1.3)
            );
        }

        float n = fract(sin(dot(floor(uv * 30.0), vec2(12.9898, 78.233))) * 43758.5453);
        col += n * 0.05;

        return vec4(col, 1.0);
    }
]]

local frag2 = [[
    uniform float direction;
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec2 texel = vec2(1.0 / 1024.0, 1.0 / 768.0);
        vec4 sum = vec4(0.0);
        float weights[5];
        weights[0] = 0.227027;
        weights[1] = 0.1945946;
        weights[2] = 0.1216216;
        weights[3] = 0.054054;
        weights[4] = 0.016216;

        sum += Texel(tex, texcoord) * weights[0];
        vec2 dir = (direction > 0.5) ? vec2(texel.x, 0.0) : vec2(0.0, texel.y);
        for (int i = 1; i < 5; i++) {
            sum += Texel(tex, texcoord + dir * float(i) * 2.0) * weights[i];
            sum += Texel(tex, texcoord - dir * float(i) * 2.0) * weights[i];
        }
        return sum;
    }
]]

local frag3 = [[
    uniform float time;
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec4 pixel = Texel(tex, texcoord);
        vec2 uv = texcoord;

        pixel.rgb *= 1.1;
        pixel.r *= 1.05;
        pixel.b *= 0.95;

        float dist = length(uv - 0.5);
        float vig = 1.0 - dist * 0.8;
        pixel.rgb *= smoothstep(0.0, 0.8, vig);

        float grain = fract(sin(dot(uv * time, vec2(12.9898, 78.233))) * 43758.5453);
        pixel.rgb += (grain - 0.5) * 0.03;

        return pixel;
    }
]]

function M.init()
    shader1 = love.graphics.newShader(frag1)
    shader2 = love.graphics.newShader(frag2)
    shader3 = love.graphics.newShader(frag3)
    canvasA = love.graphics.newCanvas(1024, 768)
    canvasB = love.graphics.newCanvas(1024, 768)
    viewMode = 1
    blurOn = true
    time = 0
end

function M.update(dt)
    time = time + dt
    shader1:send("time", time)
    shader2:send("direction", 1.0)
    shader3:send("time", time)

    love.graphics.setCanvas(canvasA)
    love.graphics.clear(0, 0, 0)
    love.graphics.setShader(shader1)
    love.graphics.rectangle("fill", 0, 0, 1024, 768)
    love.graphics.setShader()
    love.graphics.setCanvas()

    if blurOn then
        shader2:send("direction", 1.0)
        love.graphics.setCanvas(canvasB)
        love.graphics.clear(0, 0, 0)
        love.graphics.setShader(shader2)
        love.graphics.draw(canvasA)
        love.graphics.setShader()
        love.graphics.setCanvas()

        shader2:send("direction", 0.0)
        love.graphics.setCanvas(canvasA)
        love.graphics.clear(0, 0, 0)
        love.graphics.setShader(shader2)
        love.graphics.draw(canvasB)
        love.graphics.setShader()
        love.graphics.setCanvas()
    end

    love.graphics.setCanvas(canvasB)
    love.graphics.clear(0, 0, 0)
    love.graphics.setShader(shader3)
    love.graphics.draw(canvasA)
    love.graphics.setShader()
    love.graphics.setCanvas()

    liveLines = {
        "Pass 1: Pattern generation (waves + noise)",
        "Pass 2: Gaussian blur " .. (blurOn and "(H+V)" or "(off)") .. " → ping-pong",
        "Pass 3: Color grade + vignette + grain",
        "View: " .. ({"Pattern", "Blur out", "Final", "All passes"})[viewMode],
    }
end

function M.draw()
    if viewMode == 1 then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(canvasA)
    elseif viewMode == 2 then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(canvasA)
    elseif viewMode == 3 then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(canvasB)
    elseif viewMode == 4 then
        local scale = 0.48
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(canvasA, 10, 45, 0, scale, scale * (768/1024) * (1024/768))
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print("Pass 1+2", 15, 420)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(canvasB, 520, 45, 0, scale, scale * (768/1024) * (1024/768))
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print("Pass 3 (final)", 525, 420)
    end

    for i = 1, 4 do
        utils.drawButton(10 + (i - 1) * 100, 50, 90, 28, "[" .. i .. "] " .. ({"Pat", "Blur", "Final", "All"})[i], i == viewMode)
    end
    utils.drawButton(420, 50, 100, 28, "[B] Blur: " .. (blurOn and "ON" or "OFF"), blurOn)

    utils.drawTextBox(10, 40, 340, 90, liveLines)
    utils.drawFeynman(
        "Feynman: Multi-pass is assembly-line manufacturing. Worker 1 shapes\n" ..
        "the metal, Worker 2 polishes it, Worker 3 paints it. Each worker\n" ..
        "sees only the previous worker's output. Ping-pong means you need\n" ..
        "two conveyor belts — you can't sand and paint on the same table."
    )
end

function M.keypressed(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= 4 then
        viewMode = num
    elseif key == "b" then
        blurOn = not blurOn
    end
end

function M.mousepressed(x, y, button) end

return M
