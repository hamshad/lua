-- ============================================================
-- MODULE: utils — shared helpers for the game mechanics chapters
--
-- fmt            — usable number formatting for live panels
-- clamp, lerp    — the primitive unit of game math
-- damp           — frame-rate-independent exponential smoothing
-- ease*          — easing curves applied to a normalized t (0..1)
-- drawVector     — arrowhead renderer
-- drawTextBox    — soft background panel behind text
-- drawGrid       — faint reference lines
-- Collision      — AABB and circle helpers
-- ============================================================

local utils = {}

-- FIXED_DT: the constant simulation timestep, in seconds.
utils.FIXED_DT = 1 / 60

-- ============================================================
-- MATH PRIMITIVES
-- ============================================================

-- clamp(v, lo, hi): keep v inside the inclusive range [lo, hi].
function utils.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- lerp(a, b, t): linear interpolation — blend from a to b by t.
function utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- damp(current, target, lambda, dt): frame-rate-independent
-- exponential smoothing. lambda ~ 8 = sleepy, ~20 = responsive.
function utils.damp(current, target, lambda, dt)
    return current + (target - current) * (1 - math.exp(-lambda * dt))
end

-- ============================================================
-- EASING
-- ============================================================

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
-- COLLISION HELPERS
-- ============================================================

-- aabbOverlap(ax, ay, aw, ah, bx, by, bw, bh): true if two
-- axis-aligned bounding boxes overlap. Each box is defined by
-- its top-left corner (x, y) and dimensions (w, h).
--   Example: aabbOverlap(0,0,10,10, 5,5,10,10) → true (overlap at 5,5)
--            aabbOverlap(0,0,10,10, 20,20,5,5) → false (apart)
function utils.aabbOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx
       and ay < by + bh and ay + ah > by
end

-- circleOverlap(ax, ay, ar, bx, by, br): true if two circles
-- overlap. Distance between centers < sum of radii → overlap.
--   Example: circleOverlap(0,0,5, 3,0,5) → true (dist=3 < 10)
--            circleOverlap(0,0,5, 20,0,5) → false (dist=20 > 10)
function utils.circleOverlap(ax, ay, ar, bx, by, br)
    local dx, dy = ax - bx, ay - br
    -- Correct: distance between centers
    dx, dy = ax - bx, ay - by
    local distSq = dx * dx + dy * dy
    local rSum = ar + br
    return distSq < rSum * rSum
end

-- pointInRect(px, py, rx, ry, rw, rh): true if point (px,py)
-- is inside the rectangle (rx, ry, rw, rh).
function utils.pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw
       and py >= ry and py <= ry + rh
end

-- pointInCircle(px, py, cx, cy, r): true if point is within
-- radius r of center (cx, cy).
function utils.pointInCircle(px, py, cx, cy, r)
    local dx, dy = px - cx, py - cy
    return dx * dx + dy * dy <= r * r
end

-- ============================================================
-- ENTITY HELPERS
-- ============================================================

-- createEntity(x, y, w, h, opts): build a generic game entity
-- with position, size, velocity, hp, alive flag, and optional
-- tags. The foundation for players, enemies, projectiles, etc.
--   opts: {speed=, hp=, color=, tag=, accel=, maxSpeed=}
function utils.createEntity(x, y, w, h, opts)
    opts = opts or {}
    return {
        x = x, y = y, w = w, h = h,
        vx = 0, vy = 0,
        speed = opts.speed or 200,
        hp = opts.hp or 1,
        maxHp = opts.hp or 1,
        alive = true,
        color = opts.color or {1, 1, 1},
        tag = opts.tag or "default",
        accel = opts.accel or 800,
        maxSpeed = opts.maxSpeed or 300,
        -- Center coordinates (computed each frame)
        cx = function(self) return self.x + self.w / 2 end,
        cy = function(self) return self.y + self.h / 2 end,
    }
end

-- ============================================================
-- DRAWING HELPERS
-- ============================================================

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

function utils.drawTextBox(x, y, w, h, text, bgColor, textColor)
    bgColor = bgColor or {0, 0, 0, 0.7}
    textColor = textColor or {1, 1, 1}
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(textColor)
    love.graphics.print(text, x + 4, y + 2)
end

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

-- drawBar(x, y, w, h, ratio, fgColor, bgColor): horizontal bar.
-- ratio is 0..1 (current / max). Used for HP bars, cooldowns, etc.
function utils.drawBar(x, y, w, h, ratio, fgColor, bgColor)
    ratio = utils.clamp(ratio, 0, 1)
    bgColor = bgColor or {0.2, 0.2, 0.2}
    fgColor = fgColor or {0.2, 0.8, 0.2}
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(fgColor)
    love.graphics.rectangle("fill", x, y, w * ratio, h)
    love.graphics.setColor(1, 1, 1)
end

return utils
