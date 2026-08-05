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

local utils = {}

-- Fixed timestep. Procedural motion, like physics, steps at a
-- constant rate so it is deterministic regardless of frame rate.
utils.FIXED_DT = 1 / 60

-- ============================================================
-- MATH PRIMITIVES
-- ============================================================

-- clamp(v, lo, hi): keep v inside [lo, hi].
function utils.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- lerp(a, b, t): blend between a and b. t=0 → a, t=1 → b.
function utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- damp(current, target, lambda, dt): the heart of procedural
-- animation. current chases target exponentially; the rate is
-- `lambda` (higher = faster). Using 1 - exp(-lambda*dt) makes the
-- result INDEPENDENT of frame rate: the same lambda gives the same
-- motion at 30fps and 600fps. Critically-damped: no overshoot.
--
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
-- motion starts/ends gently. Each returns the reshaped t.
-- linear is identity. "out" eases the END of the motion,
-- "in" eases the start, "inout" eases both.
-- (see utils.ease below; these are standalone for reuse)

function utils.easeLinear(t) return t end

function utils.easeOutQuad(t)
    return 1 - (1 - t) * (1 - t)
end

function utils.easeInQuad(t)
    return t * t
end

function utils.easeInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - (-2 * t + 2)^2 / 2
    end
end

function utils.easeOutCubic(t)
    return 1 - (1 - t)^3
end

function utils.easeInOutCubic(t)
    if t < 0.5 then
        return 4 * t^3
    else
        return 1 - (-2 * t + 2)^3 / 2
    end
end

function utils.easeOutBack(t)
    local c1, c3 = 1.70158, 2.70158
    return 1 + c3 * (t - 1)^3 + c1 * (t - 1)^2
end

-- ============================================================
-- NUMBER FORMATTING
-- ============================================================
function utils.fmt(n, decimals)
    decimals = decimals or 2
    return string.format("%." .. decimals .. "f", n)
end

-- ============================================================
-- DRAWING HELPERS
-- ============================================================

-- drawVector(x, y, vx, vy, scale, color): arrow for a vector.
function utils.drawVector(x, y, vx, vy, scale, color)
    scale = scale or 1
    local len = math.sqrt(vx * vx + vy * vy)
    if len < 0.5 then return end
    local ex, ey = x + vx * scale, y + vy * scale
    love.graphics.setColor(color or {1, 1, 1})
    love.graphics.line(x, y, ex, ey)
    local a = math.atan2(vy, vx)
    local hl = math.min(len * scale * 0.3, 10)
    love.graphics.line(ex, ey, ex - hl * math.cos(a - 0.4), ey - hl * math.sin(a - 0.4))
    love.graphics.line(ex, ey, ex - hl * math.cos(a + 0.4), ey - hl * math.sin(a + 0.4))
    love.graphics.setColor(1, 1, 1)
end

-- drawTextBox(x, y, w, h, text, bg, fg): semi-transparent panel.
function utils.drawTextBox(x, y, w, h, text, bgColor, textColor)
    bgColor = bgColor or {0, 0, 0, 0.7}
    textColor = textColor or {1, 1, 1}
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(textColor)
    love.graphics.print(text, x + 4, y + 2)
end

-- drawGrid(): faint reference lines across the whole screen.
function utils.drawGrid()
    love.graphics.setColor(0.08, 0.08, 0.08)
    for x = 0, 1024, 32 do
        love.graphics.line(x, 0, x, 768)
    end
    for y = 0, 768, 32 do
        love.graphics.line(0, y, 1024, y)
    end
    love.graphics.setColor(1, 1, 1)
end

return utils