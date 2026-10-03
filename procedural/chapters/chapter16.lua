-- ============================================================
-- CHAPTER 16: Projectiles — Gravity Arcs and Aiming
-- ============================================================
-- Throw anything and gravity bends it into a parabola: x flies
-- straight (no force), y falls (g pulls). The cannon previews the
-- whole arc as dots BEFORE firing — aim is just kinematics run
-- forward in time. Range R = v²·sin(2θ)/g: 45° flies farthest.
--
-- LEFT/RIGHT: angle   UP/DOWN: power   SPACE: fire   [C]: clear

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua.
local M = {}

-- G: gravity px/s². Cannon anchor, angle (rad, up-negative), power.
local G = 900
local cx, cy = 120, 640
local angle, power = -0.7, 520
-- shells: live shots {x,y,vx,vy,trail}. dead: landed marks.
local shells, dead = {}, {}

-- M.init(): reset aim and clear the range.
function M.init()
    angle, power = -0.7, 520
    shells, dead = {}, {}
end

-- fire(): spawn a shell at the muzzle with v = power·(cos,sin).
function M.keypressed(key)
    if key == " " then
        shells[#shells + 1] = {
            x = cx + 34 * math.cos(angle), y = cy + 34 * math.sin(angle),
            vx = power * math.cos(angle), vy = power * math.sin(angle),
            trail = {},
        }
    elseif key == "c" then
        shells, dead = {}, {}
    end
end

-- M.update(dt): aim keys, integrate shells, bounce off ground.
function M.update(dt)
    if love.keyboard.isDown("left") then angle = angle - 1.4 * dt end
    if love.keyboard.isDown("right") then angle = angle + 1.4 * dt end
    if love.keyboard.isDown("up") then power = math.min(900, power + 300 * dt) end
    if love.keyboard.isDown("down") then power = math.max(150, power - 300 * dt) end
    angle = utils.clamp(angle, -1.5, -0.05)

    for i = #shells, 1, -1 do
        local s = shells[i]
        -- Ballistics: x unforced, y accelerated. Euler is fine here.
        s.vy = s.vy + G * dt
        s.x, s.y = s.x + s.vx * dt, s.y + s.vy * dt
        s.trail[#s.trail + 1] = { x = s.x, y = s.y }
        if #s.trail > 60 then table.remove(s.trail, 1) end
        if s.y >= 660 then
            -- Landing: bounce once if fast, else mark crater and die.
            if math.abs(s.vy) > 220 then
                s.y = 660 s.vy = -s.vy * 0.45 s.vx = s.vx * 0.8
            else
                dead[#dead + 1] = { x = s.x }
                table.remove(shells, i)
            end
        elseif s.x > 1030 or s.x < -10 then
            table.remove(shells, i)
        end
    end
end

-- M.draw(): cannon, predicted dotted arc, shells, range panel.
function M.draw()
    utils.drawGrid()
    -- Ground strip.
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, 660, 1024, 108)

    -- Predicted arc: simulate forward, dot every 4th step.
    --   Example: power 520, θ=-40° → vx=398, vy=-334, apex ≈ 62 px up.
    local px, py = cx + 34 * math.cos(angle), cy + 34 * math.sin(angle)
    local pvx, pvy = power * math.cos(angle), power * math.sin(angle)
    love.graphics.setColor(0.4, 1, 0.4, 0.7)
    for i = 1, 120 do
        pvy = pvy + G * (1 / 30)
        px, py = px + pvx * (1 / 30), py + pvy * (1 / 30)
        if py > 660 then break end
        if i % 4 == 0 then love.graphics.circle("fill", px, py, 2.5) end
    end

    -- Landed craters.
    love.graphics.setColor(1, 0.4, 0.2, 0.8)
    for _, d in ipairs(dead) do
        love.graphics.circle("fill", d.x, 660, 5)
    end

    -- Shells + fading trails.
    for _, s in ipairs(shells) do
        for j, t in ipairs(s.trail) do
            love.graphics.setColor(1, 0.7, 0.3, j / #s.trail * 0.6)
            love.graphics.circle("fill", t.x, t.y, 3)
        end
        love.graphics.setColor(1, 0.75, 0.3)
        love.graphics.circle("fill", s.x, s.y, 7)
    end

    -- Cannon barrel rotated to aim.
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(angle)
    love.graphics.setColor(0.6, 0.6, 0.65)
    love.graphics.rectangle("fill", 0, -7, 40, 14)
    love.graphics.pop()
    love.graphics.setColor(0.8, 0.8, 0.85)
    love.graphics.circle("fill", cx, cy, 14)

    -- Theory range R = v²·sin(2θ)/g (flat ground, no bounce).
    local R = power * power * math.sin(-2 * angle) / G
    love.graphics.setColor(1, 1, 0, 0.5)
    love.graphics.line(cx + R, 640, cx + R, 680)
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 560, 1000, 92, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 562)
    love.graphics.print("angle=" .. fmt(math.deg(angle), 0) .. "deg  power=" .. fmt(power, 0)
        .. "  vx=" .. fmt(power * math.cos(angle), 0) .. "  vy=" .. fmt(power * math.sin(angle), 0), 15, 578)
    love.graphics.print("theory range R=v²·sin2θ/g = " .. fmt(R, 0) .. "px   shells=" .. #shells, 15, 594)
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: x coasts, y falls — the arc is two one-line motions multiplied. 45° goes farthest;", 10, 700)
    love.graphics.print("everything else trades height for distance. The dots are the future, computed cheaply.", 10, 714)
end

return M
