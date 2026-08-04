# The Feynman Guide to LÖVE2D Physics

## A Complete Journey from Zero to Game-Physics Mastery

### Written in the spirit of Richard P. Feynman

---

> "What I cannot create, I do not understand."
> — Richard P. Feynman

---

## Table of Contents

1. [Preface — The Feynman Way](#1-preface)
2. [Chapter 1 — Vectors: The Language of Physics](#2-chapter-1)
3. [Chapter 2 — Newton's Laws in a Game Loop](#3-chapter-2)
4. [Chapter 3 — Your First LÖVE2D World](#4-chapter-3)
5. [Chapter 4 — Bodies, Shapes, and Fixtures](#5-chapter-4)
6. [Chapter 5 — Kinematics: Describing Motion](#6-chapter-5)
7. [Chapter 6 — Dynamics: F = ma in the Game Loop](#7-chapter-6)
8. [Chapter 7 — Gravity, Friction, and Restitution](#8-chapter-7)
9. [Chapter 8 — Collision Detection: The Maths Under the Hood](#9-chapter-8)
10. [Chapter 9 — Collision Response and Impulse](#10-chapter-9)
11. [Chapter 10 — Joints and Constraints](#11-chapter-10)
12. [Chapter 11 — Raycasting, Sensors, and Queries](#12-chapter-11)
13. [Chapter 12 — Performance, Warm Starting, and Tuning](#13-chapter-12)
14. [Chapter 13 — Advanced Topics](#14-chapter-13)
15. [Appendix A — Formulae Quick Reference](#15-appendix-a)
16. [Appendix B — LÖVE2D love.physics API Reference](#16-appendix-b)
17. [Appendix C — Complete Example Projects](#17-appendix-c)

---

## 1. Preface — The Feynman Way

### Why this book exists

Most physics-for-games tutorials teach you *what* to call. "Call `love.physics.newWorld`." "Create a body." "Add a fixture." They give you the API and move on. That's like teaching someone to cook by handing them a recipe without ever explaining what heat does to proteins.

This book is different. We're going to build understanding from the ground up.

Here's the Feynman approach to physics:

1. **Start with what you already know.** You've seen a ball bounce. You've felt a push. You know that heavier things are harder to stop. We begin there — with intuition — and then we *precisely* describe that intuition with mathematics.

2. **Derive everything from first principles.** We don't accept formulas on authority. We build them. If you understand why `F = ma` is true, you can derive almost anything else in game physics.

3. **Connect every equation to code.** Every formula in this book has a LÖVE2D code example. You will not just read about physics — you will *write* it, run it, and see it move.

4. **Embrace the approximations.** Game physics is not real physics. Real physics simulates every atom. Game physics simulates enough to *look right*. Understanding the difference is what separates a good game programmer from a great one.

### How to read this book

- **Read the maths.** Don't skip the derivations. They're short and they're the whole point.
- **Type the code.** Don't copy-paste. Your fingers need to learn what your brain is learning.
- **Break things.** Change a number. Make gravity negative. Set restitution to 2.0 and watch what happens. Understanding comes from seeing what goes wrong.
- **Draw diagrams.** Seriously. Get a piece of paper. Draw the forces. Draw the velocity vectors. Physics is a visual subject.

### What you need

- [LÖVE2D](https://love2d.org) installed (version 11.4+ recommended)
- A text editor (VS Code, Sublime, Neovim — whatever you like)
- Curiosity and a willingness to be confused (that's how learning works)

### Conventions

- Code blocks are Lua for LÖVE2D
- Math is written in plain text with `^` for exponents and `*` for multiplication
- Vectors are written as `(x, y)` tuples
- All code examples are complete and runnable — save them as `main.lua` and run with `love .`

---

## 2. Chapter 1 — Vectors: The Language of Physics

### What is a vector?

A vector is a quantity that has both *magnitude* (how much) and *direction* (which way). This is different from a *scalar*, which only has magnitude.

Speed is a scalar: "60 km/h." Velocity is a vector: "60 km/h *north*."

Temperature is a scalar: "25°C." Force is a vector: "10 Newtons *downward*."

In game physics, almost everything is a vector:
- Position
- Velocity
- Acceleration
- Force
- Momentum
- Impulse

### The mathematical representation

A 2D vector is an ordered pair of numbers:

```
v = (vx, vy)
```

The magnitude (length) of the vector is computed using Pythagoras' theorem:

```
|v| = sqrt(vx^2 + vy^2)
```

The direction is the angle from the positive x-axis:

```
θ = atan2(vy, vx)
```

### Vector operations — the four fundamentals

#### Addition

```
a + b = (ax + bx, ay + by)
```

Geometrically: place the tail of b at the head of a. The result is the vector from a's tail to b's head.

#### Subtraction

```
a - b = (ax - bx, ay - by)
```

This gives the vector *from b to a*. This is incredibly important in games — it tells you the direction from one object to another.

#### Scalar multiplication

```
k * a = (k * ax, k * ay)
```

Multiplying by a positive scalar stretches or shrinks the vector. Multiplying by -1 reverses it.

#### Dot product

```
a · b = ax * bx + ay * by
```

The dot product gives a *scalar* (a single number). It equals:

```
a · b = |a| * |b| * cos(θ)
```

where θ is the angle between the two vectors.

**Why this matters in games:**
- If `a · b > 0`, the angle is less than 90° (roughly facing the same direction)
- If `a · b = 0`, the vectors are perpendicular
- If `a · b < 0`, the angle is greater than 90° (roughly facing away)
- The dot product of a vector with itself gives its magnitude squared: `v · v = |v|^2`

This last fact is crucial for performance — computing `sqrt(vx^2 + vy^2)` is expensive. Comparing `v · v` to a threshold squared avoids the square root entirely.

#### Cross product (2D version)

In 2D, the cross product gives a scalar:

```
a × b = ax * by - ay * bx
```

This equals `|a| * |b| * sin(θ)`. It's positive if b is counter-clockwise from a, negative if clockwise. This is how you determine which side of a line a point is on — essential for collision detection.

### Vectors in LÖVE2D code

LÖVE2D doesn't have a built-in vector type. You can use tables, or the `vec2` library, or just use pairs of numbers. Here's a minimal vector utility:

```lua
-- vec2.lua: a tiny vector library
local vec2 = {}
vec2.__index = vec2

function vec2.new(x, y)
    return setmetatable({x = x or 0, y = y or 0}, vec2)
end

function vec2:add(other)
    return vec2.new(self.x + other.x, self.y + other.y)
end

function vec2:sub(other)
    return vec2.new(self.x - other.x, self.y - other.y)
end

function vec2:mul(s)
    return vec2.new(self.x * s, self.y * s)
end

function vec2:len()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function vec2:lenSq()
    return self.x * self.x + self.y * self.y
end

function vec2:normalize()
    local l = self:len()
    if l == 0 then return vec2.new(0, 0) end
    return vec2.new(self.x / l, self.y / l)
end

function vec2:dot(other)
    return self.x * other.x + self.y * other.y
end

function vec2:cross(other)
    return self.x * other.y - self.y * other.x
end

function vec2:angle()
    return math.atan2(self.y, self.x)
end

function vec2:rotate(angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    return vec2.new(
        self.x * c - self.y * s,
        self.x * s + self.y * c
    )
end

function vec2:copy()
    return vec2.new(self.x, self.y)
end

function vec2:tostring()
    return string.format("(%.2f, %.2f)", self.x, self.y)
end

return vec2
```

### The first law of vectors

> "The vector is the thing. The components are just how you describe it in a particular coordinate system."

A velocity of `(3, 4)` m/s is the same physical velocity whether you're looking at it from above or from the side. The numbers change with the coordinate system, but the physics doesn't.

### Exercise 1

Write a function `vec2.distance(a, b)` that returns the distance between two points. Use `lenSq` to avoid the square root when you just need to compare distances.

<details>
<summary>Solution</summary>

```lua
function vec2.distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

-- For comparing without sqrt:
function vec2.distanceSq(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return dx * dx + dy * dy
end
```
</details>

---

## 3. Chapter 2 — Newton's Laws in a Game Loop

### Newton's Three Laws

**First Law (Inertia):** An object at rest stays at rest, and an object in motion stays in motion at constant velocity, unless acted upon by a net external force.

Translation to games: if nothing happens, things don't move and moving things don't stop. This is the default state — and it's what makes physics *interesting* when a force *does* act.

**Second Law (F = ma):** The acceleration of an object is directly proportional to the net force acting on it and inversely proportional to its mass.

```
F_net = m * a
a = F_net / m
```

This is the *most important equation* in game physics. Everything else derives from it.

**Third Law (Action-Reaction):** For every action, there is an equal and opposite reaction.

When object A pushes on object B, object B pushes back on object A with equal force in the opposite direction. This is what makes collisions work — the impulse is exchanged.

### The game loop and Newton's second law

A game loop runs at some fixed or variable timestep. At each frame:

```
1. Collect forces (gravity, user input, springs, etc.)
2. Compute acceleration: a = F / m
3. Update velocity: v_new = v_old + a * dt
4. Update position: p_new = p_old + v_new * dt
```

Here `dt` is the time step in seconds. On a 60 FPS game, `dt ≈ 0.01667`.

This is called **Euler integration** and it's the simplest (and most commonly used) method in games. It's not perfect — it accumulates error — but for most games it's good enough.

### The Euler method in detail

Given:
- Position `p(t)` at time `t`
- Velocity `v(t)` at time `t`
- Acceleration `a(t)` at time `t`

The Euler update is:

```
v(t + dt) = v(t) + a(t) * dt
p(t + dt) = p(t) + v(t + dt) * dt
```

Note: we use the *new* velocity to update position. This is called the **semi-implicit Euler** method (or symplectic Euler), and it's more stable than using the old velocity. LÖVE2D's `love.physics` uses this internally.

### Why semi-implicit Euler?

With explicit Euler (using old velocity):

```
p(t + dt) = p(t) + v(t) * dt
```

Energy grows over time — objects gain energy and fly apart. With semi-implicit Euler:

```
p(t + dt) = p(t) + v(t + dt) * dt
```

Energy is approximately conserved for oscillatory systems (springs, orbits). This is why it's called *symplectic* — it preserves the geometric structure of Hamiltonian mechanics.

You don't need to understand Hamiltonian mechanics to use it. Just know: semi-implicit Euler is better. Always use it.

### A complete LÖVE2D example: ball falling under gravity

```lua
-- main.lua: A ball falling under gravity (manual physics)
local ball = {
    x = 400,
    y = 100,
    vx = 0,
    vy = 0,
    mass = 1.0,        -- kg (arbitrary units)
    radius = 20,
}

local GRAVITY = 500   -- pixels/s^2 (downward)
local dt = 0          -- will be set by love.update

function love.update(dt)
    -- 1. Collect forces
    local fx = 0
    local fy = GRAVITY * ball.mass   -- F_gravity = m * g

    -- 2. Compute acceleration: a = F / m
    local ax = fx / ball.mass
    local ay = fy / ball.mass

    -- 3. Update velocity (semi-implicit Euler)
    ball.vy = ball.vy + ay * dt

    -- 4. Update position
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt
end

function love.draw()
    -- Draw the ball
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)

    -- Draw velocity vector
    love.graphics.setColor(1, 0, 0)
    love.graphics.line(
        ball.x, ball.y,
        ball.x + ball.vx * 0.1, ball.y + ball.vy * 0.1
    )
    love.graphics.setColor(1, 1, 1)
end
```

Run this with `love .` and watch the ball fall. Change `GRAVITY` to see how it affects the motion. Set it to `-500` and watch the ball fly upward. Set it to `0` and watch the ball maintain its velocity forever — Newton's first law in action.

### The units question

In real physics, we use SI units: meters, kilograms, seconds. In games, we use *pixels*. There's no "real" conversion — you define your own scale.

A common convention:
- 1 meter = 32 pixels (or 64, or 100 — whatever looks good)
- Gravity ≈ 9.8 m/s² → in pixels: 9.8 * 32 ≈ 314 pixels/s²

The key is *consistency*. Pick a scale and stick with it.

### Exercise 2

Modify the falling ball to include air resistance. Air resistance is proportional to velocity squared and opposes the direction of motion:

```
F_drag = -0.5 * C_d * rho * A * |v|^2 * v_hat
```

where `C_d` is the drag coefficient, `rho` is air density, `A` is cross-sectional area, and `v_hat` is the unit velocity vector.

For a game, simplify: `F_drag = -k * |v| * v` where `k` is a tunable constant.

<details>
<summary>Solution</summary>

```lua
local DRAG_COEFF = 0.01

function love.update(dt)
    -- Gravity
    local fx = 0
    local fy = GRAVITY * ball.mass

    -- Air resistance: F_drag = -k * |v| * v
    local speed = math.sqrt(ball.vx^2 + ball.vy^2)
    if speed > 0 then
        local drag_mag = DRAG_COEFF * speed * speed
        local drag_x = -drag_mag * (ball.vx / speed)
        local drag_y = -drag_mag * (ball.vy / speed)
        fx = fx + drag_x
        fy = fy + drag_y
    end

    -- Acceleration
    local ax = fx / ball.mass
    local ay = fy / ball.mass

    -- Update velocity
    ball.vy = ball.vy + ay * dt
    ball.vx = ball.vx + ax * dt

    -- Update position
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt
end
```

Now the ball will reach a terminal velocity where gravity and drag balance:

```
m * g = k * v_term^2
v_term = sqrt(m * g / k)
```

With `m=1`, `g=500`, `k=0.01`: `v_term = sqrt(500/0.01) = sqrt(50000) ≈ 224 pixels/s`.
</details>

---

## 4. Chapter 3 — Your First LÖVE2D World

### What is love.physics?

`love.physics` is LÖVE2D's built-in physics engine. It wraps **Box2D**, a mature, battle-tested 2D physics engine developed by Erin Catto. Box2D handles:

- Rigid body dynamics (how objects move and respond to forces)
- Collision detection (which objects are overlapping)
- Collision response (how objects bounce off each other)
- Joints and constraints (connections between objects)
- Sensors (overlap detection without physical response)

Box2D works in **meters**, not pixels. The default scale is 1 meter = 1 pixel, which is fine for small games but can cause precision issues at large scales. We'll discuss scaling later.

### Creating a world

A `World` is the container for all physics. It holds the gravity setting and manages the simulation step.

```lua
-- main.lua: Your first Box2D world
function love.load()
    -- Create a world with gravity pointing down
    -- Gravity in Box2D is in meters/s^2 (9.81 is Earth standard)
    world = love.physics.newWorld(0, 9.81 * 30, true)
    -- The 'true' enables sleeping (bodies at rest stop being simulated)
end

function love.update(dt)
    -- Step the simulation
    -- Parameters: dt, velocityIterations, positionIterations
    world:update(dt)
end

function love.draw()
    -- We'll add bodies here
end
```

Wait — why `9.81 * 30`? Because we're using a scale where 1 meter = 30 pixels. If gravity is 9.81 m/s², that's 9.81 * 30 = 294.3 pixels/s². This gives nice-looking falling speeds for a pixel-based game.

### The world:update() call

```lua
world:update(dt, velocityIterations, positionIterations)
```

- `dt`: Time step in seconds. Use a fixed timestep for determinism (more on this later).
- `velocityIterations`: How many times to solve velocity constraints. Default 8. Higher = more accurate joints/bounces, slower.
- `positionIterations`: How many times to solve position constraints. Default 3. Higher = less overlap, slower.

For most games, the defaults are fine. For complex joints or stacking, increase positionIterations to 6-10.

### Adding a ground body

A body with no shape just exists at a position. To make it interact with other bodies, we add a *fixture* — a shape with physical properties.

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Ground body (static — doesn't move)
    groundBody = love.physics.newBody(world, 400, 550, "static")
    groundShape = love.physics.newRectangleShape(800, 20)
    groundFixture = love.physics.newFixture(groundBody, groundShape, 1)
    groundFixture:setFriction(0.5)
    groundFixture:setRestitution(0.3)
end
```

Let's break this down:

1. `newBody(world, x, y, type)` creates a body at position (x, y). Types are `"static"`, `"dynamic"`, or `"kinematic"`.
   - **Static**: Never moves. Infinite mass. Used for floors, walls.
   - **Dynamic**: Fully simulated. Affected by forces and collisions. Used for players, balls, crates.
   - **Kinematic**: Moved manually by setting velocity. Not affected by forces. Used for platforms that move.

2. `newRectangleShape(w, h)` creates a rectangle shape. Box2D works with *shapes* — geometric descriptions of collision boundaries.

3. `newFixture(body, shape, density)` attaches a shape to a body with physical properties. The `density` parameter (in kg/m²) determines the mass — for static bodies, density is ignored.

4. `setFriction(f)` sets the friction coefficient. 0 = ice, 1 = rough rubber on rough surface. Box2D uses Coulomb friction model.

5. `setRestitution(r)` sets the bounciness. 0 = no bounce (perfectly inelastic), 1 = perfect bounce (perfectly elastic). Values > 1 give super-bouncy behavior (energy is added — be careful!).

### Adding a dynamic body (a ball)

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Ground
    groundBody = love.physics.newBody(world, 400, 550, "static")
    groundShape = love.physics.newRectangleShape(800, 20)
    groundFixture = love.physics.newFixture(groundBody, groundShape, 1)
    groundFixture:setFriction(0.5)
    groundFixture:setRestitution(0.3)

    -- Ball (dynamic)
    ballBody = love.physics.newBody(world, 400, 100, "dynamic")
    ballShape = love.physics.newCircleShape(20)
    ballFixture = love.physics.newFixture(ballBody, ballShape, 1.0)
    ballFixture:setFriction(0.3)
    ballFixture:setRestitution(0.7)
    ballFixture:setRestitution(0.7)

    -- Store radius for drawing
    ballRadius = 20
end

function love.draw()
    -- Ground
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.polygon("fill", groundBody:getWorldPoints(groundShape:getPoints()))

    -- Ball
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", ballBody:getX(), ballBody:getY(), ballRadius)
    love.graphics.setColor(1, 1, 1)
end
```

Run this. The ball falls and bounces. You just created a physics simulation!

### The contact callback

Box2D calls user-defined functions when fixtures begin or end contact:

```lua
function love.load()
    -- ... world setup ...

    -- Register contact callbacks
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
end

function beginContact(a, b, contact)
    -- Called when two fixtures start overlapping
    -- 'a' and 'b' are fixtures
    -- 'contact' has info about the collision (normal, points, etc.)
    print("Contact began between fixtures")
end

function endContact(a, b, contact)
    -- Called when two fixtures stop overlapping
end

function preSolve(a, b, contact)
    -- Called after collision detection but before solving
    -- Can modify the collision response (e.g., set friction, disable collision)
end

function postSolve(a, b, contact)
    -- Called after solving — has access to impulse and friction data
    local impulse = contact:getNormalImpulses()
    -- impulse[1] is the magnitude of the impulse at the first contact point
end
```

### Exercise 3

Create a world with a floor and three balls of different masses (0.5, 1.0, 2.0 kg). Drop them from the same height. Observe that they all hit the ground at the same time (Galileo's experiment!). Then add different restitution values and observe the bounces.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    groundBody = love.physics.newBody(world, 400, 550, "static")
    groundShape = love.physics.newRectangleShape(800, 20)
    groundFixture = love.physics.newFixture(groundBody, groundShape, 1)
    groundFixture:setFriction(0.5)
    groundFixture:setRestitution(0.3)

    local masses = {0.5, 1.0, 2.0}
    local restitutions = {0.3, 0.7, 0.9}
    local colors = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}

    balls = {}
    for i = 1, 3 do
        local body = love.physics.newBody(world, 150 + i * 200, 50, "dynamic")
        local shape = love.physics.newCircleShape(15)
        local fixture = love.physics.newFixture(body, shape, masses[i])
        fixture:setFriction(0.3)
        fixture:setRestitution(restitutions[i])
        table.insert(balls, {
            body = body,
            fixture = fixture,
            radius = 15,
            color = colors[i],
            mass = masses[i],
        })
    end
end

function love.draw()
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.polygon("fill", groundBody:getWorldPoints(groundShape:getPoints()))

    for _, ball in ipairs(balls) do
        love.graphics.setColor(ball.color)
        love.graphics.circle("fill", ball.body:getX(), ball.body:getY(), ball.radius)
    end
    love.graphics.setColor(1, 1, 1)
end
```

You'll notice: all three balls land at the same time because gravitational acceleration is independent of mass. The equation is `a = F/m = mg/m = g`. Mass cancels out! This is why Galileo's Leaning Tower experiment works (in a vacuum).

The bounciness differs because restitution is a property of the *collision*, not the falling object. A ball with restitution 0.9 will bounce back to 81% of its drop height (0.9²), while one with 0.3 bounces back to only 9%.
</details>

---

## 5. Chapter 4 — Bodies, Shapes, and Fixtures

### Bodies in depth

A body in Box2D has these key properties:

| Property | Method | Description |
|----------|--------|-------------|
| Type | `body:getType()` | `"static"`, `"dynamic"`, or `"kinematic"` |
| Position | `body:getPosition()` | `(x, y)` in meters |
| Angle | `body:getAngle()` | Rotation in radians |
| Linear velocity | `body:getLinearVelocity()` | `(vx, vy)` in m/s |
| Angular velocity | `body:getAngularVelocity()` | Rotation speed in rad/s |
| Mass | `body:getMass()` | In kg (computed from fixtures) |
| Mass data | `body:getMassData()` | `{mass, center=(cx,cy), I}` where I is moment of inertia |
| Sleep state | `body:isSleeping()` | True if body has been at rest |
| Bullet flag | `body:isBullet()` | True if continuous collision detection is on |

### Setting body properties

```lua
-- Move a body to a specific position
body:setPosition(x, y)

-- Set linear velocity directly
body:setLinearVelocity(vx, vy)

-- Apply a force (continuous, accumulates over time)
body:applyForce(fx, fy, px, py)
-- (fx, fy) is the force vector in Newtons
-- (px, py) is the point of application (world coordinates)
-- If px,py are omitted, force is applied at center of mass

-- Apply an impulse (instantaneous change in momentum)
body:applyLinearImpulse(ix, iy, px, py)
-- Impulse = Force * dt. A kick is an impulse.

-- Apply torque (rotational force)
body:applyTorque(torque)

-- Apply angular impulse
body:applyAngularImpulse(impulse)
```

### The difference between force and impulse

This is fundamental and often confused:

- **Force** is applied continuously over time: `F = ma`. A force of 10 N applied for 2 seconds produces an impulse of 20 N·s.
- **Impulse** is instantaneous: `J = Δp = m * Δv`. Hitting a ball with a bat is an impulse — the contact time is tiny but the force is huge.

In code:

```lua
-- Continuous force (like gravity, thrusters)
body:applyForce(0, mass * GRAVITY)

-- Instantaneous impulse (like a jump, a kick)
body:applyLinearImpulse(0, -mass * jumpVelocity)
```

### Shapes

Box2D supports these shapes:

| Shape | Constructor | Parameters |
|-------|-------------|------------|
| Circle | `newCircleShape(radius)` | Radius in meters |
| Rectangle | `newRectangleShape(w, h)` | Width and height in meters (centered) |
| Edge | `newEdgeShape(x1, y1, x2, y2)` | A line segment (for edges only) |
| Chain | `newChainShape(loop, points)` | A chain of edges |
| Polygon | `newPolygonShape(points)` | Convex polygon (up to 8 vertices) |

### Fixtures in depth

A fixture defines the physical *material* properties of a shape attached to a body:

```lua
fixture:setDensity(density)       -- kg/m² (0 for static)
fixture:setFriction(friction)     -- 0 = frictionless, 1+ = very grippy
fixture:setRestitution(restitution) -- 0 = no bounce, 1 = perfect bounce
fixture:setSensor(sensor)         -- true = no collision response, just overlap events
fixture:setFilterData(category, mask, group)  -- Collision filtering
fixture:setRestitutionThreshold(threshold)    -- Velocity below which restitution is ignored
```

### Collision filtering

Box2D uses a category/mask system to control which fixtures can collide:

```lua
-- Categories are bit flags (powers of 2)
local CATEGORY_PLAYER = 1    -- 0001
local CATEGORY_ENEMY  = 2    -- 0010
local CATEGORY_BULLET = 4    -- 0100
local CATEGORY_WALL   = 8    -- 1000

-- Mask determines what this fixture collides with
-- Player collides with enemies, bullets, and walls
playerFixture:setFilterData(CATEGORY_PLAYER, CATEGORY_ENEMY + CATEGORY_BULLET + CATEGORY_WALL, 0)

-- Bullets collide with players and enemies, not with each other or walls
bulletFixture:setFilterData(CATEGORY_BULLET, CATEGORY_PLAYER + CATEGORY_ENEMY, 0)
```

The `group` parameter (third argument) is for grouping:
- Positive group: fixtures in the same positive group always collide
- Negative group: fixtures in the same negative group never collide
- Zero: uses category/mask

### Density, mass, and the relationship

Box2D computes mass automatically from fixture densities:

```
mass = sum over all fixtures of (density * area)
```

For a circle of radius `r`:
```
area = π * r^2
mass = density * π * r^2
```

For a rectangle of width `w` and height `h`:
```
area = w * h
mass = density * w * h
```

The moment of inertia (resistance to angular acceleration) is also computed automatically. For a solid disk:
```
I = 0.5 * m * r^2
```

For a rectangle:
```
I = (1/12) * m * (w^2 + h^2)
```

### Exercise 4

Create a scene with a ramp (angled rectangle) and a ball. Observe how the ball rolls down. Then change the ramp's friction to 0 and watch the ball slide without rolling. Change restitution to 1.0 and watch it bounce forever.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Ramp: a rectangle rotated 30 degrees
    rampBody = love.physics.newBody(world, 400, 350, "static")
    rampShape = love.physics.newRectangleShape(300, 20)
    rampFixture = love.physics.newFixture(rampBody, rampShape, 1)
    rampFixture:setFriction(0.5)
    rampFixture:setRestitution(0.1)
    rampBody:setAngle(math.rad(30))  -- 30 degrees

    -- Ball
    ballBody = love.physics.newBody(world, 400, 100, "dynamic")
    ballShape = love.physics.newCircleShape(15)
    ballFixture = love.physics.newFixture(ballBody, ballShape, 1.0)
    ballFixture:setFriction(0.5)
    ballFixture:setRestitution(0.3)

    ballRadius = 15
end

function love.draw()
    -- Ramp
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.polygon("fill", rampBody:getWorldPoints(rampShape:getPoints()))

    -- Ball
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", ballBody:getX(), ballBody:getY(), ballRadius)
    love.graphics.setColor(1, 1, 1)
end
```

The ramp's angle determines the component of gravity along the surface:
```
a_along_ramp = g * sin(θ)
```
At 30°: `a = 9.81 * sin(30°) = 9.81 * 0.5 = 4.905 m/s²`. The ball accelerates down the ramp at half of gravitational acceleration.

With friction = 0, there's no friction force to cause rolling, so the ball slides. With restitution = 1.0, every bounce is perfect — the ball never loses energy and bounces forever.
</details>

---

## 6. Chapter 5 — Kinematics: Describing Motion

### What is kinematics?

Kinematics is the study of *motion without considering forces*. It answers: "Where is the object? How fast is it moving? How is its velocity changing?"

### The three kinematic equations (constant acceleration)

When acceleration is constant (like gravity near Earth's surface), we have three equations:

**1. Velocity as a function of time:**
```
v(t) = v₀ + a * t
```

**2. Position as a function of time:**
```
p(t) = p₀ + v₀ * t + 0.5 * a * t²
```

**3. Velocity as a function of position (no time):**
```
v² = v₀² + 2 * a * (p - p₀)
```

These are derived from calculus:
- Velocity is the derivative of position: `v = dp/dt`
- Acceleration is the derivative of velocity: `a = dv/dt`
- Integrating acceleration gives velocity, integrating velocity gives position

### Projectile motion — the classic game physics problem

When you throw a ball at an angle, it follows a parabola. Here's why:

- Horizontal: no acceleration (ignoring air resistance), so `x(t) = x₀ + vx₀ * t`
- Vertical: constant acceleration from gravity, so `y(t) = y₀ + vy₀ * t + 0.5 * g * t²`

The trajectory is a parabola because `y` is quadratic in `t` while `x` is linear.

**Range** (horizontal distance when projectile returns to launch height):
```
R = v₀² * sin(2θ) / g
```

**Maximum height:**
```
H = v₀² * sin²(θ) / (2 * g)
```

**Time of flight:**
```
T = 2 * v₀ * sin(θ) / g
```

### Implementing projectile motion in LÖVE2D

```lua
-- main.lua: Projectile motion with love.physics
local world
local projectile
local trail = {}
local launchPower = 300  -- pixels/s
local launchAngle = math.rad(45)  -- 45 degrees

function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Ground
    local ground = love.physics.newBody(world, 400, 550, "static")
    local groundShape = love.physics.newRectangleShape(800, 20)
    local groundFixture = love.physics.newFixture(ground, groundShape, 1)
    groundFixture:setFriction(0.5)
    groundFixture:setRestitution(0.3)

    -- Projectile
    projectile = {}
    projectile.body = love.physics.newBody(world, 100, 100, "dynamic")
    projectile.shape = love.physics.newCircleShape(8)
    projectile.fixture = love.physics.newFixture(projectile.body, projectile.shape, 1)
    projectile.fixture:setRestitution(0.4)
    projectile.fixture:setFriction(0.2)
    projectile.radius = 8

    -- Launch!
    projectile.body:setLinearVelocity(
        launchPower * math.cos(launchAngle),
        -launchPower * math.sin(launchAngle)
    )
end

function love.update(dt)
    world:update(dt)

    -- Record trail
    table.insert(trail, {projectile.body:getX(), projectile.body:getY()})
    if #trail > 200 then
        table.remove(trail, 1)
    end
end

function love.draw()
    -- Trail
    love.graphics.setColor(0.5, 0.5, 0.5)
    for i = 1, #trail - 1 do
        love.graphics.line(trail[i][1], trail[i][2], trail[i+1][1], trail[i+1][2])
    end

    -- Projectile
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", projectile.body:getX(), projectile.body:getY(), projectile.radius)
    love.graphics.setColor(1, 1, 1)
end
```

### The beauty of the parabola

Notice something beautiful: the trajectory of a projectile is a parabola, and this is *exactly* the same curve that describes the path of light in a gravitational lens (in the weak-field approximation). The same math governs basketball arcs, cannonballs, thrown baseballs, and the orbits of planets (approximately, for short distances).

### Variable timestep problems

If your game uses variable `dt` (which it will if VSync is off or the frame rate fluctuates), physics can behave inconsistently. A large `dt` can cause objects to tunnel through walls or gain energy.

**The fix: use a fixed timestep.**

```lua
local FIXED_DT = 1/60  -- 60 Hz physics step
local accumulator = 0

function love.update(dt)
    accumulator = accumulator + dt

    -- Cap accumulator to prevent spiral of death
    if accumulator > 0.2 then
        accumulator = 0.2
    end

    while accumulator >= FIXED_DT do
        world:update(FIXED_DT)
        accumulator = accumulator - FIXED_DT
    end
end
```

This ensures physics runs at exactly 60 steps per second regardless of rendering frame rate. The accumulator carries over fractional time.

### Exercise 5

Implement a "cannon" that aims at the mouse cursor and fires a projectile. Calculate the launch angle and power needed to hit a target at a given distance.

<details>
<summary>Solution</summary>

```lua
-- Aim at mouse and fire
function love.mousepressed(x, y, button)
    if button == 1 then
        local dx = x - projectile.body:getX()
        local dy = -(y - projectile.body:getY())  -- y is flipped in LÖVE
        local dist = math.sqrt(dx^2 + dy^2)
        local angle = math.atan2(dy, dx)

        -- Reset projectile
        projectile.body:setTransform(100, 100, 0)
        projectile.body:setLinearVelocity(0, 0)
        projectile.body:setAngularVelocity(0)

        -- Launch toward mouse
        local speed = launchPower
        projectile.body:setLinearVelocity(
            speed * math.cos(angle),
            speed * math.sin(angle)
        )
    end
end
```

For a more interesting challenge: compute the minimum launch speed to reach a target at distance `d` and height `h`:

```
v_min = sqrt(g * (d + sqrt(d^2 + h^2)) / 2)
```

This comes from the range equation with an offset height.
</details>

---

## 7. Chapter 7 — Gravity, Friction, and Restitution

### Gravity in depth

In Box2D, gravity is set when creating the world:

```lua
world = love.physics.newWorld(gx, gy, allowSleep)
```

The values are in **meters/s²**. Earth's gravity is `(0, 9.81)` in the standard coordinate system (y-up). In LÖVE2D, y points down, so `(0, 9.81)` means gravity pulls downward in screen coordinates.

### Gravitational force between two bodies

Newton's law of universal gravitation:

```
F = G * m₁ * m₂ / r²
```

where:
- `G = 6.674 × 10⁻¹¹ N·m²/kg²` (gravitational constant)
- `m₁, m₂` are the masses
- `r` is the distance between centers

In a game, you'd typically use a much larger `G` to make gravity noticeable at pixel scales. For a "space" game:

```lua
local G = 100  -- tunable game constant

function applyGravity(body1, body2)
    local dx = body2:getX() - body1:getX()
    local dy = body2:getY() - body1:getY()
    local distSq = dx * dx + dy * dy
    local dist = math.sqrt(distSq)
    if dist < 0.01 then return end  -- avoid division by zero

    local force = G * body1:getMass() * body2:getMass() / distSq
    local fx = force * dx / dist
    local fy = force * dy / dist

    body1:applyForce(fx, fy, body1:getX(), body1:getY())
    body2:applyForce(-fx, -fy, body2:getX(), body2:getY())
end
```

Notice Newton's third law in action: the force on body1 is equal and opposite to the force on body2. This is how orbital mechanics work — both bodies orbit their common center of mass.

### Friction: the Coulomb model

Box2D uses a simplified Coulomb friction model:

```
F_friction ≤ μ * F_normal
```

where:
- `μ` is the coefficient of friction (set via `fixture:setFriction()`)
- `F_normal` is the normal force (perpendicular to the surface)

There are two types:
- **Static friction**: prevents motion from starting. `μ_s` (static) ≥ `μ_k` (kinetic). Box2D combines both into a single friction coefficient.
- **Kinetic friction**: opposes motion that's already happening.

The actual friction force is computed during the constraint solver — you don't set it directly each frame. You just set the friction coefficient on fixtures and Box2D handles the rest.

### Restitution and the coefficient of restitution

Restitution (`e`) determines how much kinetic energy is conserved in a collision:

```
e = |v_separation| / |v_approach|
```

- `e = 0`: Perfectly inelastic (objects stick together, maximum energy loss)
- `e = 1`: Perfectly elastic (no energy loss, maximum bounce)
- `0 < e < 1`: Real-world collisions (some energy lost to heat, sound, deformation)
- `e > 1`: Superelastic (energy added — like an explosion)

Box2D computes the combined restitution as:
```
e_combined = min(e₁, e₂)
```

### Energy in collisions

Kinetic energy before and after a collision:

```
KE_before = 0.5 * m₁ * v₁² + 0.5 * m₂ * v₂²
KE_after  = 0.5 * m₁ * v₁'² + 0.5 * m₂ * v₂'²
```

Energy lost:
```
ΔKE = KE_before - KE_after = 0.5 * (1 - e²) * reduced_mass * v_rel²
```

where `reduced_mass = m₁ * m₂ / (m₁ + m₂)` and `v_rel` is the relative velocity along the collision normal.

This is why restitution 0.5 doesn't mean "half the energy is lost" — it means the *velocity* of separation is half the velocity of approach. Since KE scales with velocity squared, a restitution of 0.5 means 75% of the kinetic energy is lost.

### Exercise 6

Create a "billiard table" with walls on all four sides and two balls. Set restitution to 1.0 and observe the balls bouncing forever. Set it to 0.0 and watch them stop. Set it to 0.5 and observe the energy loss.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Table boundaries (static walls)
    local walls = {
        {x=400, y=10, w=800, h=20},   -- top
        {x=400, y=590, w=800, h=20},  -- bottom
        {x=10, y=300, w=20, h=600},   -- left
        {x=790, y=300, w=20, h=600},  -- right
    }

    for _, w in ipairs(walls) do
        local body = love.physics.newBody(world, w.x, w.y, "static")
        local shape = love.physics.newRectangleShape(w.w, w.h)
        local fixture = love.physics.newFixture(body, shape, 1)
        fixture:setFriction(0.1)
        fixture:setRestitution(1.0)  -- perfect bounce
    end

    -- Ball 1
    local b1 = {}
    b1.body = love.physics.newBody(world, 300, 300, "dynamic")
    b1.shape = love.physics.newCircleShape(12)
    b1.fixture = love.physics.newFixture(b1.body, b1.shape, 1)
    b1.fixture:setFriction(0.0)
    b1.fixture:setRestitution(1.0)
    b1.body:setLinearVelocity(100, 50)
    b1.radius = 12

    -- Ball 2
    local b2 = {}
    b2.body = love.physics.newBody(world, 500, 300, "dynamic")
    b2.shape = love.physics.newCircleShape(12)
    b2.fixture = love.physics.newFixture(b2.body, b2.shape, 1)
    b2.fixture:setFriction(0.0)
    b2.fixture:setRestitution(1.0)
    b2.body:setLinearVelocity(-50, -30)
    b2.radius = 12

    balls = {b1, b2}
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    for _, b in ipairs(balls) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", b.body:getX(), b.body:getY(), b.radius)
    end
end
```

With restitution 1.0 and friction 0.0, the total kinetic energy of the system is conserved. The balls will bounce forever (or until floating-point precision causes issues). With restitution 0.0, all collisions are perfectly inelastic — the balls stick together and all kinetic energy converts to heat (in the simulation, they just stop).
</details>

---

## 8. Chapter 8 — Collision Detection: The Maths Under the Hood

### How Box2D detects collisions

Collision detection in Box2D happens in two phases:

**Phase 1: Broad-phase** — Uses a spatial data structure (an AABB tree, specifically a dynamic AABB tree) to quickly find pairs of fixtures that *might* be overlapping. This eliminates the vast majority of pairs without expensive per-pixel or per-polygon checks.

**Phase 2: Narrow-phase** — For each candidate pair, performs precise geometric intersection tests:
- Circle vs Circle
- Polygon vs Polygon
- Circle vs Polygon
- Edge vs Polygon

### Circle vs Circle collision

The simplest and most common test. Two circles collide when the distance between their centers is less than the sum of their radii:

```
collide = distance(c1.center, c2.center) < c1.radius + c2.radius
```

The collision normal points from c1's center to c2's center:
```
n = (c2.center - c1.center) / |c2.center - c1.center|
```

The penetration depth is:
```
d = (c1.radius + c2.radius) - distance(c1.center, c2.center)
```

### Separating Axis Theorem (SAT)

For convex polygons, Box2D uses the Separating Axis Theorem:

> Two convex shapes are not colliding if and only if there exists a line (axis) onto which their projections do not overlap.

The candidate axes are the normals of all edges of both polygons. For each axis:
1. Project both polygons onto the axis
2. Check if the projections overlap
3. If any axis has no overlap, the shapes are separated — no collision

If all axes show overlap, the shapes are colliding. The axis with the minimum overlap gives the collision normal and penetration depth.

### The collision manifold

When Box2D detects a collision, it creates a *manifold* containing:
- The collision normal
- The penetration depth
- One or two contact points
- The relative velocity at the contact points

This manifold is passed to the solver, which computes the impulse needed to separate the objects.

### Continuous Collision Detection (CCD)

At high speeds, objects can "tunnel" through thin walls — moving so far in one frame that they skip the overlap detection entirely. Box2D solves this with CCD for "bullet" bodies:

```lua
body:setBullet(true)
```

CCD uses swept volumes — it computes the *path* the shape takes during the timestep and checks for intersections along that path, not just at the endpoints.

### Exercise 7

Create a thin wall (1 pixel thick in world units) and launch a fast-moving ball at it. Without CCD, the ball tunnels through. With CCD (`setBullet(true)`), it bounces correctly.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Thin wall
    local wall = love.physics.newBody(world, 400, 300, "static")
    local wallShape = love.physics.newRectangleShape(200, 1)  -- 1 meter thick
    local wallFixture = love.physics.newFixture(wall, wallShape, 1)
    wallFixture:setFriction(0.5)
    wallFixture:setRestitution(0.5)

    -- Fast ball
    local ball = {}
    ball.body = love.physics.newBody(world, 100, 300, "dynamic")
    ball.shape = love.physics.newCircleShape(0.5)  -- 0.5 meter radius
    ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
    ball.fixture:setRestitution(0.5)
    ball.body:setBullet(true)  -- Enable CCD
    ball.body:setLinearVelocity(1000, 0)  -- Very fast!
    ball.radius = 0.5

    ballData = ball
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    -- Wall
    love.graphics.setColor(0.5, 0.5, 0.5)
    local wp = wallBody:getWorldPoints(wallShape:getPoints())
    love.graphics.polygon("fill", wp)

    -- Ball (scaled 30x for display)
    love.graphics.setColor(1, 0, 0)
    local bx, by = ballData.body:getX(), ballData.body:getY()
    love.graphics.circle("fill", bx * 30, by * 30, ballData.radius * 30)
    love.graphics.setColor(1, 1, 1)
end
```

Without `setBullet(true)`, a ball moving at 1000 m/s would travel 1000 meters in one second (16.67 meters per frame at 60 FPS). If the wall is 1 meter thick, the ball completely passes through it in a single frame. CCD prevents this by checking the swept volume.
</details>

---

## 9. Chapter 9 — Collision Response and Impulse

### What happens during a collision?

When two objects collide, they exert forces on each other for a very short time. The result is a change in velocity for each object. This change is quantified by **impulse**.

### Impulse-momentum theorem

The impulse-momentum theorem states:

```
J = Δp = m * Δv
```

where `J` is the impulse (in N·s), `Δp` is the change in momentum, `m` is mass, and `Δv` is the change in velocity.

For a collision between two bodies, we compute the impulse needed to:
1. Separate the objects (resolve penetration)
2. Apply the correct bounce (restitution)

### The collision impulse formula

For a collision between two bodies with restitution `e`, the impulse magnitude along the collision normal `n` is:

```
j = -(1 + e) * (v_rel · n) / (1/m₁ + 1/m₂)
```

where:
- `v_rel = v₁ - v₂` is the relative velocity
- `v_rel · n` is the relative velocity along the collision normal
- `m₁, m₂` are the masses
- `e` is the combined restitution

If `v_rel · n > 0`, the objects are moving apart — no impulse is needed (they're already separating).

### Computing the impulse in Box2D

Box2D does all of this internally. But you can access the impulse in the contact callback:

```lua
function postSolve(fixtureA, fixtureB, contact)
    -- Get the impulse at each contact point
    local impulses = contact:getNormalImpulses()
    local tangentImpulses = contact:getTangentImpulses()

    -- impulses[1] is the normal impulse at the first contact point
    -- tangentImpulses[1] is the friction impulse at the first contact point

    -- Total impulse magnitude (approximate):
    local totalNormal = 0
    for _, imp in ipairs(impulses) do
        totalNormal = totalNormal + math.abs(imp)
    end

    -- You can use this for sound effects, damage, particles, etc.
    if totalNormal > 5 then
        -- Hard collision — play a sound, spawn particles
    end
end
```

### The role of friction in impulse

Friction impulse is computed similarly but along the tangent direction:

```
j_tangent = -μ * j_normal * (v_rel_tangent · t) / |v_rel_tangent|
```

where `t` is the tangent vector (perpendicular to the collision normal) and `μ` is the friction coefficient.

Box2D uses a simplified Coulomb friction model where the friction impulse is capped at `μ * j_normal`.

### Exercise 8

Create two balls of different mass and observe the collision response. A heavy ball hitting a light ball should transfer most of its momentum. A light ball hitting a heavy ball should bounce back.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 0, true)  -- No gravity for clean collision demo

    -- Heavy ball (10 kg)
    heavy = {}
    heavy.body = love.physics.newBody(world, 200, 300, "dynamic")
    heavy.shape = love.physics.newCircleShape(15)
    heavy.fixture = love.physics.newFixture(heavy.body, heavy.shape, 10)
    heavy.fixture:setRestitution(1.0)
    heavy.fixture:setFriction(0.0)
    heavy.body:setLinearVelocity(200, 0)
    heavy.radius = 15

    -- Light ball (1 kg)
    light = {}
    light.body = love.physics.newBody(world, 600, 300, "dynamic")
    light.shape = love.physics.newCircleShape(15)
    light.fixture = love.physics.newFixture(light.body, light.shape, 1)
    light.fixture:setRestitution(1.0)
    light.fixture:setFriction(0.0)
    light.body:setLinearVelocity(0, 0)
    light.radius = 15

    -- Wall on right
    local wall = love.physics.newBody(world, 790, 300, "static")
    local wallShape = love.physics.newRectangleShape(20, 400)
    love.physics.newFixture(wall, wallShape, 1)
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    -- Heavy ball (red)
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", heavy.body:getX(), heavy.body:getY(), heavy.radius)

    -- Light ball (blue)
    love.graphics.setColor(0, 0, 1)
    love.graphics.circle("fill", light.body:getX(), light.body:getY(), light.radius)

    -- Wall
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", 780, 100, 20, 400)

    love.graphics.setColor(1, 1, 1)

    -- Print velocities
    love.graphics.print("Heavy vx: " .. string.format("%.1f", heavy.body:getLinearVelocity()), 10, 10)
    love.graphics.print("Light vx: " .. string.format("%.1f", light.body:getLinearVelocity()), 10, 30)
end
```

When the heavy ball hits the light ball:
- Heavy ball slows down but keeps moving forward
- Light ball shoots forward at high speed

This is conservation of momentum in action:
```
m₁ * v₁ + m₂ * v₂ = m₁ * v₁' + m₂ * v₂'
```

With `m₁ = 10`, `v₁ = 200`, `m₂ = 1`, `v₂ = 0`, and `e = 1` (perfectly elastic):
```
v₁' = (m₁ - m₂)/(m₁ + m₂) * v₁ = 9/11 * 200 ≈ 163.6
v₂' = 2*m₁/(m₁ + m₂) * v₁ = 20/11 * 200 ≈ 363.6
```

The light ball flies off at nearly twice the heavy ball's original speed!
</details>

---

## 10. Chapter 10 — Joints and Constraints

### What are joints?

Joints connect two bodies and constrain their relative motion. They're what make ragdolls, chains, ropes, pendulums, and vehicles possible.

### Types of joints in Box2D

| Joint | Description | Common Use |
|-------|-------------|------------|
| Distance | Keeps two points at a fixed distance | Chains, ropes |
| Revolute | Hinge — allows rotation around a point | Doors, wheels, elbows |
| Prismatic | Slider — allows linear motion along an axis | Pistons, drawers |
| Pulley | Connected distance joints with a ratio | Block and tackle |
| Gear | Links the angular motion of two bodies | Gear trains |
| Motor | Applies torque to a revolute joint | Wheels, engines |
| Weld | Fuses two bodies together | Breaking apart objects |
| Rope | Like distance joint but with a max length | Ropes, cables |
| Motor (linear) | Applies force along a prismatic joint | Linear actuators |
| Angle | Keeps the relative angle between bodies constant | Rigid structures |
| Weld (spring) | Spring-like connection | Soft connections |
| Wheel | Specialized for vehicle simulation | Cars, carts |
| Rope (distance limit) | Distance joint with a max length | Chains |
| Fixed | Completely locks two bodies together | Welding |
| Mouse | Drags a body toward a point | Interactive grabbing |

### Distance joint — the simplest

```lua
local joint = love.physics.newDistanceJoint(
    bodyA, bodyB,
    anchorAX, anchorAY,   -- anchor point on body A (world coords)
    anchorBX, anchorBY,   -- anchor point on body B (world coords)
    collideConnected       -- whether the connected bodies can collide
)

-- Optional: set limits
joint:setLength(5.0)              -- Target distance in meters
joint:setMinLength(2.0)           -- Minimum distance (0 = no minimum)
joint:setMaxLength(10.0)          -- Maximum distance
joint:setStiffness(100)           -- Spring stiffness (0 = no spring, only distance constraint)
joint:setDamping(5)               -- Damping (how quickly oscillations die out)
```

### Revolute joint — the hinge

```lua
local joint = love.physics.newRevoluteJoint(
    bodyA, bodyB,
    anchorX, anchorY,     -- Anchor point (world coordinates)
    collideConnected
)

-- Optional: motor
joint:enableMotor(true)
joint:setMotorSpeed(2.0)     -- Radians per second (positive = CCW)
joint:setMaxMotorTorque(100) -- Maximum torque in N·m

-- Optional: limits
joint:enableLimit(true)
joint:setLowerAngle(-math.pi/4)  -- -45 degrees
joint:setUpperAngle(math.pi/4)   -- +45 degrees
```

### Building a ragdoll

A ragdoll is a collection of bodies connected by revolute joints, forming a humanoid figure:

```lua
-- Simplified ragdoll: torso, head, two arms, two legs
function createRagdoll(world, x, y)
    local parts = {}
    local joints = {}

    -- Helper: create a body part
    local function createPart(px, py, w, h, density)
        local body = love.physics.newBody(world, px, py, "dynamic")
        local shape = love.physics.newRectangleShape(w, h)
        local fixture = love.physics.newFixture(body, shape, density)
        fixture:setFriction(0.4)
        fixture:setRestitution(0.2)
        return {body = body, shape = shape, w = w, h = h}
    end

    -- Helper: create a revolute joint between two parts
    local function createRevolute(a, b, ax, ay, bx, by)
        local j = love.physics.newRevoluteJoint(
            a.body, b.body, ax, ay, bx, by, false
        )
        j:setMaxMotorTorque(0)  -- No motor by default
        return j
    end

    -- Torso
    parts.torso = createPart(x, y, 30, 40, 1)
    -- Head
    parts.head = createPart(x, y - 50, 20, 20, 0.5)
    -- Upper arm (left)
    parts.luArm = createPart(x - 25, y - 10, 10, 25, 0.5)
    -- Lower arm (left)
    parts.llArm = createPart(x - 25, y + 20, 10, 25, 0.5)
    -- Upper leg (left)
    parts.luLeg = createPart(x - 10, y + 25, 12, 25, 1)
    -- Lower leg (left)
    parts.llLeg = createPart(x - 10, y + 55, 12, 25, 1)

    -- Same for right side... (symmetric)

    -- Joints
    table.insert(joints, createRevolute(parts.torso, parts.head, x, y - 25, x, y - 40))
    table.insert(joints, createRevolute(parts.torso, parts.luArm, x - 15, y - 10, x - 25, y - 10))
    -- ... more joints

    return parts, joints
end
```

### The mouse joint — interactive grabbing

```lua
-- Create a mouse joint when the user clicks on a body
function love.mousepressed(x, y, button)
    if button == 1 then
        -- Convert screen coordinates to world coordinates
        local wx, wy = x, y  -- if scale is 1:1

        -- Query for bodies at the click point
        local fixtures = world:queryPoint(wx, wy)
        for _, fixture in ipairs(fixtures) do
            local body = fixture:getBody()
            if body:getType() == "dynamic" then
                mouseJoint = love.physics.newMouseJoint(body, wx, wy)
                mouseJoint:setMaxForce(1000 * body:getMass())
                break
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and mouseJoint then
        mouseJoint:destroy()
        mouseJoint = nil
    end
end

function love.update(dt)
    if mouseJoint then
        -- Update target to follow mouse
        mouseJoint:setTarget(mouseX, mouseY)
    end
    world:update(dt)
end
```

### Exercise 9

Create a simple pendulum: a dynamic body connected to a static body by a revolute joint. Set the joint to have limits so the pendulum swings back and forth. Add a motor to make it swing continuously.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Pivot point (static)
    local pivot = love.physics.newBody(world, 400, 100, "static")

    -- Pendulum bob
    local bob = {}
    bob.body = love.physics.newBody(world, 400, 300, "dynamic")
    bob.shape = love.physics.newCircleShape(15)
    bob.fixture = love.physics.newFixture(bob.body, bob.shape, 1)
    bob.fixture:setRestitution(0.2)
    bob.fixture:setFriction(0.3)
    bob.radius = 15

    -- Distance joint acts as a pendulum (fixed length)
    pendulum = love.physics.newDistanceJoint(
        pivot, bob.body,
        400, 100,  -- anchor on pivot
        400, 300   -- anchor on bob
    )
    pendulum:setLength(200)  -- meters
    pendulum:setDamping(0.01)  -- slight damping

    -- Alternatively, use a revolute joint:
    -- revolute = love.physics.newRevoluteJoint(pivot, bob.body, 400, 100)
    -- revolute:enableLimit(true)
    -- revolute:setLowerAngle(-math.pi/3)  -- -60 degrees
    -- revolute:setUpperAngle(math.pi/3)   -- +60 degrees
end

function love.draw()
    -- Pivot
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", 400, 100, 5)

    -- Bob
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", bob.body:getX(), bob.body:getY(), bob.radius)

    -- Rod
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.line(400, 100, bob.body:getX(), bob.body:getY())
    love.graphics.setColor(1, 1, 1)
end
```

The period of a simple pendulum is:
```
T = 2π * sqrt(L / g)
```

With `L = 2` meters and `g = 9.81 m/s²`:
```
T = 2π * sqrt(2/9.81) ≈ 2π * 0.451 ≈ 2.84 seconds
```

This is independent of mass — a heavier bob swings at the same rate as a lighter one. This is Galileo's discovery, and it's why pendulum clocks work.
</details>

---

## 11. Chapter 11 — Raycasting, Sensors, and Queries

### Raycasting: shooting a line and finding what it hits

A raycast casts an infinite line from point A to point B and reports all fixtures it intersects. This is how you implement:
- Line of sight
- Shooting/ray weapons
- Visibility checks
- "What's under the mouse cursor?"

```lua
-- Cast a ray and get the closest fixture hit
local result = world:rayCast(x1, y1, x2, y2, callback)

-- callback(fixture, x, y, normal, fraction)
--   fixture: the fixture hit
--   x, y: the point of intersection
--   normal: the collision normal at the hit point
--   fraction: how far along the ray the hit occurred (0 = start, 1 = end)
-- Return 0 to stop the ray, fraction to continue, or -1 to ignore

function rayCallback(fixture, x, y, normal, fraction)
    print("Hit:", fixture:getBody():getType(), "at", x, y)
    return fraction  -- continue to find the closest hit
end
```

### Sensors: detecting overlap without physical response

A sensor is a fixture that detects when other fixtures enter, stay in, or leave its area — but doesn't generate collision forces. Perfect for:
- Trigger zones (e.g., "enter danger area")
- Pickup collection zones
- Proximity detection
- Seeing if a player is "in range"

```lua
local sensorFixture = love.physics.newFixture(body, shape, 1)
sensorFixture:setSensor(true)

-- In contact callbacks:
function beginContact(a, b, contact)
    if a:isSensor() or b:isSensor() then
        -- This is a sensor overlap, not a physical collision
        -- No forces are applied, but the contact event still fires
        print("Sensor overlap!")
    end
end
```

### Queries: finding fixtures in a region

```lua
-- Point query: find all fixtures at a point
local fixtures = world:queryPoint(x, y)

-- AABB query: find all fixtures in a rectangle
local fixtures = world:queryAABB(x1, y1, x2, y2)

-- Shape query: find all fixtures overlapping a shape
local fixtures = world:queryShape(shape, x, y, angle)
```

### Exercise 10

Create a "proximity mine" — a circular sensor that detects when a dynamic body enters it and then explodes (applies an impulse to all nearby bodies).

<details>
<summary>Solution</summary>

```lua
local mines = {}

function createMine(world, x, y)
    local mine = {}
    mine.x = x
    mine.y = y
    mine.radius = 50
    mine.exploded = false

    -- Visual body (static, for drawing)
    mine.body = love.physics.newBody(world, x, y, "static")
    mine.shape = love.physics.newCircleShape(mine.radius)
    mine.sensor = love.physics.newFixture(mine.body, mine.shape, 1)
    mine.sensor:setSensor(true)
    mine.sensor:setUserData("mine")

    table.insert(mines, mine)
    return mine
end

function beginContact(a, b, contact)
    -- Check if one of the fixtures is a mine sensor
    local sensor = nil
    local otherFixture = nil

    if a:getUserData() == "mine" then
        sensor = a
        otherFixture = b
    elseif b:getUserData() == "mine" then
        sensor = b
        otherFixture = a
    end

    if sensor and otherFixture then
        local otherBody = otherFixture:getBody()
        if otherBody:getType() == "dynamic" then
            -- Explode! Apply impulse away from mine center
            local mx, my = sensor:getBody():getPosition()
            local ox, oy = otherBody:getPosition()
            local dx = ox - mx
            local dy = oy - my
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < 0.01 then dist = 0.01 end

            local explosionForce = 500
            local impulse = explosionForce / dist
            otherBody:applyLinearImpulse(
                dx * impulse,
                dy * impulse
            )
        end
    end
end
```
</details>

---

## 12. Chapter 12 — Performance, Warm Starting, and Tuning

### The warm-starting trick

Box2D uses "warm starting" — it remembers the impulses applied in the previous frame and uses them as the initial guess for the current frame's solver. This dramatically speeds up convergence.

**Sleeping** is related: bodies that have been at rest for a while are put to "sleep" and excluded from simulation until they're woken by a collision. This can save enormous amounts of computation in scenes with many static objects.

```lua
-- Enable/disable sleeping
world = love.physics.newWorld(0, 9.81 * 30, true)  -- true = allow sleeping

-- Wake a sleeping body
body:setAwake(true)

-- Check if a body is sleeping
if body:isSleeping() then
    -- Don't process this body this frame
end
```

### Fixed timestep and substeps

Variable `dt` causes non-deterministic physics. The accumulator pattern (shown in Chapter 5) is essential. But what if the frame rate drops so low that `dt` exceeds your fixed step?

The accumulator caps `dt` at a maximum (e.g., 0.25 seconds) to prevent the "spiral of death" — where the physics can never catch up because each step takes longer than the frame.

### Tuning velocity and position iterations

The constraint solver iterates to converge on a solution. More iterations = more accurate but slower:

```lua
-- In love.update:
world:update(dt, 8, 3)  -- velocityIters, positionIters

-- For stacking (many objects on top of each other):
world:update(dt, 10, 8)  -- More position iterations for better stacking

-- For joints (ragdolls, chains):
world:update(dt, 12, 6)  -- More velocity iterations for joint accuracy
```

### Profiling your physics

```lua
-- Box2D provides profiling data
print("Step time:", world:getProfile().step)
print("Collide time:", world:getProfile().collide)
print("Solve time:", world:getProfile().solve)
print("Solve init time:", world:getProfile().solveInit)
print("Solve velocity time:", world:getProfile().solveVelocity)
print("Solve position time:", world:getProfile().solvePosition)
print("Broad-phase time:", world:getProfile().broadphase)
```

### Common performance pitfalls

1. **Too many fixtures**: Each fixture adds collision-checking overhead. Merge fixtures where possible.
2. **Too many small bodies**: Each body has its own update cost. Use a single body with multiple fixtures for complex shapes.
3. **No sleeping**: If everything is always awake, nothing gets a free pass.
4. **CCD on everything**: Bullet flag is expensive. Only use it for fast-moving objects.
5. **Too many joints**: Each joint adds solver iterations. Minimize joints where possible.
6. **Collision filtering done wrong**: Use categories and masks to avoid unnecessary collision checks.

### Exercise 11

Create a scene with 100 boxes stacked in a pile and measure the step time. Then enable sleeping and observe the performance difference once the pile settles.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Ground
    local ground = love.physics.newBody(world, 400, 550, "static")
    local groundShape = love.physics.newRectangleShape(800, 20)
    love.physics.newFixture(ground, groundShape, 1)

    -- Stack of 100 boxes
    boxes = {}
    local boxSize = 20  -- pixels
    local cols = 10
    for i = 1, 100 do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local body = love.physics.newBody(world, 300 + col * boxSize, 500 - row * boxSize, "dynamic")
        local shape = love.physics.newRectangleShape(boxSize, boxSize)
        local fixture = love.physics.newFixture(body, shape, 1)
        fixture:setFriction(0.3)
        fixture:setRestitution(0.1)
        table.insert(boxes, body)
    end
end

function love.update(dt)
    world:update(dt)

    -- Print profile data every 60 frames
    if love.getTimer() % 1 < dt then
        local profile = world:getProfile()
        print(string.format("Step: %.2fμs, Collide: %.2fμs, Solve: %.2fμs",
            profile.step * 1e6, profile.collide * 1e6, profile.solve * 1e6))
    end
end
```

After the pile settles, most boxes go to sleep and the step time drops dramatically. The solver only needs to process the few boxes that are still moving or in contact with active bodies.
</details>

---

## 13. Chapter 13 — Advanced Topics

### Custom forces: springs, dampers, and attraction

Box2D doesn't have built-in spring joints (except the `DistanceJoint` with stiffness/damping). For custom forces, apply them each frame:

#### Hooke's Law (spring force)

```
F = -k * (x - x₀) - c * v
```

where:
- `k` is the spring constant (stiffness)
- `x₀` is the rest length
- `c` is the damping coefficient
- `v` is the velocity along the spring axis

```lua
function applySpring(body, anchorX, anchorY, restLength, stiffness, damping)
    local bx, by = body:getPosition()
    local vx, vy = body:getLinearVelocity()

    local dx = bx - anchorX
    local dy = by - anchorY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 0.001 then return end

    -- Spring force (Hooke's law)
    local springForce = -stiffness * (dist - restLength)

    -- Damping force (proportional to velocity along spring axis)
    local vxAlong = (dx / dist) * vx + (dy / dist) * vy
    local dampForce = -damping * vxAlong

    -- Total force along spring direction
    local totalForce = springForce + dampForce
    local fx = totalForce * dx / dist
    local fy = totalForce * dy / dist

    body:applyForce(fx, fy)
end
```

This is how you build:
- Bungee cords (spring with a maximum length)
- Rope physics (distance constraint with damping)
- Character controllers (spring-based ground detection)
- Camera follow (spring smoothing)

### Buoyancy

For underwater physics, you need to apply an upward buoyancy force:

```
F_buoyancy = ρ * g * V_submerged * upward
```

where `ρ` is fluid density, `g` is gravity, and `V_submerged` is the submerged volume.

In practice, for a 2D game, you approximate this by checking how much of a body is below the water line and applying a proportional upward force plus drag:

```lua
function applyBuoyancy(body, waterY, fluidDensity, gravity)
    local bx, by = body:getPosition()
    local shape = body:getFixtureList()
    local aabb = shape:getAABB()  -- approximate bounding box

    -- How far is the body below water?
    local submersionDepth = (aabb.lowerBound.y + aabb.upperBound.y) / 2 - waterY

    if submersionDepth > 0 then
        -- Approximate submerged area
        local width = aabb.upperBound.x - aabb.lowerBound.x
        local submergedArea = width * submersionDepth

        -- Buoyancy force (upward)
        local buoyancyForce = fluidDensity * gravity * submergedArea
        body:applyForce(0, -buoyancyForce)

        -- Drag (simplified)
        local vx, vy = body:getLinearVelocity()
        local dragCoeff = 0.5
        body:applyForce(-dragCoeff * vx, -dragCoeff * vy)
    end
end
```

### Soft bodies (approximation)

True soft-body physics is complex. A common game approximation is to use a chain of distance joints connecting circle bodies:

```lua
function createSoftBody(world, x, y, numPoints, radius, stiffness)
    local bodies = {}
    local joints = {}

    -- Create circle bodies in a line
    for i = 0, numPoints - 1 do
        local body = love.physics.newBody(world, x + i * radius * 2, y, "dynamic")
        local shape = love.physics.newCircleShape(radius)
        local fixture = love.physics.newFixture(body, shape, 1)
        fixture:setFriction(0.3)
        fixture:setRestitution(0.3)
        table.insert(bodies, body)
    end

    -- Connect with distance joints
    for i = 1, #bodies - 1 do
        local j = love.physics.newDistanceJoint(
            bodies[i], bodies[i+1],
            bodies[i]:getX(), bodies[i]:getY(),
            bodies[i+1]:getX(), bodies[i+1]:getY(),
            false
        )
        j:setLength(radius * 2)
        j:setStiffness(stiffness)
        j:setDamping(1)
        table.insert(joints, j)
    end

    return bodies, joints
end
```

### Custom collision filtering with user data

Attach Lua tables to fixtures and bodies for game-specific logic:

```lua
local player = {health = 100, score = 0}

local playerBody = love.physics.newBody(world, 100, 100, "dynamic")
local playerShape = love.physics.newCircleShape(15)
local playerFixture = love.physics.newFixture(playerBody, playerShape, 1)
playerFixture:setUserData(player)

function beginContact(a, b, contact)
    local udA = a:getUserData()
    local udB = b:getUserData()

    if udA and udB then
        -- Both fixtures have user data — handle game logic
        if udA.type == "bullet" and udB.type == "enemy" then
            -- Bullet hit enemy!
            udB.health = udB.health - 25
            udA.body:destroy()  -- Destroy the bullet
        end
    end
end
```

### Continuous physics and the "bullet" flag

We covered this in Chapter 8, but here's a deeper look at when to use it:

- **Use CCD** for: bullets, fast projectiles, thin platforms, any object moving faster than its own size per frame
- **Don't use CCD** for: normal-speed objects (wastes computation)

The cost of CCD is roughly 2-3x the cost of normal collision detection for that body. Use it sparingly.

### Time of impact (TOI)

Box2D can compute the time of impact — the exact moment when two moving objects will first collide. This is used internally for CCD but can also be used for gameplay logic:

```lua
-- Not a direct API call, but the concept:
-- If a bullet is moving at 1000 m/s toward a target 50m away,
-- TOI = 50/1000 = 0.05 seconds
-- You can use this to predict where the target will be
```

### Gravity scales per body

Individual bodies can have their own gravity scale:

```lua
body:setGravityScale(0)   -- No gravity (floats)
body:setGravityScale(2)   -- Double gravity (heavy feeling)
body:setGravityScale(-1)  -- Anti-gravity (floats up)
```

This is useful for:
- Floating platforms (gravity scale 0)
- Heavy objects (gravity scale 2)
- Bubbles or balloons (negative gravity scale)
- Low-gravity environments (gravity scale 0.3)

### Damping: linear and angular

Box2D supports velocity damping that naturally slows objects:

```lua
body:setLinearDamping(0.5)   -- Linear velocity decays exponentially
body:setAngularDamping(0.5)  -- Angular velocity decays exponentially
```

The damping model is:
```
v(t) = v₀ * e^(-damping * t)
```

This is exponential decay — velocity halves every `ln(2)/damping` seconds. With damping 0.5, velocity halves every ~1.4 seconds.

### Exercise 12

Build a simple "blob" physics object: a central body connected to 8 surrounding bodies by distance joints with stiffness and damping. The blob should deform when hitting a wall and spring back to its circular shape.

<details>
<summary>Solution</summary>

```lua
function createBlob(world, x, y, numPoints, radius, stiffness, damping)
    local bodies = {}
    local joints = {}

    -- Center body
    local center = {}
    center.body = love.physics.newBody(world, x, y, "dynamic")
    center.shape = love.physics.newCircleShape(radius * 0.8)
    center.fixture = love.physics.newFixture(center.body, center.shape, 2)
    center.fixture:setFriction(0.5)
    center.fixture:setRestitution(0.3)
    table.insert(bodies, center)

    -- Surrounding bodies
    for i = 0, numPoints - 1 do
        local angle = 2 * math.pi * i / numPoints
        local bx = x + radius * math.cos(angle)
        local by = y + radius * math.sin(angle)

        local b = {}
        b.body = love.physics.newBody(world, bx, by, "dynamic")
        b.shape = love.physics.newCircleShape(radius * 0.5)
        b.fixture = love.physics.newFixture(b.body, b.shape, 1)
        b.fixture:setFriction(0.5)
        b.fixture:setRestitution(0.3)
        table.insert(bodies, b)

        -- Distance joint from center to this point
        local j = love.physics.newDistanceJoint(
            center.body, b.body,
            x, y, bx, by,
            false
        )
        j:setLength(radius)
        j:setStiffness(stiffness)
        j:setDamping(damping)
        table.insert(joints, j)

        -- Distance joint between adjacent outer points (for structural integrity)
        if i > 0 then
            local prev = bodies[#bodies - 1]  -- previous outer body
            local j2 = love.physics.newDistanceJoint(
                prev.body, b.body,
                prev.body:getX(), prev.body:getY(),
                bx, by,
                false
            )
            j2:setLength(radius * 2 * math.sin(math.pi / numPoints))
            j2:setStiffness(stiffness * 0.5)
            j2:setDamping(damping * 0.5)
            table.insert(joints, j2)
        end
    end

    -- Close the loop
    if numPoints > 2 then
        local first = bodies[2]  -- first outer body
        local last = bodies[#bodies]  -- last outer body
        local j = love.physics.newDistanceJoint(
            first.body, last.body,
            first.body:getX(), first.body:getY(),
            last.body:getX(), last.body:getY(),
            false
        )
        j:setLength(radius * 2 * math.sin(math.pi / numPoints))
        j:setStiffness(stiffness * 0.5)
        j:setDamping(damping * 0.5)
        table.insert(joints, j)
    end

    return bodies, joints
end
```

When this blob hits a wall, the outer bodies deform inward while the center maintains momentum. The springs pull everything back to the circular shape. Adjust `stiffness` for a stiff blob (like a ball) or a soft blob (like a water droplet).
</details>

---

## 14. Appendix A — Formulae Quick Reference

### Kinematics

| Equation | Formula |
|----------|---------|
| Velocity | `v = v₀ + a*t` |
| Position | `p = p₀ + v₀*t + ½*a*t²` |
| Velocity² | `v² = v₀² + 2*a*(p - p₀)` |
| Average velocity | `v_avg = (v₀ + v) / 2` |

### Dynamics

| Equation | Formula |
|----------|---------|
| Newton's 2nd Law | `F = m*a` |
| Weight | `W = m*g` |
| Momentum | `p = m*v` |
| Impulse | `J = F*Δt = Δp` |
| Kinetic Energy | `KE = ½*m*v²` |
| Potential Energy | `PE = m*g*h` |
| Work | `W = F*d*cos(θ)` |
| Power | `P = W/t = F*v` |

### Collision

| Equation | Formula |
|----------|---------|
| Coefficient of restitution | `e = |v₂' - v₁'| / |v₁ - v₂|` |
| Impulse magnitude | `j = -(1+e) * (v_rel · n) / (1/m₁ + 1/m₂)` |
| Perfectly elastic KE conserved | `½m₁v₁² + ½m₂v₂² = ½m₁v₁'² + ½m₂v₂'²` |
| Perfectly inelastic | `v' = (m₁v₁ + m₂v₂) / (m₁ + m₂)` |

### Gravity

| Equation | Formula |
|----------|---------|
| Newton's law | `F = G*m₁*m₂ / r²` |
| Gravitational PE | `PE = -G*m₁*m₂ / r` |
| Escape velocity | `v_esc = sqrt(2*G*M/r)` |
| Orbital velocity | `v_orb = sqrt(G*M/r)` |
| Orbital period | `T = 2π*sqrt(r³/(G*M))` |

### Springs

| Equation | Formula |
|----------|---------|
| Hooke's Law | `F = -k*x` |
| Spring PE | `PE = ½*k*x²` |
| Damped spring | `F = -k*x - c*v` |
| Natural frequency | `ω = sqrt(k/m)` |
| Damping ratio | `ζ = c / (2*sqrt(k*m))` |

### Circular Motion

| Equation | Formula |
|----------|---------|
| Centripetal acceleration | `a = v²/r = ω²*r` |
| Centripetal force | `F = m*v²/r` |
| Angular velocity | `ω = Δθ/Δt` |
| Period | `T = 2π/ω` |

### Projectile Motion

| Equation | Formula |
|----------|---------|
| Range | `R = v₀²*sin(2θ)/g` |
| Max height | `H = v₀²*sin²(θ)/(2g)` |
| Time of flight | `T = 2*v₀*sin(θ)/g` |
| Trajectory | `y = x*tan(θ) - g*x²/(2*v₀²*cos²(θ))` |

### Fluid (Buoyancy)

| Equation | Formula |
|----------|---------|
| Buoyancy force | `F_b = ρ*g*V_displaced` |
| Archimedes' principle | Buoyant force = weight of displaced fluid |

---

## 15. Appendix B — LÖVE2D love.physics API Reference

### World

```lua
world = love.physics.newWorld(gx, gy, allowSleep)
world:update(dt, velocityIterations, positionIterations)
world:setCallbacks(beginContact, endContact, preSolve, postSolve)
world:queryPoint(x, y)
world:queryAABB(x1, y1, x2, y2)
world:queryShape(shape, x, y, angle)
world:rayCast(x1, y1, x2, y2, callback)
world:getProfile()
world:setGravity(gx, gy)
world:getGravity()
world:setMeter(meter)  -- pixels per meter
world:getMeter()
```

### Body

```lua
body = love.physics.newBody(world, x, y, type)
body:setType(type)           -- "static", "dynamic", "kinematic"
body:setPosition(x, y)
body:getPosition()
body:setAngle(angle)         -- radians
body:getAngle()
body:setLinearVelocity(vx, vy)
body:getLinearVelocity()
body:setAngularVelocity(w)
body:getAngularVelocity()
body:applyForce(fx, fy, px, py)
body:applyLinearImpulse(ix, iy, px, py)
body:applyTorque(torque)
body:applyAngularImpulse(impulse)
body:getMass()
body:getMassData()
body:setMassData(data)
body:setLinearDamping(d)
body:getLinearDamping()
body:setAngularDamping(d)
body:getAngularDamping()
body:setGravityScale(s)
body:getGravityScale()
body:setBullet(enabled)
body:isBullet()
body:setAwake(enabled)
body:isAwake()
body:isSleeping()
body:setFixedRotation(enabled)
body:isFixedRotation()
body:destroy()
body:getWorldPoints(...)
body:getWorldPoint(x, y)
body:getLocalPoint(x, y)
body:getWorldVector(x, y)
body:getLocalVector(x, y)
body:getX(), body:getY()
body:getLinearVelocityFromWorldPoint(x, y)
body:getLinearVelocityFromLocalPoint(x, y)
```

### Fixture

```lua
fixture = love.physics.newFixture(body, shape, density)
fixture:setDensity(d)
fixture:getDensity()
fixture:setFriction(f)
fixture:getFriction()
fixture:setRestitution(r)
fixture:getRestitution()
fixture:setRestitutionThreshold(v)
fixture:getRestitutionThreshold()
fixture:setSensor(isSensor)
fixture:isSensor()
fixture:setFilterData(categoryBits, maskBits, groupIndex)
fixture:getFilterData()
fixture:setUserData(data)
fixture:getUserData()
fixture:getBody()
fixture:getShape()
fixture:destroy()
fixture:testPoint(x, y)
```

### Shapes

```lua
shape = love.physics.newCircleShape(radius)
shape = love.physics.newRectangleShape(w, h)
shape = love.physics.newRectangleShape(w, h, cx, cy, angle)
shape = love.physics.newEdgeShape(x1, y1, x2, y2)
shape = love.physics.newChainShape(loop, points)
shape = love.physics.newPolygonShape(points)
shape:getPoints()
shape:getType()
shape:getRadius()  -- for circles
shape:getChildCount()  -- for polygons
shape:getChild(index)  -- for chains/polygons
```

### Joints

```lua
-- Distance
j = love.physics.newDistanceJoint(bodyA, bodyB, ax1, ay1, ax2, ay2, collideConnected)
j:setLength(len)
j:setStiffness(k)
j:setDamping(d)
j:setFrequencyHz(hz)
j:setDampingRatio(ratio)

-- Revolute
j = love.physics.newRevoluteJoint(bodyA, bodyB, anchorX, anchorY, collideConnected)
j:enableLimit(enabled)
j:setLowerAngle(angle)
j:setUpperAngle(angle)
j:enableMotor(enabled)
j:setMotorSpeed(speed)
j:setMaxMotorTorque(torque)

-- Prismatic
j = love.physics.newPrismaticJoint(bodyA, bodyB, anchorX, anchorY, axisX, axisY, collideConnected)
j:enableLimit(enabled)
j:setLowerLimit(limit)
j:setUpperLimit(limit)
j:enableMotor(enabled)
j:setMotorSpeed(speed)
j:setMaxMotorForce(force)

-- Pulley
j = love.physics.newPulleyJoint(bodyA, bodyB, ax1, ay1, ax2, ay2, bx1, by1, bx2, by2, ratio, collideConnected)

-- Gear
j = love.physics.newGearJoint(jointA, jointB, ratio)

-- Motor (generic)
j = love.physics.newMotorJoint(bodyA, bodyB, collideConnected)
j:setMaxForce(force)
j:setMaxTorque(torque)
j:setCorrectionFactor(factor)

-- Weld
j = love.physics.newWeldJoint(bodyA, bodyB, anchorX, anchorY, collideConnected)

-- Rope
j = love.physics.newRopeJoint(bodyA, bodyB, ax1, ay1, ax2, ay2, maxLength, collideConnected)

-- Mouse
j = love.physics.newMouseJoint(body, x, y)
j:setTarget(x, y)
j:setMaxForce(force)

-- Angle
j = love.physics.newAngleJoint(bodyA, bodyB, collideConnected)
j:enableLimit(enabled)
j:setLowerLimit(angle)
j:setUpperLimit(angle)

-- Fixed
j = love.physics.newFixedJoint(bodyA, bodyB, x, y, collideConnected)

-- Wheel
j = love.physics.newWheelJoint(bodyA, bodyB, anchorX, anchorY, axisX, axisY, collideConnected)
j:setMotorSpeed(speed)
j:setMaxMotorTorque(torque)
j:setSpringFrequencyHz(hz)
j:setSpringDampingRatio(ratio)

-- Joint utility methods
j:destroy()
j:getBodyA(), j:getBodyB()
j:getCollideConnected()
j:setCollideConnected(enabled)
j:getReactionForce(inverseDt)
j:getReactionTorque(inverseDt)
```

### Contact

```lua
contact:getNormal()
contact:getNormalImpulses()
contact:getTangentImpulses()
contact:getFriction()
contact:setFriction(f)
contact:getRestitution()
contact:setRestitution(r)
contact:getTangentSpeed()
contact:setTangentSpeed(speed)
contact:isEnabled()
contact:setEnabled(enabled)
contact:getWorldManifold()  -- returns points, normals, depths
```

---

## 16. Appendix C — Complete Example Projects

### Project 1: Platformer Controller

```lua
-- main.lua: A complete platformer controller using love.physics
local world, player, ground
local GRAVITY = 9.81 * 30
local MOVE_SPEED = 200
local JUMP_FORCE = 400
local playerWidth, playerHeight = 20, 30

function love.load()
    world = love.physics.newWorld(0, GRAVITY, true)

    -- Ground
    ground = love.physics.newBody(world, 400, 550, "static")
    local groundShape = love.physics.newRectangleShape(800, 20)
    local groundFixture = love.physics.newFixture(ground, groundShape, 1)
    groundFixture:setFriction(0.6)

    -- Player
    player = {}
    player.body = love.physics.newBody(world, 100, 400, "dynamic")
    player.shape = love.physics.newRectangleShape(playerWidth, playerHeight)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    player.fixture:setFriction(0.6)
    player.fixture:setRestitution(0.1)
    player.fixture:setUserData("player")
    player.width = playerWidth
    player.height = playerHeight
    player.grounded = false
    player.canJump = true

    -- Set fixed rotation so player doesn't tumble
    player.body:setFixedRotation(true)

    -- Input state
    keys = {}

    world:setCallbacks(beginContact, endContact)
end

function beginContact(a, b, contact)
    local uA, uB = a:getUserData(), b:getUserData()
    if uA == "player" or uB == "player" then
        -- Check if contact is at the bottom of the player
        local fixture = (uA == "player") and a or b
        local otherFixture = (uA == "player") and b or a
        if fixture == player.fixture then
            local nx, ny = contact:getNormal()
            -- If normal points upward (from ground to player), player is grounded
            if ny < -0.5 then
                player.grounded = true
            end
        end
    end
end

function endContact(a, b, contact)
    local uA, uB = a:getUserData(), b:getUserData()
    if uA == "player" or uB == "player" then
        player.grounded = false
    end
end

function love.update(dt)
    -- Fixed timestep
    world:update(dt)

    -- Horizontal movement
    local vx = 0
    if keys["right"] or keys["d"] then vx = MOVE_SPEED end
    if keys["left"] or keys["a"] then vx = -MOVE_SPEED end

    -- Apply horizontal force (with some acceleration feel)
    local currentVx = player.body:getLinearVelocity()
    local targetVx = vx
    local force = (targetVx - currentVx) * player.body:getMass() * 10
    player.body:applyForce(force, 0)

    -- Jump
    if (keys["space"] or keys["up"] or keys["w"]) and player.grounded then
        player.body:applyLinearImpulse(0, -JUMP_FORCE)
        player.grounded = false
    end

    -- Cap velocity (prevent too-fast falling)
    local vx, vy = player.body:getLinearVelocity()
    if vy > 500 then vy = 500 end
    player.body:setLinearVelocity(vx, vy)
end

function love.keypressed(key)
    keys[key] = true
end

function love.keyreleased(key)
    keys[key] = false
end

function love.draw()
    -- Ground
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.polygon("fill", ground:getWorldPoints(groundShape:getPoints()))

    -- Player
    love.graphics.setColor(0, 0.8, 1)
    local px, py = player.body:getPosition()
    love.graphics.rectangle("fill", px - playerWidth/2, py - playerHeight/2, playerWidth, playerHeight)

    -- Ground indicator
    love.graphics.setColor(1, 1, 0)
    if player.grounded then
        love.graphics.print("GROUNDED", px - 30, py - 40)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Velocity: " .. string.format("%.0f, %.0f", player.body:getLinearVelocity()), 10, 10)
end
```

### Project 2: Simple Physics Puzzle (Angry Birds Lite)

```lua
-- main.lua: Launch projectiles at structures
local world
local projectile
local structures = {}
local trail = {}
local launching = false
local launchPower = 500
local launchAngle = 0

function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Ground
    local ground = love.physics.newBody(world, 400, 550, "static")
    local groundShape = love.physics.newRectangleShape(800, 20)
    love.physics.newFixture(ground, groundShape, 1)

    -- Structure: stacked boxes
    local function createStructure(x, y)
        local s = {}
        -- Base
        for i = -2, 2 do
            local b = love.physics.newBody(world, x + i * 30, y, "dynamic")
            local shape = love.physics.newRectangleShape(25, 25)
            local f = love.physics.newFixture(b, shape, 1)
            f:setFriction(0.4)
            f:setRestitution(0.2)
            table.insert(s, b)
        end
        -- Second layer (offset)
        for i = -1, 1 do
            local b = love.physics.newBody(world, x + i * 30, y - 30, "dynamic")
            local shape = love.physics.newRectangleShape(25, 25)
            local f = love.physics.newFixture(b, shape, 1)
            f:setFriction(0.4)
            f:setRestitution(0.2)
            table.insert(s, b)
        end
        -- Top
        local b = love.physics.newBody(world, x, y - 60, "dynamic")
        local shape = love.physics.newRectangleShape(25, 25)
        local f = love.physics.newFixture(b, shape, 1)
        f:setFriction(0.4)
        f:setRestitution(0.2)
        table.insert(s, b)
        return s
    end

    table.insert(structures, createStructure(500, 480))
    table.insert(structures, createStructure(600, 480))

    -- Projectile
    projectile = {}
    projectile.body = love.physics.newBody(world, 100, 450, "dynamic")
    projectile.shape = love.physics.newCircleShape(10)
    projectile.fixture = love.physics.newFixture(projectile.body, projectile.shape, 2)
    projectile.fixture:setRestitution(0.4)
    projectile.fixture:setFriction(0.2)
    projectile.radius = 10
    projectile.active = false

    world:setCallbacks(beginContact)
end

function beginContact(a, b, contact)
    -- Could track score based on structure destruction
end

function love.mousepressed(x, y, button)
    if button == 1 and not launching then
        launching = true
        -- Calculate angle toward mouse
        local dx = x - projectile.body:getX()
        local dy = -(y - projectile.body:getY())  -- flip y
        launchAngle = math.atan2(dy, dx)
        projectile.body:setLinearVelocity(0, 0)
        projectile.body:setPosition(100, 450)
        projectile.active = true
        trail = {}
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and launching then
        launching = false
        -- Launch with calculated power
        local dx = x - 100
        local dy = -(y - 450)
        local power = math.min(math.sqrt(dx^2 + dy^2) * 3, launchPower)
        local angle = math.atan2(dy, dx)
        projectile.body:setLinearVelocity(
            power * math.cos(angle),
            power * math.sin(angle)
        )
    end
end

function love.update(dt)
    world:update(dt)

    if projectile.active then
        table.insert(trail, {projectile.body:getX(), projectile.body:getY()})
        if #trail > 100 then table.remove(trail, 1) end

        -- Check if projectile is slow and grounded (reset)
        local vx, vy = projectile.body:getLinearVelocity()
        if math.sqrt(vx^2 + vy^2) < 5 and projectile.body:getY() > 500 then
            projectile.active = false
            projectile.body:setLinearVelocity(0, 0)
            projectile.body:setPosition(100, 450)
            trail = {}
        end
    end
end

function love.draw()
    -- Trail
    love.graphics.setColor(0.8, 0.8, 0.8)
    for i = 1, #trail - 1 do
        love.graphics.line(trail[i][1], trail[i][2], trail[i+1][1], trail[i+1][2])
    end

    -- Structures
    love.graphics.setColor(0.8, 0.4, 0.2)
    for _, struct in ipairs(structures) do
        for _, b in ipairs(struct) do
            local x, y = b:getPosition()
            local angle = b:getAngle()
            love.graphics.push()
            love.graphics.translate(x, y)
            love.graphics.rotate(angle)
            love.graphics.rectangle("fill", -12.5, -12.5, 25, 25)
            love.graphics.pop()
        end
    end

    -- Projectile
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", projectile.body:getX(), projectile.body:getY(), projectile.radius)

    -- Launch indicator (while aiming)
    if launching then
        local px, py = projectile.body:getPosition()
        love.graphics.setColor(1, 1, 0)
        love.graphics.line(px, py, px + 50 * math.cos(launchAngle), py - 50 * math.sin(launchAngle))
    end

    love.graphics.setColor(1, 1, 1)
end
```

---

## Final Words

Physics in games is an approximation of reality, and that's its beauty. You don't need to simulate every atom — you need to simulate enough that the player *believes* the world is real.

Here's what I want you to take away from this book:

1. **Vectors are everything.** Every position, velocity, force, and impulse is a vector. Understand vector math and everything else follows.

2. **F = ma is the engine.** Every simulation step is just computing forces, dividing by mass to get acceleration, and integrating to get velocity and position.

3. **Box2D handles the hard parts.** Collision detection, constraint solving, warm starting — you don't need to implement these from scratch. But understanding what happens under the hood makes you a better debugger and tuner.

4. **Tuning is an art.** Restitution, friction, density, gravity scale — these are dials you turn until things *feel* right. There's no formula for "fun." You develop an intuition through experimentation.

5. **Break things.** Set restitution to 5.0. Make gravity negative. Remove friction entirely. See what happens. Understanding comes from seeing what goes wrong.

Now go make something move.

---

*"Physics is like sex: sure, it may give some practical results, but that's not why we do it."*
— Richard P. Feynman (paraphrased)

---

*End of The Feynman Guide to LÖVE2D Physics*
