# Feynman Shaders: A Complete Learning Guide

## Preface — The Feynman Way

> "If you can't explain it simply, you don't understand it well enough."

This book teaches shader programming the way Feynman taught physics:

1. **Start with intuition you already have** — you've seen pixels, you've seen colors, you've seen things move on screen
2. **Derive everything from first principles** — no formulas on authority, every equation has a reason
3. **Connect every concept to runnable code** — you can type it, see it, break it, fix it
4. **Embrace approximations** — shaders are not real optics, they're tricks that look right

### What is a shader?

A shader is a program that runs on the GPU. Not the CPU — the GPU. That distinction matters because the GPU has thousands of tiny cores, each one capable of running the same program on different data simultaneously.

When you draw a rectangle on screen, the GPU breaks it into pixels (fragments). For each pixel, it runs your fragment shader. Your shader receives the pixel's position and returns its color. That's the contract.

### How to use this book

Each chapter is a standalone LÖVE2D project. Run it, play with it, read the code, read the explanation. The chapters build on each other, so go in order.

```bash
cd shaders
love .
```

Navigate chapters with number keys [1-13] or arrow keys.

---

# Part I: Foundations

---

## Chapter 1: The Pixel Pipeline — What Shaders Actually Are

### The Core Idea

Every pixel on your screen is a tiny worker. A shader is the instruction manual you give that worker. The GPU runs your shader **once per pixel**, in parallel, thousands at a time.

### How it works

A fragment shader receives one input: the pixel's position (`gl_FragCoord`). It produces one output: the pixel's color (`gl_FragColor`).

```
gl_FragCoord: (x, y) in pixels, bottom-left origin
  At pixel (512, 384): x=512.0, y=384.0
  At pixel (0, 0):    x=0.0,   y=0.0

gl_FragColor: (r, g, b, a) each 0.0 to 1.0
  Red:   (1.0, 0.0, 0.0, 1.0)
  White: (1.0, 1.0, 1.0, 1.0)
```

### Dummy value walkthrough

At pixel (512, 384):
- `gl_FragCoord = (512.0, 384.0)`
- Shader computes: `r = 512/1024 = 0.5`, `g = 384/768 = 0.5`
- Returns: `(0.5, 0.5, 0.3, 1.0)` — a yellowish pixel

### The key insight

The GPU is a factory with a million workers. Each worker gets one pixel and asks: "What color should I be?" Your shader is the answer key.

### Exercises

<details>
<summary>Exercise 1: Modify the shader to make the bottom-left corner red and the top-right corner blue.</summary>

```glsl
vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
    float r = 1.0 - pixcoord.x / 1024.0;
    float b = pixcoord.y / 768.0;
    return vec4(r, 0.0, b, 1.0);
}
```
</details>

<details>
<summary>Exercise 2: What happens if you return vec4(0.0)?</summary>

The screen goes black. All pixels become (0, 0, 0, 1) — black with full alpha.
</details>

---

## Chapter 2: Your First Shader — Anatomy of effect()

### The LÖVE2D Shader Signature

```glsl
vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
```

| Parameter | Type | Meaning |
|-----------|------|---------|
| `color` | vec4 | Tint from `love.graphics.setColor()` |
| `tex` | Image | Texture being drawn (1x1 white if none) |
| `texcoord` | vec2 | UV coords (0,0)→(1,1) across texture |
| `pixcoord` | vec2 | Pixel position on screen |

**Return value:** `vec4(r, g, b, a)` — the final pixel color.

### How LÖVE2D differs from raw GLSL

In raw OpenGL, you write `gl_FragColor = ...`. In LÖVE2D, you just **return** the color from `effect()`. The framework handles the rest.

### Dummy value walkthrough

At pixel (256, 512) with `love.graphics.setColor(1, 1, 1, 1)`:
- `color = (1, 1, 1, 1)` — white tint
- `texcoord = (0.25, 0.667)` — 25% across, 67% up
- `pixcoord = (256.0, 512.0)`
- If you return `(1.0, 0.0, 0.0, 1.0)`, the pixel turns red

### Code patterns

```lua
-- Creating a shader
local shader = love.graphics.newShader(fragSource)

-- Using it
love.graphics.setShader(shader)
love.graphics.rectangle("fill", 0, 0, 1024, 768)
love.graphics.setShader()
```

---

## Chapter 3: Uniforms — Talking to the Shader from Lua

### What is a uniform?

A uniform is a variable you send **from Lua to the shader**. "Uniform" means every pixel gets the **same** value — it's uniform across all pixels.

### The pipeline

```
Lua:    shader:send("mouse", {512.0, 384.0})
GLSL:   uniform vec2 mouse;  →  mouse = vec2(512.0, 384.0)
```

### Types you can send

| Lua call | GLSL type | Example |
|----------|-----------|---------|
| `shader:send("speed", 3.14)` | `float` | Single number |
| `shader:send("mouse", {mx, my})` | `vec2` | Two numbers |
| `shader:send("color", {1, 0, 0})` | `vec3` | Three numbers |
| `shader:send("color", {1, 0, 0, 1})` | `vec4` | Four numbers |
| `shader:send("mode", 2)` | `int` | Integer |
| `shader:send("tex", myImage)` | `sampler2D` | Texture |

### The critical distinction

- `pixcoord` changes **per pixel** — different value for every worker
- `uniform` is the **same** for every pixel — a broadcast message

### Dummy value walkthrough

```lua
shader:send("mouse", {512.0, 384.0})
shader:send("radius", 120.0)
```

For every pixel:
- `mouse = vec2(512.0, 384.0)` (same for all)
- `distance = length(pixcoord - mouse)` (different per pixel)
- Pixel at (600, 400): distance = `length(88, 16) = 89.4`
- Pixel at (512, 384): distance = `length(0, 0) = 0.0`

### Exercises

<details>
<summary>Exercise 1: Create a shader that draws a soft circle around the mouse position.</summary>

```glsl
uniform vec2 mouse;
vec4 effect(...) {
    float d = length(pixcoord - mouse);
    float glow = smoothstep(100.0, 0.0, d);
    return vec4(glow, glow * 0.5, 0.0, 1.0);
}
```
</details>

---

## Chapter 4: Time and Motion — Making Things Move

### The universal animation knob

The most powerful uniform is time. `love.timer.getTime()` gives seconds since program start. Send it to the shader and everything moves.

### The building blocks

```glsl
float wave = sin(time * frequency + phase);
float value = center + amplitude * wave;
```

| Parameter | What it does | Example |
|-----------|-------------|---------|
| frequency | How many cycles per second | `sin(time * 2.0)` = 2 cycles/sec |
| phase | Shift the wave in time | `sin(time + 1.0)` starts at sin(1) |
| amplitude | How far from center | `0.5 + 0.3 * sin(t)` oscillates ±0.3 |

### The cosine palette

Inigo Quilez discovered this gem:

```glsl
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d));
}
```

Change `d` → completely different mood. Same formula, infinite palettes.

### Dummy value walkthrough

At `t = 1.0`, frequency = 2.0:
- `sin(1.0 * 2.0) = sin(2.0) ≈ 0.909`
- `y_offset = 0.5 + 0.3 * 0.909 = 0.773`
- The wave is near its peak

### Period reference

| Expression | Period (seconds) | Use case |
|-----------|-----------------|----------|
| `sin(time)` | 6.28 | Slow breathing |
| `sin(time * 2)` | 3.14 | Gentle oscillation |
| `sin(time * 6.28)` | 1.0 | One cycle per second |
| `sin(time * 0.5)` | 12.56 | Very slow drift |

---

## Chapter 5: Textures and Sampling — Reading Images in Shaders

### What is a texture?

A texture is a grid of colors stored on the GPU. When you draw an image, the shader reads texels (texture pixels) using UV coordinates.

### UV coordinates

```
(0,0) = bottom-left of the texture
(1,1) = top-right of the texture
(0.5, 0.5) = center
```

### Sampling

```glsl
vec4 pixel = Texel(tex, uv);
pixel.r  // 0.0 to 1.0
pixel.g  // 0.0 to 1.0
pixel.b  // 0.0 to 1.0
pixel.a  // 0.0 to 1.0
```

The `tex` uniform is automatically bound to the texture you're drawing. `texcoord` comes from the vertex shader.

### Dummy value walkthrough

For a 64x64 texture at `uv = (0.5, 0.5)`:
- Texel position = `(32, 32)` — center
- `Texel(tex, vec2(0.5, 0.5))` returns the color at pixel (32, 32)

### Common texture operations

```glsl
// Grayscale
float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));

// Flip horizontally
vec2 flipped = vec2(1.0 - texcoord.x, texcoord.y);

// Tile 4x4
vec2 tiled = fract(texcoord * 4.0);

// Wave distortion
uv.x += sin(uv.y * 20.0 + time) * 0.02;
```

---

# Part II: Intermediate Techniques

---

## Chapter 6: Coordinate Systems — Screen, Normalized, and UV

### The three coordinate systems

| System | Range | Origin | Use case |
|--------|-------|--------|----------|
| Screen | (0,0) to (1024,768) | Top-left | Pixel-perfect effects |
| UV | (0,0) to (1,1) | Bottom-left | Texture lookups |
| NDC | (-1,-1) to (1,1) | Center | Math, vertex shaders |

### Conversions

```glsl
// Screen to UV
vec2 uv = pixcoord / vec2(1024.0, 768.0);

// UV to NDC
vec2 ndc = uv * 2.0 - 1.0;

// NDC to Screen
vec2 screen = (ndc + 1.0) * 0.5 * vec2(1024.0, 768.0);
```

### Why it matters

- **Screen space**: "Is this pixel within 50px of the mouse?" — game logic
- **UV space**: "What color is at 30% across the texture?" — texture sampling
- **NDC**: "Is this point left or right of center?" — mathematical symmetry

### Dummy value walkthrough

At pixel (512, 384):
- Screen: `(512, 384)`
- UV: `(512/1024, 384/768) = (0.5, 0.5)` — center
- NDC: `(0.5*2-1, 0.5*2-1) = (0.0, 0.0)` — also center

---

## Chapter 7: Noise and Randomness — Organic Patterns

### Why noise?

Pure math gives smooth, predictable patterns. Nature is messy. Noise functions give you **controlled randomness** — structured chaos.

### Value noise

```glsl
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);  // smoothstep interpolation
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
```

### Fractal Brownian Motion (fBM)

Layer noise at different scales:

```glsl
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;   // double the detail
        amplitude *= 0.5;   // halve the influence
    }
    return value;
}
```

### Why fBM works

Each octave adds finer detail. The first octave gives you big hills. The second adds smaller bumps on those hills. The third adds pebbles. It's like painting: big shapes first, details last.

### Dummy value walkthrough

fBM at `pos = (1.5, 2.3)`, 4 octaves:
- Oct 1: `noise(1.5, 2.3) * 1.0 ≈ 0.65`
- Oct 2: `noise(3.0, 4.6) * 0.5 ≈ 0.38`
- Oct 3: `noise(6.0, 9.2) * 0.25 ≈ 0.11`
- Oct 4: `noise(12., 18.4) * 0.125 ≈ 0.04`
- Total ≈ `1.18`, normalized to ~`0.59`

---

## Chapter 8: Mathematical Shapes — SDFs and Distance Fields

### What is an SDF?

A Signed Distance Function tells you **how far** a point is from a shape's surface:
- **Negative** = inside the shape
- **Zero** = on the boundary
- **Positive** = outside the shape

### Basic SDFs

```glsl
// Circle
float sdCircle(vec2 p, vec2 c, float r) {
    return length(p - c) - r;
}

// Box
float sdBox(vec2 p, vec2 c, vec2 b) {
    vec2 d = abs(p - c) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Triangle (Inigo Quilez)
float sdTriangle(vec2 p, vec2 a, vec2 b, vec2 c) {
    // ... (see chapter8.lua for full implementation)
}
```

### Antialiased edges with smoothstep

```glsl
float edge = smoothstep(0.0, 0.01, sdf);
// sdf < 0:      edge = 0 (inside)
// sdf > 0.01:   edge = 1 (outside)
// sdf 0 to 0.01: smooth transition (antialiasing)
```

### Combining shapes

```glsl
float opUnion(float d1, float d2)        { return min(d1, d2); }
float opIntersection(float d1, float d2) { return max(d1, d2); }
float opSubtraction(float d1, float d2)  { return max(d1, -d2); }
```

### Dummy value walkthrough

Circle at pixel (600, 400), center=(512,384), r=50:
- `diff = (600-512, 400-384) = (88, 16)`
- `sdf = length(88, 16) - 50 = 89.4 - 50 = 39.4` (outside)

---

## Chapter 9: Color Theory in Shaders — Palettes and Mixing

### Colors are just numbers

In shaders, a color is `vec3(r, g, b)` with values 0.0 to 1.0. The art is in **how you combine them**.

### HSV color space

```glsl
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
```

| Component | Range | Meaning |
|-----------|-------|---------|
| Hue | 0.0-1.0 | Color wheel position (0=red, 0.33=green, 0.66=blue) |
| Saturation | 0.0-1.0 | 0=gray, 1=vivid |
| Value | 0.0-1.0 | 0=black, 1=bright |

### The cosine palette (Inigo Quilez)

```glsl
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.10, 0.20);
    return a + b * cos(6.28318 * (c * t + d));
}
```

Tweak `d` for different palettes:
- `d = (0.0, 0.1, 0.2)` — warm sunset
- `d = (0.3, 0.2, 0.2)` — cool ocean
- `d = (0.5, 0.2, 0.25)` — neon cyberpunk

### Dummy value walkthrough

At `t = 0.25`, `d = (0, 0.1, 0.2)`:
- `cos(2π * (0.25 + 0)) = cos(π/2) = 0` → `r = 0.5 + 0.5*0 = 0.5`
- `cos(2π * (0.25 + 0.1)) = cos(0.7π) ≈ -0.59` → `g ≈ 0.5 - 0.3 = 0.2`
- `cos(2π * (0.25 + 0.2)) = cos(0.9π) ≈ -0.81` → `b ≈ 0.5 - 0.4 = 0.1`

---

## Chapter 10: Post-Processing Effects — Screen-Space Magic

### The workflow

1. Draw your scene to a canvas (off-screen texture)
2. Draw that canvas to the screen with a shader applied
3. The shader reads the scene and transforms it

```lua
-- Step 1: Draw scene to canvas
love.graphics.setCanvas(myCanvas)
drawScene()
love.graphics.setCanvas()

-- Step 2: Apply post-processing
love.graphics.setShader(myShader)
love.graphics.draw(myCanvas)
love.graphics.setShader()
```

### Classic effects

**Gaussian Blur:**
```glsl
vec4 sum = vec4(0.0);
float weights[5] = float[5](0.227, 0.195, 0.122, 0.054, 0.016);
sum += Texel(tex, uv) * weights[0];
for (int i = 1; i < 5; i++) {
    sum += Texel(tex, uv + dir * float(i)) * weights[i];
    sum += Texel(tex, uv - dir * float(i)) * weights[i];
}
```

**Vignette:**
```glsl
float dist = length(uv - 0.5);
float vig = 1.0 - dist * 1.2;
pixel *= smoothstep(0.0, 0.7, vig);
```

**Chromatic Aberration:**
```glsl
float r = Texel(tex, uv + vec2(offset, 0.0)).r;
float g = pixel.g;
float b = Texel(tex, uv - vec2(offset, 0.0)).b;
```

**Scanlines:**
```glsl
float scanline = sin(uv.y * 768.0) * 0.04;
pixel.rgb -= scanline;
```

### Dummy value walkthrough

Vignette at pixel (800, 600):
- `uv = (0.781, 0.781)`, center = `(0.5, 0.5)`
- `dist = length(0.281, 0.281) = 0.397`
- `vig = 1.0 - 0.397 * 1.2 = 0.524`
- Pixel brightness multiplied by 0.524 → darker at edges

---

# Part III: Advanced Techniques

---

## Chapter 11: Vertex Shaders — Deforming Geometry

### Fragment vs Vertex shaders

| | Fragment Shader | Vertex Shader |
|---|---|---|
| Runs per | Pixel | Vertex |
| Input | pixcoord, texcoord | Vertex position |
| Output | Color (gl_FragColor) | New position |
| Use case | Coloring, effects | Deformation, animation |

### LÖVE2D vertex shader

```glsl
attribute vec2 VertexPosition;
attribute vec2 VertexTexCoord;
attribute vec4 VertexColor;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    vec2 pos = VertexPosition.xy;
    // Modify pos here
    return transformProjection * vec4(pos, vertexPosition.zw);
}
```

### Deformation examples

```glsl
// Wave
pos.y += sin(pos.x * 0.03 + time * 2.0) * 30.0;

// Twist
float angle = atan(d.y, d.x);
angle += dist * 0.005 * sin(time);
pos = center + vec2(cos(angle), sin(angle)) * dist;

// Ripple
float wave = sin(dist * 0.02 - time * 3.0) * 20.0;
pos += normalize(d) * wave;
```

### Why vertex shaders are fast

A 1024x768 mesh with 16px grid = 64×48 = 3,072 vertices. A fragment shader processes 1024×768 = 786,432 pixels. Vertex shaders do ~250× less work for similar visual results.

### Dummy value walkthrough

Vertex at (100, 200), wave mode:
- `pos.y += sin(100 * 0.03 + time * 2.0) * 30.0`
- At `time = 1.0`: `sin(3.0 + 2.0) * 30 = sin(5.0) * 30 ≈ -28.76`
- New position: `(100, 171.24)` — vertex moved up by ~29px

---

## Chapter 12: Multi-Pass Rendering — Framebuffers and Ping-Pong

### Why multi-pass?

Some effects need to read the **output** of another effect as their **input**. You can't read and write to the same texture simultaneously, so you use two canvases and alternate.

### Ping-pong pattern

```
Pass 1: Canvas A ← scene + shader1
Pass 2: Canvas B ← Canvas A + shader2
Pass 3: Screen  ← Canvas B + shader3
```

### The code

```lua
-- Pass 1: Generate pattern
love.graphics.setCanvas(canvasA)
love.graphics.setShader(shader1)
love.graphics.rectangle("fill", 0, 0, 1024, 768)

-- Pass 2: Horizontal blur
love.graphics.setCanvas(canvasB)
love.graphics.setShader(blurH)
love.graphics.draw(canvasA)

-- Pass 3: Vertical blur
love.graphics.setCanvas(canvasA)
love.graphics.setShader(blurV)
love.graphics.draw(canvasB)

-- Pass 4: Color grade to screen
love.graphics.setCanvas()
love.graphics.setShader(colorGrade)
love.graphics.draw(canvasA)
```

### Why two passes for blur?

A 2D Gaussian blur is separable: you can do horizontal first, then vertical. This reduces complexity from O(n²) to O(n) per pixel. For a 5-tap blur: 25 texture reads → 10 texture reads.

---

## Chapter 13: Raymarching — 3D Worlds in a Fragment Shader

### The big idea

Raymarching renders 3D scenes **entirely in a fragment shader**. No mesh data, no vertex shader — just math.

### The algorithm

For each pixel:
1. Cast a ray from camera through the pixel
2. Step along the ray using sphere tracing
3. At each step, query the SDF for the distance to the nearest surface
4. Move forward by that distance (guaranteed not to miss anything)
5. Repeat until you hit something (SDF ≈ 0) or give up (max steps)

```glsl
float t = 0.0;
for (int i = 0; i < 100; i++) {
    vec3 p = ro + rd * t;
    float d = scene(p);
    if (d < 0.001) break;  // hit!
    t += d;
    if (t > 50.0) break;   // too far
}
```

### Lighting

Once you find a hit point, calculate the surface normal using finite differences:

```glsl
vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        scene(p + e.xyy) - scene(p - e.xyy),
        scene(p + e.yxy) - scene(p - e.yxy),
        scene(p + e.yyx) - scene(p - e.yyx)
    ));
}
```

Then apply standard lighting:
```glsl
float diff = max(dot(normal, lightDir), 0.0);
float shadow = softShadow(hitPoint, lightDir);
float spec = pow(max(dot(halfVec, normal), 0.0), 32.0);
```

### Dummy value walkthrough

Ray from `(0, 2, -3)` toward pixel at NDC `(0, 0)`:
- `rd = normalize(0, 0, 1.5) = (0, 0, 1)`
- Step 1: `p = (0, 2, -3)`, `sdf = length(0,2,-3) - 1 = 3.6` → step 3.6
- Step 2: `p = (0, 2, 0.6)`, `sdf = length(0,2,0.6) - 1 = 1.1` → step 1.1
- Step 3: `p = (0, 2, 1.7)`, `sdf = length(0,2,1.7) - 1 = 1.28` → ...
- Eventually converges to surface

---

# Appendices

---

## Appendix A: GLSL Quick Reference

### Built-in variables (LÖVE2D fragment shader)

| Variable | Type | Description |
|----------|------|-------------|
| `gl_FragCoord` | vec2 | Pixel position (via `pixcoord`) |
| `gl_FragColor` | vec4 | Output color (via return) |

### LÖVE2D shader built-ins

| Variable | Type | Description |
|----------|------|-------------|
| `pixcoord` | vec2 | Same as gl_FragCoord |
| `texcoord` | vec2 | UV coordinates |
| `color` | vec4 | Tint color from setColor |
| `tex` | Image | Bound texture |

### Common functions

| Function | Description | Example |
|----------|-------------|---------|
| `sin(x)` | Sine wave [-1, 1] | `sin(time)` |
| `cos(x)` | Cosine wave [-1, 1] | `cos(time)` |
| `length(v)` | Magnitude of vector | `length(vec2(3, 4))` = 5.0 |
| `normalize(v)` | Unit vector | `normalize(vec2(3, 4))` = (0.6, 0.8) |
| `dot(a, b)` | Dot product | `dot(vec2(1,0), vec2(0,1))` = 0.0 |
| `mix(a, b, t)` | Linear interpolation | `mix(0.0, 1.0, 0.5)` = 0.5 |
| `clamp(x, lo, hi)` | Clamp to range | `clamp(1.5, 0, 1)` = 1.0 |
| `smoothstep(e0, e1, x)` | Smooth Hermite | `smoothstep(0, 1, 0.5)` = 0.5 |
| `floor(x)` | Round down | `floor(2.7)` = 2.0 |
| `fract(x)` | Fractional part | `fract(2.7)` = 0.7 |
| `abs(x)` | Absolute value | `abs(-3.0)` = 3.0 |
| `min(a, b)` | Minimum | `min(3, 5)` = 3 |
| `max(a, b)` | Maximum | `max(3, 5)` = 5 |
| `pow(b, e)` | Power | `pow(2, 3)` = 8.0 |
| `sqrt(x)` | Square root | `sqrt(4)` = 2.0 |
| `atan(y, x)` | Arc tangent | `atan(1, 1)` = π/4 |

### GLSL types

| Type | Components | Example |
|------|-----------|---------|
| `float` | 1 | `3.14` |
| `vec2` | 2 | `vec2(1.0, 2.0)` |
| `vec3` | 3 | `vec3(1.0, 2.0, 3.0)` |
| `vec4` | 4 | `vec4(1.0, 2.0, 3.0, 4.0)` |
| `int` | 1 | `42` |
| `ivec2` | 2 | `ivec2(1, 2)` |
| `mat3` | 3×3 | `mat3(1.0)` (identity) |
| `mat4` | 4×4 | `mat4(1.0)` (identity) |

---

## Appendix B: LÖVE2D Shader API Reference

### Creating shaders

```lua
-- Fragment only
local shader = love.graphics.newShader(fragmentSource)

-- Fragment + Vertex
local shader = love.graphics.newShader(fragmentSource, vertexSource)
```

### Using shaders

```lua
love.graphics.setShader(shader)    -- activate
love.graphics.setShader()          -- deactivate
```

### Sending uniforms

```lua
shader:send("name", value)         -- float, int
shader:send("name", {x, y})       -- vec2
shader:send("name", {x, y, z})    -- vec3
shader:send("name", {x, y, z, w}) -- vec4
shader:send("name", canvas)        -- sampler2D
```

### Canvas (off-screen rendering)

```lua
local canvas = love.graphics.newCanvas(width, height)
love.graphics.setCanvas(canvas)    -- draw to canvas
love.graphics.setCanvas()          -- draw to screen
love.graphics.draw(canvas)         -- draw the canvas
```

### Mesh (vertex data)

```lua
local format = {
    {"VertexPosition", "float", 2},
    {"VertexTexCoord", "float", 2},
    {"VertexColor", "float", 4},
}
local mesh = love.graphics.newMesh(format, vertices, "triangles")
```

---

## Appendix C: Exercises by Chapter

### Chapter 1-3: Basics
1. Create a shader that draws a vertical gradient (black at top, white at bottom)
2. Add a uniform that controls the gradient midpoint
3. Make the gradient animate (scroll upward over time)

### Chapter 4-6: Intermediate
1. Create a pulsing circle that follows the mouse
2. Add UV-based checkerboard pattern behind the circle
3. Convert between all three coordinate systems and display them

### Chapter 7-9: Creative
1. Create terrain using fBM noise (heightmap visualization)
2. Build an SDF scene with union, subtraction, and smooth blending
3. Create a color palette that shifts with mouse position

### Chapter 10-13: Advanced
1. Implement a two-pass Gaussian blur (horizontal + vertical)
2. Create a vertex shader that makes a grid ripple from the mouse position
3. Build a raymarched scene with two spheres and a ground plane

---

## Appendix D: Glossary

| Term | Definition |
|------|-----------|
| **Fragment** | A candidate pixel before it passes depth testing |
| **Shader** | A program that runs on the GPU |
| **Uniform** | A constant value sent from CPU to GPU, same for all fragments |
| **Varying** | A value interpolated between vertices (vertex→fragment) |
| **Attribute** | Per-vertex data (position, color, UV) |
| **SDF** | Signed Distance Function — negative inside, positive outside |
| **fBM** | Fractal Brownian Motion — layered noise at multiple scales |
| **UV** | Texture coordinates, (0,0) to (1,1) |
| **NDC** | Normalized Device Coordinates, (-1,-1) to (1,1) |
| **Ping-pong** | Alternating between two framebuffers for multi-pass rendering |
| **Raymarching** | Rendering technique that steps along rays using SDFs |
| **Smoothstep** | Hermite interpolation for smooth transitions |
| **Texel** | A pixel within a texture |
| **Canvas** | LÖVE2D's off-screen render target (framebuffer) |
| **Post-processing** | Applying effects after the scene is rendered |
| **Normal** | A unit vector perpendicular to a surface |
| **Specular** | Bright highlight from direct light reflection |
| **Diffuse** | Scattered light from a rough surface |
| **Vignette** | Darkening toward the edges of the screen |

---

## Appendix E: Further Reading

### Shader tutorials
- [The Book of Shaders](https://thebookofshaders.com) — Patricio Gonzalez Vivo
- [Shadertoy](https://www.shadertoy.com) — Community shader playground
- [GLSL Sandbox](http://glslsandbox.com) — Another shader gallery

### Math references
- [Inigo Quilez's website](https://iquilezles.org) — SDFs, noise, palettes
- [Wikipedia: Signed distance function](https://en.wikipedia.org/wiki/Signed_distance_function)
- [3Blue1Brown: Linear algebra](https://www.3blue1brown.com/topics/linear-algebra)

### LÖVE2D specific
- [LÖVE2D Wiki: Shaders](https://love2d.org/wiki/Shader)
- [LÖVE2D Wiki: Canvas](https://love2d.org/wiki/Canvas)
- [LÖVE2D Wiki: Mesh](https://love2d.org/wiki/Mesh)

### Books
- *Real-Time Rendering* — Akenine-Möller et al.
- *GPU Gems* — NVIDIA (free online)
- *ShaderX* — Wolfgang Engel
