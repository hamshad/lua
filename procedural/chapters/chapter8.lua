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

-- M: the module table exported to main.lua.
local M = {}

-- N: how many segments (links) hang from the root.
--   Example: N=12 → the chain has 12 moving joints plus the root.
local N = 12
-- SEG: the length of one segment, in pixels.
--   Example: the full chain reaches ~12·34 = 408 px down.
local SEG = 34
-- root: the fixed anchor the whole chain hangs from, in pixels.
local root = { x = 512, y = 120 }
-- mode: the current motion style.
--   "sway" → every joint swings in sync (offset 0).
--   "wave" → phase grows down the chain (a travelling wave).
local mode = "wave"
-- A: the maximum swing of each joint angle, in radians.
--   Example: A=0.6 → each joint bends up to 0.6 rad ≈ 34°.
local A = 0.6
-- speed: how fast the sine advances, in radians of phase per second.
--   Example: speed=2 → one full sine cycle every 2π/2 ≈ 3.1 s.
local speed = 2.0

-- joints: the computed chain positions, recomputed every update.
-- joints[1] is the root; joints[i+1] follows joints[i]. Each entry
-- is {x, y, a} where `a` is the cumulative absolute angle.
--   Example: joints[3] = {x=512, y=188, a=0.35}.
local joints = {}

-- compute(): walk the chain from the root, adding each joint's sine
-- bend to the running angle and propagating position forward.
-- This is the FK march: parent → child, no solving, O(N).
local function compute()
    joints = {}
    local angle = 0      -- cumulative absolute angle (rad)
    local x, y = root.x, root.y
    table.insert(joints, {x = x, y = y, a = 0})   -- the fixed root
    for i = 1, N do
        local t = tClock
        -- phase: the offset that differentiates sway from wave.
        --   sway: 0 (all joints identical).
        --   wave: 0.55 rad per joint (peak travels down the chain).
        local phase = mode == "wave" and (i - 1) * 0.55 or 0
        -- da: this joint's bend this instant.
        --   Example: i=3, t=1, A=0.6, speed=2, wave:
        --            da = 0.6·sin(2 + 1.1) = 0.6·sin(3.1) ≈ 0.6·0.041 ≈ 0.02.
        local da = A * math.sin(t * speed + phase)
        angle = angle + da
        -- Propagate: child sits one SEG beyond parent along `angle`.
        --   Example: angle=0.5, SEG=34 → x += 34·cos(0.5) ≈ 29.8,
        --            y += 34·sin(0.5) ≈ 16.3.
        x = x + SEG * math.cos(angle)
        y = y + SEG * math.sin(angle)
        table.insert(joints, {x = x, y = y, a = angle})
    end
end

-- M.init(): reset the chain to its default wave, amplitude, and speed.
function M.init()
    mode = "wave"
    A = 0.6
    speed = 2.0
    tClock = 0
end

-- M.update(dt): advance the clock, rebuild the chain, and track how
-- fast the tail tip is moving (for the live readout).
function M.update(dt)
    tClock = tClock + dt
    -- oldTip: the tip position from the previous frame.
    local oldTip = joints[N + 1] and {x = joints[N + 1].x, y = joints[N + 1].y} or {x = root.x, y = root.y}
    compute()   -- rebuild all joint positions at the new clock time
    local newTip = joints[N + 1]
    -- tip velocity = displacement this step / step time.
    --   Example: tip moved 12 px in 1/60 s → 720 px/s.
    tipVelX = (newTip.x - oldTip.x) / dt
    tipVelY = (newTip.y - oldTip.y) / dt
end

-- M.keypressed(key): [1]/[2] pick the mode, arrows tune the dials.
function M.keypressed(key)
    if key == "1" then mode = "sway" end
    if key == "2" then mode = "wave" end
    if key == "right" then A = math.min(1.4, A + 0.05) end   -- bigger bends
    if key == "left" then A = math.max(0.05, A - 0.05) end   -- gentler bends
    if key == "up" then speed = math.min(8, speed + 0.2) end -- faster
    if key == "down" then speed = math.max(0.2, speed - 0.2) end -- slower
end

-- M.draw(): render the grid, the chain links and joints, the root,
-- the mode/parameter readouts, and the live panel.
function M.draw()
    utils.drawGrid()

    -- Chain: one thick line segment per joint pair (i-1 → i).
    for i = 2, #joints do
        local p = joints[i - 1]
        local j = joints[i]
        love.graphics.setColor(0.85, 0.85, 0.85)
        love.graphics.setLineWidth(4)
        love.graphics.line(p.x, p.y, j.x, j.y)
        love.graphics.setLineWidth(1)
    end
    -- Joints: a dot at each moving joint.
    for i = 2, #joints do
        local j = joints[i]
        love.graphics.setColor(0.4, 0.5, 0.9)
        love.graphics.circle("fill", j.x, j.y, 6)
    end
    -- Root: the white anchor at the top.
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", root.x, root.y, 10)

    -- Mode + parameter readout.
    love.graphics.setColor(0.6, 0.2, 0.2)
    love.graphics.print("mode: " .. mode .. "  [1]=sway  [2]=wave", 10, 100)
    love.graphics.print("A=" .. fmt(A, 2) .. "  speed=" .. fmt(speed, 2) .. " rad/s", 10, 116)

    -- Live panel: chain count, tip position, tip velocity.
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

-- module-level state (declared after the functions that use them;
-- Lua resolves these as upvalues when compute()/update() run):
-- tipVelX/Y: the tail tip's velocity from the last update, px/s.
local tipVelX, tipVelY = 0, 0
-- tClock: the chapter clock in seconds, driven by M.update.
local tClock = 0

return M