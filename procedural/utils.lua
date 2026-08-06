-- ============================================================
-- MODULE: utils — shared helpers for the procedural chapters
--
-- fmt            — usable number formatting for live panels
-- clamp, lerp    — the primitive unit of procedural math
-- damp           — frame-rate-independent exponential smoothing
-- ease*          — easing curves applied to a normalized t (0..1)
-- drawVector     — arrowhead renderer (shared by chapters)
-- drawTextBox    — soft background panel behind text
-- drawGrid       — faint reference lines
-- ============================================================

-- The single exported table. Chapters do `local utils = require("utils")`
-- then call `utils.clamp(...)`, `utils.damp(...)`, etc.
local utils = {}

-- FIXED_DT: the constant simulation timestep, in seconds.
-- Procedural motion, like physics, steps at a constant rate so it
-- is deterministic regardless of frame rate.
--   Example: 60 FPS → 60 steps/sec → each step advances 1/60 s.
utils.FIXED_DT = 1 / 60

-- ============================================================
-- MATH PRIMITIVES
-- ============================================================

-- clamp(v, lo, hi): keep v inside the inclusive range [lo, hi].
-- Used everywhere to keep values in legal territory (angles in a
-- cone, positions on screen, scales above zero).
--   Example: clamp(1.5, 0, 1)  = 1   (1.5 exceeds hi → clamp to 1)
--            clamp(-2, 0, 1)   = 0   (-2 below lo  → clamp to 0)
--            clamp(0.5, 0, 1)  = 0.5 (inside range → unchanged)
function utils.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- lerp(a, b, t): linear interpolation — blend from a to b by t.
-- t=0 returns a exactly, t=1 returns b exactly, t=0.5 is halfway.
--   Example: lerp(10, 20, 0.5) = 10 + (20-10)*0.5 = 10 + 5 = 15
--            lerp(10, 20, 1.0) = 10 + (20-10)*1.0 = 20
--            lerp(10, 20, 0.0) = 10 + (20-10)*0.0 = 10
function utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- damp(current, target, lambda, dt): the heart of procedural
-- animation. current chases target exponentially; lambda is the
-- chase rate in 1/seconds (higher = faster). Using the factor
-- `1 - exp(-lambda*dt)` makes the result INDEPENDENT of frame
-- rate: the same lambda gives the same motion at 30fps and 600fps.
-- Critically damped: it approaches but never overshoots.
--
--   Example: current=0, target=100, lambda=20, dt=1/60.
--     1 - exp(-20/60) = 1 - exp(-0.333) = 1 - 0.7165 = 0.2835
--     return = 0 + (100-0)*0.2835 = 28.35   (jumped 28% of the gap)
--   lambda ~ 8  → sleepy, laggy, rubbery (tails, weight)
--   lambda ~ 20 → responsive, gamey (aim-assist, camera)
--   lambda ~ 60 → snappy, nearly instant (recoil returns)
function utils.damp(current, target, lambda, dt)
    return current + (target - current) * (1 - math.exp(-lambda * dt))
end

-- ============================================================
-- EASING
-- ============================================================

-- Easing curves take a normalized t (0..1) and reshape it so a
-- motion starts/ends gently. Each returns the reshaped t, still in
-- [0,1] (except easeOutBack which overshoots past 1).
-- "out" eases the END (fast start, gentle stop — the default),
-- "in" eases the START (slow launch, crashing finish),
-- "inout" eases both ends.

-- easeLinear(t): identity — no reshaping. t comes out as-is.
--   Example: easeLinear(0.7) = 0.7
function utils.easeLinear(t) return t end

-- easeOutQuad(t): quick start, decelerates to a gentle stop.
--   Example: t=0.5 → 1 - (0.5)² = 1 - 0.25 = 0.75
--            (at half-time the motion is already 75% done)
function utils.easeOutQuad(t)
    return 1 - (1 - t) * (1 - t)
end

-- easeInQuad(t): starts slow, accelerates to a crashing finish.
--   Example: t=0.5 → 0.5² = 0.25
--            (at half-time only 25% done — still crawling)
function utils.easeInQuad(t)
    return t * t
end

-- easeInOutQuad(t): slow start AND slow end, fastest mid-trip.
--   Example: t=0.25 → 2·(0.25)² = 0.125
--            t=0.75 → 1 - (-2·0.75+2)²/2 = 1 - (0.5)²/2 = 1-0.125 = 0.875
function utils.easeInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - (-2 * t + 2)^2 / 2
    end
end

-- easeOutCubic(t): stronger version of easeOut — even quicker start,
-- softer landing.
--   Example: t=0.5 → 1 - (0.5)³ = 1 - 0.125 = 0.875 (87.5% done)
function utils.easeOutCubic(t)
    return 1 - (1 - t)^3
end

-- easeInOutCubic(t): the classic "smoothstep" — symmetric gentle
-- start and end.
--   Example: t=0.25 → 4·(0.25)³ = 0.0625
--            t=0.75 → 1 - (-2·0.75+2)³/2 = 1 - (0.5)³/2 = 1-0.0625 = 0.9375
function utils.easeInOutCubic(t)
    if t < 0.5 then
        return 4 * t^3
    else
        return 1 - (-2 * t + 2)^3 / 2
    end
end

-- easeOutBack(t): rushes forward, OVERSHOOTS past 1, then settles
-- back to 1. The overshoot reads as "arrived with energy" — the
-- classic UI pop-in bounce.
--   Example: t=0.9 → c3=2.70158, c1=1.70158
--            1 + 2.70158·(-0.1)³ + 1.70158·(-0.1)²
--            = 1 + 2.70158·(-0.001) + 1.70158·(0.01)
--            = 1 - 0.00270 + 0.01702 = 1.0143  (4% past the end)
function utils.easeOutBack(t)
    local c1, c3 = 1.70158, 2.70158
    return 1 + c3 * (t - 1)^3 + c1 * (t - 1)^2
end

-- ============================================================
-- NUMBER FORMATTING
-- ============================================================

-- fmt(n, decimals): format a number to a fixed number of decimal
-- places, for the live-values panels.
--   Example: fmt(3.14159)      = "3.14"   (default 2 decimals)
--            fmt(3.14159, 4)   = "3.1416"
--            fmt(42, 0)        = "42"
function utils.fmt(n, decimals)
    decimals = decimals or 2
    return string.format("%." .. decimals .. "f", n)
end

-- ============================================================
-- DRAWING HELPERS
-- ============================================================

-- drawVector(x, y, vx, vy, scale, color): draw an arrow for a
-- vector at position (x, y) with components (vx, vy), magnified by
-- `scale` for visibility. Nearly-zero vectors are skipped so the
-- screen doesn't fill with dots.
--   Example: drawVector(512, 384, 100, 0, 0.5, {1,1,0})
--            → an arrow starting at (512,384) ending at (512+50, 384)
function utils.drawVector(x, y, vx, vy, scale, color)
    scale = scale or 1
    -- len: the vector's magnitude |v| = sqrt(vx² + vy²).
    --   Example: vx=3, vy=4 → len = sqrt(9+16) = 5
    local len = math.sqrt(vx * vx + vy * vy)
    -- Skip invisible (near-zero) vectors.
    if len < 0.5 then return end
    -- (ex, ey): the arrowhead tip = tail + (v * scale).
    --   Example: x=512, vx=100, scale=0.5 → ex = 512+50 = 562
    local ex, ey = x + vx * scale, y + vy * scale
    love.graphics.setColor(color or {1, 1, 1})
    -- The shaft.
    love.graphics.line(x, y, ex, ey)
    -- a: direction angle of the vector. hl: arrowhead length,
    -- capped at 10 px so short vectors still get a visible head.
    local a = math.atan2(vy, vx)
    local hl = math.min(len * scale * 0.3, 10)
    -- Two head strokes, ±0.4 rad around the direction angle.
    love.graphics.line(ex, ey, ex - hl * math.cos(a - 0.4), ey - hl * math.sin(a - 0.4))
    love.graphics.line(ex, ey, ex - hl * math.cos(a + 0.4), ey - hl * math.sin(a + 0.4))
    love.graphics.setColor(1, 1, 1)
end

-- drawTextBox(x, y, w, h, text, bgColor, textColor): draw a
-- semi-transparent rectangle behind text so the live panels stay
-- readable over the moving scene.
--   Example: drawTextBox(10, 400, 420, 96, "", {0,0,0,0.8})
--            → a black 80%-opaque box at (10,400) size 420x96
function utils.drawTextBox(x, y, w, h, text, bgColor, textColor)
    bgColor = bgColor or {0, 0, 0, 0.7}
    textColor = textColor or {1, 1, 1}
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(textColor)
    love.graphics.print(text, x + 4, y + 2)
end

-- drawGrid(): draw a faint reference grid every 32 px across the
-- whole 1024x768 screen. Gives the eye a frame of reference for
-- distances and motion.
--   Example: a ball moving from (0,400) to (100,400) visibly crosses
--            just over 3 grid squares → ~96 px of travel.
function utils.drawGrid()
    love.graphics.setColor(0.08, 0.08, 0.08)
    -- Vertical lines: x = 0, 32, 64, ..., 1024.
    for x = 0, 1024, 32 do
        love.graphics.line(x, 0, x, 768)
    end
    -- Horizontal lines: y = 0, 32, 64, ..., 768.
    for y = 0, 768, 32 do
        love.graphics.line(0, y, 1024, y)
    end
    love.graphics.setColor(1, 1, 1)
end

return utils