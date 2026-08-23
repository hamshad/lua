-- ============================================================
-- CHAPTER 13: Raymarching — 3D Worlds in a Fragment Shader
-- ============================================================
-- Raymarching renders 3D scenes entirely in a fragment shader.
-- No mesh data, no vertex shader — just math and distance fields.
--
-- The algorithm (per pixel):
--   1. Cast a ray from the camera through the pixel
--   2. Step along the ray until you hit something
--   3. Calculate lighting at the hit point
--
-- Sphere tracing: at each step, move forward by the SDF distance.
--   pos += rayDir * sdf(pos);
--   If sdf < 0.001 → you hit something
--   If steps > maxSteps → you missed (sky color)
--
-- Dummy walk-through for one step at ray position (0, 0, 5):
--   sdf(position) = length(0,0,5) - 1.0 = 4.0 (sphere at origin, r=1)
--   Step forward 4.0 units → new position (0, 0, 1.0)
--   sdf(0,0,1) = 0.0 → HIT! Normal = normalize(pos) = (0,0,1)
--
-- KEYS: [SPACE] rotate  [R] reset camera  [+/-] zoom
-- MOUSE: look around
-- ============================================================

local M = {}
local utils = require("utils")

local shader = nil
local liveLines = {}
local camAngle = 0.0
local camPitch = 0.0
local zoom = 3.0

local fragSrc = [[
    uniform float time;
    uniform vec2 mouse;
    uniform float zoom;

    mat3 rotateY(float a) {
        float c = cos(a), s = sin(a);
        return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
    }

    mat3 rotateX(float a) {
        float c = cos(a), s = sin(a);
        return mat3(1, 0, 0, 0, c, -s, 0, s, c);
    }

    float sdSphere(vec3 p, float r) {
        return length(p) - r;
    }

    float sdBox(vec3 p, vec3 b) {
        vec3 d = abs(p) - b;
        return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
    }

    float sdPlane(vec3 p, float h) {
        return p.y - h;
    }

    float opUnion(float d1, float d2) {
        return min(d1, d2);
    }

    float opSmoothUnion(float d1, float d2, float k) {
        float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
        return mix(d2, d1, h) - k * h * (1.0 - h);
    }

    float scene(vec3 p) {
        float sphere1 = sdSphere(p - vec3(sin(time) * 2.0, 0.5, 0.0), 0.8);
        float sphere2 = sdSphere(p - vec3(0.0, sin(time * 1.3) * 1.5, cos(time * 0.7) * 2.0), 0.6);
        float box1 = sdBox(p - vec3(2.0, 0.0, 2.0), vec3(0.5));
        float ground = sdPlane(p, -1.0);

        float objects = opSmoothUnion(sphere1, opUnion(sphere2, box1), 0.5);
        return opUnion(objects, ground);
    }

    vec3 getNormal(vec3 p) {
        vec2 e = vec2(0.001, 0.0);
        return normalize(vec3(
            scene(p + e.xyy) - scene(p - e.xyy),
            scene(p + e.yxy) - scene(p - e.yxy),
            scene(p + e.yyx) - scene(p - e.yyx)
        ));
    }

    float softShadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
        float res = 1.0;
        float t = mint;
        for (int i = 0; i < 32; i++) {
            float h = scene(ro + rd * t);
            if (h < 0.001) return 0.0;
            res = min(res, k * h / t);
            t += h;
            if (t > maxt) break;
        }
        return res;
    }

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec2 uv = (pixcoord - vec2(512.0, 384.0)) / 768.0;

        vec3 ro = vec3(0.0, 2.0, -zoom);
        ro = rotateY(mouse.x * 0.005) * rotateX(mouse.y * 0.005) * ro;
        vec3 rd = normalize(vec3(uv, 1.5));

        vec3 col = vec3(0.4, 0.6, 0.9);

        float t = 0.0;
        bool hit = false;
        for (int i = 0; i < 100; i++) {
            vec3 p = ro + rd * t;
            float d = scene(p);
            if (d < 0.001) {
                hit = true;
                break;
            }
            t += d;
            if (t > 50.0) break;
        }

        if (hit) {
            vec3 p = ro + rd * t;
            vec3 n = getNormal(p);

            vec3 lightDir = normalize(vec3(0.8, 1.0, -0.6));
            float diff = max(dot(n, lightDir), 0.0);
            float shadow = softShadow(p + n * 0.01, lightDir, 0.02, 10.0, 8.0);

            vec3 matCol = vec3(0.8, 0.3, 0.2);
            if (p.y > -0.95) {
                matCol = vec3(0.3, 0.6, 0.8);
                float checker = mod(floor(p.x) + floor(p.z), 2.0);
                matCol = mix(matCol, vec3(0.5), checker * 0.3);
            }

            col = matCol * (diff * shadow + 0.15);

            vec3 hal = normalize(lightDir - rd);
            float spe = pow(max(dot(n, hal), 0.0), 32.0);
            col += vec3(1.0, 0.9, 0.7) * spe * shadow * 0.5;

            float fres = pow(1.0 - max(dot(n, -rd), 0.0), 3.0);
            col += vec3(0.3, 0.5, 0.8) * fres * 0.3;
        }

        col = pow(col, vec3(0.4545));

        return vec4(col, 1.0);
    }
]]

function M.init()
    shader = love.graphics.newShader(fragSrc)
    camAngle = 0
    camPitch = 0
    zoom = 3.0
end

function M.update(dt)
    local mx, my = love.mouse.getPosition()
    shader:send("time", love.timer.getTime())
    shader:send("mouse", {mx - 512, my - 384})
    shader:send("zoom", zoom)

    local dist = 0
    local step = 0
    local hitDist = zoom
    local ro = {0, 2, -zoom}
    local rd = {0, 0, 1}

    liveLines = {
        "Camera: orbiting at " .. utils.fmt(zoom, 1) .. " units",
        "Ray: origin→pixel, step by SDF distance",
        "100 max steps, hit threshold = 0.001",
        "Smooth union blends sphere shapes",
    }
end

function M.draw()
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 0, 1024, 768)
    love.graphics.setShader()

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 750, 440, 260, 60, 6, 6)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setFont(fontSmall)
    love.graphics.print("Hold mouse + drag to orbit", 760, 448)
    love.graphics.print("[+/-] Zoom  [R] Reset", 760, 468)

    utils.drawTextBox(10, 40, 340, 90, liveLines)
    utils.drawFeynman(
        "Feynman: Raymarching is echolocation. You shout a ray and ask:\n" ..
        "\"How far is the nearest wall?\" Move that far. Ask again. Repeat\n" ..
        "until you're touching something. The SDF tells you the distance.\n" ..
        "No geometry needed — just math describing shapes in space."
    )
end

function M.keypressed(key)
    if key == "space" then
    elseif key == "r" then
        zoom = 3.0
    elseif key == "=" or key == "+" then
        zoom = math.max(1.0, zoom - 0.5)
    elseif key == "-" then
        zoom = math.min(8.0, zoom + 0.5)
    end
end

function M.mousepressed(x, y, button) end

return M
