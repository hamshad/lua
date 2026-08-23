-- ============================================================
-- CHAPTER 3: Collision Detection — When Things Crash Into Each Other
-- ============================================================
-- The two fundamental shapes: AABB (axis-aligned bounding box)
-- and circle. Everything else is built from these.
--
-- INTERACTION: move the mouse to drag the red box. Watch the
-- overlap tests light up when they touch the blue shapes.

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local box = {x = 300, y = 300, w = 60, h = 60}
local targets = {
    {x = 200, y = 200, w = 80, h = 80, type = "aabb", hit = false},
    {x = 500, y = 300, w = 80, h = 80, type = "aabb", hit = false},
    {x = 700, y = 200, w = 50, h = 50, type = "aabb", hit = false},
    {x = 350, y = 500, r = 40, type = "circle", hit = false},
    {x = 600, y = 450, r = 55, type = "circle", hit = false},
    {x = 800, y = 550, r = 35, type = "circle", hit = false},
}

function M.init()
    box = {x = 300, y = 300, w = 60, h = 60}
    for _, t in ipairs(targets) do t.hit = false end
end

function M.update(dt)
    -- Box follows mouse
    local mx, my = love.mouse.getPosition()
    box.x = mx - box.w / 2
    box.y = my - box.h / 2

    -- Test each target
    for _, t in ipairs(targets) do
        if t.type == "aabb" then
            t.hit = utils.aabbOverlap(box.x, box.y, box.w, box.h, t.x, t.y, t.w, t.h)
        elseif t.type == "circle" then
            -- Circle vs AABB: clamp circle center to box, check distance
            local cx = utils.clamp(box.x + box.w / 2, t.x - t.r, t.x + t.r)
            local cy = utils.clamp(box.y + box.h / 2, t.y - t.r, t.y + t.r)
            local dx = (box.x + box.w / 2) - cx
            local dy = (box.y + box.h / 2) - cy
            t.hit = dx * dx + dy * dy < t.r * t.r
        end
    end
end

function M.draw()
    utils.drawGrid()

    -- Targets
    for _, t in ipairs(targets) do
        if t.hit then
            love.graphics.setColor(1, 0.3, 0.3)
        else
            love.graphics.setColor(0.2, 0.5, 0.8)
        end

        if t.type == "aabb" then
            love.graphics.rectangle("fill", t.x, t.y, t.w, t.h)
        else
            love.graphics.circle("fill", t.x, t.y, t.r)
        end

        -- Label
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(1, 1, 1)
        if t.type == "aabb" then
            love.graphics.print("AABB", t.x + 5, t.y + 5)
        else
            love.graphics.print("circle r=" .. t.r, t.x - 20, t.y + t.r + 5)
        end
    end

    -- The draggable box
    love.graphics.setColor(1, 0.4, 0.2)
    love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("DRAG ME", box.x + 5, box.y + 5)

    -- Count hits
    local hits = 0
    for _, t in ipairs(targets) do if t.hit then hits = hits + 1 end end

    -- Live panel
    local px, py = 10, 400
    drawTextBox(px, py, 400, 110, "", {0, 0, 0, 0.8})
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", px + 5, py + 2)
    love.graphics.print("box = (" .. fmt(box.x) .. ", " .. fmt(box.y) .. ") " .. box.w .. "x" .. box.h, px + 5, py + 18)
    love.graphics.print("targets hit: " .. hits .. " / " .. #targets, px + 5, py + 34)
    love.graphics.print("AABB test: ax < bx+bw AND ax+w > bx ...", px + 5, py + 50)
    love.graphics.print("circle test: distance^2 < (r1+r2)^2", px + 5, py + 66)
    love.graphics.print("circle-vs-box: clamp center to box edge, then dist", px + 5, py + 82)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Collision is just geometry. Is the left edge of A left of", px, py + 104)
    love.graphics.print("B's right edge? And so on. Two if-statements = AABB collision.", px, py + 118)
end

return M
