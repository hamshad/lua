-- ============================================================
-- MODULE: vec2 — tiny 2D vector library (shared with all
-- procedural chapters). Same ideas as the physics book.
--
-- A vector holds two components: vec.x (horizontal) and vec.y
-- (vertical). Every method returns a NEW vector; none modify self,
-- so `a:add(b)` leaves `a` unchanged and hands you a fresh one.
--
--   Example: local v = vec2.new(3, 4)
--            v.x == 3, v.y == 4, v:len() == 5, v:angle() ≈ 53°
-- ============================================================

local vec2 = {}
-- __index = vec2 lets vector instances find methods on the vec2
-- table, so `v:len()` works even though v is a plain table.
vec2.__index = vec2

-- vec2.new(x, y): create a new 2D vector. Missing components
-- default to 0.
--   Example: vec2.new(3, 4)  → {x=3, y=4}
--            vec2.new()      → {x=0, y=0}
function vec2.new(x, y)
    return setmetatable({x = x or 0, y = y or 0}, vec2)
end

-- vec2:add(other): component-wise addition — add other's x to
-- self's x, other's y to self's y.
--   Example: (2,3):add(4,1) = (2+4, 3+1) = (6, 4)
function vec2:add(other)
    return vec2.new(self.x + other.x, self.y + other.y)
end

-- vec2:sub(other): the vector FROM other TO self (self minus other).
--   Example: (5,7):sub(2,3) = (5-2, 7-3) = (3, 4)
--            → a vector pointing from (2,3) to (5,7)
function vec2:sub(other)
    return vec2.new(self.x - other.x, self.y - other.y)
end

-- vec2:mul(s): scale both components by a scalar s.
--   Example: (3,4):mul(2)   = (6, 8)   (doubled)
--            (3,4):mul(0.5) = (1.5, 2) (halved)
--            (3,4):mul(-1)  = (-3,-4)  (reversed)
function vec2:mul(s)
    return vec2.new(self.x * s, self.y * s)
end

-- vec2:len(): magnitude via Pythagoras — the length |v|.
--   Example: (3,4):len() = sqrt(9 + 16) = sqrt(25) = 5
function vec2:len()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

-- vec2:lenSq(): squared magnitude, skipping the sqrt. Only use for
-- comparisons (lenSq(a) > lenSq(b) ⟺ len(a) > len(b)) — it's faster.
--   Example: (3,4):lenSq() = 9 + 16 = 25  (len would be 5)
function vec2:lenSq()
    return self.x * self.x + self.y * self.y
end

-- vec2:normalize(): the unit vector — same direction, length 1.
-- The zero-vector guard prevents dividing by zero.
--   Example: (3,4):normalize() = (3/5, 4/5) = (0.6, 0.8)
--            and 0.6² + 0.8² = 0.36 + 0.64 = 1.0  (length exactly 1)
function vec2:normalize()
    local l = self:len()
    if l < 0.0001 then return vec2.new(0, 0) end
    return vec2.new(self.x / l, self.y / l)
end

-- vec2:dot(o): dot product — a scalar measuring how aligned two
-- vectors are: a·b = |a||b|cos(θ). Positive = same general
-- direction, zero = perpendicular, negative = opposite.
--   Example: (2,3):dot(4,1) = 2·4 + 3·1 = 8 + 3 = 11
--            (1,0):dot(0,1) = 0           (perpendicular → 0)
function vec2:dot(o)
    return self.x * o.x + self.y * o.y
end

-- vec2:cross(o): 2D cross product — the signed area of the
-- parallelogram spanned by self and o. Sign = turn direction.
--   Example: (2,3):cross(4,1) = 2·1 - 3·4 = 2 - 12 = -10
--            → o is clockwise from self (negative sign)
function vec2:cross(o)
    return self.x * o.y - self.y * o.x
end

-- vec2:angle(): the direction angle in radians from the +x axis.
-- In LÖVE, +y is DOWN, so (0,1) points straight down = +90°.
--   Example: (1,1):angle() = atan2(1,1) = π/4 ≈ 0.785 rad ≈ 45°
function vec2:angle()
    return math.atan2(self.y, self.x)
end

-- vec2:rotate(a): rotate this vector by angle a (radians).
--   Example: (1,0):rotate(π/2) → cos=0, sin=1
--            = (1·0 - 0·1, 1·1 + 0·0) = (0, 1)  (90° counter-clockwise)
function vec2:rotate(a)
    local c, s = math.cos(a), math.sin(a)
    return vec2.new(self.x * c - self.y * s, self.x * s + self.y * c)
end

-- __tostring: how vectors print in panels — "(x.x, y.y)".
--   Example: tostring(vec2.new(1.25, 2.75)) = "(1.3, 2.8)" (1 decimal)
vec2.__tostring = function(self)
    return string.format("(%.1f, %.1f)", self.x, self.y)
end

return vec2