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

-- M: the module table exported to main.lua.
local M = {}

-- phase: the punch state machine's current step.
--   idle → windup → strike → stop → follow → idle.
local phase = "idle"
-- phaseT: seconds spent inside the current phase; drives progress.
--   Example: windup phaseT reaches 0.18 → strike begins.
local phaseT = 0
-- shake: the current screen-shake radius, in pixels. Spawns at 14 on
-- impact, then decays to 0 via damp(). 0 = calm screen.
local shake = 0
-- hitStop: whether the world freezes on impact (the headline feature).
--   Example: hitStop=false skips the stop phase → softer feel.
local hitStop = true
-- punch: the puncher's state — body anchor and the fist position.
--   Example: {x=512, y=430, arm=0, fistX=512, fistY=430} = fist at rest.
local punch = { x = 512, y = 430, arm = 0, fistX = 512, fistY = 430 }

-- PHASES: the timeline table. Each phase has its duration in seconds
-- and a human label. dur is what the update() loop counts against.
--   Example: strike lasts 0.06 s = 3.6 frames at 60 fps — a real lunge.
local PHASES = {
    idle   = { dur = 0 },
    windup = { dur = 0.18, label = "ANTICIPATION — draw back, squash" },
    strike = { dur = 0.06, label = "STRIKE — lunge forward" },
    stop   = { dur = 0.12, label = "HIT-STOP — world frozen" },
    follow = { dur = 0.25, label = "FOLLOW-THROUGH — recover" },
}

-- nextPhase(): advance the state machine one step. Handles the linear
-- part of the chain; hit-stop skipping is handled in update().
--   Example: "windup" → "strike"; "stop" → "follow"; else → "idle".
local function nextPhase()
    if phase == "windup" then phase = "strike"
    elseif phase == "strike" then phase = "stop"
    elseif phase == "stop" then phase = "follow"
    else phase = "idle" end
    phaseT = 0   -- restart the new phase's clock
end

-- M.init(): reset the machine, the shake, and the punch.
function M.init()
    phase = "idle"
    phaseT = 0
    shake = 0
    hitStop = true
    punch = { x = 512, y = 430, arm = 0, fistX = 512, fistY = 430 }
end

-- M.update(dt): run the phase clock. On strike landing, spawn the
-- shake and branch on hitStop; otherwise decay the shake every frame.
function M.update(dt)
    if phase ~= "idle" then
        phaseT = phaseT + dt
        if phaseT >= PHASES[phase].dur then
            if phase == "follow" then
                -- Follow-through done → back to rest.
                phase = "idle"
                phaseT = 0
            else
                if phase == "strike" then
                    -- Impact moment: kick the screen shake, then pick
                    -- the next phase. With hitStop ON we freeze the
                    -- world for a beat; OFF we jump straight to follow.
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

    -- Follow-through arm relaxes; shake decays. damp() toward 0 with
    -- λ=10: 99% of the shake is gone in ~0.46 s.
    shake = utils.damp(shake, 0, 10, dt)
end

-- M.keypressed(key): [SPACE] starts a punch (only when idle),
-- [C] toggles hit-stop so you can A/B the feel.
function M.keypressed(key)
    if key == " " and phase == "idle" then
        phase = "windup"
        phaseT = 0
    elseif key == "c" then
        hitStop = not hitStop
    end
end

-- M.draw(): shake the world, draw the enemy and the puncher's body +
-- arm (all pose math from the phase), then the timeline, panel, footer.
function M.draw()
    -- Screen shake: offset the whole world by a random jitter scaled
    -- by `shake`. Randomness = nauseatingly organic camera trauma.
    --   Example: shake=14 → the world jumps up to ±14 px each frame.
    local sx = (love.math.random() * 2 - 1) * shake
    local sy = (love.math.random() * 2 - 1) * shake
    love.graphics.push()
    love.graphics.translate(sx, sy)

    -- Enemy dummy (target): a grey slab the punch lands on.
    love.graphics.setColor(0.4, 0.4, 0.45)
    love.graphics.rectangle("fill", 760, 300, 90, 200)
    love.graphics.rectangle("fill", 770, 280, 70, 30)

    -- Puncher: body + arm driven by phase. bodyX/Y is the torso anchor.
    local bodyX = 420
    local bodyY = 430
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.circle("fill", bodyX, bodyY - 60, 40)

    -- Anticipation squash: sink down as we wind up.
    --   Example: windup=1 → body drops 16 px; follow → rises 8 px.
    local windup = 0
    if phase == "windup" then windup = 1 end
    local recover = 0
    if phase == "follow" then recover = 1 end
    local bodyOff = -windup * 16 + recover * 8

    -- Arm angle: windup draws back, strike lunges.
    --   windup: sweeps from 0 back to -2.2 rad over its duration.
    --   strike/stop: locked fully extended at -2.2 + 2.6 = 0.4 rad.
    --   follow: eases back toward rest.
    --   Example: half done with windup → armA = -2.2·0.5 = -1.1 rad.
    local armA = 0
    if phase == "windup" then
        armA = -2.2 * phaseT / PHASES.windup.dur
    elseif phase == "strike" or phase == "stop" then
        armA = -2.2 + 2.6   -- fully extended
    elseif phase == "follow" then
        armA = 0.4 + (1 - phaseT / PHASES.follow.dur) * 0.4
    end
    local armLen = 130
    -- Fist position: one arm-length from the shoulder along armA.
    local fx = bodyX + armLen * math.cos(armA)
    local fy = bodyY - 60 + armLen * math.sin(armA) + bodyOff

    -- Arm: a thick line from shoulder to fist, then the fist ball.
    love.graphics.setColor(0.6, 0.2, 0.2)
    love.graphics.setLineWidth(14)
    love.graphics.line(bodyX, bodyY - 40 + bodyOff, fx, fy)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.3, 0.1, 0.1)
    love.graphics.circle("fill", fx, fy, 16)

    -- Body (translate whole torso down during windup).
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.rectangle("fill", bodyX - 40, bodyY + bodyOff, 80, 140)

    love.graphics.pop()

    -- Phase timeline (top): a bar per phase, highlighted when active.
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

    -- Live panel: current shake and the punch's total duration.
    --   Example: hit-stop ON → 0.18+0.06+0.12+0.25 = 0.61 s total.
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