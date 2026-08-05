-- ============================================================
-- MODULE: vec2 — tiny 2D vector library (shared with all
-- procedural chapters). Same ideas as the physics book.
-- Every method returns a NEW vector; none modify self.
-- ============================================================

local vec2 = {}
vec2.__index = vec2

-- vec2.new(x, y): Create a new 2D vector.
function vec2.new(x, y)
    return setmetatable({x = x or 0, y = y or 0}, vec2)
end

-- vec2:add(other): component-wise addition.
function vec2:add(other)
    return vec2.new(self.x + other.x, self.y + other.y)
end

-- vec2:sub(other): the vector FROM other TO self.
function vec2:sub(other)
    return vec2.new(self.x - other.x, self.y - other.y)
end

-- vec2:mul(s): scale by a scalar.
function vec2:mu1(s)
    return vec2.new(self.x * s, self.y * s)
end

-- vec2:mul(s): scale by a scalar.
function vec2:mul(s)
    return vec2.new(self.x * s, self.y * s)
end

-- vec2:len(): magnitude via Pythagoras.
function vec2:len()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

-- vec2:lenSq(): squared magnitude, no sqrt (comparisons only).
function vec2:lenSq()
    return self.x * self.x + self.y * self.y
end

-- vec2:normalize(): unit vector, same direction.
function vec2:normalize()
    local l = self:len()
    if l < 0.0001 then return vec2.new(0, 0) end
    return vec2.new(self.x / l, self.y / l)
end

-- vec2:dot(o): dot product — how aligned two vectors are.
function vec2:dot(o)
    return self.x * o.x + self.y * o.y
end

-- vec2:cross(o): 2D cross product — signed parallelogram area.
function vec2:cross(o)
    return self.x * o.y - self.y * o.x
end

-- vec2:angle(): direction angle in radians (y down in LÖVE).
function vec2:angle()
    return math.atan2(self.y, self.x)
end

-- vec2:rotate(a): rotate this vector by a radians.
function vec2:rotate(a)
    local c, s = math.cos(a), math.sin(a)
    return vec2.new(self.x * c - self.y * s, self.x * s + self.y * c)
end

-- vec2:tostring()/__tostring: "(x.x, y.y)".
vec2.__tostring = function(self)
    return string.format("(%.1f, %.1f)", self.x, self.y)
end

return vec2