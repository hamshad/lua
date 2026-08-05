-- ============================================================
-- MODULE: utils — shared helpers used by every chapter
--
-- Provides the fixed physics timestep, number formatting,
-- vector/text drawing, and the standard body factories
-- (ground, wall, ball). All body factories operate on the
-- global `world` object (created per-chapter in main.lua).
-- ============================================================

local utils = {}

-- Fixed timestep: 1/60 s. Deterministic, stable physics.
utils.FIXED_DT = 1 / 60

-- ============================================================
-- NUMBER FORMATTING
-- ============================================================
-- fmt(n, decimals): Format a number to fixed decimals (default 2).
--   fmt(3.14159)     → "3.14"
--   fmt(3.14159, 4)  → "3.1416"
--   fmt(42, 0)       → "42"
function utils.fmt(n, decimals)
    decimals = decimals or 2
    return string.format("%." .. decimals .. "f", n)
end

-- ============================================================
-- VECTOR ARROW DRAWING
-- ============================================================
-- drawVector(x, y, vx, vy, scale, color): Draw an arrow for a vector.
--   x, y:   tail position in pixels
--   vx, vy: vector components
--   scale:  screen-length multiplier (default 1)
--   color:  {r, g, b} in 0-1
--   Nearly-zero vectors (len < 0.5) are skipped.
function utils.drawVector(x, y, vx, vy, scale, color)
    scale = scale or 1
    local len = math.sqrt(vx * vx + vy * vy)
    if len < 0.5 then return end
    local ex = x + vx * scale
    local ey = y + vy * scale
    love.graphics.setColor(color or {1, 1, 1})
    love.graphics.line(x, y, ex, ey)
    local angle = math.atan2(vy, vx)
    local headLen = math.min(len * scale * 0.3, 10)
    love.graphics.line(ex, ey, ex - headLen * math.cos(angle - 0.4), ey - headLen * math.sin(angle - 0.4))
    love.graphics.line(ex, ey, ex - headLen * math.cos(angle + 0.4), ey - headLen * math.sin(angle + 0.4))
    love.graphics.setColor(1, 1, 1)
end

-- ============================================================
-- TEXT BOX DRAWING
-- ============================================================
-- drawTextBox(x, y, w, h, text, bgColor, textColor): Semi-transparent
--   rectangle behind text so it stays readable over the simulation.
function utils.drawTextBox(x, y, w, h, text, bgColor, textColor)
    bgColor = bgColor or {0, 0, 0, 0.7}
    textColor = textColor or {1, 1, 1}
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(textColor)
    love.graphics.print(text, x + 4, y + 2)
end

-- ============================================================
-- BODY FACTORIES
-- ============================================================

-- createGround(w, h, friction, restitution): Static floor at screen
--   bottom center (512, 720). Static = infinite mass, never moves.
function utils.createGround(w, h, friction, restitution)
    friction = friction or 0.5
    restitution = restitution or 0.3
    local body = love.physics.newBody(world, 512, 720, "static")
    local shape = love.physics.newRectangleShape(w, h)
    local fixture = love.physics.newFixture(body, shape, 1)
    fixture:setFriction(friction)
    fixture:setRestitution(restitution)
    return body, shape
end

-- createWall(x, y, w, h, friction, restitution): Static wall at a
--   custom position (x, y is the center).
function utils.createWall(x, y, w, h, friction, restitution)
    friction = friction or 0.5
    restitution = restitution or 0.3
    local body = love.physics.newBody(world, x, y, "static")
    local shape = love.physics.newRectangleShape(w, h)
    local fixture = love.physics.newFixture(body, shape, 1)
    fixture:setFriction(friction)
    fixture:setRestitution(restitution)
    return body, shape
end

-- createBall(x, y, radius, density, friction, restitution): Dynamic
--   circle that responds to gravity, forces and collisions.
--   density: mass per unit area — density=1, radius=15 ⇒
--     mass ≈ π·15² ≈ 707 kg (Box2D units).
--   restitution 0.7 ⇒ bounce height = 0.7² = 49% of drop height.
function utils.createBall(x, y, radius, density, friction, restitution)
    density = density or 1.0
    friction = friction or 0.3
    restitution = restitution or 0.5
    local body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(radius)
    local fixture = love.physics.newFixture(body, shape, density)
    fixture:setFriction(friction)
    fixture:setRestitution(restitution)
    return body, shape, radius
end

return utils
