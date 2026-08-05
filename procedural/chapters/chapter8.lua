-- ============================================================
-- CHAPTER 8: Chains and Forward Kinematics
-- ============================================================
-- A limb, a tail, a rope: a CHAIN of segments. Forward kinematics
-- (FK) means we drive the chain from the ROOT: each segment's pose
-- is decided, and its children just follow. Cheap, predictable,
-- perfect for swaying tails, waving tentacles, and marching arms.
--
-- Each joint angle = sine with a PHASE OFFSET from its parent:
--   angle[i] = A * sin(t * speed + i * offset)
-- The offset is what turns a column of sines into a travelling wave.
--
-- [1] sway (all segments in sync)   [2] wave (phase travels)
-- LEFT/RIGHT: change amplitude      UP/DOWN: change speed

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local N = 12
local SEG = 34          -- segment length px
local root = { x = 512, y = 120 }
local mode = "wave"     -- "sway" or "wave"
local A = 0.6           -- max joint angle (rad)
local speed = 2.0

-- joint positions computed each update
local joints = {}

local function compute()
    joints = {}
    local angle = 0
    local x, y = root.x, root.y
    table.insert(joints, {x = x, y = y, a = 0})
    for i = 1, N do
        local t = tClock
        local phase = mode == "wave" and (i - 1) * 0.55 or 0
        local da = A * math.sin(t * speed + phase)
        angle = angle + da
        x = x + SEG * math.cos(angle)
        y = y + SEG * math.sin(angle)
        table.insert(joints, {x = x, y = y, a = angle})
    end
end

function M.init()
    mode = "wave"
    A = 0.6
    speed = 2.0
    tClock = 0
end

function M.update(dt)
    tClock = tClock + dt
    local oldTip = joints[N + 1] and {x = joints[N + 1].x, y = joints[N + 1].y} or {x = root.x, y = root.y}
    compute()
    local newTip = joints[N + 1]
    tipVelX = (newTip.x - oldTip.x) / dt
    tipVelY = (newTip.y - oldTip.y) / dt
end

function M.keypressed(key)
    if key == "1" then mode = "sway" end
    if key == "2" then mode = "wave" end
    if key == "right" then A = math.min(1.4, A + 0.05) end
    if key == "left" then A = math.max(0.05, A - 0.05) end
    if key == "up" then speed = math.min(8, speed + 0.2) end
    if key == "down" then speed = math.max(0.2, speed - 0.2) end
end

function M.draw()
    utils.drawGrid()

    -- Chain
    for i = 2, #joints do
        local p = joints[i - 1]
        local j = joints[i]
        love.graphics.setColor(0.85, 0.85, 0.85)
        love.graphics.setLineWidth(4)
        love.graphics.line(p.x, p.y, j.x, j.y)
        love.graphics.setLineWidth(1)
    end
    for i = 2, #joints do
        local j = joints[i]
        love.graphics.setColor(0.4, 0.5, 0.9)
        love.graphics.circle("fill", j.x, j.y, 6)
    end
    -- Root
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", root.x, root.y, 10)

    -- Phase dots: same sine, different offsets (why a wave forms)
    love.graphics.setColor(0.6, 0.2, 0.2)
    love.graphics.print("mode: " .. mode .. "  [1]=sway  [2]=wave", 10, 100)
    love.graphics.print("A=" .. fmt(A, 2) .. "  speed=" .. fmt(speed, 2) .. " rad/s", 10, 116)

    -- Live panel
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 600, 1000, 90, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 602)
    love.graphics.print("joints: " .. N .. "   tail tip: (" .. fmt(joints[N + 1].x) .. ", " .. fmt(joints[N + 1].y) .. ")", 15, 618)
    love.graphics.print("tip velocity (px/s): (" .. fmt(tipVelX) .. ", " .. fmt(tipVelY) .. ")", 15, 634)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: FK is a marching order — the root swings, each child adds its own sin.", 10, 700)
    love.graphics.print("Add a phase offset down the chain and the column of sines becomes a travelling", 10, 714)
    love.graphics.print("wave, like a snake or a waving flag. No collision, no solving: just time per joint.", 10, 728)
end

-- module-level state
local tipVelX, tipVelY = 0, 0
local tClock = 0

return M