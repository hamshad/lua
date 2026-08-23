-- ============================================================
-- CHAPTER 4: Time and Motion — Making Things Move
-- ============================================================
-- The most powerful uniform is time. love.timer.getTime() gives you
-- seconds since the program started. Send it to the shader, and
-- suddenly everything moves.
--
-- sin(time) oscillates between -1 and +1, period = 2π ≈ 6.28 seconds
-- cos(time) same but phase-shifted by π/2
--
-- Pattern for animation:
--   float wave = sin(time * frequency + phase);
--   float value = center + amplitude * wave;
--
-- Dummy walk-through at t = 1.0 second, frequency = 2.0:
--   sin(1.0 * 2.0) = sin(2.0) ≈ 0.909
--   y_offset = 0.5 + 0.3 * 0.909 = 0.773
--
-- KEYS: [SPACE] pause/resume  [+/-] speed up/slow down
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local liveLines = {}
local paused = false
local speed = 1.0
local elapsed = 0.0

local fragSrc = [[
    uniform float time;
    uniform float speed;
    uniform vec2 mouse;

    vec3 palette(float t) {
        vec3 a = vec3(0.5, 0.5, 0.5);
        vec3 b = vec3(0.5, 0.5, 0.5);
        vec3 c = vec3(1.0, 1.0, 1.0);
        vec3 d = vec3(0.00, 0.33, 0.67);
        return a + b * cos(6.28318 * (c * t + d));
    }

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec2 uv = pixcoord / vec2(1024.0, 768.0);

        float wave1 = sin(uv.x * 6.28 + time * speed) * 0.1;
        float wave2 = cos(uv.x * 4.0 + time * speed * 0.7) * 0.05;
        float threshold = uv.y + wave1 + wave2;

        vec3 col = palette(uv.x + time * speed * 0.1);

        float stripe = smoothstep(0.01, 0.0, abs(threshold - 0.5));
        col = mix(col * 0.3, col, stripe);

        vec2 diff = pixcoord - mouse;
        float glow = exp(-length(diff) * 0.01) * 0.5;
        col += vec3(glow);

        return vec4(col, 1.0);
    }
]]

function M.init()
    shader = love.graphics.newShader(fragSrc)
    paused = false
    speed = 1.0
    elapsed = 0.0
end

function M.update(dt)
    if not paused then
        elapsed = elapsed + dt * speed
    end
    local mx, my = love.mouse.getPosition()
    shader:send("time", elapsed)
    shader:send("speed", speed)
    shader:send("mouse", {mx, my})
    liveLines = {
        "time = " .. utils.fmt(elapsed) .. " s",
        "speed = " .. utils.fmt(speed, 1) .. "x",
        "sin(t) = " .. utils.fmt(math.sin(elapsed)),
        "cos(t) = " .. utils.fmt(math.cos(elapsed)),
    }
end

function M.draw()
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 40, 1024, 728)
    love.graphics.setShader()

    local barW = 200
    local barX = 10
    local barY = 720
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", barX, barY, barW, 20, 4, 4)
    local fill = (math.sin(elapsed) + 1) / 2
    love.graphics.setColor(0.2, 0.8, 0.4, 0.9)
    love.graphics.rectangle("fill", barX, barY, barW * fill, 20, 4, 4)
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("sin(t) = " .. utils.fmt(math.sin(elapsed), 2), barX + barW + 10, barY + 2)

    utils.drawButton(850, 50, 160, 28, "[SPACE] " .. (paused and "Play" or "Pause"), paused)
    utils.drawButton(850, 84, 160, 28, "[+/-] Speed: " .. utils.fmt(speed, 1) .. "x", false)

    utils.drawTextBox(10, 40, 280, 90, liveLines)
    utils.drawFeynman(
        "Feynman: Time is the universal knob. Every wave, every animation,\n" ..
        "every pulsing light — it's all sin(time * something + something).\n" ..
        "Change the frequency, change the speed. Change the phase, shift the beat."
    )
end

function M.keypressed(key)
    if key == "space" then
        paused = not paused
    elseif key == "=" or key == "+" then
        speed = speed + 0.25
    elseif key == "-" then
        speed = math.max(0.25, speed - 0.25)
    end
end

function M.mousepressed(x, y, button) end

return M
