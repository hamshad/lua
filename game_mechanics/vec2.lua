-- ============================================================
-- MODULE: vec2 — tiny 2D vector library
--
-- A vector stores a magnitude and a direction. In games we use
-- them for positions, velocities, accelerations and forces.
-- Every method returns a NEW vector; none modify self.
-- ============================================================

local vec2 = {}
vec2.__index = vec2

-- vec2.new(x, y): Create a new 2D vector.
--   Example: vec2.new(3, 4) → {x=3, y=4}
function vec2.new(x, y)
    return setmetatable({x = x or 0, y = y or 0}, vec2)
end

-- vec2:add(other): Add two vectors component-wise.
function vec2:add(other)
    return vec2.new(self.x + other.x, self.y + other.y)
end

-- vec2:sub(other): Subtract other from self.
function vec2:sub(other)
    return vec2.new(self.x - other.x, self.y - other.y)
end

-- vec2:mul(s): Scale both components by a scalar.
function vec2:mul(s)
    return vec2.new(self.x * s, self.y * s)
end

-- vec2:len(): Magnitude via Pythagoras: |v| = sqrt(vx^2 + vy^2).
function vec2:len()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

-- vec2:lenSq(): Squared magnitude, no sqrt(). Use for comparisons only.
function vec2:lenSq()
    return self.x * self.x + self.y * self.y
end

-- vec2:normalize(): Unit vector (length 1), same direction.
function vec2:normalize()
    local l = self:len()
    if l < 0.0001 then return vec2.new(0, 0) end
    return vec2.new(self.x / l, self.y / l)
end

-- vec2:dot(other): Dot product — a scalar.
function vec2:dot(other)
    return self.x * other.x + self.y * other.y
end

-- vec2:cross(other): 2D cross product — a scalar.
function vec2:cross(other)
    return self.x * other.y - self.y * other.x
end

-- vec2:angle(): Direction angle in radians from +x axis.
function vec2:angle()
    return math.atan2(self.y, self.x)
end

-- vec2:rotate(angle): Rotate this vector by angle (radians).
function vec2:rotate(angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    return vec2.new(self.x * c - self.y * s, self.x * s + self.y * c)
end

-- vec2:dist(other): Euclidean distance between two points.
function vec2:dist(other)
    local dx = self.x - other.x
    local dy = self.y - other.y
    return math.sqrt(dx * dx + dy * dy)
end

-- vec2:tostring(): Human-readable "(x.x, y.y)" for the live panels.
function vec2:tostring()
    return string.format("(%.1f, %.1f)", self.x, self.y)
end

return vec2
