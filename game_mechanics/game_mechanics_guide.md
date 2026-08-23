# The Feynman Guide to Game Mechanics

## A Complete Journey from Zero to Game-Design Mastery

### Written in the spirit of Richard P. Feynman

---

> "What I cannot create, I do not understand."
> — Richard P. Feynman

---

## Table of Contents

1. [Preface — The Feynman Way](#1-preface)
2. [Chapter 1 — Movement: How Things Get From A to B](#2-chapter-1)
3. [Chapter 2 — Input: Talking to the Machine](#3-chapter-2)
4. [Chapter 3 — Collision Detection: When Things Crash Into Each Other](#4-chapter-3)
5. [Chapter 4 — Health, Damage, and Death](#5-chapter-4)
6. [Chapter 5 — Scoring and Progression](#6-chapter-5)
7. [Chapter 6 — State Machines: The Brain of the Game](#7-chapter-6)
8. [Chapter 7 — Cameras: Your Window Into the World](#8-chapter-7)
9. [Chapter 8 — Spawning and Waves: Populating the Void](#9-chapter-8)
10. [Chapter 9 — Particle Effects: Making Things Look Cool](#10-chapter-9)
11. [Chapter 10 — Power-ups and Pickups: Tiny Rewards, Big Joy](#11-chapter-10)
12. [Chapter 11 — UI and HUD: Talking to the Player](#12-chapter-11)
13. [Chapter 12 — Screen Management: Menus, Pauses, Transitions](#13-chapter-12)
14. [Chapter 13 — Putting It All Together: A Complete Game](#14-chapter-13)
15. [Appendix A — Formulae Quick Reference](#15-appendix-a)
16. [Appendix B — LÖVE2D API Reference](#16-appendix-b)
17. [Appendix C — Complete Example Projects](#17-appendix-c)
18. [Appendix D — Derivations from First Principles](#18-appendix-d)
19. [Appendix E — Further Reading (vetted links per chapter)](#19-appendix-e)
20. [Appendix F — Terminology Glossary](#20-appendix-f)

---

## Companion App — Project Structure

Every chapter in this book has a runnable companion: the *Feynman Game Mechanics* LÖVE2D app, one interactive demo per chapter. This is how the project is organized so you can read a chapter and poke at its demo at the same time.

```
game_mechanics/
├── main.lua            # Bootstrap: fonts, chapter dispatch, LOVE callbacks
├── conf.lua            # LÖVE2D window config (1024×768)
├── vec2.lua            # Tiny 2D vector library
├── utils.lua           # clamp/lerp/damp, collision, entity factories, easing
├── chapters/
│   ├── chapter1.lua    # Movement — velocity, acceleration, friction
│   ├── chapter2.lua    # Input — polling vs event-based
│   ├── chapter3.lua    # Collision detection — AABB and circles
│   ├── chapter4.lua    # Health, damage, death — HP systems
│   ├── chapter5.lua    # Scoring and progression — points, combos
│   ├── chapter6.lua    # State machines — IDLE, CHASE, FLEE
│   ├── chapter7.lua    # Cameras — follow, look-ahead, shake
│   ├── chapter8.lua    # Spawning and waves — enemy waves
│   ├── chapter9.lua    # Particle effects — emitters, life, alpha
│   ├── chapter10.lua   # Power-ups and pickups — timed effects
│   ├── chapter11.lua   # UI and HUD — bars, minimap, damage numbers
│   ├── chapter12.lua   # Screen management — title, pause, game over
│   └── chapter13.lua   # Putting it all together — a complete game
└── game_mechanics_guide.md  # This book
```

**How the modules fit together.** Each chapter is a plain Lua module that returns a table with the same interface:

- `init()` — resets all chapter state.
- `update(dt)` — advances the simulation. `main.lua` calls it at a **fixed timestep** (`FIXED_DT = 1/60`) accumulated against the real frame delta, so every chapter is deterministic regardless of frame rate.
- `draw()` — renders the scene, the live-values panel, and the Feynman notes.
- `mousepressed(x, y, button)` — optional, chapter-specific interaction.
- `keypressed(key)` — optional, chapter-specific keys.

`main.lua` is just the dispatcher: it loads all thirteen chapters, forwards the LOVE callbacks, and draws the persistent header and control hints. `utils.lua` holds the math primitives, collision helpers, and drawing utilities every chapter needs — so chapters stay short and focused on their single idea.

**Running it.** From the `game_mechanics/` directory, run `love .`. Controls:

```
1-9,0   chapters 1-10
-  =    chapters 11 and 12
Enter   chapter 13
SPACE   reset the current chapter
ESC     quit
```

Run the app, then read the corresponding chapter. Change a number, run again, watch what breaks — that loop *is* the book.

---

## 1. Preface — The Feynman Way

### Why this book exists

Most game-development tutorials teach you *what* to call. "Set `player.x` to 100." "Check `love.keyboard.isDown`." "Draw a rectangle." They give you the API and move on. That's like teaching someone to swim by telling them to move their arms without explaining what water does.

This book is different. We're going to build understanding from the ground up.

Here's the Feynman approach to game mechanics:

1. **Start with what you already know.** You've played games. You know that moving a character feels good or bad, that collecting things gives you a rush, that a well-timed screen shake makes an explosion feel *real*. We begin there — with intuition — and then we *precisely* describe that intuition with mathematics and code.

2. **Derive everything from first principles.** We don't accept formulas on authority. We build them. If you understand why `position += velocity * dt` is the right formula, you can derive almost anything else in game mechanics.

3. **Connect every equation to code.** Every formula in this book has a LÖVE2D code example. You will not just read about game mechanics — you will *write* them, run them, and see them move.

4. **Embrace the approximations.** Game mechanics are not real physics. Real physics simulates every atom. Game mechanics simulate enough to *feel right*. Understanding the difference is what separates a good game programmer from a great one.

### How to read this book

- **Read the maths.** Don't skip the derivations. They're short and they're the whole point.
- **Type the code.** Don't copy-paste. Your fingers need to learn what your brain is learning.
- **Break things.** Change a number. Set the friction to 0.01. Make the player speed 10000. Understanding comes from seeing what goes wrong.
- **Play with the demos.** Every chapter demo has keyboard and mouse controls that let you change the exact constants the book talks about.

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


## 2. Chapter 1 — Movement: How Things Get From A to B

### What movement really is

Move your character across the screen. What changed? The position. Everything else — the character's color, size, the UI — stayed fixed. Movement, at bottom, is a single act: **position changes, and the change is velocity times time.**

This seems trivial, but it reframes the entire craft. A game character is not a drawing on the screen. A game character is a *set of numbers* — an x, a y, a velocity — and a set of *laws* that say how those numbers evolve. The simplest law is: `x = x + vx * dt`.

### The hierarchy of motion

Movement has three layers. You need all three to make something feel alive:

```
position  +=  velocity  *  dt       (position changes by velocity)
velocity  +=  accel     *  dt       (velocity changes by acceleration)
accel     =   force / mass           (acceleration comes from forces)
```

Most games stop at the first two. A character has a position and a velocity. When you press a key, you set the velocity. When you release, friction reduces it. That's enough for 90% of games.

### Velocity: the first derivative

Velocity is how fast position changes. In math:

```
v = dx / dt

or equivalently:

x(t + dt) = x(t) + v * dt
```

In code, this is a single line:

```lua
player.x = player.x + player.vx * dt
player.y = player.y + player.vy * dt
```

If `vx = 200` (pixels per second) and `dt = 1/60` (one frame), then the player moves `200 * (1/60) = 3.33` pixels per frame. Over 60 frames (one second), that's 200 pixels. The math checks out.

### Acceleration: the second derivative

Acceleration is how fast velocity changes:

```
a = dv / dt

or:

v(t + dt) = v(t) + a * dt
```

In code:

```lua
player.vx = player.vx + player.ax * dt
player.vy = player.vy + player.ay * dt
```

When you press the right arrow, you set `ax = 400`. The velocity increases by `400 * (1/60) = 6.67` pixels per second per frame. After one second, velocity is 400 px/s. After two seconds, 800 px/s. The character accelerates.

### Friction: killing velocity

Without friction, a character that starts accelerating never stops. Friction is a force that opposes motion:

```
v = v * friction

where 0 < friction < 1
```

Each frame, velocity is multiplied by friction. If `friction = 0.92`:

```
frame 1:  v = 100 * 0.92 = 92
frame 2:  v = 92 * 0.92  = 84.64
frame 3:  v = 84.64 * 0.92 = 77.87
...
frame 20: v ≈ 19.2
frame 40: v ≈ 3.7
```

Velocity decays exponentially toward zero. The character slows down, then stops. That's what friction *feels* like.

### Dummy value walkthrough — building a movement system

Let's trace a complete frame of movement:

```
Given:
  player.x = 500, player.y = 300
  player.vx = 0, player.vy = 0
  ACCEL = 400 px/s^2
  FRICTION = 0.92
  dt = 1/60 s

Frame: right arrow held

1. Input produces acceleration:
   ax = 400, ay = 0

2. Velocity updates:
   vx = 0 + 400 * (1/60) = 6.667
   vy = 0

3. Friction is applied:
   vx = 6.667 * 0.92 = 6.133
   vy = 0 * 0.92     = 0

4. Position updates:
   x = 500 + 6.133 * (1/60) = 500.102
   y = 300 + 0              = 300

After 60 frames (1 second):
   vx ≈ 100 px/s (terminal velocity from friction balance)
   x ≈ 500 + 100 = 600
```

### Game mechanic: smooth platformer movement

This exact pattern — accelerate on input, apply friction, update position — is the foundation of every platformer, top-down shooter, and action game. The *feel* comes from tuning two numbers:

| ACCEL | FRICTION | Feel |
|-------|----------|------|
| 800 | 0.85 | Snappy, responsive (Celeste-like) |
| 400 | 0.92 | Smooth, weighty (Hollow Knight-like) |
| 200 | 0.98 | Heavy, sluggish (tank-like) |
| 1200 | 0.75 | Instant, no momentum (puzzle game) |

The ratio of ACCEL to FRICTION determines the *terminal velocity*:

```
terminal_v = ACCEL / (1 - friction)
```

At `ACCEL = 400, friction = 0.92`:

```
terminal_v = 400 / (1 - 0.92) = 400 / 0.08 = 5000 px/s
```

But friction means you never actually reach it — you approach it asymptotically. That's why the character feels smooth instead of jerky.

### Exercise 1

Create a movement system with diagonal movement. When pressing right and up simultaneously, the character should move diagonally at the same speed as moving in a single direction (not `sqrt(2)` times faster).

<details>
<summary>Solution</summary>

```lua
function love.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("right") then dx = dx + 1 end
    if love.keyboard.isDown("left") then dx = dx - 1 end
    if love.keyboard.isDown("down") then dy = dy + 1 end
    if love.keyboard.isDown("up") then dy = dy - 1 end

    -- Normalize diagonal movement
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        dx = dx / len
        dy = dy / len
    end

    player.vx = player.vx + dx * ACCEL * dt
    player.vy = player.vy + dy * ACCEL * dt

    player.vx = player.vx * FRICTION
    player.vy = player.vy * FRICTION

    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
end
```

The key insight: **normalize the input vector before applying acceleration.** This caps diagonal speed to the same magnitude as cardinal movement.

</details>

---

## 3. Chapter 2 — Input: Talking to the Machine

### Polling vs events

LÖVE2D gives you two ways to read input:

**Polling** — you ask every frame: "Is this key down *right now*?"
```lua
if love.keyboard.isDown("right") then
    player.x = player.x + speed * dt
end
```

**Events** — you receive a callback when something *just happened*:
```lua
function love.keypressed(key)
    if key == "space" then
        shoot()
    end
end
```

The distinction matters. Movement should be polled — you want the character to move *while* the key is held. Shooting should be event-based — you want one bullet per click, not a stream of bullets.

### Why timing matters

The event callback fires *once* per keypress. The polling check runs *every frame*. If you poll for shooting:

```lua
-- BAD: fires every frame the mouse is held
if love.mouse.isDown(1) then
    shoot()
end
```

You get 60 bullets per second. If you use the event:

```lua
-- GOOD: fires once per click
function love.mousepressed(x, y, button)
    if button == 1 then shoot() end
end
```

You get one bullet per click. The player controls the rate.

### The cooldown pattern

Sometimes you want auto-fire (hold to shoot, but at a limited rate). The cooldown is a timer that counts down:

```lua
local cooldown = 0
local COOLDOWN_TIME = 0.15  -- 150ms between shots

function love.update(dt)
    if cooldown > 0 then
        cooldown = cooldown - dt
    end

    if love.mouse.isDown(1) and cooldown <= 0 then
        shoot()
        cooldown = COOLDOWN_TIME
    end
end
```

The cooldown is a simple countdown. It ticks down each frame. When it reaches zero, the player can shoot again. Set it to 0.15 seconds and you get roughly 6-7 shots per second — fast enough to feel responsive, slow enough to be controllable.

### Mouse position vs world position

The mouse position from `love.mouse.getPosition()` is in *screen* coordinates. If your game has a camera (Chapter 7), you need to convert:

```lua
local screenX, screenY = love.mouse.getPosition()
local worldX = screenX + camera.x
local worldY = screenY + camera.y
```

This trips up everyone at least once. The mouse doesn't know about your camera. It only knows about the screen.

### Exercise 2

Build a shooting system that fires bullets toward the mouse position. Add a cooldown of 0.12 seconds. Bullets should travel at 400 px/s.

<details>
<summary>Solution</summary>

```lua
local bullets = {}
local cooldown = 0

function love.mousepressed(x, y, button)
    if button == 1 and cooldown <= 0 then
        local dx = x - player.x
        local dy = y - player.y
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            table.insert(bullets, {
                x = player.x, y = player.y,
                vx = dx / len * 400,
                vy = dy / len * 400,
            })
            cooldown = 0.12
        end
    end
end

function love.update(dt)
    if cooldown > 0 then cooldown = cooldown - dt end

    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.y < -10 or b.x < -10 or b.x > 1034 then
            table.remove(bullets, i)
        end
    end
end
```

The key insight: **normalize the direction vector, then scale by speed.** This gives you a bullet that moves at exactly 400 px/s regardless of which direction you aim.

</details>

---

## 4. Chapter 3 — Collision Detection: When Things Crash Into Each Other

### The two fundamental shapes

Every collision in games boils down to two tests: **AABB** (axis-aligned bounding box) and **circle**. Everything else is built from these.

### AABB collision

An AABB is a rectangle that isn't rotated. It's defined by its top-left corner `(x, y)` and its size `(w, h)`. Two AABBs overlap if and only if:

```
A overlaps B  if and only if:
  A.x < B.x + B.w     (A's left edge is left of B's right edge)
  AND  A.x + A.w > B.x (A's right edge is right of B's left edge)
  AND  A.y < B.y + B.h (A's top edge is above B's bottom edge)
  AND  A.y + A.h > B.y (A's bottom edge is below B's top edge)
```

That's it. Four comparisons. In code:

```lua
function aabbOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx
       and ay < by + bh and ay + ah > by
end
```

If any one of the four conditions fails, there's no overlap. All four must be true.

### Circle collision

Two circles overlap if the distance between their centers is less than the sum of their radii:

```
distance(center_A, center_B) < radius_A + radius_B
```

In code, we use the squared distance to avoid the expensive `sqrt`:

```lua
function circleOverlap(ax, ay, ar, bx, by, br)
    local dx = ax - bx
    local dy = ay - by
    local distSq = dx * dx + dy * dy
    local rSum = ar + br
    return distSq < rSum * rSum
end
```

Why squared? Because `sqrt` is slow and we only need to compare. If `distSq < rSum^2`, then `dist < rSum`. Same result, no square root.

### Circle vs AABB

The trick: clamp the circle's center to the nearest point on the rectangle, then check if that point is within the circle's radius.

```lua
-- Clamp circle center to the box
local cx = clamp(circleX, boxX, boxX + boxW)
local cy = clamp(circleY, boxY, boxY + boxH)

-- Distance from clamped point to circle center
local dx = circleX - cx
local dy = circleY - cy

-- Overlap if distance < radius
return dx * dx + dy * dy < circleR * circleR
```

The clamping finds the closest point on the box to the circle center. If that point is within the radius, they overlap.

### Dummy value walkthrough — AABB test

```
Box A:  (100, 100, 40, 40)   → top-left (100,100), size 40x40
Box B:  (120, 120, 40, 40)   → top-left (120,120), size 40x40

Test:
  100 < 120 + 40  → 100 < 160  ✓
  100 + 40 > 120  → 140 > 120  ✓
  100 < 120 + 40  → 100 < 160  ✓
  100 + 40 > 120  → 140 > 120  ✓

All four pass → overlap detected.
```

Now move B to the right:
```
Box B:  (160, 120, 40, 40)

Test:
  100 < 160 + 40  → 100 < 200  ✓
  100 + 40 > 160  → 140 > 160  ✗

Second condition fails → no overlap.
```

### Game mechanic: hitbox tuning

In real games, the visual sprite is often bigger than the collision box. A character might look 64 pixels wide, but the hitbox is only 32. This is *intentional* — it makes the game feel fair. Players feel cheated when they "dodge" an attack but still get hit by an invisible edge.

The rule of thumb: **hitbox smaller than sprite = generous. Hitbox bigger than sprite = cruel.**

### Exercise 3

Create a scene with a draggable red box and several blue targets (some AABB, some circle). Light up targets green when the red box overlaps them.

<details>
<summary>Solution</summary>

```lua
local box = {x = 300, y = 300, w = 60, h = 60}
local targets = {
    {x = 200, y = 200, w = 80, h = 80, type = "aabb"},
    {x = 500, y = 300, w = 80, h = 80, type = "aabb"},
    {x = 350, y = 500, r = 40, type = "circle"},
    {x = 600, y = 450, r = 55, type = "circle"},
}

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    box.x = mx - box.w / 2
    box.y = my - box.h / 2

    for _, t in ipairs(targets) do
        if t.type == "aabb" then
            t.hit = aabbOverlap(box.x, box.y, box.w, box.h, t.x, t.y, t.w, t.h)
        elseif t.type == "circle" then
            local cx = clamp(box.x + box.w / 2, t.x - t.r, t.x + t.r)
            local cy = clamp(box.y + box.h / 2, t.y - t.r, t.y + t.r)
            local dx = (box.x + box.w / 2) - cx
            local dy = (box.y + box.h / 2) - cy
            t.hit = dx * dx + dy * dy < t.r * t.r
        end
    end
end
```

</details>

---

## 5. Chapter 4 — Health, Damage, and Death

### HP is just a number

Health points (HP) are the simplest game mechanic: a number that goes down when you take damage and goes up when you heal. The entire system is:

```lua
entity.hp = entity.hp - damage
entity.hp = clamp(entity.hp, 0, entity.maxHp)
```

That's it. Two lines. The `clamp` prevents negative HP and over-healing.

### The damage pattern

Every game that has health uses this pattern:

```lua
function takeDamage(entity, amount)
    entity.hp = entity.hp - amount
    if entity.hp <= 0 then
        entity.hp = 0
        entity.alive = false
    end
end
```

Death is just `hp <= 0`. The entity is still in memory — it's just marked as dead. The next frame, you remove it.

### Invincibility frames

When a player takes damage, you don't want them to take damage again on the next frame (60 damage events per second is unfair). The solution: a brief invincibility period.

```lua
local invTimer = 0
local INV_TIME = 0.5  -- half a second of invincibility

function takeDamage(amount)
    if invTimer > 0 then return end  -- can't be hit while invincible
    player.hp = player.hp - amount
    invTimer = INV_TIME
end

function love.update(dt)
    if invTimer > 0 then
        invTimer = invTimer - dt
    end
end
```

This is why characters in games flash after taking damage — the flashing *is* the invincibility timer, made visible.

### The HP bar

An HP bar is just a rectangle with width proportional to `hp / maxHp`:

```lua
function drawBar(x, y, w, h, ratio, color)
    -- Background (empty portion)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, w, h)
    -- Foreground (filled portion)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, w * ratio, h)
end

-- Usage:
drawBar(10, 10, 200, 16, player.hp / player.maxHp, {0.2, 0.8, 0.2})
```

The ratio `hp / maxHp` is a value from 0 to 1. Multiply by the bar width and you get the filled portion. That's the entire mechanic behind every health bar in every game ever made.

### Dummy value walkthrough — damage over time

```
Player:  hp = 100, maxHp = 100
Enemy contact damage: 30 per second
invTimer = 0

Frame 1 (dt = 1/60):
  hp = 100 - 30 * (1/60) = 100 - 0.5 = 99.5

Frame 2:
  hp = 99.5 - 0.5 = 99.0

Frame 60 (1 second later):
  hp = 100 - 30 = 70

Frame 200 (~3.3 seconds):
  hp = 100 - 30 * 3.33 ≈ 0
  → entity.alive = false
```

### Exercise 4

Build a scene where enemies chase the player. The player has 100 HP. Enemies deal 30 damage per second on contact. When HP hits zero, the player respawns at the center with full HP. Add a visible HP bar.

<details>
<summary>Solution</summary>

```lua
local player = {x = 512, y = 384, hp = 100, maxHp = 100}
local enemies = {}

function love.update(dt)
    -- Player movement, enemy chase logic...

    -- Damage on contact
    for _, e in ipairs(enemies) do
        if aabbOverlap(player.x, player.y, player.w, player.h, e.x, e.y, e.w, e.h) then
            player.hp = player.hp - 30 * dt
            if player.hp <= 0 then
                player.hp = player.maxHp
                player.x = 512
                player.y = 384
            end
        end
    end
end

function love.draw()
    -- Draw HP bar
    drawBar(10, 10, 200, 16, player.hp / player.maxHp, {0.2, 0.8, 0.2})
end
```

</details>

---

## 6. Chapter 5 — Scoring and Progression

### Points are language

Points are how the game talks to the player. "You did something. Here's a number." The simplest scoring system is:

```lua
score = score + points
```

But the *design* is in how you assign points and what you do with the number.

### Collectibles

The most common scoring mechanic: objects scattered around the world that give points when touched.

```lua
for i = #collectibles, 1, -1 do
    local c = collectibles[i]
    if circleOverlap(player.x, player.y, player.r, c.x, c.y, c.r) then
        score = score + c.points
        table.remove(collectibles, i)
    end
end
```

The pattern: iterate backwards (so removing doesn't skip items), test overlap, add points, remove the collectible.

### The combo multiplier

A combo rewards skill. Collect things quickly and the multiplier increases. Wait too long and it resets.

```lua
local combo = 1
local comboTimer = 0
local COMBO_WINDOW = 2.0  -- seconds

function collect()
    score = score + 100 * combo
    combo = math.min(combo + 1, 10)  -- cap at 10x
    comboTimer = COMBO_WINDOW
end

function love.update(dt)
    if comboTimer > 0 then
        comboTimer = comboTimer - dt
        if comboTimer <= 0 then
            combo = 1  -- reset combo
        end
    end
end
```

The combo is a timer and a counter. Timer counts down, counter goes up on each collection. When the timer expires, the counter resets. The player learns: *collect fast, or lose your multiplier.*

### Dummy value walkthrough — combo scoring

```
Collect orb 1:  score = 0 + 100*1 = 100,   combo = 2, timer = 2.0
Collect orb 2:  score = 100 + 100*2 = 300,  combo = 3, timer = 2.0
Collect orb 3:  score = 300 + 100*3 = 600,  combo = 4, timer = 2.0
(1.5 seconds pass, timer = 0.5)
Collect orb 4:  score = 600 + 100*4 = 1000, combo = 5, timer = 2.0
(timer expires before next collection)
Reset:         combo = 1
Collect orb 5:  score = 1000 + 100*1 = 1100, combo = 2, timer = 2.0
```

Total without combo: 500. Total with combo: 1100. The combo more than doubled the score — that's the incentive.

### Exercise 5

Add a combo system to the collectible scene. Orbs give 100 points base. Collecting within 2 seconds of the last one increases the multiplier by 1 (max 10x). Display the multiplier on screen.

<details>
<summary>Solution</summary>

```lua
local combo = 1
local comboTimer = 0

function collectOrb(orb)
    score = score + 100 * combo
    combo = math.min(combo + 1, 10)
    comboTimer = 2.0
end

function love.update(dt)
    if comboTimer > 0 then
        comboTimer = comboTimer - dt
        if comboTimer <= 0 then combo = 1 end
    end
end

function love.draw()
    if combo > 1 then
        love.graphics.setColor(1, 0.5, 0.1)
        love.graphics.print("COMBO x" .. combo, 800, 10)
    end
end
```

</details>


---

## 7. Chapter 6 — State Machines: The Brain of the Game

### Every entity has states

A character can be idle, walking, jumping, attacking, or dead. An enemy can be patrolling, chasing, fleeing, or stunned. These are *states* — and the rules for moving between them are a **finite state machine** (FSM).

An FSM is just two things:

1. A **current state** (one of N possibilities)
2. A **transition table** (if in state A and condition X is true, go to state B)

That's the entire concept. Everything else is implementation.

### The structure

```lua
local enemy = {
    state = "IDLE",
    x = 100, y = 100,
}

function updateEnemy(dt)
    local d = distanceToPlayer(enemy)

    -- TRANSITIONS (the rules)
    if enemy.state == "IDLE" then
        if d < 200 then
            enemy.state = "CHASE"
        end

    elseif enemy.state == "CHASE" then
        if d > 300 then
            enemy.state = "IDLE"
        elseif d < 80 then
            enemy.state = "FLEE"
        end

    elseif enemy.state == "FLEE" then
        if d > 250 then
            enemy.state = "IDLE"
        end
    end

    -- BEHAVIORS (what each state does)
    if enemy.state == "IDLE" then
        patrol(enemy, dt)
    elseif enemy.state == "CHASE" then
        moveToward(enemy, player, dt)
    elseif enemy.state == "FLEE" then
        moveAway(enemy, player, dt)
    end
end
```

Notice the separation: transitions are checked *first*, then behaviors execute. The state might change during transition checks, and the behavior runs in the *new* state. This is important — it means the entity responds immediately to changes.

### Why not just if/else?

You *could* write:

```lua
if d < 80 then
    -- flee
elseif d < 200 then
    -- chase
else
    -- idle
end
```

This works for three states. But what happens when you add "attacking", "stunned", "dead", "teleporting"? The if/else chain becomes unreadable. The FSM keeps each state as a separate block with clear entry and exit conditions.

### Dummy value walkthrough — enemy AI

```
Enemy at (400, 300), player at (500, 350)
distance = sqrt(100^2 + 50^2) = sqrt(12500) ≈ 111.8

State: IDLE
Transition check: d=111.8 < 200 → CHASE

Behavior: move toward player
  direction = (100, 50) / 111.8 = (0.894, 0.447)
  new position = (400 + 0.894*120*dt, 300 + 0.447*120*dt)
               = (400 + 1.79, 300 + 0.89)
               = (401.79, 300.89)

Next frame: d ≈ 110.1, still in CHASE.
```

### Exercise 6

Build an enemy with three states: IDLE (patrol left-right), CHASE (move toward player), FLEE (move away). Use distance thresholds of 120 (flee) and 300 (chase). Color the enemy differently in each state.

<details>
<summary>Solution</summary>

```lua
local STATE_COLORS = {
    IDLE  = {0.4, 0.4, 0.4},
    CHASE = {1, 0.3, 0.2},
    FLEE  = {0.2, 0.8, 0.3},
}

function updateEnemy(dt)
    local d = distToPlayer()

    -- Transitions
    if d < 120 then enemy.state = "FLEE"
    elseif d < 300 then enemy.state = "CHASE"
    else enemy.state = "IDLE" end

    -- Behaviors
    if enemy.state == "IDLE" then
        enemy.x = enemy.x + enemy.patrolDir * 40 * dt
        if enemy.x > 800 or enemy.x < 200 then
            enemy.patrolDir = -enemy.patrolDir
        end
    elseif enemy.state == "CHASE" then
        moveToward(player, enemy.speed, dt)
    elseif enemy.state == "FLEE" then
        moveAway(player, enemy.speed * 1.5, dt)
    end
end

function love.draw()
    love.graphics.setColor(STATE_COLORS[enemy.state])
    love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.w, enemy.h)
end
```

</details>

---

## 8. Chapter 7 — Cameras: Your Window Into the World

### The camera is subtraction

When the game world is bigger than the screen, you need a camera. But a camera isn't a complex object — it's a *position*, and drawing is just offsetting everything by that position:

```
screen_x = world_x - camera_x
screen_y = world_y - camera_y
```

If the camera is at `(200, 100)`, then a world object at `(300, 150)` appears on screen at `(100, 50)`. The world stays still; the camera moves. That's the entire concept.

In LÖVE2D, you use `love.graphics.push()` and `love.graphics.translate()`:

```lua
function love.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- Everything here is drawn in WORLD coordinates
    love.graphics.rectangle("fill", player.x, player.y, 24, 24)
    love.graphics.rectangle("fill", enemy.x, enemy.y, 20, 20)

    love.graphics.pop()

    -- Everything here is drawn in SCREEN coordinates (HUD)
    love.graphics.print("Score: " .. score, 10, 10)
end
```

### Camera follow

The simplest camera just centers on the player:

```lua
camera.x = player.x + player.w / 2 - SCREEN_W / 2
camera.y = player.y + player.h / 2 - SCREEN_H / 2
```

This puts the player in the center of the screen. But it feels *stiff* — every micro-movement of the player shifts the camera. The fix: damping.

```lua
local targetX = player.x + player.w / 2 - SCREEN_W / 2
local targetY = player.y + player.h / 2 - SCREEN_H / 2
camera.x = damp(camera.x, targetX, 5, dt)
camera.y = damp(camera.y, targetY, 5, dt)
```

The camera *follows* the player smoothly instead of snapping. Lambda of 5 makes it feel like the camera is floating behind the character.

### Look-ahead

Good cameras don't just follow — they *anticipate*. When the player moves right, the camera shifts slightly right *before* the player gets there:

```lua
local lookAhead = 100
camera.x = damp(camera.x,
    targetX + player.vx * lookAhead / player.speed, 5, dt)
```

The camera offset is `player.vx * lookAhead / player.speed`. When the player is moving right at full speed, this adds 100 pixels ahead. When stopped, it's zero. The camera leads the player's eye into the space they're about to enter.

### Screen shake

Screen shake is just random noise added to the camera position for a brief time:

```lua
if shakeTimer > 0 then
    shakeTimer = shakeTimer - dt
    local intensity = shakeIntensity * (shakeTimer / shakeDuration)
    camera.x = camera.x + (math.random() - 0.5) * intensity
    camera.y = camera.y + (math.random() - 0.5) * intensity
end
```

The intensity fades linearly from `shakeIntensity` to 0 over `shakeDuration` seconds. This is why screen shakes feel punchy at first then settle — that's the linear decay.

### Exercise 7

Create a world larger than the screen (2048x1536). Add a player that moves with arrow keys, a camera that follows with damping (lambda=5), and 20 decorative gems scattered around. Press C to cycle through FOLLOW, LOOK_AHEAD, and SHAKE modes.

<details>
<summary>Solution</summary>

```lua
local WORLD_W, WORLD_H = 2048, 1536
local camera = {x = 0, y = 0, mode = "FOLLOW"}

function love.update(dt)
    -- Player movement...
    local targetX = player.x + player.w / 2 - 512
    local targetY = player.y + player.h / 2 - 384

    if camera.mode == "FOLLOW" then
        camera.x = damp(camera.x, targetX, 5, dt)
        camera.y = damp(camera.y, targetY, 5, dt)
    elseif camera.mode == "LOOK_AHEAD" then
        local la = 100
        camera.x = damp(camera.x, targetX + player.vx * la / player.speed, 5, dt)
        camera.y = damp(camera.y, targetY + player.vy * la / player.speed, 5, dt)
    end

    camera.x = clamp(camera.x, 0, WORLD_W - 1024)
    camera.y = clamp(camera.y, 0, WORLD_H - 768)
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)
    -- Draw world objects...
    love.graphics.pop()
    -- Draw HUD...
end
```

</details>

---

## 9. Chapter 8 — Spawning and Waves: Populating the Void

### The spawn pattern

Games need to create things at the right time and place. The core pattern is a **queue + timer**:

```lua
local queue = {}
local timer = 0
local interval = 1.0  -- seconds between spawns

function love.update(dt)
    if #queue > 0 then
        timer = timer + dt
        if timer >= interval then
            timer = timer - interval
            spawn(queue[1])
            table.remove(queue, 1)
        end
    end
end
```

This is the foundation of every wave system, every enemy spawner, every power-up drop.

### Wave design

Waves create *escalation*. Each wave is harder than the last. The simplest formula:

```
enemies_per_wave = BASE + GROWTH * (wave_number - 1)
spawn_interval = max(MIN_INTERVAL, START_INTERVAL - wave_number * DECAY)
```

This gives you:

| Wave | Enemies | Interval |
|------|---------|----------|
| 1 | 5 | 1.0s |
| 2 | 7 | 0.9s |
| 3 | 9 | 0.8s |
| 4 | 11 | 0.7s |
| 5 | 13 | 0.6s |

More enemies, faster spawns. The difficulty ramps up linearly.

### Spawn positions

Where do things appear? Common patterns:

```lua
-- From screen edges (enemies approach from outside)
local side = math.random(1, 4)
if side == 1 then x = -20; y = math.random(0, WORLD_H)     -- left
elseif side == 2 then x = WORLD_W + 20; y = math.random(0, WORLD_H)  -- right
elseif side == 3 then x = math.random(0, WORLD_W); y = -20  -- top
else x = math.random(0, WORLD_W); y = WORLD_H + 20 end     -- bottom
```

```lua
-- From random positions (chaotic, unpredictable)
x = math.random(50, WORLD_W - 50)
y = math.random(50, WORLD_H - 50)
```

```lua
-- From spawn points (controlled, level-designed)
for _, point in ipairs(spawnPoints) do
    spawn(point.x, point.y)
end
```

### Wave completion

A wave is "complete" when all enemies are spawned AND all enemies are dead:

```lua
if enemiesRemaining == 0 and #enemies == 0 then
    waveDelay = 2.0  -- brief pause before next wave
    startNextWave()
end
```

The two conditions are independent. `enemiesRemaining` counts how many are *waiting to be spawned*. `#enemies` counts how many are *alive in the world*. Both must be zero.

### Exercise 8

Build a wave system. Wave 1 starts with 5 enemies, each wave adds 3 more. Spawn interval starts at 1.0s and decreases by 0.05s per wave (minimum 0.3s). Show the wave number and remaining enemies on screen.

<details>
<summary>Solution</summary>

```lua
local wave = 0
local enemiesRemaining = 0
local spawnTimer = 0
local spawnInterval = 1.0

function startWave()
    wave = wave + 1
    enemiesRemaining = 4 + 3 * (wave - 1)
    spawnInterval = math.max(0.3, 1.0 - wave * 0.05)
    spawnTimer = 0
end

function love.update(dt)
    if enemiesRemaining > 0 then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnInterval then
            spawnTimer = spawnTimer - spawnInterval
            spawnEnemy()
            enemiesRemaining = enemiesRemaining - 1
        end
    end

    if enemiesRemaining == 0 and #enemies == 0 then
        startWave()
    end
end
```

</details>

---

## 10. Chapter 9 — Particle Effects: Making Things Look Cool

### What is a particle?

A particle is a tiny object that lives for a short time, moves with velocity, and dies. The entire particle is:

```lua
{
    x = 500, y = 300,       -- position
    vx = 50, vy = -80,      -- velocity
    life = 0.8,              -- seconds left to live
    maxLife = 0.8,           -- total lifespan (for fading)
    size = 4,                -- radius in pixels
    color = {1, 0.5, 0.2},  -- RGB
}
```

That's it. A table with a few numbers.

### The particle loop

Each frame, every particle does the same four things:

```lua
for i = #particles, 1, -1 do
    local p = particles[i]
    p.life = p.life - dt          -- 1. count down
    if p.life <= 0 then           -- 2. check death
        table.remove(particles, i)
    else
        p.x = p.x + p.vx * dt    -- 3. move
        p.y = p.y + p.vy * dt
        p.size = p.size * 0.98    -- 4. shrink
    end
end
```

Four lines of logic per particle. That's the entire system.

### The emitter

An emitter creates particles. It's just a loop:

```lua
function emit(x, y, count, config)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = config.minSpeed + math.random() * (config.maxSpeed - config.minSpeed)
        local life = config.minLife + math.random() * (config.maxLife - config.minLife)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = life, maxLife = life,
            size = config.minSize + math.random() * (config.maxSize - config.minSize),
            color = config.color,
            gravity = config.gravity or 0,
        })
    end
end
```

Each particle gets a random angle, a random speed in a range, and a random lifespan. This randomness is what makes particles look *organic* instead of mechanical.

### Fading with alpha

Particles look best when they fade out as they die. The alpha is the ratio of remaining life to total life:

```lua
local alpha = p.life / p.maxLife
love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
love.graphics.circle("fill", p.x, p.y, p.size)
```

At full life, alpha = 1 (fully visible). At death, alpha = 0 (invisible). The particle *dissolves* instead of popping out of existence.

### Gravity

Particles can be affected by gravity — just add to vy each frame:

```lua
p.vy = p.vy + gravity * dt
```

This makes particles arc upward then fall back down (fireworks, fountain effects). Set gravity to 0 for explosions that expand in all directions.

### Dummy value walkthrough — explosion

```
Config: minSpeed=50, maxSpeed=250, minLife=0.5, maxLife=2.0, gravity=60

emit(500, 300, 50 particles)

Particle #1:
  angle = 2.31 rad (132 degrees, upper-left)
  speed = 50 + random()*200 = 147
  life = 0.5 + random()*1.5 = 1.2s
  vx = cos(2.31) * 147 = -98.3
  vy = sin(2.31) * 147 = 108.7

Frame 1 (dt=1/60):
  x = 500 + (-98.3) * 0.0167 = 498.36
  y = 300 + 108.7 * 0.0167 = 301.81
  vy = 108.7 + 60 * 0.0167 = 109.70  (gravity pulls down)
  life = 1.2 - 0.0167 = 1.183
  alpha = 1.183 / 1.2 = 0.986 (barely faded)

Frame 36 (0.6s later):
  life = 1.2 - 0.6 = 0.6
  alpha = 0.6 / 1.2 = 0.5 (half faded)

Frame 72 (1.2s later):
  life = 0 → removed
```

### Exercise 9

Create a continuous particle emitter that follows the mouse. Particles should have random angles, speeds between 30-120 px/s, lifespans of 0.3-1.2 seconds, and be affected by gravity (40 px/s^2). Click to create a burst of 50 particles.

<details>
<summary>Solution</summary>

```lua
local particles = {}

function emit(x, y, count, config)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = config.minSpeed + math.random() * (config.maxSpeed - config.minSpeed)
        local life = config.minLife + math.random() * (config.maxLife - config.minLife)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = life, maxLife = life,
            size = 2 + math.random() * 4,
            color = config.color,
            gravity = config.gravity or 0,
        })
    end
end

function love.update(dt)
    emit(emitterX, emitterY, 2, {
        minSpeed = 30, maxSpeed = 120,
        minLife = 0.3, maxLife = 1.2,
        color = {1, 0.6, 0.1}, gravity = 40,
    })

    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i)
        else
            p.vy = p.vy + p.gravity * dt
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.size = p.size * 0.99
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        emit(x, y, 50, {
            minSpeed = 50, maxSpeed = 250,
            minLife = 0.5, maxLife = 2.0,
            color = {1, 0.3, 0.2}, gravity = 60,
        })
    end
end
```

</details>


---

## 11. Chapter 10 — Power-ups and Pickups: Tiny Rewards, Big Joy

### What is a power-up?

A power-up is a temporary change to a player property, governed by a timer. The pattern:

1. Player touches a pickup
2. A property changes (speed increases, HP restores, shield activates)
3. A timer starts counting down
4. When the timer hits zero, the property restores to its original value

That's the entire mechanic. Three lines of logic, infinite variety.

### The effect system

```lua
local activeEffects = {}

function applyEffect(pickup)
    if pickup.type == "speed" then
        player.speed = player.baseSpeed * 2
        table.insert(activeEffects, {
            type = "speed",
            timer = pickup.duration,
            maxTimer = pickup.duration,
        })
    elseif pickup.type == "heal" then
        player.hp = math.min(player.hp + 50, player.maxHp)
        -- No timer — instant effect
    end
end

function love.update(dt)
    for i = #activeEffects, 1, -1 do
        local e = activeEffects[i]
        e.timer = e.timer - dt
        if e.timer <= 0 then
            -- Remove effect
            if e.type == "speed" then
                player.speed = player.baseSpeed
            end
            table.remove(activeEffects, i)
        end
    end
end
```

### Instant vs timed effects

Some effects are instant (heal, score bonus, extra life). Some are timed (speed boost, shield, invisibility). The difference:

```
Instant:  hp = hp + 50                        (no timer)
Timed:    speed = baseSpeed * 2; timer = 5.0  (timer counts down)
```

Instant effects don't need the effect system. Just change the property and move on.

### Visual feedback

Power-ups need to *feel* good. The minimum feedback:

1. **Particle burst** on collection — the pickup "explodes" into particles
2. **HUD indicator** — show the active effect and its remaining time
3. **Color change** — the player's appearance changes while the effect is active

```lua
-- Particle burst on collection
emitParticles(pickup.x, pickup.y, 12, pickup.color, 80, 0.6)

-- HUD indicator
for i, e in ipairs(activeEffects) do
    love.graphics.print(e.type .. " " .. fmt(e.timer) .. "s", 800, 10 + i * 18)
    drawBar(800, 10 + i * 18 + 14, 180, 4, e.timer / e.maxTimer, {0.3, 1, 0.3})
end
```

### Dummy value walkthrough — speed power-up

```
Player:  baseSpeed = 200, speed = 200
Pickup:  type = "speed", duration = 5.0

Collection:
  player.speed = 200 * 2 = 400
  activeEffects = [{type="speed", timer=5.0, maxTimer=5.0}]

After 2 seconds:
  timer = 5.0 - 2.0 = 3.0
  player.speed still = 400 (effect active)

After 5 seconds:
  timer = 5.0 - 5.0 = 0.0
  player.speed = player.baseSpeed = 200 (effect removed)
```

### Exercise 10

Create a scene with two pickup types: SPEED (green, doubles speed for 5 seconds) and HEAL (red, restores 50 HP). Show active effects with countdown timers in the top-right corner.

<details>
<summary>Solution</summary>

```lua
local PICKUP_TYPES = {
    {type = "speed", color = {0.2, 1, 0.3}, duration = 5},
    {type = "heal", color = {1, 0.3, 0.3}, duration = 0},
}

function collectPickup(pickup)
    if pickup.type == "speed" then
        player.speed = player.baseSpeed * 2
        table.insert(activeEffects, {
            type = "speed", timer = 5.0, maxTimer = 5.0,
        })
    elseif pickup.type == "heal" then
        player.hp = math.min(player.hp + 50, player.maxHp)
    end
    table.remove(pickups, pickup.index)
end

function love.update(dt)
    for i = #activeEffects, 1, -1 do
        activeEffects[i].timer = activeEffects[i].timer - dt
        if activeEffects[i].timer <= 0 then
            if activeEffects[i].type == "speed" then
                player.speed = player.baseSpeed
            end
            table.remove(activeEffects, i)
        end
    end
end
```

</details>

---

## 12. Chapter 11 — UI and HUD: Talking to the Player

### What is a HUD?

A **HUD** (Heads-Up Display) is information drawn on top of the game world. It exists in *screen space*, not *world space*. When the camera moves, the HUD stays put.

The HUD answers the player's questions:
- How much health do I have? → HP bar
- How many points? → Score text
- Where are the enemies? → Minimap
- What just happened? → Damage numbers
- What should I do now? → Tooltip

### The HP bar

A health bar is a ratio rendered as a rectangle:

```lua
function drawBar(x, y, w, h, ratio, fgColor, bgColor)
    ratio = clamp(ratio, 0, 1)
    bgColor = bgColor or {0.2, 0.2, 0.2}
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(fgColor)
    love.graphics.rectangle("fill", x, y, w * ratio, h)
end

-- Usage:
drawBar(10, 10, 200, 18, player.hp / player.maxHp, {0.2, 0.8, 0.2})
```

The ratio is `current / max`. At full health, the bar is green and full. At low health, it's nearly empty. The player reads this instinctively — no numbers needed.

### The minimap

A minimap is the entire world shrunk down to a small rectangle:

```lua
local mmx, mmy = 870, 10
local mmw, mmh = 140, 100

-- Background
love.graphics.setColor(0, 0, 0, 0.7)
love.graphics.rectangle("fill", mmx, mmy, mmw, mmh)

-- Player dot
love.graphics.setColor(0.3, 0.8, 1)
local px = mmx + (player.x / WORLD_W) * mmw
local py = mmy + (player.y / WORLD_H) * mmh
love.graphics.rectangle("fill", px, py, 3, 3)

-- Enemy dots
love.graphics.setColor(1, 0.3, 0.3)
for _, e in ipairs(enemies) do
    local ex = mmx + (e.x / WORLD_W) * mmw
    local ey = mmy + (e.y / WORLD_H) * mmh
    love.graphics.rectangle("fill", ex, ey, 2, 2)
end
```

The math: `world_pos / world_size * minimap_size` maps world coordinates to minimap coordinates. That's the entire algorithm.

### Damage numbers

Damage numbers are text that float upward and fade out. They're particles, but with text:

```lua
function addDamageNumber(x, y, text, color)
    table.insert(damageNumbers, {
        x = x, y = y,
        text = tostring(text),
        color = color or {1, 0.3, 0.3},
        life = 1.0,
    })
end

-- Update: float up and fade
for i = #damageNumbers, 1, -1 do
    local d = damageNumbers[i]
    d.life = d.life - dt
    d.y = d.y - 25 * dt  -- float upward
    if d.life <= 0 then
        table.remove(damageNumbers, i)
    end
end

-- Draw: alpha based on remaining life
for _, d in ipairs(damageNumbers) do
    love.graphics.setColor(d.color[1], d.color[2], d.color[3], d.life)
    love.graphics.print(d.text, d.x, d.y)
end
```

### Tooltips

A tooltip is a temporary message that fades away:

```lua
local tooltip = {text = "Collect the orbs!", timer = 5.0}

function love.update(dt)
    if tooltip.timer > 0 then
        tooltip.timer = tooltip.timer - dt
    end
end

function love.draw()
    if tooltip.timer > 0 then
        local alpha = clamp(tooltip.timer, 0, 1)
        love.graphics.setColor(1, 1, 0.5, alpha)
        love.graphics.print(tooltip.text, 350, 730)
    end
end
```

The tooltip shows for 5 seconds, then the alpha fades it out over the last second.

### Exercise 11

Build a complete HUD with: (1) an HP bar at top-left, (2) a score display at top-center, (3) a minimap at top-right, (4) damage numbers that float up when enemies are hit, (5) a tooltip that fades after 5 seconds.

<details>
<summary>Solution</summary>

```lua
function love.draw()
    -- HP bar
    drawBar(10, 10, 200, 18, player.hp / player.maxHp, {0.2, 0.8, 0.2})
    love.graphics.print("HP: " .. player.hp, 215, 12)

    -- Score
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.print("SCORE: " .. score, 430, 10)

    -- Minimap
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 870, 10, 140, 100)
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", 870 + player.x / WORLD_W * 140, 10 + player.y / WORLD_H * 100, 3, 3)

    -- Damage numbers
    for _, d in ipairs(damageNumbers) do
        love.graphics.setColor(d.color[1], d.color[2], d.color[3], d.life)
        love.graphics.print(d.text, d.x, d.y)
    end

    -- Tooltip
    if tooltip.timer > 0 then
        love.graphics.setColor(1, 1, 0.5, clamp(tooltip.timer, 0, 1))
        love.graphics.print(tooltip.text, 350, 730)
    end
end
```

</details>

---

## 13. Chapter 12 — Screen Management: Menus, Pauses, Transitions

### Game states

A game has more than just gameplay. It has:

- **Title screen** — the first thing the player sees
- **Gameplay** — the actual game
- **Pause** — frozen gameplay with a menu
- **Game over** — results, restart option

Each is a *state*. The game is always in exactly one state.

### The state stack

A simple state variable works for two states. But pause needs to *remember* the gameplay state underneath. The solution: a **stack**.

```lua
local gameState = "TITLE"
local stateStack = {}

function pushState(newState)
    table.insert(stateStack, gameState)  -- save current
    gameState = newState
end

function popState()
    if #stateStack > 0 then
        gameState = table.remove(stateStack)  -- restore previous
    end
end
```

When you pause: `pushState("PAUSED")` → stack has `["TITLE", "PLAYING"]`, current is `"PAUSED"`.
When you resume: `popState()` → stack has `["TITLE"]`, current is `"PLAYING"`.
The stack remembers where you were.

### The game loop with states

```lua
function love.update(dt)
    if gameState == "PLAYING" then
        updateGame(dt)
    end
    -- PAUSED: don't update anything
end

function love.draw()
    if gameState == "TITLE" then
        drawTitleScreen()
    elseif gameState == "PLAYING" then
        drawGame()
    elseif gameState == "PAUSED" then
        drawGame()          -- draw the frozen game behind
        drawPauseOverlay()  -- draw the pause menu on top
    elseif gameState == "GAMEOVER" then
        drawGame()
        drawGameOverOverlay()
    end
end
```

Notice: during PAUSED, we still *draw* the game — we just don't *update* it. The game is frozen in place, with a semi-transparent overlay on top.

### Button interaction

Title screens and game-over screens need clickable buttons:

```lua
local buttons = {
    {x = 412, y = 350, w = 200, h = 40, label = "START", action = startGame},
    {x = 412, y = 410, w = 200, h = 40, label = "QUIT", action = quit},
}

function love.mousepressed(x, y, button)
    if button == 1 then
        for _, btn in ipairs(buttons) do
            if x >= btn.x and x <= btn.x + btn.w
           and y >= btn.y and y <= btn.y + btn.h then
                btn.action()
            end
        end
    end
end
```

Point-in-rectangle test. That's the entire UI system.

### Exercise 12

Build a game with four screens: TITLE (with a Start button), PLAYING (with enemies), PAUSED (press P), and GAMEOVER (when HP hits zero). Use a state stack so PAUSED correctly returns to PLAYING.

<details>
<summary>Solution</summary>

```lua
local gameState = "TITLE"
local stateStack = {}

function pushState(s)
    table.insert(stateStack, gameState)
    gameState = s
end

function popState()
    if #stateStack > 0 then
        gameState = table.remove(stateStack)
    end
end

function love.keypressed(key)
    if key == "p" and gameState == "PLAYING" then
        pushState("PAUSED")
    elseif key == "p" and gameState == "PAUSED" then
        popState()
    elseif key == "return" and gameState == "TITLE" then
        gameState = "PLAYING"
        resetGame()
    end
end

function love.update(dt)
    if gameState == "PLAYING" then
        updateGame(dt)
        if player.hp <= 0 then pushState("GAMEOVER") end
    end
end

function love.draw()
    if gameState == "TITLE" then drawTitle()
    elseif gameState == "PLAYING" then drawGame()
    elseif gameState == "PAUSED" then drawGame(); drawPauseOverlay()
    elseif gameState == "GAMEOVER" then drawGame(); drawGameOverOverlay() end
end
```

</details>

---

## 14. Chapter 13 — Putting It All Together: A Complete Game

### The integration

Every chapter in this book taught you one mechanic. This chapter combines them all into a single playable game:

| Mechanic | Chapter | How it's used |
|----------|---------|---------------|
| Movement | 1 | Player moves with arrow keys |
| Input | 2 | Mouse to aim, click to shoot |
| Collision | 3 | Bullets hit enemies, enemies hit player |
| Health | 4 | Player has HP, enemies have HP |
| Scoring | 5 | Collect orbs for points |
| State machine | 6 | Enemy AI: patrol/chase/flee |
| Spawning | 8 | Enemies spawn in waves |
| Particles | 9 | Explosions on enemy death |
| Power-ups | 10 | Speed boost, healing pickups |
| HUD | 11 | HP bar, score, wave counter |
| Screen management | 12 | Title, pause, game over |

### The architecture

A complete game is a collection of systems that communicate through shared state:

```
player   → movement, health, power-ups
enemies  → state machine, spawning, collision
bullets  → movement, collision
particles → visual effects
orbs     → scoring, collection
HUD      → draws player/enemy/score state
screens  → manages game flow
```

Each system is independent. The collision system doesn't know about particles. The scoring system doesn't know about the camera. They all read and write to the same data, and the game loop orchestrates the order.

### The update order matters

```lua
function love.update(dt)
    -- 1. Input → movement
    handleInput(dt)

    -- 2. AI → enemy movement
    updateEnemies(dt)

    -- 3. Collision → damage, collection
    checkCollisions()

    -- 4. Effects → particles, damage numbers
    updateEffects(dt)

    -- 5. Cleanup → remove dead things
    cleanup()

    -- 6. Wave management → spawn new enemies
    updateWaves(dt)
end
```

The order prevents subtle bugs. If you check collisions *before* moving, you miss collisions from the current frame's movement. If you clean up *before* checking collisions, you might reference removed objects.

### What makes a game "feel good"?

It's not the code — it's the *tuning*. A game that feels good has:

1. **Responsive controls** — low latency between input and movement (ACCEL high, friction tuned)
2. **Clear feedback** — particles, screen shake, sound on every action
3. **Fair difficulty** — the player can see and react to threats
4. **Juice** — the extra 10%: damage numbers, combo text, hit-stop, squash and stretch

The code for a "juicy" game is barely more complex than a "dry" one. The difference is in the constants, the particles, and the polish.

### Exercise 13

The final exercise: modify chapter 13's complete game. Add a new enemy type that's faster but has less HP. Add a new power-up that makes the player temporarily invincible. Add screen shake when the player takes damage.

<details>
<summary>Solution</summary>

```lua
-- Fast enemy type
function spawnFastEnemy()
    table.insert(enemies, {
        x = ..., y = ..., w = 16, h = 16,
        hp = 10, maxHp = 10,
        speed = 150,
        color = {1, 0.8, 0.2},
    })
end

-- Invincibility power-up
if pickup.type == "invincible" then
    player.invincible = true
    table.insert(activeEffects, {
        type = "invincible", timer = 5.0, maxTimer = 5.0,
    })
end

-- Screen shake on damage
function playerTakeDamage(amount)
    if player.invincible then return end
    player.hp = player.hp - amount
    shakeTimer = 0.2
    shakeIntensity = 12
end
```

</details>


---

## 15. Appendix A — Formulae Quick Reference

### Movement

```
position += velocity * dt
velocity += acceleration * dt
velocity *= friction                    (0 < friction < 1)
terminal_velocity = acceleration / (1 - friction)
```

### Collision

```
AABB overlap:
  A.x < B.x + B.w  AND  A.x + A.w > B.x
  AND  A.y < B.y + B.h  AND  A.y + A.h > B.y

Circle overlap:
  dx^2 + dy^2 < (r1 + r2)^2

Circle vs AABB:
  clamp(circle_center, box_min, box_max)
  distance^2 < radius^2
```

### Health and Damage

```
hp = clamp(hp - damage, 0, maxHp)
death = (hp <= 0)
hp_bar_width = (hp / maxHp) * bar_max_width
```

### Scoring

```
score += base_points * combo_multiplier
combo increases on collection
combo resets after COMBO_WINDOW seconds
```

### Spawning

```
enemies_per_wave = BASE + GROWTH * (wave - 1)
spawn_interval = max(MIN, START - wave * DECAY)
wave_complete = (remaining == 0 AND alive == 0)
```

### Particles

```
position += velocity * dt
velocity += gravity * dt
alpha = life / maxLife
size *= shrink_factor
death = (life <= 0)
```

### Easing

```
easeOutQuad(t)     = 1 - (1-t)^2
easeInQuad(t)      = t^2
easeInOutQuad(t)   = 2t^2                     (t < 0.5)
                    = 1 - (-2t+2)^2 / 2       (t >= 0.5)
easeOutCubic(t)    = 1 - (1-t)^3
easeOutBack(t)     = 1 + c3*(t-1)^3 + c1*(t-1)^2
```

### Damping

```
damp(current, target, lambda, dt) = current + (target - current) * (1 - exp(-lambda * dt))
```

### Camera

```
screen_pos = world_pos - camera_pos
look_ahead_offset = velocity * look_ahead_distance / max_speed
shake_offset = random(-1, 1) * intensity * (timer / duration)
```

---

## 16. Appendix B — LÖVE2D API Reference

### Core Callbacks

| Callback | Signature | Purpose |
|----------|-----------|---------|
| `love.load` | `()` | Initialize game state, create fonts |
| `love.update` | `(dt)` | Advance simulation by dt seconds |
| `love.draw` | `()` | Render the current frame |
| `love.keypressed` | `(key)` | Fired once when a key is pressed |
| `love.keyreleased` | `(key)` | Fired once when a key is released |
| `love.mousepressed` | `(x, y, button)` | Fired once on mouse click |
| `love.mousereleased` | `(x, y, button)` | Fired once on mouse release |
| `love.mouse.getPosition` | `()` | Returns current mouse x, y |

### Input

| Function | Returns | Purpose |
|----------|---------|---------|
| `love.keyboard.isDown(key)` | `boolean` | Is this key held down? |
| `love.mouse.isDown(button)` | `boolean` | Is this mouse button held? |
| `love.mouse.getPosition()` | `x, y` | Current mouse position |

### Graphics

| Function | Purpose |
|----------|---------|
| `love.graphics.setColor(r, g, b, a)` | Set current draw color |
| `love.graphics.rectangle(mode, x, y, w, h)` | Draw rectangle |
| `love.graphics.circle(mode, x, y, r)` | Draw circle |
| `love.graphics.line(x1, y1, x2, y2)` | Draw line |
| `love.graphics.print(text, x, y)` | Draw text |
| `love.graphics.setFont(font)` | Set current font |
| `love.graphics.newFont(size)` | Create a font |
| `love.graphics.push()` | Save transform state |
| `love.graphics.pop()` | Restore transform state |
| `love.graphics.translate(x, y)` | Offset all drawing |

### Math

| Function | Purpose |
|----------|---------|
| `love.math.random()` | Random float 0-1 |
| `love.math.random(a, b)` | Random integer a-b |
| `love.math.noise(x, y)` | Perlin noise 0-1 |

### System

| Function | Purpose |
|----------|---------|
| `love.event.quit()` | Exit the game |
| `love.timer.getDelta()` | Time since last frame |

---

## 17. Appendix C — Complete Example Projects

### Example 1: Minimal Platformer

```lua
-- Save as main.lua and run with: love .
local player = {x = 100, y = 300, vx = 0, vy = 0, w = 24, h = 32}
local GRAVITY = 800
local JUMP = -400
local SPEED = 200
local FRICTION = 0.85
local grounded = false

local platforms = {
    {x = 0, y = 600, w = 1024, h = 168},
    {x = 200, y = 450, w = 150, h = 16},
    {x = 500, y = 350, w = 150, h = 16},
    {x = 750, y = 250, w = 150, h = 16},
}

function love.load()
    love.window.setTitle("Minimal Platformer")
end

function love.update(dt)
    -- Input
    if love.keyboard.isDown("right") then player.vx = SPEED end
    if love.keyboard.isDown("left") then player.vx = -SPEED end

    -- Gravity
    player.vy = player.vy + GRAVITY * dt

    -- Move
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
    player.vx = player.vx * FRICTION

    -- Platform collision
    grounded = false
    for _, p in ipairs(platforms) do
        if player.x + player.w > p.x and player.x < p.x + p.w
       and player.y + player.h > p.y and player.y + player.h < p.y + p.h + 20
       and player.vy >= 0 then
            player.y = p.y - player.h
            player.vy = 0
            grounded = true
        end
    end

    -- Reset if fallen
    if player.y > 800 then
        player.x = 100; player.y = 300
        player.vx = 0; player.vy = 0
    end
end

function love.keypressed(key)
    if key == "space" and grounded then
        player.vy = JUMP
    end
end

function love.draw()
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
    love.graphics.setColor(0.4, 0.4, 0.4)
    for _, p in ipairs(platforms) do
        love.graphics.rectangle("fill", p.x, p.y, p.w, p.h)
    end
end
```

### Example 2: Asteroid Shooter

```lua
local player = {x = 512, y = 384, angle = 0, vx = 0, vy = 0}
local bullets = {}
local asteroids = {}
local score = 0

function love.load()
    for i = 1, 8 do
        table.insert(asteroids, {
            x = math.random(0, 1024), y = math.random(0, 768),
            r = 20 + math.random() * 30,
            vx = (math.random() - 0.5) * 100,
            vy = (math.random() - 0.5) * 100,
        })
    end
end

function love.update(dt)
    if love.keyboard.isDown("left") then player.angle = player.angle - 3 * dt end
    if love.keyboard.isDown("right") then player.angle = player.angle + 3 * dt end
    if love.keyboard.isDown("up") then
        player.vx = player.vx + math.cos(player.angle) * 200 * dt
        player.vy = player.vy + math.sin(player.angle) * 200 * dt
    end

    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
    -- Wrap around screen
    player.x = (player.x + 1024) % 1024
    player.y = (player.y + 768) % 768

    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then table.remove(bullets, i)
        else
            for j = #asteroids, 1, -1 do
                local a = asteroids[j]
                local dx, dy = b.x - a.x, b.y - a.y
                if dx * dx + dy * dy < a.r * a.r then
                    table.remove(bullets, i)
                    table.remove(asteroids, j)
                    score = score + 10
                    break
                end
            end
        end
    end
end

function love.keypressed(key)
    if key == "space" then
        table.insert(bullets, {
            x = player.x, y = player.y,
            vx = math.cos(player.angle) * 400 + player.vx,
            vy = math.sin(player.angle) * 400 + player.vy,
            life = 1.5,
        })
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    for _, b in ipairs(bullets) do
        love.graphics.circle("fill", b.x, b.y, 2)
    end
    for _, a in ipairs(asteroids) do
        love.graphics.circle("line", a.x, a.y, a.r)
    end
    love.graphics.setColor(0.3, 0.8, 1)
    local px = player.x + math.cos(player.angle) * 15
    local py = player.y + math.sin(player.angle) * 15
    love.graphics.line(player.x, player.y, px, py)
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.print("Score: " .. score, 10, 10)
end
```

---

## 18. Appendix D — Derivations from First Principles

### D.1: Why position += velocity * dt

Velocity is defined as the rate of change of position:

```
v = dx / dt
```

Rearranging:

```
dx = v * dt
```

Since `dx = x(t+dt) - x(t)`:

```
x(t+dt) = x(t) + v * dt
```

This is the **Euler method** — the simplest numerical integration. It's accurate when dt is small (1/60 s is small enough for games).

### D.2: Why friction = v * f is exponential decay

If each frame multiplies velocity by `f`:

```
v(1) = v0 * f
v(2) = v0 * f^2
v(n) = v0 * f^n
```

This is an exponential function: `v(n) = v0 * f^n`. In continuous time:

```
v(t) = v0 * e^(-lambda * t)
```

where `lambda = -ln(f)`. For `f = 0.92`:

```
lambda = -ln(0.92) = 0.0834
```

The velocity decays to `1/e ≈ 37%` of its initial value after `1/lambda ≈ 12` frames (0.2 seconds).

### D.3: Why the AABB test has exactly four conditions

An AABB is the intersection of four half-planes:

```
x > left_edge     (right of left edge)
x < right_edge    (left of right edge)
y > top_edge      (below top edge)
y < bottom_edge   (above bottom edge)
```

Two rectangles overlap if and only if they share space in *all four* dimensions. Each condition checks one dimension. All four must be true — that's the logical AND.

### D.4: Why damping uses exp(-lambda * dt)

The continuous damping equation is:

```
dv/dt = -lambda * (v - target)
```

This is a first-order linear ODE. Its solution:

```
v(t) = target + (v0 - target) * e^(-lambda * t)
```

Discretized with step dt:

```
v(t+dt) = target + (v - target) * e^(-lambda * dt)
        = v + (target - v) * (1 - e^(-lambda * dt))
```

This is frame-rate-independent: the same lambda gives the same motion regardless of dt. At 30 fps (dt=1/30) and 600 fps (dt=1/600), the character reaches the same position after the same real time.

---

## 19. Appendix E — Further Reading

### Chapter 1 — Movement
- [Game Programming Patterns — Component](https://gameprogrammingpatterns.com/component.html)
- [Gabriel Gambetta — Fast-Adjusting Player Movement](https://www.gabrielgambetta.com/game-physics-tutorial.html)

### Chapter 2 — Input
- [LÖVE2D Wiki — Keyboard](https://love2d.org/wiki/love.keyboard)
- [LÖVE2D Wiki — Mouse](https://love2d.org/wiki/love.mouse)

### Chapter 3 — Collision Detection
- [N Tutorial — Collision Detection (Nehe)](https://nehe.gamedev.net/tutorial/collision_detection/)
- [Box2D Manual — Collision Detection](https://box2d.org/documentation/)

### Chapter 4 — Health and Damage
- [Red Blob Games — HP and Damage](https://www.redblobgames.com/)
- [Game Programming Patterns — Type Object](https://gameprogrammingpatterns.com/type-object.html)

### Chapter 5 — Scoring
- [GDC Talk — The Psychology of Scoring](https://www.gdcvault.com/)
- [Game Design Theory — Intrinsic vs Extrinsic Motivation](https://www.gamedeveloper.com/)

### Chapter 6 — State Machines
- [Game Programming Patterns — State](https://gameprogrammingpatterns.com/state.html)
- [VFSM (Visual FSM) — Wiki](https://en.wikipedia.org/wiki/Finite-state_machine)

### Chapter 7 — Cameras
- [Gaffer on Games — Camera in 2D Games](https://gafferongames.com/)
- [LÖVE2D Wiki — Graphics Push/Pop](https://love2d.org/wiki/graphics.push)

### Chapter 8 — Spawning
- [Red Blob Games — Spawn Patterns](https://www.redblobgames.com/)
- [Game Programming Patterns — Object Pool](https://gameprogrammingpatterns.com/object-pool.html)

### Chapter 9 — Particles
- [Red Blob Games — Particle Effects](https://www.redblobgames.com/)
- [LÖVE2D Wiki — Graphics Particles](https://love2d.org/wiki/love.graphics)

### Chapter 10 — Power-ups
- [Game Programming Patterns — Observer](https://gameprogrammingpatterns.com/observer.html)
- [GDC Talk — Juice It or Lose It](https://www.gdcvault.com/)

### Chapter 11 — UI and HUD
- [Game Programming Patterns — Double Buffer](https://gameprogrammingpatterns.com/double-buffer.html)
- [Human Interface Guidelines — HUD Design](https://developer.apple.com/)

### Chapter 12 — Screen Management
- [Game Programming Patterns — State](https://gameprogrammingpatterns.com/state.html)
- [Game Programming Patterns — Double Buffer](https://gameprogrammingpatterns.com/double-buffer.html)

### General
- [LÖVE2D Wiki](https://love2d.org/wiki/Main_Page)
- [Game Programming Patterns (book)](https://gameprogrammingpatterns.com/)
- [Red Blob Games (blog)](https://www.redblobgames.com/)
- [3Blue1Brown (math visualizations)](https://www.youtube.com/c/3blue1brown)

---

## 20. Appendix F — Terminology Glossary

**AABB** — Axis-Aligned Bounding Box. A rectangle whose edges are parallel to the screen axes. The simplest collision shape.

**Acceleration** — The rate of change of velocity. Measured in pixels per second squared (px/s^2).

**Accumulator** — A variable that collects leftover time from the real frame clock and spends it in fixed-size simulation steps.

**Alpha** — The opacity of a color, from 0 (invisible) to 1 (fully opaque). Used for fading particles and UI elements.

**Camera** — A position offset that determines which part of the world is visible on screen.

**Combo** — A multiplier that increases with rapid successive actions and resets after a timeout.

**Cooldown** — A timer that prevents an action from being repeated until it counts down to zero.

**Delta time (dt)** — The time elapsed since the last frame, in seconds. Fundamental to frame-rate-independent simulation.

**Damping** — Exponential smoothing toward a target value. Frame-rate-independent via the formula `1 - exp(-lambda * dt)`.

**ECS** — Entity-Component-System. An architecture where entities are IDs, components are data tables, and systems process them.

**Entity** — A game object with position, size, and properties (health, velocity, etc.).

**Euler integration** — The numerical method `x += v * dt`. Simple, fast, accurate enough for games.

**FSM** — Finite State Machine. An entity has one current state and transitions between states based on conditions.

**Friction** — A multiplier applied to velocity each frame that reduces it toward zero. Values between 0 and 1.

**HUD** — Heads-Up Display. UI elements drawn on top of the game world (HP bars, scores, minimaps).

**Hitbox** — The collision shape of an entity. Often smaller than the visual sprite for fairness.

**Hit-stop** — A brief freeze (2-6 frames) after a significant impact. Makes hits feel powerful.

**Invincibility frames** — A brief period after taking damage during which the entity cannot be hit again.

**Lerp** — Linear interpolation. `lerp(a, b, t) = a + (b - a) * t`. Blends between two values.

**Look-ahead** — A camera technique where the view shifts slightly in the direction of player movement.

**Minimap** — A small representation of the entire game world, showing entity positions.

**Normalized** — A vector scaled to length 1. Used to get direction without magnitude.

**Parallax** — Background layers that scroll at different speeds to create depth.

**Particle** — A tiny object with position, velocity, lifespan, and visual properties. Dies when lifespan expires.

**Polling** — Checking input state every frame (e.g., `love.keyboard.isDown`). Used for continuous actions.

**Screen shake** — Random offset applied to the camera position for a brief time. Adds impact to events.

**State stack** — A stack of game states that allows pausing and resuming. Push to pause, pop to resume.

**Terminal velocity** — The maximum speed reached when acceleration balances friction. `v_term = accel / (1 - friction)`.

**Timestep** — The time step of the simulation. Fixed timestep (1/60) ensures deterministic behavior.

**Trigger** — A collision shape that detects overlaps but doesn't cause physical responses. Used for pickups, zones.

**Velocity** — The rate of change of position. Measured in pixels per second (px/s).

**Wave** — A group of enemies spawned together with shared difficulty parameters.

**Wrapping** — When an entity moves off one edge of the screen, it reappears on the opposite edge.

---

*End of The Feynman Guide to Game Mechanics.*

