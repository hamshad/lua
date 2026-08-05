-- ============================================================
-- MODULE: vec2 — tiny 2D vector library (built for Chapter 1)
--
-- A vector stores a magnitude and a direction. In games we use
-- them for positions, velocities, accelerations and forces.
-- Every method returns a NEW vector; none modify self.
-- ============================================================

local vec2 = {}
vec2.__index = vec2

-- vec2.new(x, y): Create a new 2D vector.
--   Example: vec2.new(3, 4) → {x=3, y=4}
--     magnitude = sqrt(3² + 4²) = 5
--     angle     = atan2(4, 3) ≈ 53.1° from the x-axis
function vec2.new(x, y)
    return setmetatable({x = x or 0, y = y or 0}, vec2)
end

-- vec2:add(other): Add two vectors component-wise.
--   Example: (2,3) + (4,1) = (6,4). self is unchanged.
function vec2:add(other)
    return vec2.new(self.x + other.x, self.y + other.y)
end

-- vec2:sub(other): Subtract other from self.
--   Example: (5,7) - (2,3) = (3,4).
--   Gives the vector FROM other TO self (direction + distance).
function vec2:sub(other)
    return vec2.new(self.x - other.x, self.y - other.y)
end

-- vec2:mul(s): Scale both components by a scalar.
--   Example: (3,4) * 2 = (6,8); * 0.5 shrinks; * -1 reverses.
--   Multiplying velocity by dt gives displacement for one frame.
function vec2:mul(s)
    return vec2.new(self.x * s, self.y * s)
end

-- vec2:len(): Magnitude via Pythagoras: |v| = sqrt(vx² + vy²).
--   Example: (3,4):len() = sqrt(9+16) = 5.
function vec2:len()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

-- vec2:lenSq(): Squared magnitude, no sqrt().
--   Use for comparisons only: 25 > 16 ⟺ len > 4, but faster.
function vec2:lenSq()
    return self.x * self.x + self.y * self.y
end

-- vec2:normalize(): Unit vector (length 1), same direction.
--   Example: (3,4):normalize() = (0.6, 0.8), and 0.36+0.64 = 1.0.
--   The zero check avoids dividing by zero.
function vec2:normalize()
    local l = self:len()
    if l < 0.0001 then return vec2.new(0, 0) end
    return vec2.new(self.x / l, self.y / l)
end

-- vec2:dot(other): Dot product — a scalar.
--   Formula: a·b = ax*bx + ay*by = |a|*|b|*cos(θ)
--   Example: (2,3)·(4,1) = 8+3 = 11.
--   Sign tells you the angle between them:
--     > 0 → θ < 90°  (same general direction)
--     = 0 → θ = 90°  (perpendicular)
--     < 0 → θ > 90°  (opposite general direction)
--   Used for "is this in front of me?" and projections.
function vec2:dot(other)
    return self.x * other.x + self.y * other.y
end

-- vec2:cross(other): 2D cross product — a scalar.
--   Formula: a×b = ax*by - ay*bx
--   Example: (2,3)×(4,1) = 2*1 - 3*4 = 2 - 12 = -10.
--   Sign tells you turn direction:
--     > 0 → b is counter-clockwise from a
--     = 0 → parallel
--     < 0 → b is clockwise from a
--   Essential for polygon collision (SAT) side checks.
function vec2:cross(other)
    return self.x * other.y - self.y * other.x
end

-- vec2:angle(): Direction angle in radians from +x axis.
--   Example: (1,1):angle() = atan2(1,1) = π/4 ≈ 0.785 rad ≈ 45°.
--   Note: in LÖVE, +y is DOWN, so (0,1) is 90° (straight down).
--   Used to rotate sprites to face their movement direction.
function vec2:angle()
    return math.atan2(self.y, self.x)
end

-- vec2:rotate(angle): Rotate this vector by angle (radians).
--   Formula: x' = x·cosθ - y·sinθ,  y' = x·sinθ + y·cosθ
function vec2:rotate(angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    return vec2.new(self.x * c - self.y * s, self.x * s + self.y * c)
end

-- vec2:tostring(): Human-readable "(x.x, y.y)" for the live panels.
function vec2:tostring()
    return string.format("(%.1f, %.1f)", self.x, self.y)
end

return vec2
