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
18. [Appendix D — Derivations from First Principles](#18-appendix-d)
19. [Appendix E — Further Reading (vetted links per chapter)](#19-appendix-e)
20. [Appendix F — Terminology Glossary](#20-appendix-f)

---

## Companion App — Project Structure

Every chapter in this book has a runnable companion: the *Feynman Physics* LÖVE2D app, one interactive demo per chapter. This is how the project is organized so you can read a chapter and poke at its demo at the same time.

```
physics/
├── main.lua            # Bootstrap: fonts, chapter dispatch, LOVE callbacks
├── conf.lua            # LÖVE2D window config (1024×768, 30 px/metre)
├── vec2.lua            # The vector library built in Chapter 1
├── utils.lua           # Shared helpers: fmt, drawVector, drawTextBox,
│                       #   createGround, createWall, createBall, FIXED_DT
├── chapters/
│   ├── chapter1.lua    # Vectors
│   ├── chapter2.lua    # Newton's Laws (F = ma in the game loop)
│   ├── chapter3.lua    # First love.physics world, restitution
│   ├── chapter4.lua    # Bodies, shapes, fixtures
│   ├── chapter5.lua    # Projectile motion
│   ├── chapter6.lua    # Dynamics — F = ma with force visualization
│   ├── chapter7.lua    # Gravity, friction, restitution
│   ├── chapter8.lua    # Collision detection maths
│   ├── chapter9.lua    # Collision response and impulse
│   ├── chapter10.lua   # Joints and constraints
│   ├── chapter11.lua   # Raycasting, sensors, queries
│   ├── chapter12.lua   # Performance, warm starting, sleeping
│   └── chapter13.lua   # Springs (Hooke's law)
└── physics_book.md     # This book
```

**How the modules fit together.** Each chapter is a plain Lua module that returns a table with the same interface:

- `init()` — creates the Box2D `world` (the global each chapter owns), builds all bodies, fixtures, joints, and registers any contact callbacks.
- `update()` — steps the world forward. `main.lua` calls it at a **fixed timestep** (`FIXED_DT = 1/60`) accumulated against the real frame delta, so physics is deterministic regardless of frame rate.
- `draw()` — renders the scene, the live-values panel, and the Feynman notes.
- `mousepressed(x, y, button)` — optional, chapter-specific interaction.
- `keypressed(key)` — optional, chapter-specific keys.

`main.lua` is just the dispatcher: it loads all thirteen chapters, forwards the LOVE callbacks (`load`, `update`, `draw`, `keypressed`, `mousepressed`) to the active chapter, and draws the persistent header and control hints. `utils.lua` holds the shared body factories and drawing helpers so chapters stay short and focused on their single idea.

**Running it.** From the `physics/` directory, run `love .`. Controls:

```
1-9,0   switch to chapters 1-10
-  =    chapters 11 and 12
Enter   chapter 13
SPACE   reset the current chapter
ESC     quit
```

Run the app, then read the corresponding chapter. Change a number, run again, watch what breaks — that loop *is* the book.

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

## 7. Chapter 6 — Dynamics: F = ma with Forces Visualization

### The force-acceleration chain

Every game physics engine follows this exact sequence every frame:

```
Force → Acceleration → Velocity → Position
```

This is Newton's second law in action. The net force on an object determines its acceleration, which changes its velocity, which changes its position.

### Applying forces in LÖVE2D

Forces are applied to dynamic bodies using `body:applyForce(fx, fy)`. The force is in Newtons (pixels/s² * kg in our pixel-based units).

```lua
-- Apply a continuous force (like gravity or a thruster)
body:applyForce(fx, fy)

-- Apply an impulse (like a jump or a kick)
body:applyLinearImpulse(ix, iy)
```

### Dummy value walkthrough — one frame with a rightward force

Box: mass=1kg, at (200, 650), velocity (0, 0)
Applied force: F_right = 3000 N
Gravity: F_gravity = 1 * 294.3 = 294.3 N downward
Normal force (from ground): F_normal = 294.3 N upward (balances gravity)
Net force: F_net = (3000, 0) — only horizontal matters
Acceleration: a = F_net/m = (3000/1, 0) = (3000, 0) px/s²
After 1/60s: vx = 0 + 3000/60 = 50 px/s
After 1/60s: x = 200 + 50/60 = 200.83 px

### The yellow arrow shows F_net, the red arrow shows F_applied,
the blue arrow shows F_gravity, and the green arrow shows F_normal.

### Exercise 6

Create a scene with a box on a frictionless surface. Apply a constant force and observe the acceleration. Then add friction and observe how the net force changes.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Frictionless ground
    local ground = love.physics.newBody(world, 400, 550, "static")
    local groundShape = love.physics.newRectangleShape(800, 20)
    local groundFixture = love.physics.newFixture(ground, groundShape, 1)
    groundFixture:setFriction(0.0)  -- No friction!

    -- Box
    local box = {}
    box.body = love.physics.newBody(world, 200, 500, "dynamic")
    box.shape = love.physics.newRectangleShape(40, 40)
    box.fixture = love.physics.newFixture(box.body, box.shape, 1)
    box.fixture:setFriction(0.0)  -- No friction!
    box.radius = 0
end

function love.update(dt)
    -- Apply a constant rightward force
    box.body:applyForce(3000, 0)
    world:update(dt)
end

function love.draw()
    -- Ground
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.polygon("fill", groundBody:getWorldPoints(groundShape:getPoints()))

    -- Box
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.rectangle("fill", box.body:getX() - 20, box.body:getY() - 20, 40, 40)
    love.graphics.setColor(1, 1, 1)
end
```

With no friction, the box accelerates continuously to the right. The force never stops, so the speed keeps increasing. In a real game, you'd add drag or a maximum speed to prevent infinite acceleration.
</details>

---

## 8. Chapter 7 — Gravity, Friction, and Restitution

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

### Exercise 7

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

## 9. Chapter 8 — Collision Detection: The Maths Under the Hood

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

### Exercise 8

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

## 10. Chapter 9 — Collision Response and Impulse

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

### Exercise 9

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

## 11. Chapter 10 — Joints and Constraints

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
joint:setLowerAngle(-math.rad(45))  -- Lower angle limit
joint:setUpperAngle(math.rad(45))   -- Upper angle limit
```

### Prismatic joint — the slider

```lua
local joint = love.physics.newPrismaticJoint(
    bodyA, bodyB,
    anchorX, anchorY,     -- Anchor point (world coordinates)
    axisX, axisY,         -- Axis of motion (normalized)
    collideConnected
)

-- Optional: motor
joint:enableMotor(true)
joint:setMotorSpeed(1.0)     -- Linear speed in meters/s
joint:setMaxMotorForce(100)  -- Maximum force in N

-- Optional: limits
joint:enableLimit(true)
joint:setLowerLimit(-5.0)    -- Minimum distance along axis
joint:setUpperLimit(5.0)     -- Maximum distance along axis
```

### Dummy value walkthrough — Pendulum:

Pivot at (512, 100), bob at (512, 300)
Arm length = 200 pixels (≈6.67 meters at 30 px/m)
Period T = 2π√(L/g) = 2π√(6.67/9.81) ≈ 2π*0.824 ≈ 5.18 seconds
The bob swings back and forth with this period
Stiffness=10 controls how rigid the arm is
Damping=0.5 causes the swing to gradually die out

### Exercise 10

Create a double pendulum — two revolute joints connected in series. Observe how the motion becomes chaotic for certain initial conditions.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Anchor point (static)
    local anchor = love.physics.newBody(world, 512, 50, "static")

    -- First arm (dynamic)
    local arm1 = {}
    arm1.body = love.physics.newBody(world, 512, 250, "dynamic")
    arm1.shape = love.physics.newRectangleShape(10, 200)
    arm1.fixture = love.physics.newFixture(arm1.body, arm1.shape, 1)
    arm1.fixture:setFriction(0.3)
    arm1.fixture:setRestitution(0.2)
    arm1.radius = 0

    -- First revolute joint (anchor to arm1)
    local joint1 = love.physics.newRevoluteJoint(
        anchor, arm1.body,
        512, 50,  -- anchor on anchor body
        512, 250, -- anchor on arm1 body
        false
    )

    -- Second arm (dynamic)
    local arm2 = {}
    arm2.body = love.physics.newBody(world, 512, 450, "dynamic")
    arm2.shape = love.physics.newRectangleShape(10, 200)
    arm2.fixture = love.physics.newFixture(arm2.body, arm2.shape, 1)
    arm2.fixture:setFriction(0.3)
    arm2.fixture:setRestitution(0.2)
    arm2.radius = 0

    -- Second revolute joint (arm1 to arm2)
    local joint2 = love.physics.newRevoluteJoint(
        arm1.body, arm2.body,
        512, 250, -- anchor on arm1 body
        512, 450, -- anchor on arm2 body
        false
    )
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    -- Draw arms
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", 507, 50, 10, 200)  -- anchor (static)
    love.graphics.setColor(0.7, 0.7, 1)
    love.graphics.rectangle("fill", arm1.body:getX() - 5, arm1.body:getY(), 10, 200)
    love.graphics.setColor(0.7, 1, 0.7)
    love.graphics.rectangle("fill", arm2.body:getX() - 5, arm2.body:getY(), 10, 200)
    love.graphics.setColor(1, 1, 1)
end
```

A double pendulum is a classic example of chaotic motion. Small changes in initial conditions lead to dramatically different trajectories. This is why weather prediction is so difficult — the atmosphere is a chaotic system.
</details>

---

## 12. Chapter 11 — Raycasting, Sensors, and Queries

### Raycasting concepts

A ray is defined by two points (start and end). Box2D returns the first fixture hit, plus:
- Hit point (x, y)
- Collision normal (direction the surface faces)
- Fraction (how far along the ray the hit occurred, 0-1)

Raycasting is used for: line of sight, shooting, visibility checks.

### Sensor concepts

A sensor is a fixture that detects overlap but doesn't collide. Used for: trigger zones, pickup detection, proximity alerts.

### Dummy value walkthrough — Ray cast:

Ray from (100, 384) to (900, 384) — horizontal line at y=384
If Box 1 is at (300, 300) with size 30x30:
  Box spans from (285, 285) to (315, 315)
  Ray at y=384 misses the box (384 > 315)
  Result: no hit, no ray hits

If we move the ray to y=300:
  Ray enters Box 1 at x=285, exits at x=315
  Hit point: (285, 300)
  Normal: (-1, 0) — the left face of the box
  Fraction: (285-100)/(900-100) = 185/800 = 0.231

### Dummy value walkthrough — Sensor:

Sensor is a circle at (512, 384) with radius 80
Sensor spans from (432, 304) to (592, 464)
Box 1 at (300, 300) with size 30x30:
  Box center at (300, 300), box spans (285,285)-(315,315)
  Distance from sensor center to box center:
    sqrt((512-300)² + (384-300)²) = sqrt(44944+7056) = sqrt(52000) ≈ 228
  228 > 80 → Box 1 is NOT in the sensor zone
If Box 1 moves to (500, 384):
  Distance = sqrt((512-500)² + (384-384)²) = sqrt(144) = 12
  12 < 80 → Box 1 IS in the sensor zone → "IN SENSOR!" displayed

### Exercise 11

Create a raycaster that shoots toward the mouse cursor. When the ray hits a body, apply a force at the hit point in the direction of the normal. This simulates a "push" effect.

<details>
<summary>Solution</summary>

```lua
function love.mousepressed(x, y, button)
    if button == 1 then
        -- Cast a ray from the center of the screen to the mouse
        local startX, startY = 512, 384
        local dx = x - startX
        local dy = y - startY
        local dist = math.sqrt(dx^2 + dy^2)

        -- Ray cast
        local hit = world:rayCast(startX, startY, x, y,
            function(fixture, hitX, hitY, normal, fraction)
                -- Apply force at the hit point
                local body = fixture:getBody()
                body:applyLinearImpulse(
                    normal.x * 500 * body:getMass(),
                    normal.y * 500 * body:getMass(),
                    hitX, hitY
                )
                return 0  -- Stop at first hit
            end
        )
    end
end
```

The ray cast returns the first fixture hit. We apply an impulse at the hit point in the direction of the collision normal. The force is proportional to the body's mass, so heavier objects are pushed less (they have more inertia).
</details>

---

## 13. Chapter 12 — Performance, Warm Starting, and Tuning

### Warm starting

Box2D remembers impulses from the previous frame and uses them as an initial guess for the solver. This dramatically speeds up convergence.

### Sleeping

Bodies at rest are excluded from simulation until woken by a collision. Huge performance win.

### Fixed timestep

Physics runs at a constant rate regardless of frame rate, ensuring determinism and stability.

### Dummy value walkthrough — 100 boxes stacked:

10 columns × 10 rows = 100 dynamic bodies
Each box: 30x30 pixels, density=1
Mass per box ≈ 30*30*1 = 900 (in Box2D units)
Total mass in scene ≈ 90,000

Profile data (typical values):
  Step time: ~0.1ms for 100 boxes
  Collide time: ~0.05ms (broad-phase eliminates most pairs)
  Solve time: ~0.03ms (warm starting helps convergence)

After the stack settles:
  ~90 bodies go to sleep
  Only ~10 active bodies are simulated
  Step time drops to ~0.02ms (5x faster!)

### Exercise 12

Create a scene with 200 boxes stacked in a 10x20 grid. Observe how warm starting makes the solver converge faster each frame. Then disable warm starting and observe the difference.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Ground
    local ground = love.physics.newBody(world, 400, 550, "static")
    local groundShape = love.physics.newRectangleShape(800, 20)
    local groundFixture = love.physics.newFixture(ground, groundShape, 1)
    groundFixture:setFriction(0.3)
    groundFixture:setRestitution(0.1)

    -- 10x20 grid of boxes
    local cols = 10
    local rows = 20
    local boxW, boxH = 30, 30

    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local x = 300 + col * boxW
            local y = 680 - row * boxH
            local body = love.physics.newBody(world, x, y, "dynamic")
            local shape = love.physics.newRectangleShape(boxW, boxH)
            local fixture = love.physics.newFixture(body, shape, 1)
            fixture:setFriction(0.3)
            fixture:setRestitution(0.1)
        end
    end
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    -- Draw all bodies
    for _, body in ipairs(world:getBodies()) do
        if body:getType() == "dynamic" then
            for _, fixture in ipairs(body:getFixtureList()) do
                local shape = fixture:getShape()
                if shape:getType() == "Rectangle" then
                    local w, h = shape:getDimensions()
                    love.graphics.setColor(0.5, 0.5, 0.8)
                    love.graphics.polygon("fill", body:getWorldPoints(shape:getPoints()))
                end
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
end
```

Warm starting makes the solver converge in fewer iterations. For a stack of 200 boxes, warm starting can reduce the solve time by 3-5x compared to cold starting.
</details>

---

## 14. Chapter 13 — Advanced Topics

### Custom forces: Springs

Hooke's Law: F = -k * x

The spring force is proportional to the displacement from the rest length and points toward the anchor.

### Buoyancy

Buoyancy is the upward force exerted by a fluid on an immersed object. It equals the weight of the fluid displaced by the object.

### Soft bodies

Soft bodies are simulated using chains of distance joints. Each link acts like a small rigid body connected to its neighbors.

### Dummy value walkthrough — Spring:

Mass at (100, 400), anchor at (100, 100)
dx = 0, dy = 300, dist = 300
displacement = 300 - 200 = 100 (spring stretched 100px)
springFx = -50 * 100 * 0/300 = 0 (no horizontal force)
springFy = -50 * 100 * 300/300 = -5000 (upward force)
If vy = 50 (moving down):
  dampFy = -2 * 50 = -100 (upward, opposing motion)
Total: F = (0, -5100) → mass accelerates upward

### Exercise 13

Create a soft body simulation using a chain of distance joints. Add a wind force that pushes the soft body sideways. Observe how the soft body deforms and oscillates.

<details>
<summary>Solution</summary>

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Create a chain of 6 links
    local numLinks = 6
    local linkLength = 20
    local startX, startY = 512, 100

    -- Anchor (static)
    local anchor = love.physics.newBody(world, startX, startY, "static")

    -- Create each link
    local prevBody = anchor
    for i = 1, numLinks do
        local body = love.physics.newBody(world, startX, startY + i * linkLength, "dynamic")
        local shape = love.physics.newCircleShape(8)
        local fixture = love.physics.newFixture(body, shape, 1)
        fixture:setFriction(0.3)
        fixture:setRestitution(0.2)

        -- Distance joint connects this link to the previous one
        local joint = love.physics.newDistanceJoint(
            prevBody, body,
            startX, startY + (i-1) * linkLength,
            startX, startY + i * linkLength,
            false
        )
        joint:setLength(linkLength)
        joint:setStiffness(5)
        joint:setDamping(1)

        prevBody = body
    end
end

function love.update(dt)
    -- Apply wind force to all dynamic bodies
    for _, body in ipairs(world:getBodies()) do
        if body:getType() == "dynamic" then
            body:applyForce(100, 0)  -- Wind pushing right
        end
    end
    world:update(dt)
end

function love.draw()
    for _, body in ipairs(world:getBodies()) do
        if body:getType() == "dynamic" then
            love.graphics.setColor(0.7, 1, 0.7)
            love.graphics.circle("fill", body:getX(), body:getY(), 8)
        end
    end
    love.graphics.setColor(1, 1, 1)
end
```

The wind force pushes the soft body to the right. The distance joints resist stretching, causing the body to deform and oscillate. The damping in the joints causes the oscillations to gradually die out.
</details>

---

## Appendix A — Formulae Quick Reference

### Vectors

| Operation | Formula |
|-----------|---------|
| Magnitude | `|v| = sqrt(vx² + vy²)` |
| Dot product | `a · b = ax*bx + ay*by` |
| Cross product (2D) | `a × b = ax*by - ay*bx` |
| Normalize | `v̂ = v / |v|` |
| Angle | `θ = atan2(vy, vx)` |

### Newton's Laws

| Law | Formula |
|-----|---------|
| Second Law | `F = m * a` |
| Gravity | `F = m * g` |
| Drag | `F_drag = -k * |v| * v` |
| Spring (Hooke's Law) | `F = -k * x` |

### Kinematics

| Equation | Formula |
|----------|---------|
| Velocity | `v = v₀ + a * t` |
| Position | `p = p₀ + v₀ * t + 0.5 * a * t²` |
| Velocity² | `v² = v₀² + 2 * a * (p - p₀)` |
| Range | `R = v₀² * sin(2θ) / g` |
| Max Height | `H = v₀² * sin²(θ) / (2g)` |
| Time of Flight | `T = 2 * v₀ * sin(θ) / g` |

### Collision

| Concept | Formula |
|---------|---------|
| Impulse | `j = -(1+e) * (v_rel · n) / (1/m₁ + 1/m₂)` |
| Restitution | `e = |v_separation| / |v_approach|` |
| Energy lost | `ΔKE = 0.5 * (1 - e²) * reduced_mass * v_rel²` |

### Pendulum

| Quantity | Formula |
|----------|---------|
| Period | `T = 2π√(L/g)` |
| Angular frequency | `ω = sqrt(g/L)` |

---

## Appendix B — LÖVE2D love.physics API Reference

### World

| Method | Description |
|--------|-------------|
| `love.physics.newWorld(gx, gy, allowSleep)` | Create a new physics world |
| `world:update(dt, velocityIterations, positionIterations)` | Step the simulation |
| `world:setCallbacks(beginContact, endContact, preSolve, postSolve)` | Register collision callbacks |
| `world:rayCast(x1, y1, x2, y2, callback)` | Cast a ray and return hit info |
| `world:getProfile()` | Get profiling data for the current step |
| `world:destroy()` | Destroy the world and all bodies |

### Body

| Method | Description |
|--------|-------------|
| `love.physics.newBody(world, x, y, type)` | Create a body (static/dynamic/kinematic) |
| `body:getPosition()` | Get body position `(x, y)` |
| `body:setPosition(x, y)` | Set body position |
| `body:getX()` / `body:getY()` | Get individual coordinates |
| `body:getLinearVelocity()` | Get velocity `(vx, vy)` |
| `body:setLinearVelocity(vx, vy)` | Set velocity |
| `body:getMass()` | Get mass in kg |
| `body:getAngle()` | Get rotation in radians |
| `body:setAngle(angle)` | Set rotation |
| `body:applyForce(fx, fy, px, py)` | Apply continuous force |
| `body:applyLinearImpulse(ix, iy, px, py)` | Apply instantaneous impulse |
| `body:applyTorque(torque)` | Apply rotational force |
| `body:applyAngularImpulse(impulse)` | Apply rotational impulse |
| `body:setBullet(enabled)` | Enable/disable continuous collision detection |
| `body:isSleeping()` | Check if body is sleeping |
| `body:wakeUp()` | Wake a sleeping body |
| `body:destroy()` | Destroy the body |

### Shape

| Method | Description |
|--------|-------------|
| `love.physics.newCircleShape(radius)` | Create a circle shape |
| `love.physics.newRectangleShape(w, h)` | Create a rectangle shape |
| `love.physics.newPolygonShape(...)` | Create a polygon shape |
| `love.physics.newEdgeShape(x1, y1, x2, y2)` | Create an edge shape |
| `shape:getType()` | Get shape type ("Circle", "Polygon", "Rectangle", "Edge") |
| `shape:getPoints()` | Get polygon vertices |
| `shape:getDimensions()` | Get rectangle width and height |
| `shape:getArea()` | Get polygon area |
| `shape:getRadius()` | Get circle radius |

### Fixture

| Method | Description |
|--------|-------------|
| `love.physics.newFixture(body, shape, density)` | Attach a shape to a body |
| `fixture:setFriction(f)` | Set friction coefficient |
| `fixture:setRestitution(r)` | Set bounciness (0-1) |
| `fixture:setDensity(d)` | Set density (kg/m²) |
| `fixture:setSensor(enabled)` | Set as sensor (no collision response) |
| `fixture:setUserData(data)` | Attach custom data |
| `fixture:getUserData()` | Get custom data |
| `fixture:getBody()` | Get the parent body |
| `fixture:getShape()` | Get the attached shape |
| `fixture:getMass()` | Get the fixture's mass contribution |

### Joint

| Method | Description |
|--------|-------------|
| `love.physics.newDistanceJoint(bodyA, bodyB, ...)` | Create a distance joint |
| `love.physics.newRevoluteJoint(bodyA, bodyB, ...)` | Create a revolute joint |
| `love.physics.newPrismaticJoint(bodyA, bodyB, ...)` | Create a prismatic joint |
| `joint:setLength(length)` | Set target distance |
| `joint:setStiffness(stiffness)` | Set spring stiffness |
| `joint:setDamping(damping)` | Set damping |
| `joint:enableMotor(enabled)` | Enable/disable motor |
| `joint:setMotorSpeed(speed)` | Set motor speed |
| `joint:setMaxMotorTorque(torque)` | Set max motor torque |
| `joint:destroy()` | Destroy the joint |

---

## Appendix C — Complete Example Projects

### Project 1: Bouncing Ball

A simple ball that bounces on the ground with configurable restitution.

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    local ground = love.physics.newBody(world, 400, 550, "static")
    local groundShape = love.physics.newRectangleShape(800, 20)
    local groundFixture = love.physics.newFixture(ground, groundShape, 1)
    groundFixture:setFriction(0.5)
    groundFixture:setRestitution(0.5)

    ball = {}
    ball.body = love.physics.newBody(world, 400, 100, "dynamic")
    ball.shape = love.physics.newCircleShape(15)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
    ball.fixture:setFriction(0.3)
    ball.fixture:setRestitution(0.7)
    ball.radius = 15
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.polygon("fill", groundBody:getWorldPoints(groundShape:getPoints()))

    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", ball.body:getX(), ball.body:getY(), ball.radius)
    love.graphics.setColor(1, 1, 1)
end
```

### Project 2: Spring Oscillator

A mass on a spring that oscillates with configurable stiffness and damping.

```lua
function love.load()
    world = love.physics.newWorld(0, 9.81 * 30, true)

    -- Anchor (static)
    local anchor = love.physics.newBody(world, 512, 100, "static")

    -- Mass (dynamic)
    mass = {}
    mass.body = love.physics.newBody(world, 512, 300, "dynamic")
    mass.shape = love.physics.newCircleShape(15)
    mass.fixture = love.physics.newFixture(mass.body, mass.shape, 1)
    mass.fixture:setFriction(0.3)
    mass.fixture:setRestitution(0.2)
    mass.radius = 15
    mass.anchorX = 512
    mass.anchorY = 100
    mass.restLength = 200
    mass.stiffness = 50
    mass.damping = 2

    -- Distance joint (spring)
    local joint = love.physics.newDistanceJoint(
        anchor, mass.body,
        512, 100, 512, 300,
        false
    )
    joint:setLength(200)
    joint:setStiffness(50)
    joint:setDamping(2)
end

function love.update(dt)
    -- Apply spring force manually
    local bx, by = mass.body:getPosition()
    local vx, vy = mass.body:getLinearVelocity()

    local dx = bx - mass.anchorX
    local dy = by - mass.anchorY
    local dist = math.sqrt(dx^2 + dy^2)
    local displacement = dist - mass.restLength

    local springFx = -mass.stiffness * displacement * dx / (dist + 0.001)
    local springFy = -mass.stiffness * displacement * dy / (dist + 0.001)

    local dampFx = -mass.damping * vx
    local dampFy = -mass.damping * vy

    mass.body:applyForce(springFx + dampFx, springFy + dampFy)

    world:update(dt)
end

function love.draw()
    -- Spring line
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.line(mass.anchorX, mass.anchorY, mass.body:getX(), mass.body:getY())

    -- Mass
    love.graphics.setColor(1, 0.5, 0)
    love.graphics.circle("fill", mass.body:getX(), mass.body:getY(), mass.radius)
    love.graphics.setColor(1, 1, 1)
end
```

---

## Appendix D — Derivations from First Principles

> "Everything is derived. Nothing is taken on faith." — the Feynman rule.

This appendix builds each key formula from scratch. If you can re-derive a formula, you understand it; if you can only look it up, you don't yet.

### D.1 The dot product: `a·b = ax*bx + ay*by = |a||b|cos(θ)`

Start from the geometric definition and derive the coordinate form.

1. **Law of cosines** on the triangle formed by `a`, `b`, and `a - b`:
   `|a - b|² = |a|² + |b|² - 2|a||b|cos(θ)`

2. Expand the left side in coordinates:
   `(ax-bx)² + (ay-by)² = ax² + bx² - 2·ax·bx + ay² + by² - 2·ay·by`
   `= (ax² + ay²) + (bx² + by²) - 2(ax·bx + ay·by)`
   `= |a|² + |b|² - 2(ax·bx + ay·by)`

3. Equate the two forms, cancel `|a|² + |b|²`:
   `-2(ax·bx + ay·by) = -2|a||b|cos(θ)`

4. Divide by -2:
   **`ax·bx + ay·by = |a||b|cos(θ)`**

So the coordinate formula and the geometric formula are the *same number*. The dot product measures how much one vector points along another (a projection, scaled by the other's length).

### D.2 The 2D cross product: `a×b = ax*by - ay*bx = |a||b|sin(θ)`

The 2D cross product is the signed area of the parallelogram spanned by `a` and `b` — the determinant of the matrix with `a` and `b` as columns.

`det = ax*by - ay*bx`

That determinant equals the parallelogram area: base `|a|` times height `|b|sin(θ)`:
**`ax*by - ay*bx = |a||b|sin(θ)`**

Sign tells orientation: positive = `b` is counter-clockwise from `a`. This is what Separating Axis Theorem uses to test which side of an edge a vertex sits on.

### D.3 Newton's second law and the game loop: `v' = v + a·dt`

Start from the *definition* of force as rate of change of momentum, `F = dp/dt`. For constant mass, `p = mv`, so:

`F = m·dv/dt  ⟹  dv/dt = F/m = a`

Integrate velocity over one small step, assuming `a` is constant during the step:

`Δv = a·dt ⟹ v' = v + a·dt`

This is the *forward Euler* update. The game loop replaces integration with **discrete summation**:
- `v' = v + a·dt`
- `x' = x + v'·dt`  (note: uses the *new* velocity — semi-implicit Euler)

Using the new velocity makes the scheme *symplectic*: it preserves energy for oscillatory systems (see D.4). Standard forward Euler uses the old velocity and slowly gains energy — springs explode.

### D.4 Why semi-implicit Euler conserves energy

For a harmonic oscillator, each step of forward Euler performs a shear that *increases* the orbit radius slightly — energy grows. Semi-implicit Euler performs two shears that are *exactly inverse*, so the orbit stays bounded forever (up to floating point). That's why every serious game engine steps velocity before position. It's not a cosmetic choice; it's the difference between a spring that rings forever and one that blows up.

### D.5 Free fall: impact speed from drop height

Energy conservation: potential energy at the top converts fully to kinetic energy at the bottom.

`PE = m·g·h`,  `KE = ½·m·v²`
`m·g·h = ½·m·v² ⟹ v² = 2·g·h ⟹` **`v = sqrt(2gh)`**

Drop 600px at g=294.3: `v = sqrt(2·294.3·600) ≈ 594 px/s`. This matches what Chapter 3's ball actually reaches.

### D.6 Restitution and bounce height

Coefficient of restitution: `e = |v_after| / |v_before|` (speed after vs before a bounce).

Bounce up at speed `e·v`, then rise until KE again becomes PE:
`½·m·(e·v)² = m·g·h' ⟹ h' = (e·v)²/(2g) = e²·v²/(2g) = e²·h`

So **bounce height = e² · drop height**. e=0.7 ⟹ 0.49 = 49%. e=0.9 ⟹ 81%. This is why the red ball in Chapter 3 bounces to half its drop height.

### D.7 Projectile range: `R = v₀²·sin(2θ)/g`

Split motion into horizontal (no acceleration) and vertical (gravity).

Time to apex: `0 = v₀·sin(θ) - g·t_apex ⟹ t_apex = v₀·sin(θ)/g`
Full flight: `t = 2·t_apex = 2·v₀·sin(θ)/g`

Horizontal displacement during flight (constant vx = v₀·cos(θ)):
`R = v₀·cos(θ) · 2·v₀·sin(θ)/g = v₀²·(2·sin(θ)cos(θ))/g`

Use the identity `sin(2θ) = 2·sin(θ)cos(θ)`:
**`R = v₀²·sin(2θ)/g`**

Max range at θ=45° because sin(90°)=1. Note: this ignores launch height, air drag, and ground elevation — the demo in Chapter 5 launches from y=650 so reality falls short of the prediction; that discrepancy is instructive.

### D.8 Impulse-momentum: `J = Δp = m·Δv`

From Newton's law in integral form:
`J = ∫F dt = Δp` (the impulse of a force equals the change in momentum).

For a collision resolved over a tiny time, the impulse is `J = m(v' - v)`. Solving the pair of collision equations with restitution `e` gives the classic result:

**`j = -(1+e) · (v_rel · n) / (1/m₁ + 1/m₂)`**

where `v_rel · n` is the approach speed along the contact normal. Derivation sketch:
1. Relative velocity along normal after impact = `-e` times before: `v_rel' · n = -e·(v_rel · n)`.
2. Each body's velocity change is its impulse divided by its mass: `v₁' = v₁ + j·n/m₁`, `v₂' = v₂ - j·n/m₂`.
3. Substitute into step 1 and solve for the single unknown `j`. The term `1/(1/m₁ + 1/m₂)` is the **reduced mass** `μ` (D.9) — the effective mass of the pair.

With e=1, heavy 5kg at 150 hits light 1kg at 0: `j = -2·150/(0.2+1) = -250`, giving heavy 100 and light 250. Check with D.10.

### D.9 Reduced mass: `μ = m₁·m₂/(m₁ + m₂)`

When two bodies interact, neither responds as if it had its own mass alone — each is dragged by the other. The pair's "effective mass" along the contact normal is the harmonic sum:

`1/μ = 1/m₁ + 1/m₂ ⟹ μ = m₁·m₂/(m₁ + m₂)`

Think: equal masses give `μ = m/2` (both move, neither is "anchored"); one body much heavier gives `μ ≈ m_light` (the heavy one is nearly an immovable wall). The impulse formula `j = -(1+e)·v_rel·μ` is the compact form.

### D.10 Elastic collision velocities

For e=1, conservation of momentum `m₁v₁ + m₂v₂ = m₁v₁' + m₂v₂'` and conservation of kinetic energy give:

`v₁' = (m₁ - m₂)/(m₁ + m₂) · v₁ + (2m₂)/(m₁ + m₂) · v₂`
`v₂' = (2m₁)/(m₁ + m₂) · v₁ + (m₂ - m₁)/(m₁ + m₂) · v₂`

With m₁=5, m₂=1, v₁=150, v₂=0:
`v₁' = (4/6)·150 = 100`, `v₂' = (10/6)·150 = 250`. The light ball leaves at 2.5× the heavy ball's speed — exactly what Chapter 9 shows.

### D.11 Pendulum period: `T = 2π√(L/g)`

For small angles, the restoring force is approximately linear: `F = -m·g·sin(θ) ≈ -m·g·θ`. This makes the pendulum a harmonic oscillator with angular frequency `ω = sqrt(g/L)` (derive: torque τ = -m·g·L·θ = I·d²θ/dt² with I = mL², giving d²θ/dt² + (g/L)θ = 0).

Period: `T = 2π/ω =` **`2π√(L/g)`**

With L=6.67m (200px ÷ 30px/m), g=9.81: `T = 2π√(6.67/9.81) ≈ 5.18s`. The approximation is accurate to ~1% below 15° and degrades as the swing grows — another place where the demo's live value and reality diverge on purpose.

### D.12 Spring motion (Hooke's law + damping)

Hooke: `F = -k·x`. Newton: `m·d²x/dt² = -k·x`. This is `d²x/dt² + (k/m)·x = 0`, the harmonic oscillator with `ω₀ = sqrt(k/m)`.

With damping `F = -c·v`:
`m·d²x/dt² + c·dx/dt + k·x = 0`
Solution depends on the damping ratio `ζ = c/(2·sqrt(km))`:
- `ζ < 1` (underdamped): oscillates with decaying amplitude — the Chapter 13 demo.
- `ζ = 1` (critical): fastest return without overshoot.
- `ζ > 1` (overdamped): slow asymptotic return, no oscillation.

The energy story: total mechanical energy `E = ½kx² + ½mv²` is constant for undamped motion, and decays at rate `-c·v²` (work done against damping) otherwise.

---

## Appendix E — Further Reading (vetted links per chapter)

Every link below was checked and resolves. Read the chapter, play the demo, then follow the link for the deeper story.

### Chapter 1 — Vectors
- 3Blue1Brown, *Dot products and duality* — the dot product as projection, beautifully animated. <https://www.youtube.com/watch?v=LyGKycYT2v0>
- 3Blue1Brown, *Cross products* — why the cross product is a signed area. <https://www.youtube.com/watch?v=eu6i7WJeinw>
- Wikipedia, *Vector (mathematics and physics)* — rigorous definitions. <https://en.wikipedia.org/wiki/Vector_(mathematics_and_physics)>

### Chapter 2 — Newton's Laws, the game loop, integration
- Glenn Fiedler (Gaffer on Games), *Fix Your Timestep!* — the definitive essay on fixed-timestep game loops. This is the loop `main.lua` implements. <https://gafferongames.com/post/fix_your_timestep/>
- Wikipedia, *Symplectic integrator* — why semi-implicit Euler conserves energy. <https://en.wikipedia.org/wiki/Symplectic_integrator>
- Wikipedia, *Newton's laws of motion*. <https://en.wikipedia.org/wiki/Newton%27s_laws_of_motion>
- Wikipedia, *Numerical integration* — the family Euler belongs to. <https://en.wikipedia.org/wiki/Numerical_integration>

### Chapter 3 — Box2D and LÖVE
- LÖVE wiki, *love.physics* — the official LÖVE physics module reference. <https://love2d.org/wiki/love.physics>
- Box2D, *official documentation/manual* — the C++ engine LÖVE wraps (v2.3.0). <https://box2d.org/documentation/>
- Wikipedia, *Coefficient of restitution*. <https://en.wikipedia.org/wiki/Coefficient_of_restitution>

### Chapter 4 — Bodies, shapes, fixtures
- Box2D documentation — the *Collision shapes* section covers circles, polygons, and why vertices must be convex (≤ 8 in Box2D). <https://box2d.org/documentation/>
- Wikipedia, *Convex polygon* — why convexity keeps the Separating Axis Theorem simple. <https://en.wikipedia.org/wiki/Convex_polygon>
- Wikipedia, *Moment of inertia* — the rotational sibling of mass. <https://en.wikipedia.org/wiki/Moment_of_inertia>

### Chapter 5 — Projectile motion
- Wikipedia, *Projectile motion* — full derivation of range, height, and flight time. <https://en.wikipedia.org/wiki/Projectile_motion>

### Chapter 6 — Dynamics and forces
- Wikipedia, *Newton's laws of motion*. <https://en.wikipedia.org/wiki/Newton%27s_laws_of_motion>
- Wikipedia, *Rigid body dynamics* — the general framework Box2D solves. <https://en.wikipedia.org/wiki/Rigid_body_dynamics>

### Chapter 7 — Friction and restitution
- Wikipedia, *Friction* (Coulomb model). <https://en.wikipedia.org/wiki/Friction>
- Wikipedia, *Coefficient of restitution*. <https://en.wikipedia.org/wiki/Coefficient_of_restitution>

### Chapter 8 — Collision detection
- Wikipedia, *Collision detection* — broad-phase vs narrow-phase, SAT, GJK, CCD. <https://en.wikipedia.org/wiki/Collision_detection>
- Wikipedia, *Separating axis theorem* — the narrow-phase algorithm Box2D uses for polygons. <https://en.wikipedia.org/wiki/Separating_axis_theorem>
- Wikipedia, *Bounding volume hierarchy* / *AABB* — the broad-phase tree. <https://en.wikipedia.org/wiki/Bounding_volume_hierarchy>

### Chapter 9 — Collision response and impulse
- Wikipedia, *Impulse (physics)*. <https://en.wikipedia.org/wiki/Impulse_(physics)>
- Wikipedia, *Elastic collision* — derives the two-body velocity formulas. <https://en.wikipedia.org/wiki/Elastic_collision>
- Wikipedia, *Reduced mass* — the effective mass of a colliding pair. <https://en.wikipedia.org/wiki/Reduced_mass>
- Wikipedia, *Collision response*. <https://en.wikipedia.org/wiki/Collision_response>

### Chapter 10 — Joints and constraints
- Box2D documentation — the *Joints* section: revolute, distance, prismatic, and how the constraint solver works. <https://box2d.org/documentation/>
- Wikipedia, *Pendulum (mechanics)* — the exact (non-linearized) solution. <https://en.wikipedia.org/wiki/Pendulum_(mechanics)>

### Chapter 11 — Raycasting and sensors
- LÖVE wiki, *World:rayCast* — signature and callback semantics. <https://love2d.org/wiki/World:rayCast>

### Chapter 12 — Performance
- Glenn Fiedler, *Fix Your Timestep!* — determinism and stability. <https://gafferongames.com/post/fix_your_timestep/>
- Wikipedia, *Verlet integration* — an alternative to Euler used by many engines. <https://en.wikipedia.org/wiki/Verlet_integration>

### Chapter 13 — Springs
- Wikipedia, *Hooke's law*. <https://en.wikipedia.org/wiki/Hooke%27s_law>
- Wikipedia, *Simple harmonic motion* — the undamped oscillator and its period. <https://en.wikipedia.org/wiki/Simple_harmonic_motion>

---

## Appendix F — Terminology Glossary

**AABB** (axis-aligned bounding box) — the smallest rectangle, unrotated, that encloses a body. Box2D's broad-phase uses AABBs in a tree to skip pairs that obviously can't collide.

**Broad-phase / narrow-phase** — two-stage collision detection. Broad-phase cheaply eliminates non-overlapping pairs (AABB tree). Narrow-phase precisely tests the survivors (SAT for polygons, distance for circles).

**Bullet / CCD** (continuous collision detection) — marks a fast body so Box2D sweeps its path, preventing "tunneling" through thin walls between steps. `body:setBullet(true)`.

**Coefficient of restitution (e)** — ratio of separation speed to approach speed in a collision, 0 ≤ e ≤ 1. e=1 elastic (KE conserved), e=0 perfectly inelastic (bodies stick). Bounce height scales as e².

**Constraint** — a rule that limits relative motion between bodies (a joint is a constraint). Box2D's solver enforces all constraints each step by iteration.

**Damping** — a force opposing velocity, `F = -c·v`. In joints it models friction/air resistance; without it springs oscillate forever.

**Density** — mass per unit area (kg/m²). Box2D computes `mass = density × shape_area`.

**Dynamic body** — fully simulated: affected by forces, gravity, and collisions.

**Fixture** — attaches a shape to a body and holds material properties (density, friction, restitution, sensor flag, user data).

**Fixed timestep** — physics steps at a constant rate (1/60 s) independent of frame rate. Accumulate real delta time, step physics a fixed number of times. Gives determinism and stability.

**Friction coefficient (μ)** — proportionality in Coulomb's model: `F_friction ≤ μ·F_normal`. μ=0 ice, μ=1 rough. Independent of contact area.

**Impulse** — `J = ∫F dt = Δp`. A force applied over a tiny time; the instantaneous way to change momentum (bounces, kicks).

**Kinematic body** — moved by code (velocity set explicitly), ignores forces, but can collide. Used for moving platforms.

**Normal force** — the contact force a surface exerts perpendicular to itself; it balances gravity for a body at rest on the ground.

**Reduced mass (μ)** — `μ = m₁m₂/(m₁+m₂)`. The effective mass of a two-body system along their contact normal; governs how they respond to each other.

**Restitution** — see *Coefficient of restitution*.

**SAT** (separating axis theorem) — narrow-phase test: two convex polygons don't overlap iff a line can separate them; check projections on the normals of all edges.

**Semi-implicit / symplectic Euler** — integration that updates velocity first, then position with the *new* velocity. Preserves energy for oscillatory systems; the standard for game physics.

**Sensor** — a fixture with `setSensor(true)` that reports overlaps (via contact callbacks) but produces no physical response. Trigger zones.

**Sleeping** — a dynamic body at rest is excluded from the solver until woken by a collision. Big performance win for static scenes.

**Static body** — infinite mass, never moves, never affected by forces. Floors and walls.

**Warm starting** — the solver stores last frame's impulses and reuses them as the initial guess, converging in far fewer iterations.

---

## Final Words

> "Physics is not about formulas. It's about understanding how the world works. And the best way to understand how the world works is to build it yourself — even if it's just a simplified version running at 60 frames per second."

You now have the tools to build physics simulations that look and feel real. The equations are simple. The code is straightforward. The magic is in the details — the friction, the restitution, the warm starting, the fixed timestep.

Go build something. Break it. Fix it. Break it again. That's how you learn.

— In the spirit of Richard P. Feynman
