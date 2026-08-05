-- ============================================================
-- CHAPTER 12: Game Feel — Anticipation, Hit-Stop, Shake
-- ============================================================
-- Animation is timing, and game feel is ANIMATING THE TIMELINE
-- ITSELF. A punch is not one motion — it is four phases:
--
--   anticipation (wind-up, 0.18s): draw the fist back, squash down
--   strike        (0.06s):        lunge, the punch moment
--   hit-stop      (0.12s):        FREEZE time — both characters
--   follow-through(0.25s):        release, recover, shake decays
--
-- Hit-stop is the magic one: the world stops for a beat on impact.
-- The freeze lets the brain SEE the hit land, and the shake that
-- follows sells the force. Games without hit-stop feel mushy.
--
-- SPACE: throw a punch   [C] toggle hit-stop to see its cost

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local phase = "idle"        -- idle / windup / strike / stop / follow
local phaseT = 0
local shake = 0             -- decaying screen shake magnitude
local hitStop = true
local punch = { x = 512, y = 430, arm = 0, fistX = 512, fistY = 430 }

local PHASES = {
    idle   = { dur = 0 },
    windup = { dur = 0.18, label = "ANTICIPATION — draw back, squash" },
    strike = { dur = 0.06, label = "STRIKE — lunge forward" },
    stop   = { dur = 0.12, label = "HIT-STOP — world frozen" },
    follow = { dur = 0.25, label = "FOLLOW-THROUGH — recover" },
}

local function nextPhase()
    if phase == "windup" then phase = "strike"
    elseif phase == "strike" then phase = "stop"
    elseif phase == "stop" then phase = "follow"
    else phase = "idle" end
    phaseT = 0
end

function M.init()
    phase = "idle"
    phaseT = 0
    shake = 0
    hitStop = true
    punch = { x = 512, y = 430, arm = 0, fistX = 512, fistY = 430 }
end

function M.update(dt)
    if phase ~= "idle" then
        phaseT = phaseT + dt
        if phaseT >= PHASES[phase].dur then
            if phase == "follow" then
                phase = "idle"
                phaseT = 0
            else
                if phase == "strike" then
                    shake = 14
                    if hitStop then
                        phase = "stop"
                        phaseT = 0
                    else
                        phase = "follow"
                        phaseT = 0
                    end
                    return
                end
                nextPhase()
            end
        end
    end

    -- Follow-through arm relaxes; shake decays.
    shake = utils.damp(shake, 0, 10, dt)
end

function M.keypressed(key)
    if key == " " and phase == "idle" then
        phase = "windup"
        phaseT = 0
    elseif key == "c" then
        hitStop = not hitStop
    end
end

function M.draw()
    -- Screen shake: offset the whole world
    local sx = (love.math.random() * 2 - 1) * shake
    local sy = (love.math.random() * 2 - 1) * shake
    love.graphics.push()
    love.graphics.translate(sx, sy)

    -- Enemy dummy (target)
    love.graphics.setColor(0.4, 0.4, 0.45)
    love.graphics.rectangle("fill", 760, 300, 90, 200)
    love.graphics.rectangle("fill", 770, 280, 70, 30)

    -- Puncher: body + arm driven by phase
    local bodyX = 420
    local bodyY = 430
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.circle("fill", bodyX, bodyY - 60, 40)

    -- Anticipation squash: sink down as we wind up
    local windup = 0
    if phase == "windup" then windup = 1 end
    local recover = 0
    if phase == "follow" then recover = 1 end
    local bodyOff = -windup * 16 + recover * 8

    -- Arm angle: windup draws back, strike lunges
    local armA = 0
    if phase == "windup" then
        armA = -2.2 * phaseT / PHASES.windup.dur
    elseif phase == "strike" or phase == "stop" then
        armA = -2.2 + 2.6   -- fully extended
    elseif phase == "follow" then
        armA = 0.4 + (1 - phaseT / PHASES.follow.dur) * 0.4
    end
    local armLen = 130
    local fx = bodyX + armLen * math.cos(armA)
    local fy = bodyY - 60 + armLen * math.sin(armA) + bodyOff

    love.graphics.setColor(0.6, 0.2, 0.2)
    love.graphics.setLineWidth(14)
    love.graphics.line(bodyX, bodyY - 40 + bodyOff, fx, fy)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.3, 0.1, 0.1)
    love.graphics.circle("fill", fx, fy, 16)

    -- Body (translate whole torso down during windup)
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.rectangle("fill", bodyX - 40, bodyY + bodyOff, 80, 140)

    love.graphics.pop()

    -- Phase timeline (top)
    love.graphics.setFont(fontSmall)
    local order = { "idle", "windup", "strike", "stop", "follow" }
    local x0 = 100
    for i, p in ipairs(order) do
        local w = i == 1 and 80 or 150
        local c = phase == p and {0.2, 0.7, 0.3} or {0.3, 0.3, 0.3}
        love.graphics.setColor(c)
        love.graphics.rectangle("fill", x0, 60, w - 6, 26)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(p, x0 + 6, 66)
        x0 = x0 + w
    end
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("phase = " .. phase .. "   t = " .. fmt(phaseT, 2) .. "/" .. fmt(PHASES[phase].dur, 2), 10, 96)

    -- Live panel
    drawTextBox(10, 120, 700, 100, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 122)
    love.graphics.print("shake = " .. fmt(shake) .. " px", 15, 138)
    love.graphics.print("hit-stop " .. (hitStop and "ON" or "OFF") .. "   [C] toggle   [SPACE] punch", 15, 154)
    love.graphics.print("total punch time = " .. fmt(0.18 + 0.06 + (hitStop and 0.12 or 0) + 0.25, 2) .. "s", 15, 170)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: the strike is the event, but anticipation is what reads as INTENT —", 10, 700)
    love.graphics.print("the body telegraphs before it acts. Hit-stop pauses the clock so the hit registers", 10, 714)
    love.graphics.print("in the eye; shake carries the force out. Turn hit-stop off and compare: the same", 10, 728)
    love.graphics.print("punch feels half as hard. Timing IS the mechanic.", 10, 742)
end

return M