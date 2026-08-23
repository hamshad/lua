-- ============================================================
-- CHAPTER 7: Cameras — Your Window Into the World
-- ============================================================
-- When the game world is bigger than the screen, you need a
-- camera. A camera is just an offset: world coords - camera
-- position = screen coordinates.
--
-- INTERACTION: arrow keys move the player. Camera follows.
-- Press C to toggle camera modes: FOLLOW, LOOK-AHEAD, SHAKE.

local utils = require("utils")
local vec2 = require("vec2")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local WORLD_W = 2048
local WORLD_H = 1536
local player = {x = 1024, y = 768, w = 24, h = 24, speed = 250, vx = 0, vy = 0}
local camera = {x = 0, y = 0, mode = "FOLLOW", shakeTimer = 0, shakeIntensity = 0}
local stars = {}
local gems = {}

function M.init()
    player = {x = 1024, y = 768, w = 24, h = 24, speed = 250, vx = 0, vy = 0}
    camera = {x = 0, y = 0, mode = "FOLLOW", shakeTimer = 0, shakeIntensity = 0}
    stars = {}
    gems = {}
    math.randomseed(42)
    for i = 1, 60 do
        table.insert(stars, {
            x = math.random(0, WORLD_W),
            y = math.random(0, WORLD_H),
            r = math.random(1, 3),
        })
    end
    for i = 1, 20 do
        table.insert(gems, {
            x = math.random(50, WORLD_W - 50),
            y = math.random(50, WORLD_H - 50),
            r = 8,
            color = {math.random(), math.random(), math.random()},
        })
    end
end

function M.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("left") then dx = dx - 1 end
    if love.keyboard.isDown("right") then dx = dx + 1 end
    if love.keyboard.isDown("up") then dy = dy - 1 end
    if love.keyboard.isDown("down") then dy = dy + 1 end
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        player.vx = (dx / len) * player.speed
        player.vy = (dy / len) * player.speed
    else
        player.vx = 0
        player.vy = 0
    end
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
    player.x = utils.clamp(player.x, 0, WORLD_W - player.w)
    player.y = utils.clamp(player.y, 0, WORLD_H - player.h)

    local targetX = player.x + player.w / 2 - 512
    local targetY = player.y + player.h / 2 - 384

    if camera.mode == "FOLLOW" then
        camera.x = targetX
        camera.y = targetY

    elseif camera.mode == "LOOK_AHEAD" then
        local lookAhead = 100
        camera.x = utils.damp(camera.x, targetX + player.vx * lookAhead / player.speed, 5, dt)
        camera.y = utils.damp(camera.y, targetY + player.vy * lookAhead / player.speed, 5, dt)

    elseif camera.mode == "SHAKE" then
        camera.x = targetX
        camera.y = targetY
        if camera.shakeTimer > 0 then
            camera.shakeTimer = camera.shakeTimer - dt
            local shake = camera.shakeIntensity * (camera.shakeTimer / 0.3)
            camera.x = camera.x + (math.random() - 0.5) * shake
            camera.y = camera.y + (math.random() - 0.5) * shake
        end
    end

    camera.x = utils.clamp(camera.x, 0, WORLD_W - 1024)
    camera.y = utils.clamp(camera.y, 0, WORLD_H - 768)
end

function M.keypressed(key)
    if key == "c" then
        local modes = {"FOLLOW", "LOOK_AHEAD", "SHAKE"}
        for i, m in ipairs(modes) do
            if m == camera.mode then
                camera.mode = modes[(i % #modes) + 1]
                break
            end
        end
        if camera.mode == "SHAKE" then
            camera.shakeTimer = 0.3
            camera.shakeIntensity = 20
        end
    end
end

function M.draw()
    -- Draw in world space (offset by camera)
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- Background stars
    for _, s in ipairs(stars) do
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    -- Gems
    for _, g in ipairs(gems) do
        love.graphics.setColor(g.color)
        love.graphics.circle("fill", g.x, g.y, g.r)
    end

    -- World boundary
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", 0, 0, WORLD_W, WORLD_H)

    -- Player
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    love.graphics.pop()

    -- HUD (screen space)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.print("MODE: " .. camera.mode .. "  [C] to toggle", 10, 700)

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 400, 100, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    love.graphics.print("player = (" .. fmt(player.x) .. ", " .. fmt(player.y) .. ")", px + 5, py + 18)
    love.graphics.print("camera = (" .. fmt(camera.x) .. ", " .. fmt(camera.y) .. ")", px + 5, py + 34)
    love.graphics.print("screen = world - camera offset", px + 5, py + 50)
    love.graphics.print("world  = " .. WORLD_W .. "x" .. WORLD_H, px + 5, py + 66)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: A camera is subtraction. screen_pos = world_pos - camera.pos.", px, py + 90)
    love.graphics.print("The world stays still; the camera moves. That offset is your viewport.", px, py + 104)
end

return M
