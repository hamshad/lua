-- ============================================================
-- CHAPTER 19: Kinetic Ragdoll — Verlet Mesh and Shatter
-- ============================================================
-- A ragdoll is dots + sticks: points carry Verlet motion
-- (x' = x + (x-old)·damp + a·dt² — velocity is implicit in the
-- last two positions), sticks enforce distance. Iterate sticks
-- 3×/frame and the mesh holds. SPACE detonates: every point gets
-- a radial kick, sticks stretch but survive. DRAG to tear around.
--
-- DRAG: grab point   SPACE: shockwave   [B]: rebuild   [G]: gravity

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

-- M: the module table exported to main.lua.
local M = {}

-- pts: {x,y,ox,oy,pinned}. sticks: {a,b,len}. grav: px/s².
local pts, sticks, grav = {}, {}, 900
-- held: dragged point index (or nil).
local held = nil
-- shock: shockwave flash timer for the shake/sell.
local shock = 0

-- build(): a 9×6 soft box hanging from two pins.
local function build()
    pts, sticks, held, shock = {}, {}, nil, 0
    local nx, ny, gap, x0, y0 = 9, 6, 30, 377, 220
    for j = 1, ny do
        for i = 1, nx do
            pts[#pts + 1] = { x = x0 + (i - 1) * gap, y = y0 + (j - 1) * gap,
                ox = x0 + (i - 1) * gap, oy = y0 + (j - 1) * gap,
                pinned = (j == 1 and (i == 1 or i == nx)) }
        end
    end
    local function link(a, b)
        local dx, dy = pts[b].x - pts[a].x, pts[b].y - pts[a].y
        sticks[#sticks + 1] = { a = a, b = b, len = math.sqrt(dx * dx + dy * dy) }
    end
    for j = 1, ny do
        for i = 1, nx do
            local id = (j - 1) * nx + i
            if i < nx then link(id, id + 1) end
            if j < ny then link(id, id + nx) end
            if i < nx and j < ny then link(id, id + nx + 1) link(id + 1, id + nx) end
        end
    end
end

-- M.init(): fresh hanging mesh.
function M.init() build() end

-- M.update(dt): Verlet points, 3 relaxation passes, drag + shock.
function M.update(dt)
    shock = math.max(0, shock - dt)
    local damp = 0.985
    for _, p in ipairs(pts) do
        if not p.pinned then
            -- Verlet: new = pos + (pos - old)·damp + a·dt².
            local nx = p.x + (p.x - p.ox) * damp
            local ny = p.y + (p.y - p.oy) * damp + grav * dt * dt
            p.ox, p.oy, p.x, p.y = p.x, p.y, nx, ny
        end
    end
    if held and pts[held] then
        local mx, my = love.mouse.getPosition()
        pts[held].x, pts[held].y = mx, my
    end
    -- Relax: pull each stick to rest length, split by pinned state.
    for _ = 1, 3 do
        for _, s in ipairs(sticks) do
            local A, B = pts[s.a], pts[s.b]
            local dx, dy = B.x - A.x, B.y - A.y
            local d = math.max(0.001, math.sqrt(dx * dx + dy * dy))
            local diff = (d - s.len) / d
            if A.pinned and B.pinned then
            elseif A.pinned then B.x, B.y = B.x - dx * diff, B.y - dy * diff
            elseif B.pinned then A.x, A.y = A.x + dx * diff, A.y + dy * diff
            else
                A.x, A.y = A.x + dx * diff * 0.5, A.y + dy * diff * 0.5
                B.x, B.y = B.x - dx * diff * 0.5, B.y - dy * diff * 0.5
            end
        end
    end
end

-- M.mousepressed: grab nearest point within 30 px.
function M.mousepressed(x, y, button)
    if button ~= 1 then return end
    local best, bd = nil, 30
    for i, p in ipairs(pts) do
        local d = math.sqrt((x - p.x) ^ 2 + (y - p.y) ^ 2)
        if d < bd then best, bd = i, d end
    end
    held = best
end

function M.mousereleased(_, _, button)
    if button == 1 then held = nil end
end

-- M.keypressed(key): shockwave kick, rebuild, gravity toggle.
function M.keypressed(key)
    if key == " " then
        -- Radial kick from center: near = fast, far = slow.
        shock = 0.35
        for _, p in ipairs(pts) do
            if not p.pinned then
                local dx, dy = p.x - 512, p.y - 320
                local d = math.max(30, math.sqrt(dx * dx + dy * dy))
                p.ox, p.oy = p.ox - (dx / d) * 26, p.oy - (dy / d) * 26
            end
        end
    elseif key == "b" then
        build()
    elseif key == "g" then
        grav = grav > 0 and 0 or 900
    end
end

-- M.draw(): sticks, points, shock ring, strain readout.
function M.draw()
    local shake = shock > 0 and 8 * (shock / 0.35) or 0
    love.graphics.push()
    love.graphics.translate((love.math.random() * 2 - 1) * shake, (love.math.random() * 2 - 1) * shake)
    utils.drawGrid()
    -- Sticks redden under strain: |d-len|/len → color.
    local strain = 0
    for _, s in ipairs(sticks) do
        local A, B = pts[s.a], pts[s.b]
        local d = math.sqrt((B.x - A.x) ^ 2 + (B.y - A.y) ^ 2)
        local k = math.min(1, math.abs(d - s.len) / 24)
        strain = math.max(strain, k)
        love.graphics.setColor(0.55 + k * 0.45, 0.6 - k * 0.35, 0.55 - k * 0.3)
        love.graphics.line(A.x, A.y, B.x, B.y)
    end
    for i, p in ipairs(pts) do
        if p.pinned then love.graphics.setColor(1, 1, 0)
        elseif i == held then love.graphics.setColor(1, 0.4, 0.4)
        else love.graphics.setColor(0.85, 0.85, 0.9) end
        love.graphics.circle("fill", p.x, p.y, p.pinned and 6 or 4)
    end
    if shock > 0 then
        love.graphics.setColor(1, 0.6, 0.2, shock / 0.35)
        love.graphics.circle("line", 512, 320, (0.35 - shock) * 1400)
    end
    love.graphics.pop()

    love.graphics.setFont(fontSmall)
    drawTextBox(10, 620, 1000, 100, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 622)
    love.graphics.print("points=" .. #pts .. "  sticks=" .. #sticks .. "  max strain=" .. fmt(strain * 100, 0) .. "%  gravity=" .. grav, 15, 638)
    love.graphics.print("x' = x + (x-old)·0.985 + a·dt², then 3× stick relax", 15, 654)
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: velocity hides in two positions. Points fly, sticks argue them back —", 10, 700)
    love.graphics.print("that argument IS the body. SPACE detonates, DRAG tears, B rebuilds, G kills gravity.", 10, 714)
end

return M
