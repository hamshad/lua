-- ============================================================
-- CHAPTER 2: Input — Talking to the Machine
-- ============================================================
-- Every game needs to read the player's intentions. LÖVE2D
-- gives us callbacks (keypressed, mousepressed) and polling
-- (love.keyboard.isDown). This chapter shows both approaches
-- and why timing matters.
--
-- INTERACTION: click to spawn a bullet that fires toward the
-- mouse position. Press 1/2 to switch input modes.

local utils = require("utils")
local vec2 = require("vec2")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local player = {x = 512, y = 500, w = 30, h = 30}
local bullets = {}
local mode = 1 -- 1 = polling, 2 = event
local cooldown = 0
local COOLDOWN_TIME = 0.15

function M.init()
    player = {x = 512, y = 500, w = 30, h = 30}
    bullets = {}
    cooldown = 0
    mode = 1
end

function M.update(dt)
    -- Polling mode: check every frame
    if mode == 1 then
        local speed = 250
        if love.keyboard.isDown("left") then player.x = player.x - speed * dt end
        if love.keyboard.isDown("right") then player.x = player.x + speed * dt end
        if love.keyboard.isDown("up") then player.y = player.y - speed * dt end
        if love.keyboard.isDown("down") then player.y = player.y + speed * dt end

        -- Auto-fire while mouse held (polling the mouse state)
        if love.mouse.isDown(1) and cooldown <= 0 then
            fireBullet()
            cooldown = COOLDOWN_TIME
        end
    end

    -- Cooldown ticks down in both modes
    if cooldown > 0 then cooldown = cooldown - dt end

    -- Update bullets
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.y < -10 or b.x < -10 or b.x > 1034 then
            table.remove(bullets, i)
        end
    end

    -- Clamp player
    player.x = utils.clamp(player.x, 0, 1024 - player.w)
    player.y = utils.clamp(player.y, 0, 768 - player.h)
end

function fireBullet()
    local mx, my = love.mouse.getPosition()
    local cx = player.x + player.w / 2
    local cy = player.y
    local dx, dy = mx - cx, my - cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then len = 1 end
    local speed = 400
    table.insert(bullets, {
        x = cx, y = cy,
        vx = dx / len * speed,
        vy = dy / len * speed,
        r = 3,
    })
end

function M.mousepressed(x, y, button)
    if button == 1 and mode == 2 and cooldown <= 0 then
        fireBullet()
        cooldown = COOLDOWN_TIME
    end
end

function M.keypressed(key)
    if key == "1" then mode = 1 end
    if key == "2" then mode = 2 end
end

function M.draw()
    utils.drawGrid()

    -- Player
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    -- Crosshair at mouse
    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(1, 1, 0)
    love.graphics.line(mx - 10, my, mx + 10, my)
    love.graphics.line(mx, my - 10, mx, my + 10)

    -- Bullets
    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 0.4, 0.2)
        love.graphics.circle("fill", b.x, b.y, b.r)
    end

    -- Aim line (dashed)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineStyle("rough")
    love.graphics.line(player.x + player.w / 2, player.y, mx, my)
    love.graphics.setLineStyle("smooth")

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 420, 110, "", {0, 0, 0, 0.8})
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    love.graphics.print("mode      = " .. (mode == 1 and "POLLING (hold key/mouse)" or "EVENT (press/click)"), px + 5, py + 18)
    love.graphics.print("bullets   = " .. #bullets, px + 5, py + 34)
    love.graphics.print("cooldown  = " .. fmt(cooldown, 3) .. " s", px + 5, py + 50)
    love.graphics.print("mouse     = (" .. fmt(mx) .. ", " .. fmt(my) .. ")", px + 5, py + 66)
    love.graphics.print("[1] polling  [2] event-based  fire toward mouse", px + 5, py + 82)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Polling asks 'is it down NOW?', events say 'it JUST happened'.", px, py + 104)
    love.graphics.print("Both are needed. Movement = polling. Shooting = events.", px, py + 118)
end

return M
