-- ============================================================
-- CHAPTER 1: Movement — How Things Get From A to B
-- ============================================================
-- Movement is velocity: position changes by velocity * dt.
-- But velocity itself can change — that's acceleration.
-- This chapter shows the hierarchy: position <- velocity <- accel.
--
-- INTERACTION: arrow keys accelerate the player. Watch the
-- velocity vector grow and shrink. Friction pulls it back to zero.

local utils = require("utils")
local vec2 = require("vec2")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local player = {x = 512, y = 384, vx = 0, vy = 0, w = 24, h = 24}
local ACCEL = 400
local FRICTION = 0.92
local WORLD_W = 1024
local WORLD_H = 768

function M.init()
    player = {x = 512, y = 384, vx = 0, vy = 0, w = 24, h = 24}
end

function M.update(dt)
    -- Acceleration from input
    local ax, ay = 0, 0
    if love.keyboard.isDown("right") then ax = ax + ACCEL end
    if love.keyboard.isDown("left") then ax = ax - ACCEL end
    if love.keyboard.isDown("down") then ay = ay + ACCEL end
    if love.keyboard.isDown("up") then ay = ay - ACCEL end

    -- Velocity changes by acceleration * dt
    player.vx = player.vx + ax * dt
    player.vy = player.vy + ay * dt

    -- Friction: velocity decays each frame
    player.vx = player.vx * FRICTION
    player.vy = player.vy * FRICTION

    -- Position changes by velocity * dt
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    -- Clamp to screen
    player.x = utils.clamp(player.x, 0, WORLD_W - player.w)
    player.y = utils.clamp(player.y, 0, WORLD_H - player.h)
end

function M.draw()
    utils.drawGrid()

    -- The player square
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    -- Velocity arrow from center of player
    local cx = player.x + player.w / 2
    local cy = player.y + player.h / 2
    utils.drawVector(cx, cy, player.vx, player.vy, 0.15, {1, 0.3, 0.3})

    -- Speed indicator (scalar magnitude of velocity)
    local speed = math.sqrt(player.vx * player.vx + player.vy * player.vy)

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 400, 120, "", {0, 0, 0, 0.8})
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    love.graphics.print("position  = (" .. fmt(player.x) .. ", " .. fmt(player.y) .. ")", px + 5, py + 18)
    love.graphics.print("velocity  = (" .. fmt(player.vx) .. ", " .. fmt(player.vy) .. ")", px + 5, py + 34)
    love.graphics.print("speed     = " .. fmt(speed) .. " px/s", px + 5, py + 50)
    love.graphics.print("friction  = " .. fmt(FRICTION), px + 5, py + 66)
    love.graphics.print("accel     = " .. ACCEL .. " px/s^2", px + 5, py + 82)
    love.graphics.print("dt        = " .. fmt(1/60, 4) .. " s (fixed)", px + 5, py + 98)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Movement is just math. Position += velocity * dt.", px, py + 120)
    love.graphics.print("Arrow keys accelerate. Watch the velocity vector — friction kills it.", px, py + 134)
end

function M.keypressed(key)
    -- No chapter-specific keys
end

return M
