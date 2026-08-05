-- ============================================================
-- CHAPTER 1: Vectors — The Language of Physics
-- ============================================================
-- A vector has magnitude AND direction. |v| = sqrt(vx² + vy²).
-- The dot product a·b = |a||b|cos(θ) tells you how aligned
-- two vectors are. Everything else in physics builds on this.
--
-- INTERACTION: move the mouse — the red vector v follows it.
--   Mouse at (700, 250) → v = (700-512, 250-384) = (188, -134)
--   |v| = sqrt(188² + 134²) ≈ 230.9, angle = atan2(-134, 188) ≈ -35.6°

local vec2 = require("vec2")
local utils = require("utils")
local fmt = utils.fmt
local drawVector = utils.drawVector
local drawTextBox = utils.drawTextBox

local M = {}

local origin = vec2.new(512, 384)
local mousePos = vec2.new(512, 384)
local vectors = {
    { start = vec2.new(512, 384), ["end"] = vec2.new(612, 300), color = {1, 0.3, 0.3}, label = "v = (100, -84)" },
    { start = vec2.new(512, 384), ["end"] = vec2.new(400, 280), color = {0.3, 1, 0.3}, label = "u = (-112, -104)" },
    { start = vec2.new(512, 384), ["end"] = vec2.new(512, 250), color = {0.3, 0.3, 1}, label = "w = (0, -134)" },
}

function M.init()
    origin = vec2.new(512, 384)
    mousePos = vec2.new(512, 384)
    vectors[1]["end"] = vec2.new(612, 300)
    vectors[2]["end"] = vec2.new(400, 280)
    vectors[3]["end"] = vec2.new(512, 250)
    vectors[3].label = "w = (0, -134)"
end

function M.update()
    -- Red vector v follows the mouse
    vectors[1]["end"] = mousePos
    vectors[1].label = "v = (" .. fmt(mousePos.x - origin.x) .. ", " .. fmt(mousePos.y - origin.y) .. ")"

    -- Sum vector: v + u = (vx+ux, vy+uy), the parallelogram diagonal
    local u = vectors[2]["end"]:sub(origin)
    local v = vectors[1]["end"]:sub(origin)
    local sum = u:add(v)
    vectors[3]["end"] = origin:add(sum)
    vectors[3].label = "v+u = (" .. fmt(sum.x) .. ", " .. fmt(sum.y) .. ")"
end

function M.draw()
    local ox, oy = origin.x, origin.y

    -- Grid: 30px spacing, reference lines through the origin
    love.graphics.setColor(0.1, 0.1, 0.1)
    for i = -13, 13 do
        love.graphics.line(ox + i * 30, oy - 300, ox + i * 30, oy + 300)
    end
    for i = -10, 10 do
        love.graphics.line(ox - 400, oy + i * 30, ox + 400, oy + i * 30)
    end

    -- Axes
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.line(ox - 400, oy, ox + 400, oy)
    love.graphics.line(ox, oy - 300, ox, oy + 300)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("x", ox + 390, oy - 8)
    love.graphics.print("y", ox + 5, oy - 300)
    love.graphics.print("O", ox - 12, oy + 5)

    -- Vectors
    for _, v in ipairs(vectors) do
        local sx, sy = v.start.x, v.start.y
        local ex, ey = v["end"].x, v["end"].y
        drawVector(sx, sy, ex - sx, ey - sy, 1, v.color)
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(v.color)
        love.graphics.print(v.label, ex + 5, ey - 10)
    end

    -- Parallelogram rule for v + u:
    -- place u's tail at v's head; the diagonal from origin to the
    -- opposite corner is v + u. Dashed lines complete the shape.
    local v = vectors[1]["end"]:sub(origin)
    local u = vectors[2]["end"]:sub(origin)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineStyle("rough")
    love.graphics.line(ox + v.x, oy + v.y, ox + v.x + u.x, oy + v.y + u.y)
    love.graphics.line(ox + u.x, oy + u.y, ox + v.x + u.x, oy + v.y + u.y)
    love.graphics.setLineStyle("smooth")

    -- Mouse position indicator
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", mousePos.x, mousePos.y, 4)

    -- Live calculations panel
    local v = vectors[1]["end"]:sub(origin)
    local mag = v:len()
    local ang = math.deg(v:angle())
    local u = vectors[2]["end"]:sub(origin)
    local dotProduct = v:dot(u)
    local crossProduct = v:cross(u)
    local cosTheta = dotProduct / (mag * u:len() + 0.0001)
    local theta = math.deg(math.acos(math.max(-1, math.min(1, cosTheta))))

    local px, py = 10, 400
    love.graphics.setFont(fontSmall)
    drawTextBox(px, py, 380, 160, "", {0, 0, 0, 0.8})

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE CALCULATIONS", px + 5, py + 2)
    love.graphics.print("v = " .. v:tostring(), px + 5, py + 18)
    love.graphics.print("|v| = sqrt(" .. fmt(v.x)^2 .. " + " .. fmt(v.y)^2 .. ") = " .. fmt(mag), px + 5, py + 34)
    love.graphics.print("angle = atan2(" .. fmt(v.y) .. ", " .. fmt(v.x) .. ") = " .. fmt(ang) .. " deg", px + 5, py + 50)
    love.graphics.print("u = " .. u:tostring(), px + 5, py + 68)
    love.graphics.print("u·v = " .. fmt(v.x) .. "*" .. fmt(u.x) .. " + " .. fmt(v.y) .. "*" .. fmt(u.y) .. " = " .. fmt(dotProduct), px + 5, py + 84)
    love.graphics.print("u×v = " .. fmt(v.x) .. "*" .. fmt(u.y) .. " - " .. fmt(v.y) .. "*" .. fmt(u.x) .. " = " .. fmt(crossProduct), px + 5, py + 100)
    love.graphics.print("cos(theta) = " .. fmt(dotProduct) .. " / (" .. fmt(mag) .. " * " .. fmt(u:len()) .. ") = " .. fmt(cosTheta), px + 5, py + 116)
    love.graphics.print("theta = " .. fmt(theta) .. " degrees", px + 5, py + 132)

    -- Feynman explanation
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: Vectors are the language of physics. Position, velocity, force — all vectors.", px, py + 150)
    love.graphics.print("The dot product is a projection: a·b = |a||b|cos(θ). The cross product is a signed area:", px, py + 164)
    love.graphics.print("a×b = |a||b|sin(θ) — its sign tells you the turn direction (see Appendix D.1, D.2).", px, py + 178)
end

function M.mousepressed(x, y, button)
    if button == 1 then
        mousePos = vec2.new(x, y)
    end
end

return M
