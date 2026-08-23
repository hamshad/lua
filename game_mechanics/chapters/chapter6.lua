-- ============================================================
-- CHAPTER 6: State Machines — The Brain of the Game
-- ============================================================
-- Every entity in a game can be in one of several states, and
-- transitions between states follow rules. A finite state machine
-- (FSM) is just a current state + a transition table.
--
-- INTERACTION: click to move the enemy. Watch it transition
-- between IDLE, CHASE, and FLEE states based on player distance.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local player = {x = 200, y = 384, w = 24, h = 24}
local enemy = {
    x = 700, y = 384, w = 28, h = 28,
    state = "IDLE",
    speed = 120,
    timer = 0,
    patrolDir = 1,
}
local stateHistory = {}
local STATE_COLORS = {
    IDLE  = {0.4, 0.4, 0.4},
    CHASE = {1, 0.3, 0.2},
    FLEE  = {0.2, 0.8, 0.3},
}

function dist(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

function transition(newState)
    if enemy.state ~= newState then
        table.insert(stateHistory, 1, enemy.state .. " -> " .. newState)
        if #stateHistory > 6 then table.remove(stateHistory) end
        enemy.state = newState
    end
end

function M.init()
    player = {x = 200, y = 384, w = 24, h = 24}
    enemy = {
        x = 700, y = 384, w = 28, h = 28,
        state = "IDLE", speed = 120, timer = 0, patrolDir = 1,
    }
    stateHistory = {}
end

function M.update(dt)
    -- Player movement
    if love.keyboard.isDown("left") then player.x = player.x - 180 * dt end
    if love.keyboard.isDown("right") then player.x = player.x + 180 * dt end
    if love.keyboard.isDown("up") then player.y = player.y - 180 * dt end
    if love.keyboard.isDown("down") then player.y = player.y + 180 * dt end
    player.x = utils.clamp(player.x, 0, 1024 - player.w)
    player.y = utils.clamp(player.y, 0, 768 - player.h)

    -- Compute distance to player
    local d = dist(
        enemy.x + enemy.w / 2, enemy.y + enemy.h / 2,
        player.x + player.w / 2, player.y + player.h / 2
    )

    -- STATE TRANSITIONS (the rules)
    if d < 120 then
        transition("FLEE")
    elseif d < 300 then
        transition("CHASE")
    else
        transition("IDLE")
    end

    -- STATE BEHAVIORS (what each state does)
    if enemy.state == "IDLE" then
        -- Patrol: walk back and forth
        enemy.timer = enemy.timer + dt
        enemy.x = enemy.x + enemy.patrolDir * 40 * dt
        if enemy.x > 800 or enemy.x < 200 then
            enemy.patrolDir = -enemy.patrolDir
        end

    elseif enemy.state == "CHASE" then
        -- Move toward player
        local ecx = enemy.x + enemy.w / 2
        local ecy = enemy.y + enemy.h / 2
        local pcx = player.x + player.w / 2
        local pcy = player.y + player.h / 2
        local dx, dy = pcx - ecx, pcy - ecy
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            enemy.x = enemy.x + (dx / len) * enemy.speed * dt
            enemy.y = enemy.y + (dy / len) * enemy.speed * dt
        end

    elseif enemy.state == "FLEE" then
        -- Move away from player
        local ecx = enemy.x + enemy.w / 2
        local ecy = enemy.y + enemy.h / 2
        local pcx = player.x + player.w / 2
        local pcy = player.y + player.h / 2
        local dx = ecx - pcx
        local dy = ecy - pcy
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            enemy.x = enemy.x + (dx / len) * enemy.speed * 1.5 * dt
            enemy.y = enemy.y + (dy / len) * enemy.speed * 1.5 * dt
        end
    end

    enemy.x = utils.clamp(enemy.x, 0, 1024 - enemy.w)
    enemy.y = utils.clamp(enemy.y, 0, 768 - enemy.h)
end

function M.draw()
    utils.drawGrid()

    -- Distance rings
    love.graphics.setColor(0.15, 0.15, 0.15)
    local ecx = enemy.x + enemy.w / 2
    local ecy = enemy.y + enemy.h / 2
    love.graphics.circle("line", ecx, ecy, 120)
    love.graphics.circle("line", ecx, ecy, 300)

    -- Player
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    love.graphics.print("PLAYER", player.x - 5, player.y - 14)

    -- Enemy with state color
    local col = STATE_COLORS[enemy.state]
    love.graphics.setColor(col)
    love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.w, enemy.h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(enemy.state, enemy.x - 5, enemy.y - 14)

    -- Connection line
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.setLineStyle("rough")
    love.graphics.line(ecx, ecy, player.x + player.w / 2, player.y + player.h / 2)
    love.graphics.setLineStyle("smooth")

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 400, 120, "", {0, 0, 0, 0.8})
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    local d = dist(ecx, ecy, player.x + player.w / 2, player.y + player.h / 2)
    love.graphics.print("distance    = " .. fmt(d) .. " px", px + 5, py + 18)
    love.graphics.print("state       = " .. enemy.state, px + 5, py + 34)
    love.graphics.print("CHASE if d < 300, FLEE if d < 120", px + 5, py + 50)
    love.graphics.print("", px + 5, py + 66)

    -- State history
    love.graphics.print("TRANSITIONS:", px + 5, py + 82)
    for i, h in ipairs(stateHistory) do
        love.graphics.setColor(0.7, 0.9, 0.7)
        love.graphics.print("  " .. h, px + 5, py + 82 + i * 14)
    end

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: A state machine is just: current_state + if/then rules.", px, py + 120)
    love.graphics.print("Three states. Three behaviors. One switch. That's all AI needs.", px, py + 134)
end

return M
