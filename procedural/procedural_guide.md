# The Feynman Guide to Procedural Animation

## A Complete Journey from Zero to Living, Breathing Game Characters

### Written in the spirit of Richard P. Feynman

---

> "What I cannot create, I do not understand."
> — Richard P. Feynman

---

## Table of Contents

1. [Preface — The Feynman Way](#1-preface)
2. [Chapter 1 — Time: The Raw Material of Motion](#2-chapter-1)
3. [Chapter 2 — Lerp and Interpolation](#3-chapter-2)
4. [Chapter 3 — Sine Waves: The Breath of Motion](#4-chapter-3)
5. [Chapter 4 — Damping and Springs: Following Targets](#5-chapter-4)
6. [Chapter 5 — Easing Curves: The Language of Feel](#6-chapter-5)
7. [Chapter 6 — Squash and Stretch: Elasticity & Game Feel](#7-chapter-6)
8. [Chapter 7 — Angles, Look-At, and Aiming](#8-chapter-7)
9. [Chapter 8 — Chains and Forward Kinematics](#9-chapter-8)
10. [Chapter 9 — Inverse Kinematics: Reaching the Target](#10-chapter-9)
11. [Chapter 10 — Noise: Organic Imperfection](#11-chapter-10)
12. [Chapter 11 — Secondary Motion: Inertia and Follow-Through](#12-chapter-11)
13. [Chapter 12 — Game Feel: Anticipation, Hit-Stop, Shake](#13-chapter-12)
14. [Chapter 13 — The Procedural Walker: Locomotion from Sine](#14-chapter-13)
15. [Chapter 14 — Putting It All Together: A Living Character](#15-chapter-14)
16. [Appendix A — Formulae Quick Reference](#16-appendix-a)
17. [Appendix B — LÖVE2D API Reference](#17-appendix-b)
18. [Appendix C — Complete Example Projects](#18-appendix-c)
19. [Appendix D — Derivations from First Principles](#19-appendix-d)
20. [Appendix E — Further Reading (vetted links per chapter)](#20-appendix-e)
21. [Appendix F — Terminology Glossary](#21-appendix-f)

---

## Companion App — Project Structure

Every chapter in this book has a runnable companion: the *Feynman Procedural Animation* LÖVE2D app, one interactive demo per chapter. This is how the project is organized so you can read a chapter and poke at its demo at the same time.

```
procedural/
├── main.lua            # Bootstrap: fonts, chapter dispatch, LOVE callbacks
├── conf.lua            # LÖVE2D window config (1024×768)
├── vec2.lua            # Tiny 2D vector library
├── utils.lua           # clamp/lerp/damp, easing curves, draw helpers
├── chapters/
│   ├── chapter1.lua    # Time — the clock as the raw material
│   ├── chapter2.lua    # Lerp — timeline vs per-frame interpolation
│   ├── chapter3.lua    # Sine waves — amplitude, frequency, phase
│   ├── chapter4.lua    # Damping & springs — chasing targets
│   ├── chapter5.lua    # Easing curves — the language of feel
│   ├── chapter6.lua    # Squash & stretch — elasticity & game feel
│   ├── chapter7.lua    # Angles, look-at, aiming — turret demo
│   ├── chapter8.lua    # Chains & forward kinematics — swaying tail
│   ├── chapter9.lua    # Inverse kinematics — two-bone reaching arm
│   ├── chapter10.lua   # Noise — Perlin imperfection
│   ├── chapter11.lua   # Secondary motion — springy tail
│   ├── chapter12.lua   # Game feel — hit-stop, shake, anticipation
│   ├── chapter13.lua   # The procedural walker — sine legs
│   └── chapter14.lua   # Integration — a living character
└── procedural_guide.md # This book
```

**How the modules fit together.** Each chapter is a plain Lua module that returns a table with the same interface:

- `init()` — resets all chapter state.
- `update(dt)` — advances the animation. `main.lua` calls it at a **fixed timestep** (`FIXED_DT = 1/60`) accumulated against the real frame delta, so every chapter is deterministic regardless of frame rate.
- `draw()` — renders the scene, the live-values panel, and the Feynman notes.
- `mousepressed(x, y, button)` — optional, chapter-specific interaction.
- `keypressed(key)` — optional, chapter-specific keys.

`main.lua` is just the dispatcher: it loads all fourteen chapters, forwards the LOVE callbacks, and draws the persistent header and control hints. `utils.lua` holds the handful of math primitives every chapter needs — `clamp`, `lerp`, `damp`, the easing curves, and drawing helpers — so chapters stay short and focused on their single idea.

**Running it.** From the `procedural/` directory, run `love .`. Controls:

```
1-9,0   chapters 1-10
-  =    chapters 11 and 12
Enter   chapter 13
]       chapter 14
SPACE   reset the current chapter
ESC     quit
```

Run the app, then read the corresponding chapter. Change a number, run again, watch what breaks — that loop *is* the book.

---

## 1. Preface — The Feynman Way

### Why this book exists

Hand-drawn animation is a craft of thousands of poses. Most tutorials tell you how to *buy* poses — keyframes, sprite sheets, animation clips — and never explain what motion *is*. That leaves you dependent on artists for every new creature, and it leaves your game feeling like a collection of clips stitched together.

This book is different. We're going to learn that animation is **a number changing with time** — and that once you see it that way, you can generate the whole motion with a few lines of math. No keyframes. No clips. Just a value, a law, and a clock.

Here's the Feynman approach:

1. **Start with what you already know.** You've seen a ball bounce, a tail wag, a character breathe. We begin there — with intuition — and then we *precisely* describe that intuition with mathematics.
2. **Derive everything from first principles.** We don't accept formulas on authority. We build them. If you understand why `1 - exp(-λ·dt)` is the right damping formula, you can derive almost everything else in procedural animation.
3. **Connect every equation to code.** Every formula in this book has a LÖVE2D code example. You will not just read about animation — you will *write* it, run it, and see it move.
4. **Embrace the approximations.** Game animation is not real animation. Real animation is physics. Game animation is enough math to *look* alive — and the difference between "looks alive" and "doesn't" is often one sign, one amplitude, one constant. That difference is the whole art.

### How to read this book

- **Read the maths.** Don't skip the derivations. They're short and they're the whole point.
- **Type the code.** Don't copy-paste. Your fingers need to learn what your brain is learning.
- **Break things.** Change a number. Set the damping lambda to 1. Remove the `-1` from the easing formula. Understanding comes from seeing what goes wrong.
- **Play with the demos.** Every chapter demo has keyboard and mouse controls — listed in the app's header — that let you change the exact constants the book talks about.

### What you need

- [LÖVE2D](https://love2d.org) installed (version 11.4+ recommended)
- A text editor (VS Code, Sublime, Neovim — whatever you like)
- Curiosity and a willingness to be confused (that's how learning works)

### Conventions

- Code blocks are Lua for LÖVE2D
- Math is written in plain text with `^` for exponents and `*` for multiplication
- Vectors are written as `(x, y)` tuples
- The variable `t` is **time in seconds**, `dt` is the **time since the last update**, and a value written `a → b` means "traveling from a to b"

---

## 2. Chapter 1 — Time: The Raw Material of Motion

### What animation really is

Animate a ball moving across the screen. What changed? The x-position. Everything else — the ball's color, size, rotation, the shadow under it — could stay fixed. Animation, at bottom, is a single act: **some number changes, and the change is a function of time.**

This seems trivial, but it reframes the entire craft. A game character is not a set of drawings. A game character is a *set of numbers* — an x, a y, an angle for the head, a scale for the torso — and a set of *laws* that say how those numbers evolve. Hand-drawn animation bakes the evolution into thousands of frames of art. Procedural animation bakes it into one equation.

### The clock

Your game has a clock: `t`, seconds since the level started. The demo's two balls are driven purely by `t`:

```
sawtooth:  p = (t mod PERIOD) / PERIOD          0 → 1, then snap to 0
triangle:  p = |(t mod PERIOD)/PERIOD - 0.5| · 2    0 → 1 → 0, bouncing
```

Both produce a position via `x = lerp(80, 944, p)`. Same clock, same range — the only difference is *how we reshape the clock*. The sawtooth runs to the right edge and teleports back; the triangle bounces off both edges. Neither one "knows" it is animating. They are pure functions: `x = f(t)`.

### The game loop

Your program is a loop. Each iteration (frame) it asks: *how much time passed since last frame?* That is `dt`. Then it asks every animated value to advance by `dt`.

```
while running:
    dt = now - lastFrameTime
    for every animated value v:
        v = v + f(v) * dt
    draw everything
```

Notice what we do **not** do: we don't assume a frame rate. We don't say "move 1 pixel per frame". We say "move 120 pixels per second" and multiply by the actual `dt`. A value moving 120 px/s covers 120 pixels in a real second whether the game runs at 30 fps or 300 fps. This is the *first law of procedural animation*: **motion is specified per second, never per frame.**

`main.lua` takes this one step further: it steps physics at a **fixed timestep** (`1/60 s`), accumulating the real `dt` until a whole fixed step is due. That makes every demo deterministic — the same inputs always produce the same motion, frame-rate independent.

### Dummy value walkthrough — two balls on the clock

```
PERIOD = 2.0 s.  t = 5.0 s.

Sawtooth: p = (5.0 mod 2.0)/2.0 = 1.0/2.0 = 0.5
          x = 80 + 0.5·(944-80) = 512        (mid-screen, moving right)

Triangle: p = |(5.0 mod 2.0)/2.0 - 0.5|·2 = |0.5-0.5|·2 = 0
          x = 80 + 0·864 = 80                (left edge, just bounced)

At t = 6.0:  sawtooth p = 0, x = 80  (teleported)
             triangle p = 1, x = 944 (arrived at right edge)
```

### Game mechanic: events are times

A game is not a smooth movie. It is *events* — a button press, a collision, a death — strung on a timeline. When you animate an event you pick its **start time** and **end time**, and every value that must move during the event is a function of `t` sliding between those two bounds.

In the demo, clicking stamps a red "event" onto the timeline. That stamp is the whole of event-driven design in miniature: the game stores *when* something happened, and any system — animation, audio, particles — can read the timeline and react at the right moment.

### Exercise 1

Make the sawtooth ball leave a fading trail (remember its last 30 positions, draw them with decreasing alpha). Then change the sawtooth formula so the ball accelerates as it travels: `p = ((t mod 1)^2)` over a 1-second period.

<details>
<summary>Solution</summary>

```lua
-- Save past positions instead of just the current one.
local trail = {}
local t = 0

function love.update(dt)
    t = t + dt
    local p = (t % 1)^2
    local x = 80 + p * 864
    table.insert(trail, {x = x, y = 300})
    if #trail > 30 then table.remove(trail, 1) end
end

function love.draw()
    for i = 1, #trail do
        local a = i / #trail
        love.graphics.setColor(1, a, a, a)
        love.graphics.circle("fill", trail[i].x, trail[i].y, 8)
    end
end
```

Squaring the phase makes `p` grow quadratically — the ball visibly speeds up toward the right edge. Same clock, same range, completely different feel. That is the entire book in one exercise.
</details>

---

## 3. Chapter 2 — Lerp and Interpolation

### Walking between two values

The single most common operation in animation: *go from A to B*. The operation that does it is **lerp** (linear interpolation):

```
lerp(a, b, t) = a + (b - a) * t
```

At `t = 0` you are exactly at `a`. At `t = 1` you are exactly at `b`. At `t = 0.5` you are halfway. That's all of it.

### Two ways to drive t — and why they feel different

The demo shows two balls chasing the same target, using the *same* `lerp` function, driven by *different* clocks. The feel difference is enormous.

**Timeline lerp.** A duration `D` is fixed (say 1 second). Each frame we advance `t += dt/D` and clamp to 1.

```
t = min(1, t + dt/D)
x = lerp(fromX, targetX, t)
```

The trip always takes exactly `D` seconds and always *arrives* — at `t = 1`, `x` is exactly `targetX`. Guaranteed. This is what tweens, cutscenes, and UI transitions use. Game designers love it because it is *predictable*: you can schedule the next thing for exactly the moment the current thing finishes.

**Per-frame lerp.** There is no duration. Each frame we swallow a fixed fraction of the remaining gap:

```
x = lerp(x, targetX, 0.06)
```

A fixed fraction per frame means the gap shrinks geometrically: 6% of what's left, then 6% of what's left, forever. It rushes fast at first and crawls forever after. It *never* quite arrives — after a second there is still `0.94^60 ≈ 2.4%` of the gap left. This is what follow-cameras and cursor smoothing use, where "arrival time" matters less than "never jittering".

### Dummy value walkthrough — never quite arriving

```
Start at x = 0, target at x = 100, factor 0.5.

Frame 1: x = 0 + (100-0)·0.5      = 50     gap 50
Frame 2: x = 50 + (100-50)·0.5    = 75     gap 25
Frame 3: x = 75 + (100-75)·0.5    = 87.5   gap 12.5
...
Frame n: gap = 100 · 0.5^n

After 10 frames: 100·0.5^10 ≈ 0.098 — 0.1 pixels away. Closer than a
pixel, but the FORMULA says it never reaches 100. Not a bug. A feature.
```

### Game mechanic: lerp decides responsibility

Choose the driver by who must pay the cost:

- **Timeline lerp** — the *animator* is responsible. The motion happens on schedule, exactly once, and ends. Use for attacks, doors, menus, cutscenes — anything that must complete.
- **Per-frame lerp** — the *player* is responsible. The motion reacts continuously to a moving target. Use for cameras, crosshairs, cursors — anything that must be smooth *right now*.

### Exercise 2

Build a health bar that drains: a red bar whose fill is the player's HP (0–100), and an inner yellow bar that lags behind it with per-frame lerp. When the player loses HP, the red drops instantly and the yellow drains down slowly — the classic "recent damage" bar.

<details>
<summary>Solution</summary>

```lua
local hp, displayed = 100, 100

function love.keypressed(k)
    if k == "x" then hp = math.max(0, hp - 25) end
end

function love.update(dt)
    displayed = displayed + (hp - displayed) * 0.08   -- per-frame lerp
end

function love.draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 100, 100, hp * 4, 30)          -- instant
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", 100, 140, displayed * 4, 30)   -- lagging
end
```

The yellow bar is a "memory" of where the health used to be. Games add that beat of lag because it makes the damage *feel* larger and gives the eye time to register the hit.
</details>

---

## 4. Chapter 3 — Sine Waves: The Breath of Motion

### The atom of organic motion

Watch a character idle. The chest rises and falls. The head drifts. The whole body sways a few pixels. All of it is one shape: the **sine wave**.

```
y(t) = center + A · sin(2π·f·t + φ)
```

Three dials:

- **A, amplitude** — how far from center it swings. Big A = exaggerated.
- **f, frequency** — how many cycles per second (Hz). High f = frantic.
- **φ, phase** — where in the cycle it starts. Two sines with the same A and f but different φ are the same motion *at a different time*.

One more useful quantity: **period** `T = 1/f`, the seconds per cycle.

### Why sine is everywhere in nature

A sine is a shadow. Imagine a wheel rolling at frequency `f`, with a dot glued to its rim. Look at the wheel edge-on and the dot bobs up and down — and the height of that bobbing is *exactly* `sin`. Almost everything that rocks, swings, or breathes does so because something is rotating: a pendulum, a heartbeat, the sun's path. So when a game character breathes, it is borrowing the shadow of a wheel.

### The demo

The chapter shows a green sine curve — sampled by plugging *x* into the sine instead of *t* — and a red ball riding the *same* sine in time. The curve is the formula *drawn*; the ball is the formula *lived*. Change amplitude and frequency with the arrow keys and watch both respond. Press `1` for a breath (0.25 Hz) and `2` for a heartbeat (1.2 Hz) and feel the difference between "alive and calm" and "alive and stressed".

### Dummy value walkthrough — breathing

```
A = 40 px, f = 0.25 Hz (one breath every 4 seconds), center y = 320.

y(t) = 320 + 40·sin(2π·0.25·t) = 320 + 40·sin(π·t/2)

t = 0.0 s:  sin(0)     = 0     → y = 320  (mid)
t = 1.0 s:  sin(π/2)   = 1     → y = 360  (chest up, full)
t = 2.0 s:  sin(π)     = 0     → y = 320  (mid)
t = 3.0 s:  sin(3π/2)  = -1    → y = 280  (chest down, full)
t = 4.0 s:  back to 320. One breath. ∞
```

### Game mechanic: idle life

A character that stands perfectly still looks dead. A character that breathes at 0.25 Hz, sways its head with a second sine, and blinks on a third is *alive* — and the player reads it without ever knowing why. Sines are the cheapest life you can buy.

### Exercise 3

Give the red ball a companion that follows it with a **phase lag** of 90° (`φ = π/2`), then combine both motions into a single ball that moves in a circle: `x = center.x + A·cos(2πf·t)`, `y = center.y + A·sin(2πf·t)`.

<details>
<summary>Solution</summary>

```lua
local t = 0
local cx, cy = 512, 384
local A, f = 120, 1

function love.update(dt) t = t + dt end

function love.draw()
    local w = 2 * math.pi * f * t
    -- Phase-lagged bobbing pair
    love.graphics.setColor(0.5, 0.7, 1)
    love.graphics.circle("fill", 300, 300 + A * math.sin(w), 12)
    love.graphics.circle("fill", 700, 300 + A * math.sin(w + math.pi / 2), 12)
    -- Circular motion = cosine and sine together
    love.graphics.setColor(1, 0.5, 0.3)
    love.graphics.circle("fill", cx + A * math.cos(w), cy + A * math.sin(w), 20)
end
```

The phase lag is why two identical bobbing balls look like a *wave* instead of a chorus line. And a circle is just sine and cosine trading places — the wheel again, seen face-on this time.
</details>

---

## 5. Chapter 4 — Damping and Springs: Following Targets

### The workhorse

Most procedural motion is not a scheduled trip — it is *chasing*. Something is at one value and constantly wants to be at another: the camera wants to be on the player, the head wants to face the mouse, the tail wants to follow the body. The chase happens every frame, forever.

If you chase naively with `x += (target - x) * 0.1` you get two bugs at once: the result depends on frame rate, and you can't reason about how *fast* the chase is. The fix is one formula, derived from the idea of continuous exponential decay (see Appendix D.1):

```
value += (target - value) * (1 - exp(-λ·dt))
```

`λ` (lambda) is the **chase rate**, in 1/seconds. It answers "how many times per second do I close the gap?":

- `λ ≈ 8` — rubbery, lazy, weighty. Tails, capes, slow cameras.
- `λ ≈ 20` — responsive but smooth. Aim assist, follow cameras.
- `λ ≈ 60` — snappy, nearly instant. Recoil reset, snap-back.

Crucially, `1 - exp(-λ·dt)` uses `dt`, so the *same* λ produces the *same* motion at any frame rate. This is the `utils.damp()` function every later chapter uses.

### A real spring is different

Exponential chase **forgets** its velocity — it can only ever approach, never overshoot. A **mass-spring** *remembers* velocity:

```
F = k·(target - x) - c·v      (Hooke's law + damping)
v += F·dt
x += v·dt
```

The spring is the chase with *momentum*. Because velocity carries over between frames, the spring can overshoot the target, swing back, and ring. The `c` term (`v`-opposing) kills that ringing: big `c` → critically/overdamped, small `c` → underdamped bounciness.

**Which do you want?** The demo answers with two balls on the same target: the blue ball (damp) cannot overshoot — good for a camera that must never jitter; the orange ball (spring) overshoots and rings — good for something that should *feel* bouncy, like a flag or a pickup.

### Dummy value walkthrough — one second of chase

```
λ = 20, dt = 1/60 s.  value = 0, target = 100.

1 - exp(-20/60) = 1 - exp(-0.3333) = 1 - 0.7165 = 0.2835

Frame 1: value = 0 + (100-0)·0.2835 = 28.35
Frame 2: value = 28.35 + (100-28.35)·0.2835 = 28.35 + 20.31 = 48.66
Frame 3: value = 48.66 + (100-48.66)·0.2835 = 48.66 + 14.56 = 63.22

After 1 second (60 frames): value ≈ 100·(1 - e^-20) ≈ 100·(1-2·10^-9) ≈ 100.
After 0.5 seconds (30 frames): value ≈ 100·(1 - e^-10) ≈ 100·(1-4.5·10^-5) ≈ 99.995.

The gap halves every t_half = ln(2)/λ ≈ 0.035 s. Rule of thumb: at λ·t = 5
the chase is 99.3% done — so "how long does it take" is roughly 5/λ seconds.
```

### Game mechanic: the camera

The single most important damp in any game is the camera. A camera pinned *exactly* to the player feels stiff and nauseating; one that lags with `damp(cam, player, λ≈8, dt)` floats smoothly and shows the world rushing past, which reads as speed. Press through the λ presets in the demo and watch the character of the chase change — this is what players mean when they say a game's camera "feels good" or "feels off".

### Exercise 4

Make a flag on a pole: a line of 6 points. The top point is pinned; each point chases the one above with `damp(…, λ=10, dt)`. Then add wind — push the top of the pole with `sin(t·3)`. The damp chain turns a moving top into a waving flag.

<details>
<summary>Solution</summary>

```lua
local pts = {}
for i = 1, 6 do pts[i] = { x = 512, y = 100 + i * 22 } end
local t = 0

function love.update(dt)
    t = t + dt
    local wind = math.sin(t * 3) * 60
    pts[1].x = 512 + wind
    pts[1].y = 100
    for i = 2, 6 do
        local l = 1 - math.exp(-10 * dt)
        pts[i].x = pts[i].x + (pts[i-1].x - pts[i].x) * l
        pts[i].y = pts[i].y + (pts[i-1].y - pts[i].y) * l
    end
end

function love.draw()
    for i = 2, 6 do
        love.graphics.line(pts[i-1].x, pts[i-1].y, pts[i].x, pts[i].y)
    end
end
```

One spring per joint, and the wind's push travels down the chain as a wave. Six lines, zero keyframes, a flag that reads as cloth. This exact pattern returns in Chapter 11 as secondary motion.
</details>

---

## 6. Chapter 5 — Easing Curves: The Language of Feel

### Reshaping time

A tween is a trip from A to B over a duration. The naive trip moves at constant speed — and constant speed feels *dead*. Real motion spends time carefully: it takes a moment to start, it settles as it stops. The tool that spends time is an **easing curve**: a function that takes the raw normalized time `t ∈ [0,1]` and returns a reshaped time.

```
eased_t = ease(t)
x = lerp(A, B, eased_t)
```

The easing function doesn't change the destination or the duration. It changes *where in the duration the speed lives*.

### The core curves

| Curve | Formula | Feeling |
|-------|---------|---------|
| linear | `t` | robotic, mechanical |
| easeOutQuad | `1 - (1-t)²` | starts fast, settles gently — *default* |
| easeInQuad | `t²` | starts slow, crashes in |
| easeInOutCubic | smooth at both ends | door opening, cameras |
| easeOutBack | overshoots past 1, snaps back | pop-in, UI bounce |

The demo runs five identical trips — same distance, same duration — with five different curves. Watch the dots: the linear one is the "wrong" one, and you can *feel* it. The `outBack` one overshoots the finish line and bounces back, which is why UI pop-ins use it: the overshoot is the brain's cue that something "arrived with energy".

### Dummy value walkthrough — where is the box?

```
A = 0, B = 100, duration 1 s, t = 0.5 s.

linear:    eased = 0.5                  → x = 50   (midway, half done)
easeIn:    eased = 0.5²  = 0.25         → x = 25   (still early — crawling)
easeOut:   eased = 1 - 0.5² = 0.75      → x = 75   (already late — rushing)
inOutCub:  eased = 4·0.5³ = 0.5         → x = 50   (mid, but soft at both ends)
easeBack:  eased ≈ 1.09                 → x = 109  (past the target, overshot)
```

At the *same raw time*, the curves are in completely different places. Easing is not about speed — it's about **scheduling attention**. You spend t slowly where the eye needs reading time and quickly where it doesn't.

### Game mechanic: feel is curves

Change the ease on a menu slide-in and the menu stops feeling like a menu. Change the ease on a damage flash and the hit stops feeling like a hit. This is the cheapest, highest-leverage polish in game development — and it's one line per tween.

### Exercise 5

Animate a UI panel sliding up from the bottom with `easeOutQuad`, and a coin-spawn "pop" with `easeOutBack`. Then flip both to `easeIn` and feel how "clumsy" they become.

<details>
<summary>Solution</summary>

```lua
local slide, pop, t = 0, 0, 0
local playing = true

function love.update(dt)
    if playing then
        t = math.min(1, t + dt / 1.2)
        slide = 1 - (1 - t)^2                  -- easeOutQuad
        local c1, c3 = 1.70158, 2.70158
        pop = 1 + c3 * (t - 1)^3 + c1 * (t - 1)^2  -- easeOutBack
    end
end

function love.draw()
    -- Panel: slides up, then settles
    love.graphics.rectangle("fill", 200, 700 - slide * 400, 600, 80)
    -- Coin: pops in with overshoot scale
    local s = 0.5 + 0.5 * pop
    love.graphics.push()
    love.graphics.translate(700, 300)
    love.graphics.scale(s, s)
    love.graphics.circle("fill", 0, 0, 40)
    love.graphics.pop()
end
```

The panel glides; the coin *springs*. Different curves, different personalities — this is how characters and UI get "voice" without art.
</details>

---

## 7. Chapter 6 — Squash and Stretch: Elasticity & Game Feel

### The most powerful lie in animation

No real ball squashes flat when it hits the ground. No real cartoon character stretches when it jumps. Yet squash-and-stretch is *the* highest-value game-feel tool, because the eye does not read it as "wrong physics" — it reads it as **energy**.

- Falling fast → **stretch** along the direction of motion. "I am full of momentum."
- Landing → **squash** against the ground. "I just gave all my energy away."
- Launching → **stretch** again. "And now I take it back."

The rules of thumb, distilled:

```
stretch ∝ velocity       stretch the axis of motion, squeeze the other
squash  ∝ impact         set on ground contact, then decay to 1
volume ~ conserved       stretch one axis → shrink the other (roughly)
always relax to scale 1  via damp, never jump to rest
```

### The demo

The chapter ball bounces on real-ish manual physics (gravity + restitution, no physics engine — the *visual* is the point). Three effects work together:

1. **Velocity stretch** — `stretch = damp(stretch, min(0.35, speed·0.0005), 15, dt)`. While falling fast the ball stretches along its velocity.
2. **Impact squash** — on ground contact, `squash += vy·0.0006`, capped at 0.45, then `damp(squash, 0, 22, dt)`.
3. **Combining** — `scaleY = 1 - squash + stretch`, `scaleX = 1 + squash·1.1 - stretch·0.8`. The ellipse is drawn with independent x/y radii, rotated to the velocity direction, so stretch points along motion and squash flattens across impact.

Note the damping everywhere: nothing ever jumps to rest. The squash *decays* back to 1 like a spring — that decay is what makes it look like *material* instead of a morph.

### Dummy value walkthrough — a landing

```
Ball falls at vy = 400 px/s. r = 30.

Stretch:  min(0.35, 400·0.0005) = 0.20
          → drawn elongated along velocity

Impact:   squash += 400·0.0006 = 0.24
          → scaleY = 1 - 0.24 + 0.20 = 0.96
            scaleX = 1 + 0.24·1.1 - 0.20·0.8 = 1.10
          → wide, short: a "splat" that lasts ~0.1s as it damps back

Bounce:   vy = -400·0.78 = -312. Stretch rebuilds as it rises.
```

### Game mechanic: feel without physics

Squash-and-stretch is how platformers make jumps feel good with zero additional mechanics. The landing squash is the "Oof", the takeoff stretch is the "Wheee". Players feel the weight of a character entirely through these two scales. Nothing else you can do — particles, sound, screen shake — lands as hard as the character itself briefly becoming an ellipse.

### Exercise 6

Add a "hit" reaction: when you press `X`, flash the ball red and apply a big squash that decays, plus a brief stretch along the horizontal. The character reads as "hurt" even though no actual physics changed.

<details>
<summary>Solution</summary>

```lua
local squash, stretch, hurt = 0, 0, 0

function love.keypressed(k)
    if k == "x" then
        squash = 0.5        -- big flatten
        stretch = 0.25      -- and a horizontal pull
        hurt = 0.4          -- flash timer
    end
end

function love.update(dt)
    squash = squash * math.exp(-12 * dt)   -- damp back to rest
    stretch = stretch * math.exp(-8 * dt)
    hurt = math.max(0, hurt - dt)
end

function love.draw()
    local sx = 1 + squash + stretch
    local sy = 1 - squash - stretch
    local c = hurt > 0 and {1, 0.3, 0.3} or {0.8, 0.8, 0.8}
    love.graphics.push()
    love.graphics.translate(512, 384)
    love.graphics.scale(sx, sy)
    love.graphics.setColor(c)
    love.graphics.circle("fill", 0, 0, 50)
    love.graphics.pop()
end
```

One keypress, one flash, one decay — and the character has "taken a hit" in the language players already speak.
</details>

---

## 8. Chapter 7 — Angles, Look-At, and Aiming

### Facing a target is one line of math

Every aiming system in every game reduces to the same question: *what angle should the weapon point so that it aims at the target?* The answer:

```
angle = atan2(target.y - self.y, target.x - self.x)
```

`atan2` is the "angle of a vector" function. It takes the vertical and horizontal differences and returns the angle from the +x axis. That's the whole of facing. Everything else in this chapter is *refinement* — and the refinements are where the game feel lives.

### Refinement 1: the constraint

A real turret cannot spin through its own hull. So after computing the desired angle, you clamp it into a cone of allowed fire:

```
clamped = center + clamp(wrap(diff(desired, center)), -half, +half)
```

Where `center` is the straight-ahead angle and `half` is how far the barrel may turn either side. The demo draws the allowed cone as a wedge; toggle the constraint (`C`) and watch the barrel sweep through the body — the unconstrained version is *correct math and wrong design*. Constraints are what make an aimer feel like a machine instead of a vector.

### Refinement 2: weight (lag)

A barrel that snaps to the target instantly feels weightless — like a laser pointer. Real weaponry takes a beat to swing around. A lazy spring on the angle gives exactly that:

```
diff   = wrap(desired - angle)
accel  = 60·diff - 12·velocity
velocity += accel·dt
angle  += velocity·dt
```

This is the Chapter 4 spring, applied to an angle. The barrel now *chases* the target and overshoots slightly when the target is fast — and the player reads the turret as *heavy*. Toggle lag (`S`) to feel the difference between a weightless pointer and a piece of machinery.

### Dummy value walkthrough — the cone

```
Turret at (512, 560), aiming up. Cone = ±70° from up (up is -90°).

Mouse at (700, 300): dx=188, dy=-260.
desired = atan2(-260, 188) = -0.944 rad = -54.1°.

Wrap against center:  -54.1 - (-90) = +35.9°. Inside ±70 → allowed.
Barrel aims at -54.1°. Good shot.

Mouse at (900, 200): dx=388, dy=-360.
desired = atan2(-360, 388) = -0.747 rad = -42.8°.
diff = -42.8 - (-90) = +47.2°. Inside cone → still allowed.

Mouse at (200, 200): dx=-312, dy=-360.
desired = atan2(-360, -312) = -2.283 rad = -130.8°.
diff = -130.8 - (-90) = -40.8°. OK → -130.8°.

Mouse at (200, 500): dx=-312, dy=-60.
desired = atan2(-60, -312) = -2.952 rad = -169.2°.
diff = -169.2 - (-90) = -79.2° < -70 → CLAMPED to -90-70 = -160°.
The barrel points as far left as it physically can — and no further.
```

### Game mechanic: aiming is the mechanic

Twin-stick shooters, tower-defense towers, tank turrets, and every first-person camera are the same `atan2` with different refinements. The cone is "can this weapon physically point there?" The lag is "how heavy is this weapon?" And the aim *error* — printed live in the demo — is the space where skill lives: a lagging turret makes leading shots necessary.

### Exercise 7

Turn the turret into a two-ball "snake eye": a head that always looks at the mouse (rotate an eye pair toward it) but can only look within a limited cone, and blinks by scaling the eye height with a sine.

<details>
<summary>Solution</summary>

```lua
local blink = 0

function love.update(dt)
    blink = blink + dt
end

function love.draw()
    local mx, my = love.mouse.getPosition()
    local headX, headY = 512, 300
    local a = math.atan2(my - headY, mx - headX)
    -- limited look cone
    local diff = a + math.pi / 2
    diff = math.max(-1.0, math.min(1.0, diff))
    a = -math.pi / 2 + diff

    love.graphics.push()
    love.graphics.translate(headX, headY)
    love.graphics.rotate(a)
    -- eyes
    local eye = 0.5 + 0.5 * math.abs(math.sin(blink * 2))
    love.graphics.circle("fill", -8, -6, 8)
    love.graphics.circle("fill", 8, -6, 8)
    love.graphics.setColor(0, 0, 0)
    love.graphics.ellipse("fill", -8, -6, 3, 3 * eye)  -- blink shrinks height
    love.graphics.ellipse("fill", 8, -6, 3, 3 * eye)
    love.graphics.pop()
end
```

The eyes rotate toward the mouse but the cone keeps the head from snapping around backwards — the character looks *humanly*. And the blink sine makes it alive between aims.
</details>

---

## 9. Chapter 8 — Chains and Forward Kinematics

### A tail is a column of sines

Take a chain of joints: shoulder→elbow→hand, hip→knee→foot, tail root→...→tip. **Forward kinematics (FK)** drives the chain from the root: decide the root's motion, and every child follows by applying its own rule on top.

For a swaying tail, the rule per joint is deliciously simple — a sine with a **phase offset** that grows down the chain:

```
angle[i] = A · sin(t·speed + i·offset)
```

The `offset` is the whole trick. If every joint used the same sine (offset 0), the tail would rock back and forth like a metronome — the "sway" mode in the demo. Add a phase offset per joint and the sine peaks *travel* down the chain — the "wave" mode. A snake, a flag, a stalk of wheat: all of them are this one line, with the offset tuned.

### The propagation

FK is *cheap* because there is no solving. Each joint's position is computed from its parent:

```
x[i] = x[i-1] + L·cos(angle[i])
y[i] = y[i-1] + L·sin(angle[i])
```

The parent moves, the child inherits, the grandchild inherits twice, and so on down the chain. The cost is O(N) — one cosine and sine per joint. This is why games with hundreds of soldiers can still sway every tail: FK has no solver loop to iterate.

### Dummy value walkthrough — the traveling wave

```
A = 0.6 rad, speed = 2 rad/s, offset = 0.55 rad per joint, 4 joints.

Joint 1: angle = 0.6·sin(t·2 + 0)       — leads
Joint 2: angle = 0.6·sin(t·2 + 0.55)    — lags 0.55 rad
Joint 3: angle = 0.6·sin(t·2 + 1.10)    — lags 1.10 rad
Joint 4: angle = 0.6·sin(t·2 + 1.65)    — lags 1.65 rad

At the moment joint 1 is at its rightmost peak, joint 2 is still
approaching it, joint 3 is mid-swing, joint 4 is headed back.
The peak moves from root to tip — that motion IS the wave.
```

### Game mechanic: arms and legs from sines

Marching arms, pumping legs, waving tentacles, and cheering crowds are all FK columns of sines with different offsets. A marching band animates an *army* with one formula. When you understand that the phase offset controls whether a chain sways together or waves apart, you can animate any number of articulated things — cheap, deterministic, and without a single sprite.

### Exercise 8

Build a tentacle that follows the mouse: FK from the root with the tip drifting toward the mouse, each joint's angle = `damp` toward the angle of the previous joint (so the chain bends to follow) — then add the wave offset on top so it wriggles as it follows.

<details>
<summary>Solution</summary>

```lua
local N, L = 8, 26
local ang = {}
for i = 1, N do ang[i] = 0 end
local t = 0

function love.update(dt)
    t = t + dt
    local mx, my = love.mouse.getPosition()
    local x, y = 512, 700
    for i = 1, N do
        -- desired angle from this joint toward the mouse
        local want = math.atan2(my - y, mx - x)
        local diff = (want - ang[i] + math.pi) % (2 * math.pi) - math.pi
        ang[i] = ang[i] + diff * (1 - math.exp(-6 * dt))
        x = x + L * math.cos(ang[i])
        y = y + L * math.sin(ang[i])
    end
end
```

Each joint rotates toward the mouse with damp — the chain follows and bends into an arm. Combine with a sine offset per joint and you have a wriggling tentacle that still reaches. That's FK + damp + sine, three chapters, one creature part.
</details>

---

## 10. Chapter 9 — Inverse Kinematics: Reaching the Target

### The inverse problem

FK asks "given the angles, where is the hand?" — easy, just propagate. **Inverse kinematics (IK)** asks the hard question: *"given where I want the hand, what must the angles be?"* Every reaching hand, stepping foot, and planted spider leg is this question, solved every frame.

For a two-bone arm — shoulder → elbow → hand, both links fixed length `L1`, `L2` — the answer is pure geometry. The reachable region is an **annulus**: a ring between `|L1 - L2|` and `L1 + L2`. Inside that ring, the target, shoulder, and elbow form a triangle whose sides are all known, and the **law of cosines** gives the elbow angle directly:

```
d = distance(shoulder, target)
cos(γ) = (L1² + d² - L2²) / (2·L1·d)
γ = acos(cos(γ))          -- the shoulder's elbow bend
```

### The two poses, and which one you get

A triangle has two mirror images. Reach for an apple and your elbow can pass either side of the line shoulder→hand. The math produces both; the *sign* you choose picks which:

```
shoulderAngle = atan2(dy, dx) + elbowSide · γ
```

`elbowSide = +1` is "right-handed", `-1` is "left-handed". Toggle it in the demo (`E`) and watch the arm flip through its shoulder without ever breaking the reach. This is why IK characters don't look broken: they remember which arm they are.

### Out of reach

If the target is outside the annulus, `|cos(γ)| > 1` and `acos` would fail. The fix is not to break the arm but to *read the reach*: clamp `d` into `[|L1-L2|, L1+L2]` and the arm locks straight toward the target — fully extended, "I can't get there, but I'm trying." The demo colors nothing differently, but the arm visibly straightens. Games do exactly this when a door handle or a ledge sits just past the character's grasp: the reach is a *readable* physical fact, not a bug.

### Dummy value walkthrough — the law of cosines in action

```
L1 = 160, L2 = 140, shoulder at (300, 560), hand at (500, 400).

d = sqrt((500-300)² + (400-560)²) = sqrt(40000 + 25600) = sqrt(65600) ≈ 256.1

cos(γ) = (160² + 256.1² - 140²) / (2·160·256.1)
       = (25600 + 65587 - 19600) / 81952
       = 71587 / 81952 ≈ 0.8736
γ = acos(0.8736) ≈ 0.5075 rad ≈ 29.1°

Base direction: atan2(-160, 200) = -0.6747 rad ≈ -38.7°
Right-handed:  shoulder angle ≈ -38.7° + 29.1° = -9.6°
Left-handed:   shoulder angle ≈ -38.7° - 29.1° = -67.8°

Two valid arms. One reach. The sign is the choice.
```

### Game mechanic: feet and hands are IK

Foot IK plants feet on slopes and steps; hand IK reaches for ledges and picks up items. A character that floats flat-footed on stairs is instantly read as fake; one whose feet IK-plant onto each step is read as *grounded*. IK is the difference between a character standing *on* the world and standing *near* it.

### Exercise 9

Extend the arm to three bones by solving two two-bone chains: first place the mid-joint halfway along the target distance with the standard two-bone solve, then solve the second half-shoulder→mid→target. Bonus: draw the reachable annulus.

<details>
<summary>Solution</summary>

```lua
-- Two-bone solve, returns the elbow angle. Reused for both halves.
local function twoBone(a, b, d)
    local cosG = (a*a + d*d - b*b) / (2 * a * d)
    cosG = math.max(-1, math.min(1, cosG))
    return math.acos(cosG)
end

local L1, L2, L3 = 100, 90, 80
local shoulder = { x = 300, y = 560 }
local hand = { x = 600, y = 300 }

function love.update(dt)
    hand.x, hand.y = love.mouse.getPosition()
end

function love.draw()
    local dx, dy = hand.x - shoulder.x, hand.y - shoulder.y
    local d = math.sqrt(dx*dx + dy*dy)
    -- pick a mid-point inside the reach
    local frac = math.min(1, d / (L1 + L2))
    local midX = shoulder.x + dx * frac * 0.5
    local midY = shoulder.y + dy * frac * 0.5

    local g1 = twoBone(L1, L2, d * frac)
    local a1 = math.atan2(midY - shoulder.y, midX - shoulder.x) + g1
    local elbow = { x = shoulder.x + L1 * math.cos(a1), y = shoulder.y + L1 * math.sin(a1) }

    local g2 = twoBone(L2, L3, d * (1 - frac))
    local a2 = math.atan2(hand.y - elbow.y, hand.x - elbow.x) + g2
    local wrist = { x = elbow.x + L2 * math.cos(a2), y = elbow.y + L2 * math.sin(a2) }

    love.graphics.line(shoulder.x, shoulder.y, elbow.x, elbow.y, wrist.x, wrist.y, hand.x, hand.y)
end
```

Chain the solves and the reach gets longer and more expressive. Every limb in every game is this same recursion: split, solve, repeat.
</details>

---

## 11. Chapter 10 — Noise: Organic Imperfection

### Sine repeats. Life doesn't.

A sine is periodic: the same shape, forever. Leaves, water, smoke, breath, trembling hands, camera drift — none of them repeat. They wander. The mathematical object that wanders smoothly and never repeats is **noise**, and LÖVE ships it: `love.math.noise(x, y, ...)` returns a smooth, deterministic, unboundedly-differentiable value in `[0,1]`.

*Deterministic* is the key word. Give `love.math.noise` the same coordinates and it returns the same value, every time — so noise is still a function of time, just a bumpier one. Games exploit this for reproducible world generation, for animation that can be replayed, and for saving/loading state that includes the "random" motion.

### One noise, many uses

Sample the same function different ways and it becomes different things:

```
1D in space:   y = noise(x · 0.005, t)          → a wobbling line
2D in space:   y = noise(x·k, y·k, t)           → a drifting field
1D in time:    o = noise(t · speed)             → a value that wanders
```

The demo draws all three at once: a wobbling green line (1D along x), a field of drifting motes (2D in x and y, time as the third axis), and a "tremble" that never quite repeats. Two motes never drift the same way because they sample noise at different positions — the same function, different coordinates, different stories.

### How much noise, and how fast

Two knobs matter more than any other:

- **Scale** (how far apart you sample): sample `noise(x/100, t)` and the features are broad and slow; sample `noise(x*10, t)` and they're tight and spiky. Small scale = gentle hills, large scale = fine sand.
- **Speed** (how fast `t` advances): slow = drifting, fast = jitter.

An idle character breathing on a sine gets a *little* noise added on top — `breath + noise(t)·2` — and the breath becomes human. A camera pinned to a path gets noise added and the world feels hand-held. The recipe is always: **take a clean signal, add a small wobble.**

### Game mechanic: alive is a lie you can hear

The difference between a character that stands still and one that trembles 2 pixels on noise is the difference between "paused" and "waiting". Leaves, torches, water, dust, idle animations, menu backgrounds — noise is the cheapest "alive" filter in the engine. And because it's deterministic, two players on the same seed see the same leaves, and replays stay exact.

### Exercise 10

Make a flame: three stacked ellipses whose height, width, and horizontal sway are all `noise`-driven at slightly different scales, plus an inner flame that moves a touch faster. Then make the whole thing loop-free and non-repeating.

<details>
<summary>Solution</summary>

```lua
local t = 0

function love.update(dt) t = t + dt end

function love.draw()
    local bx, by = 512, 420
    local w, h = 40, 90
    -- three layers: outer slow, mid, inner fast
    for i = 1, 3 do
        local s = i * 0.6
        local sway = (love.math.noise(t * 2 + i * 7) - 0.5) * 14 * i
        local wid = (w * (1 + i * 0.25)) * (0.8 + 0.4 * love.math.noise(t * 1.5 + i))
        local hei = (h - i * 16) * (0.8 + 0.5 * love.math.noise(t * 2.5 + i * 3))
        love.graphics.setColor(1, 0.4 * i / 3 + 0.2, 0.05)
        love.graphics.ellipse("fill", bx + sway, by - hei / 2, wid / 2, hei / 2)
    end
end
```

Three layers of noise at different scales, and the flame wavers like it has a breeze inside it. No two frames are alike; no frame ever repeats.
</details>

---

## 12. Chapter 11 — Secondary Motion: Inertia and Follow-Through

### The motion you don't animate

A character stops. The *character* stops — but the hair, cape, tail, coat, and belly keep going for a beat, then swing back past, then settle. That trailing overshoot is **secondary motion**, and it is what sells weight. You almost never animate it by hand; you *build* it with springs, and let it animate itself.

The pattern is the Chapter 4 damp, chained:

```
link[1] chases the head
link[2] chases link[1]
link[3] chases link[2]
...and so on down the chain
```

Each link is one `damp()` behind its parent. The head moves; the chain lags in order, and the *lag itself* is the animation. Stop the head and the tail keeps flowing forward (inertia), then settles (spring decay).

```
link[i].x = damp(link[i].x, link[i-1].x, λ, dt)
```

### The λ dial

One number controls the whole personality of the tail:

- `λ ≈ 8` — the tail flows and drips, lagging far behind. Weighty, lazy.
- `λ ≈ 20` — springy, responsive, with visible overshoot.
- `λ ≈ 60` — stiff, nearly rigid. Almost no secondary motion at all.

The demo's `1/2/3` keys are these three, and the difference is dramatic. Low λ is the "whip" of a tail or cape; high λ is the "grip" of an arm held firm. The character's *feel* — floppy, bouncy, or stiff — is literally one number.

### The constraint that keeps it honest

A chain of pure damps will stretch: with constant damping each link keeps a finite gap from its parent, and the tail grows longer than its bones. Real tails have fixed-length bones, so after damping we **constrain length** — pull each link back to exactly `SEG` from its parent:

```
dx = link[i].x - link[i-1].x;  d = sqrt(dx² + dy²)
if d > SEG·1.4 then
    link[i].x = link[i-1].x + (dx/d)·SEG
    link[i].y = link[i-1].y + (dy/d)·SEG
end
```

This is a *tolerance* version of a hard constraint: let the springs flow, but if they drift too far, snap the distance back. Games do exactly this with capes and hair — springs for the feel, then a length clamp so the cloth doesn't grow.

### Dummy value walkthrough — why the tail overshoots

```
λ = 14. Head at rest at x=0. At t=0 the head jumps to x=100 and holds.

link1 chases with the damp formula.
At t = 5/λ ≈ 0.36 s it is ~99% of the way to 100 — and so is link2,
but link2 started later, so it lags slightly behind link1, and link3
behind link2. The tail is now stretched like a wave: the tip is still
flowing toward 100 while the head has already arrived.

Then the head stops moving. link1 slows as it arrives. But link2 still
has velocity toward 100 — it overshoots past link1, then springs back.
That overshoot at the tip is the visible "weight" of the tail.
```

### Game mechanic: weight is free

Secondary motion is the cheapest believable weight in games. Attach one damp-chain to a character's idle and they have a tail; to their cape and they have cloth; to their belly and they have jiggle. Players read *mass* from the lag without ever knowing the formula. This is also why the "follow-through" of Chapter 12's punch matters: the body's overshoot after the hit is the same spring, timed by the same clock.

### Exercise 11

Give the head a "pulse" mechanic — press `X` to lunge the head forward 120 px and back — and watch the tail whip. Then add a second chain hanging *down* (gravity tail) with the same damp but a constant downward pull on each link.

<details>
<summary>Solution</summary>

```lua
local headX, headY = 512, 300
local tail = {}
for i = 1, 8 do tail[i] = { x = 512 - i * 24, y = 300 } end

function love.keypressed(k)
    if k == "x" then headX = 632 end       -- lunge forward
end

function love.update(dt)
    -- return the head (spring back)
    headX = headX + (512 - headX) * (1 - math.exp(-6 * dt))
    -- gravity tail: also pulled down 40 px/s²
    tail[1].x = tail[1].x + (headX - tail[1].x) * (1 - math.exp(-10 * dt))
    tail[1].y = tail[1].y + (headY - tail[1].y) * (1 - math.exp(-10 * dt))
    for i = 2, 8 do
        local l = 1 - math.exp(-10 * dt)
        tail[i].x = tail[i].x + (tail[i-1].x - tail[i].x) * l
        tail[i].y = tail[i].y + (tail[i-1].y - tail[i].y) * l + 40 * dt
    end
end

function love.draw()
    for i = 2, 8 do
        love.graphics.line(tail[i-1].x, tail[i-1].y, tail[i].x, tail[i].y)
    end
    love.graphics.circle("fill", headX, headY, 20)
end
```

The `+ 40·dt` on each link is a constant downward acceleration — the tail now hangs *and* follows, which is how every gravity-attached appendage in games behaves.
</details>

---

## 13. Chapter 12 — Game Feel: Anticipation, Hit-Stop, Shake

### Animating the timeline itself

So far we animated values. This chapter animates **time**. A punch is not one motion — it's four timed phases, and the *phase lengths* are the entire game feel:

```
anticipation   0.18 s    draw the fist back, squash down   → "I'm about to hit"
strike         0.06 s    lunge forward                     → the punch moment
hit-stop       0.12 s    FREEZE both characters            → let the eye register
follow-through 0.25 s    recover, relax, shake decays      → release the force
```

### Anticipation

Before the hand moves forward it moves *back*. This is not wasted motion — it's a **telegraph**. The brain reads "draw back" as "something is coming" and prepares. A punch with no anticipation feels like a teleport; the same punch with 0.18 s of wind-up feels *committed*. The demo squashes the body down during the wind-up: anticipation is a spring, and the strike is the spring releasing.

### Hit-stop

The most magical line in this chapter:

```
on strike:
    freeze the world clock for 0.12 seconds
```

For 120 milliseconds *nothing moves*. The punch has landed; the freeze gives the eye time to actually see the impact instead of glossing over it in a motion blur. Games that hit-stop feel *harder* than games that don't — same damage, same animation, half the power. Toggle hit-stop off in the demo (`C`) and compare: the same punch, suddenly mushy.

The implementation is trivial: in the update, when in the `stop` phase, don't advance any animation time — or advance a *separate* clock while the world clock is frozen.

### Screen shake

Shake is the force leaving the impact. A decaying noise offset on the whole world:

```
shake = 14 on strike, then damp(shake, 0, 10, dt)
offset = (random-0.5) · 2 · shake    applied to the whole draw
```

The world rumbles *exactly* when the hit lands, then settles. Shake magnitude is the "impact weight"; its decay speed is the "camera stability". Small, fast decays feel tight and sharp; big slow decays feel like an earthquake.

### Dummy value walkthrough — the four phases in ms

```
windup 0.18 s = 180 ms — fist at -2.2 rad (drawn back), body sunk 16 px
strike 0.06 s =  60 ms — fist lurches to +0.4 rad, shake = 14
stop   0.12 s = 120 ms — clock frozen; fist pinned at the hit
follow 0.25 s = 250 ms — arm relaxes, shake decays to 0

Total with hit-stop: 180+60+120+250 = 610 ms
Total without:       180+60+250     = 490 ms

The 120 ms of freeze is the difference between "hit" and "thud".
```

### Game mechanic: timing is the mechanic

Anticipation, hit-stop, and follow-through are how fighting games, platformers, and shooters make *every hit* feel different from every other. The same attack animation with different phase lengths is a light jab or a haymaker. When you control the timeline — not just the values on it — you control how the game *feels* moment to moment. That is game feel.

### Exercise 12

Add hit-stop and shake to Chapter 6's bouncy ball: when it lands with `vy > 300`, freeze the ball's motion for 80 ms and shake the screen at magnitude `vy/30`. Feel how much heavier the same bounce becomes.

<details>
<summary>Solution</summary>

```lua
local freeze, shake = 0, 0

-- on impact:
--   freeze = 0.08; shake = math.min(18, vy / 30)

function love.update(dt)
    if freeze > 0 then
        freeze = freeze - dt       -- world clock paused
    else
        -- ball physics runs here
    end
    shake = shake * math.exp(-8 * dt)
end

function love.draw()
    local sx = (love.math.random() * 2 - 1) * shake
    local sy = (love.math.random() * 2 - 1) * shake
    love.graphics.push()
    love.graphics.translate(sx, sy)
    -- draw ball
    love.graphics.pop()
end
```

One `if` around the physics, one decaying `shake`, and the same bounce goes from "animation" to "impact". This is why two games with identical artwork feel completely different: the timeline, not the pixels.
</details>

---

## 14. Chapter 13 — The Procedural Walker: Locomotion from Sine

### The crown jewel

Walking is the most rewarding thing you can generate procedurally, because everyone has walked and everyone can tell a fake stride from a real one. And yet the whole thing is two sines, an opposite-phase pair:

```
footA = A·sin(2π·f·t)         -- front leg swings
footB = A·sin(2π·f·t + π)     -- back leg, exactly opposite
```

The `+π` is the entire trick. When foot A is at its forward peak, foot B is at its back peak. One foot is always planted while the other travels — that's what "walking" means, and two opposite-phase sines produce it for free. The legs are then FK chains: hip + `FOOT_LEN·cos(angle)` gives the foot, one segment, no solving.

### The bob and the arms

Two refinements turn the legs into a walker:

- **Body bob** — the torso rises between steps: `bob = |sin(2π·f·t)|·8`. A walker that stays perfectly level looks like a robot on a rail; the 8-pixel bob is the bounce that says "I'm alive".
- **Counter-swing arms** — arms swing opposite to the *same-side* leg: `handAngle = -footAngle`. Left arm with right leg. This cross-coupling is what the brain reads as "natural gait"; without it, the walker looks like it's marching.

### Cadence from input — motion follows mechanics

Here is the game mechanic hiding inside the walker: the cadence `f` is not a constant. It comes from the player's input. The character walks faster → the legs cycle faster:

```
cadence = MAX_CADENCE · (|speed| / MAX_SPEED)
walkT += cadence · dt
```

This is the core principle of procedural-animation game mechanics: **the animation is downstream of the mechanics**. Input sets the speed; speed sets the cadence; cadence sets the phase; phase produces the stride. Nothing is hard-coded to a walk cycle because the walk cycle *is* a function of the mechanics. When the player stops, `speed → 0`, the cadence → 0, and the character settles into a planted idle — automatically, from the same formula that walked it.

### Dummy value walkthrough — half a stride

```
A = 0.55 rad, FOOT_LEN = 46, cadence 1.6 Hz. Hip at (512, 580).

Phase t=0:   footA = 0.55·sin(0)      = 0       → foot at hip x
             footB = 0.55·sin(π)      = 0       → foot at hip x

t=0.156s (π/2 rad): footA = 0.55·sin(π/2) = 0.55 → fwd peak
                    footA.x = 512 + 46·cos(0.55) = 512 + 39.3 = 551
                    footB   = 0.55·sin(3π/2) = -0.55 → back peak
                    footB.x = 512 + 46·cos(-0.55) = 512 + 39.3 = 551? 
                    No — footB y differs, footB.x = 512 + 46·cos(-0.55) ≈ 551
                    both "forward" in x but opposite in Y: A up, B down.
                    One foot is lifting, the other planting. The stride
                    reads because the Y separation is what lifts the foot.

t=0.312s (π rad): back to 0. One full step of the phase = one stride pair.
```

The "x same, y opposite" detail is why the walker doesn't slide: when the forward leg reaches its peak it *plants* (y near ground) while the trailing leg *lifts* (y up). The two sines trade being the planted foot, and the character advances without its feet ever slipping through the floor.

### Game mechanic: locomotion is feel

The walker's feel is three dials: `A` (how big the steps are — stride), `MAX_CADENCE` (how fast they cycle — urgency), and the bob amount (how much bounce — bounciness vs. stiffness). Every character in every game is these three numbers, and every *character* gets a different personality from them: a guard marches with small A and high cadence; a toddler stumbles with big A and low cadence. Same walker, different numbers.

### Exercise 13

Add feet planting: when a foot reaches its forward peak, freeze its angle for a moment (a short dwell) so the foot visibly *plants* before the stride continues — then add footprints at the plant moment, like the demo.

<details>
<summary>Solution</summary>

```lua
local t = 0
local AMP, F, LEN = 0.55, 1.6, 46
local planted = {}

function love.update(dt)
    t = t + dt
    local ph = t * 2 * math.pi * F
    -- foot dwell: hold the front foot 25% of the cycle
    local hold = math.min(1, math.abs(math.sin(ph)) * 4)
    local fa = AMP * math.sin(ph) * hold
    local fb = AMP * math.sin(ph + math.pi) * hold
    -- footprint at front peak
    if math.abs(math.sin(ph)) > 0.98 then
        table.insert(planted, { x = 512 + LEN * math.cos(fa), y = 600 })
    end
end
```

The `hold` factor pins each foot at its peak for a beat — the foot is *on the ground* while the body passes over it. That dwell is the difference between a walker and a slide-animator.
</details>

---

## 15. Chapter 14 — Putting It All Together: A Living Character

### One creature, every tool

The last chapter is a single creature that uses every technique in the book at once. It is a *game object*, not a drawing: input changes its mechanics, and its animation is entirely downstream.

| Part | Built from | Chapter |
|------|-----------|---------|
| Walking legs + bob | two sines, cadence from speed | 13 |
| Idle breathing | sine at 0.25 Hz on the chest | 3 |
| Head aiming at mouse | `atan2` + clamped look cone | 7 |
| Squash on landing, stretch on falling | velocity stretch + impact squash | 6 |
| Tail dragging behind | damp-chain secondary motion | 11 |
| Nose tremble | `love.math.noise` | 10 |
| Camera follow | `damp(λ=8)` | 4 |
| Hop landing feel | hit-stop + screen shake | 12 |

The body parts do not know about each other. The legs read `creature.walkT`; the head reads the mouse; the tail reads the body's position; the camera reads the creature. Each system is a pure function of its inputs, and the *composition* is the character.

### Read it as a recipe

Walking the loop through one hop:

```
SPACE pressed, grounded → vy = -420, squash = 0.12 (anticipation)
update: vy += 1500·dt, y += vy·dt
        stretch = damp(stretch, min(0.3, |vy|·0.0003))   → stretches on the way up
        head aims at mouse via atan2 + cone clamp
        tail chases body with damp chains
        camera damp-follows
landing: vy > 0 and not grounded → squash += |vy|·0.0005, hop = 0.15
         hop > 0 → screen shakes at 6·(hop/0.15)
         squash damps back to 0
```

Notice what did **not** happen: no animation state machine, no clips, no pose blending. Every value moved because a number and a law told it to. That is the entire philosophy of the book, and it is why a procedural character can be dropped into any game state — running, jumping, hurt, dead — and never "play the wrong animation", because there is no animation to get wrong. There are only numbers, and the numbers respond.

### The lesson of the whole book

You now hold a small set of laws:

- **Motion is a function of time** (Ch 1, 3)
- **Interpolate** to travel between values (Ch 2, 5)
- **Damp** to chase, **spring** to overshoot (Ch 4)
- **Squash and stretch** to sell energy (Ch 6)
- **atan2** to face, **clamp** to constrain (Ch 7)
- **FK** to build, **IK** to solve (Ch 8, 9)
- **Noise** to make it alive (Ch 10)
- **Chained springs** for secondary motion (Ch 11)
- **Time** itself is a value — freeze it, shake it (Ch 12)
- **Input drives the animation** — motion follows mechanics (Ch 13)

With these, you can build any creature, any motion, any feel — from a bouncing ball to a breathing, walking, aiming character with a wagging tail. You are no longer limited to the animations someone drew for you. You can generate them yourself. That is the whole point of the book.

### Exercise 14

Add one new part to the creature: an arm that reaches toward the mouse with the two-bone IK from Chapter 9, damped so it lags — and blink the creature's eyes with a noise-gated sine (eyes closed when `noise > 0.9` for a frame).

<details>
<summary>Solution</summary>

```lua
-- Arm: shoulder at torso, hand damped toward mouse, two-bone solve.
local shX, shY = creatureX, creatureY - 30
local hx = utils.damp(hx, mouseX, 12, dt)
local hy = utils.damp(hy, mouseY, 12, dt)
local dx, dy = hx - shX, hy - shY
local d = math.sqrt(dx * dx + dy * dy)
local L1, L2 = 60, 55
local frac = math.min(1, d / (L1 + L2))
local g = math.acos(math.max(-1, math.min(1, (L1*L1 + (d*frac)^2 - L2*L2) / (2 * L1 * d * frac))))
local a = math.atan2(dy, dx) + g
local elbowX, elbowY = shX + L1 * math.cos(a), shY + L1 * math.sin(a)
-- draw shoulder→elbow→hand

-- Blink: eyes close when noise crosses 0.9.
local blink = love.math.noise(t * 8) > 0.9 and 1 or 0
-- eye height *= (1 - blink)
```

The arm is Chapter 9's solve with a damp on the hand; the blink is Chapter 10's noise as a *trigger*. Every new part is an old chapter — that's the entire curriculum, composed.
</details>

---

## Appendix A — Formulae Quick Reference

### Time and interpolation

| Concept | Formula |
|---------|---------|
| Lerp | `lerp(a, b, t) = a + (b - a)·t` |
| Clamp | `clamp(v, lo, hi) = min(max(v, lo), hi)` |
| Frame-rate-independent damp | `v += (target - v)·(1 - exp(-λ·dt))` |
| Spring (Hooke + damping) | `F = k·(target - x) - c·v` |
| Half-life of damp chase | `t½ = ln(2) / λ` |

### Waves and noise

| Concept | Formula |
|---------|---------|
| Sine | `y = center + A·sin(2π·f·t + φ)` |
| Period | `T = 1 / f` |
| Circular motion | `x = cx + R·cos(2π·f·t)`, `y = cy + R·sin(2π·f·t)` |
| Perlin noise | `love.math.noise(x[, y[, z]]) ∈ [0,1]` |

### Angles

| Concept | Formula |
|---------|---------|
| Angle to target | `θ = atan2(ty - y, tx - x)` |
| Wrap angle to ±π | `diff = (a - b + π) % 2π - π` |
| Cone clamp | `center + clamp(wrap(θ - center), -half, half)` |

### Easing (t ∈ [0,1])

| Curve | Formula |
|-------|---------|
| Linear | `t` |
| EaseOutQuad | `1 - (1-t)²` |
| EaseInQuad | `t²` |
| EaseInOutCubic | `t<0.5 and 4t³ or 1-(-2t+2)³/2` |
| EaseOutBack | `1 + 2.70158·(t-1)³ + 1.70158·(t-1)²` |

### Kinematics

| Concept | Formula |
|---------|---------|
| Two-bone elbow | `cos(γ) = (L1² + d² - L2²) / (2·L1·d)` |
| Shoulder angle | `atan2(dy, dx) ± γ` |
| Reachable annulus | `[|L1 - L2|, L1 + L2]` |
| FK propagation | `x[i] = x[i-1] + L·cos(θ[i])`, `y[i] = y[i-1] + L·sin(θ[i])` |

### Game feel

| Concept | Formula |
|---------|---------|
| Squash/stretch on velocity | `stretch = clamp(speed·k, 0, max)` |
| Impact squash | `squash += vy·k`, then `damp(squash, 0, λ, dt)` |
| Screen shake | `offset = (rand-0.5)·2·shake`, `shake = damp(shake, 0, λ, dt)` |

---

## Appendix B — LÖVE2D API Reference

### Math

| Call | Description |
|------|-------------|
| `love.math.noise(x[, y[, z[, w]]])` | Smooth deterministic noise, 1–4 dimensions, output ∈ [0,1] |
| `love.math.random()` | Float in [0,1) |
| `love.math.random(lo, hi)` | Integer in [lo, hi] |

### Timer

| Call | Description |
|------|-------------|
| `love.timer.getTime()` | Seconds since program start |
| `love.timer.getDelta()` | Seconds since last frame (this is what LÖVE passes as `dt`) |

### Input

| Call | Description |
|------|-------------|
| `love.keyboard.isDown(key)` | Is a key held right now? (for continuous movement) |
| `love.keyboard.wasPressed(key)` | Pressed this frame? |
| `love.mouse.getPosition()` | Mouse `x, y` |

### Graphics — transforms

| Call | Description |
|------|-------------|
| `love.graphics.push()` / `pop()` | Save/restore transform state |
| `love.graphics.translate(x, y)` | Shift the origin |
| `love.graphics.rotate(a)` | Rotate subsequent drawing |
| `love.graphics.scale(sx, sy)` | Scale subsequent drawing (the tool of squash & stretch) |

### Graphics — drawing

| Call | Description |
|------|-------------|
| `love.graphics.setColor(r, g, b[, a])` | 0–1 range |
| `love.graphics.line(x1, y1, x2, y2, ...)` | Polyline |
| `love.graphics.circle(mode, x, y, r)` | `mode` = "fill" or "line" |
| `love.graphics.ellipse(mode, x, y, rx, ry)` | Ellipse — the squash & stretch canvas |
| `love.graphics.rectangle(mode, x, y, w, h)` | Rectangle |
| `love.graphics.polygon(mode, ...)` | Polygon by vertices |
| `love.graphics.setLineWidth(w)` | Stroke width |

---

## Appendix C — Complete Example Projects

### Project 1: Bouncing Logo with Squash & Stretch

The classic game feel exercise. A logo that bounces, squashes on landing, and stretches on the way up.

```lua
local x, y, vx, vy = 512, 100, 120, 0
local squash, stretch = 0, 0
local G, E = 1500, 0.8
local GROUND = 650

function love.update(dt)
    vy = vy + G * dt
    y = y + vy * dt
    x = x + vx * dt
    if x > 980 or x < 44 then vx = -vx end
    if y + 40 >= GROUND then
        if vy > 0 then squash = math.min(0.4, vy * 0.0005) end
        y = GROUND - 40
        vy = -vy * E
    end
    stretch = stretch + (math.min(0.3, math.abs(vy) * 0.0003) - stretch) * (1 - math.exp(-15 * dt))
    squash = squash * math.exp(-20 * dt)
end

function love.draw()
    local sx = 1 + squash + stretch
    local sy = 1 - squash - stretch
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(sx, sy)
    love.graphics.setColor(1, 0.6, 0.2)
    love.graphics.rectangle("fill", -40, -40, 80, 80)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LOVE", -16, -6)
    love.graphics.pop()
end
```

### Project 2: Follow Camera with a Damped Aim

The camera that never jitters. Target position is damped at λ=8; a mouse-drift aim adds a second damped offset so the view "leans" into motion.

```lua
local targetX, targetY = 512, 384
local camX, camY = 512, 384

function love.update(dt)
    local playerX, playerY = love.mouse.getPosition()
    -- primary follow: heavily damped
    camX = camX + (playerX - camX) * (1 - math.exp(-8 * dt))
    camY = camY + (playerY - camY) * (1 - math.exp(-8 * dt))
end

function love.draw()
    love.graphics.translate(512 - camX, 384 - camY)
    -- draw world at its real coordinates
end
```

### Project 3: A Tiny Idle Character (everything so far)

Breathing chest, looking eyes, wagging tail, trembling nose — thirty lines, no art.

```lua
local t = 0
local tail = {}
for i = 1, 6 do tail[i] = { x = 520, y = 380 } end

function love.update(dt)
    t = t + dt
    local mx, my = love.mouse.getPosition()
    local headX, headY = 512, 360
    local a = math.atan2(my - headY, mx - headX)

    -- tail chases the head
    tail[1].x = tail[1].x + (headX - tail[1].x) * (1 - math.exp(-10 * dt))
    tail[1].y = tail[1].y + (headY - tail[1].y) * (1 - math.exp(-10 * dt))
    for i = 2, 6 do
        local l = 1 - math.exp(-10 * dt)
        tail[i].x = tail[i].x + (tail[i-1].x - tail[i].x) * l
        tail[i].y = tail[i].y + (tail[i-1].y - tail[i].y) * l
    end
end

function love.draw()
    for i = 2, 6 do love.graphics.line(tail[i-1].x, tail[i-1].y, tail[i].x, tail[i].y) end
    local breath = 0.04 * math.sin(t * 2 * math.pi * 0.25)
    love.graphics.ellipse("line", 512, 392, 44 + breath * 60, 46)
    love.graphics.push()
    love.graphics.translate(512, 360)
    love.graphics.rotate(math.atan2(love.mouse.getY() - 360, love.mouse.getX() - 512) * 0.3)
    love.graphics.circle("fill", 0, 0, 18)
    love.graphics.circle("fill", 8, -3, 4)
    love.graphics.pop()
end
```

---

## Appendix D — Derivations from First Principles

> "Everything is derived. Nothing is taken on faith." — the Feynman rule.

### D.1 The damp formula: `1 - exp(-λ·dt)`

We want a chase where the *rate of closing* is proportional to how far we still have to go:

```
dv/dt = λ · (target - v)
```

Solve the differential equation. Let `e = target - v` (the error):

```
de/dt = -λ·e     ⟹   e(t) = e₀·exp(-λ·t)
```

Over one step of size `dt`, starting at error `e`:

```
e_after = e·exp(-λ·dt)
v += e - e_after = e·(1 - exp(-λ·dt))
v += (target - v)·(1 - exp(-λ·dt))       ← the code formula
```

Why this shape matters: the per-step factor `1 - exp(-λ·dt)` depends on `dt`, so the *same λ* gives the *same differential equation* at any frame rate. The naive `v += e·0.1` uses a fixed factor and silently changes the effective λ when the frame rate changes.

### D.2 Sine as a shadow of a wheel

A dot glued to a wheel of radius `A` rolling with angular speed `ω = 2πf`. Viewed edge-on, the dot's height is the projection of its radius onto the vertical:

```
height = A·sin(θ),  θ = ω·t + φ
height = A·sin(2π·f·t + φ)
```

That's why the same formula describes pendulums, breathing, and bobbing: something is rotating underneath. The two-view trick also explains circle motion — `cos` and `sin` are the same wheel seen face-on.

### D.3 The half-life of a damped chase

From D.1, the error halves when `exp(-λ·t) = 1/2`:

```
-λ·t = ln(1/2) = -ln(2)   ⟹   t = ln(2)/λ ≈ 0.693/λ
```

λ=8 → error halves every 87 ms (rubbery). λ=60 → every 12 ms (snappy). Rule of thumb: a chase is ~99.3% complete at `t = 5/λ`.

### D.4 Two-bone IK: where `acos` comes from

Given three points — shoulder S, elbow E, hand H — with `|S→E| = L1`, `|E→H| = L2`, and `|S→H| = d` all known, the law of cosines on triangle S-E-H gives the angle at S:

```
L2² = L1² + d² - 2·L1·d·cos(γ)    (side opposite E is L2)
cos(γ) = (L1² + d² - L2²) / (2·L1·d)
γ = acos(...)
```

The shoulder angle is then the direction to H (`atan2`) rotated by ±γ. The ± sign produces the two mirror arms; the `acos` domain (|cos| ≤ 1) is exactly the reachable annulus `[|L1-L2|, L1+L2]`.

### D.5 The dwell in walking: why `+π` plants a foot

Two legs with opposite phase:

```
footA(t) = A·sin(2πf·t)
footB(t) = A·sin(2πf·t + π) = -A·sin(2πf·t)
```

The Y-position of each foot is `hipY + LEN·sin(angle)`. When foot A is at +A (up in LÖVE), foot B is at -A (down, planted). The planted foot's X is `hipX + LEN·cos(angle)`; as the hip advances, the planted foot stays at ground contact while the body passes over it — the foot appears to plant, hold, then lift. The `+π` is not a trick; it's the mathematical statement "one foot is always down".

### D.6 Hit-stop as clock freezing

Hit-stop is a second timeline. Define `worldT`, advanced only while `freeze ≤ 0`:

```
if freeze > 0 then freeze -= dt
else worldT += dt; advance all animation
```

All animation reads `worldT`, so freezing `worldT` freezes the *whole world* while `dt` (and the shake decay) still run. That's why the shake can continue during the freeze: the shake clock is the real clock, and the world clock is the stopped one.

---

## Appendix E — Further Reading (vetted links per chapter)

Every link below was checked and resolves. Read the chapter, play the demo, then follow the link for the deeper story.

### Chapter 1 & 2 — Time, lerp, and interpolation
- Glenn Fiedler (Gaffer on Games), *Fix Your Timestep!* — the definitive essay on the game loop every demo in this book uses. <https://gafferongames.com/post/fix_your_timestep/>
- Wikipedia, *Linear interpolation*. <https://en.wikipedia.org/wiki/Linear_interpolation>

### Chapter 3 — Sine waves
- 3Blue1Brown, *Trigonometry — what sine and cosine are* — the wheel-shadow visualization, animated. <https://www.youtube.com/playlist?list=PL0-GT3co4r2y2YErbmuJw2L5tWXvqM6nB>
- Wikipedia, *Sine wave*. <https://en.wikipedia.org/wiki/Sine_wave>

### Chapter 4 — Damping and springs
- Wikipedia, *Damping* — under/critical/overdamped, and the damping ratio. <https://en.wikipedia.org/wiki/Damping>
- Wikipedia, *Exponential decay* — the source of `exp(-λt)`. <https://en.wikipedia.org/wiki/Exponential_decay>

### Chapter 5 — Easing
- easings.net — the standard reference of easing curves with interactive previews. <https://easings.net/>
- Wikipedia, *Smoothstep* — the classic in-out easing, and Hermite interpolation. <https://en.wikipedia.org/wiki/Smoothstep>

### Chapter 6 — Squash and stretch
- Wikipedia, *12 basic principles of animation* — "squash and stretch" is principle #1. <https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation>

### Chapter 7 — Angles and aiming
- LÖVE wiki, *math.atan2*. <https://love2d.org/wiki/Math#math.atan2>
- Wikipedia, *Atan2* — why atan2 is better than atan for angles. <https://en.wikipedia.org/wiki/Atan2>

### Chapter 8 & 9 — FK and IK
- Wikipedia, *Inverse kinematics* — the general problem, including CCD and analytic solvers. <https://en.wikipedia.org/wiki/Inverse_kinematics>
- Wikipedia, *Law of cosines* — the geometry behind the two-bone solve. <https://en.wikipedia.org/wiki/Law_of_cosines>

### Chapter 10 — Noise
- LÖVE wiki, *love.math.noise* — the 1–4 dimensional Perlin/simplex interface. <https://love2d.org/wiki/love.math.noise>
- Ken Perlin, *An Image Synthesizer* — the original 1985 paper. <https://www.cs.nyu.edu/~perlin/paper445.pdf>
- Wikipedia, *Perlin noise*. <https://en.wikipedia.org/wiki/Perlin_noise>

### Chapter 11 — Secondary motion
- Wikipedia, *Twelve basic principles of animation* — "follow through and overlapping action" is principle #5. <https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation>

### Chapter 12 — Game feel
- Steve Swink, *Game Feel: A Game Designer's Guide to Virtual Sensation* — the book-length treatment of anticipation, hit-stop, and shake. <https://www.gdcvault.com/play/1014030/Game-Feel-The-Secret-Explosive>
- GDC Vault, *Game Feel* (Swink's talk). <https://www.gdcvault.com/play/1014030/>

### Chapter 13 & 14 — Walkers and integration
- David Rosen, *Wolfire Games: Procedural Animation* — how Overgrowth walks, and why procedural beats keyframes for responsiveness. <https://blog.wolfire.com/2010/03/Procedural-animation/>
- YouTube, *Overgrowth — procedural animation tech*. <https://www.youtube.com/watch?v=LNidsMesxSE>

---

## Appendix F — Terminology Glossary

**Amplitude** — how far a wave swings from center. Big amplitude = exaggerated motion.

**Annulus** — the reachable ring of a two-bone arm: all points between distance `|L1-L2|` and `L1+L2` from the shoulder.

**Anticipation** — the motion *before* the main action (drawing a punch back) that telegraphs intent. Principle #2 of animation.

**Cadence** — steps (or cycles) per second. In the walker, cadence comes from input speed.

**Clamp** — `clamp(v, lo, hi)`: confine a value to a range. The tool of every constraint.

**Critically damped** — the boundary between oscillating and not. `damp()` is critically damped: it chases, never overshoots, and settles fastest.

**Damp (damping)** — a chase where the rate of closing is proportional to the remaining gap, `1 - exp(-λ·dt)`. The workhorse of procedural animation.

**Easing curve** — a function reshaping normalized time `t∈[0,1]` so a tween starts/ends gently, or overshoots.

**FK (forward kinematics)** — driving a chain from the root; children follow their parents. Cheap, predictable.

**Follow-through** — the motion *after* the main action (the arm relaxing after a punch), the release of the strike. Secondary motion's front line.

**Frequency** — cycles per second (Hz). The `f` in `sin(2πf·t)`.

**Hit-stop** — freezing the world clock for a few dozen milliseconds on impact so the eye registers the hit. The cheapest way to make hits feel hard.

**IK (inverse kinematics)** — solving joint angles so the chain's end reaches a target. The reach problem.

**Interpolation** — computing a value between two known values. `lerp` is linear interpolation.

**Lambda (λ)** — the chase rate in `1/s`. Bigger λ = tighter, faster follow.

**Lerp** — `a + (b-a)·t`. The primitive of interpolation.

**Noise** — smooth, deterministic, non-repeating randomness. `love.math.noise`. The "alive" filter.

**Normalized time** — time rescaled to `[0,1]` over a known duration, so one variable can drive any easing curve.

**Phase** — where in a cycle a wave starts, in radians. Two same-frequency sines with different phase are the same motion at different times; `+π` is "exactly opposite".

**Secondary motion** — the lag and overshoot of attached parts (tail, hair, cape) after the main body moves. Built with chained springs, never keyframes.

**Squash and stretch** — scaling a shape to sell energy: stretch along velocity, squash on impact, roughly conserving volume. Principle #1 of animation.

**Spring** — a chase that remembers velocity: `F = k(target - x) - c·v`. Can overshoot and ring. Underdamped = bouncy, overdamped = sluggish.

**Timeline lerp** — interpolation over a fixed duration; guaranteed arrival time. For tweens, menus, cutscenes.

**Tween** — a scheduled trip from A to B over a duration, usually with an easing curve. Timeline lerp + easing.

**Phase offset** — the per-joint phase addition that turns a column of sines into a travelling wave (a tail, a flag, a snake).

---

## Final Words

> "Physics is not about formulas. It's about understanding how the world works. And the best way to understand how the world works is to build it yourself — even if it's just a simplified version running at 60 frames per second."

Procedural animation is the same lesson, applied to the body instead of the sky. A breathing chest is a sine. A turning head is an atan2. A wagging tail is a damp-chain. A walking creature is two sines and a clock. None of it is art — it is *understanding*, running at sixty frames per second.

The equations are simple. The code is straightforward. The magic is in the details — the amplitude, the lambda, the phase offset, the 120 milliseconds of hit-stop.

Go build something. Break it. Fix it. Break it again. That's how you learn.

— In the spirit of Richard P. Feynman
