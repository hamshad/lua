-- ============================================================
-- CHAPTER 5: Easing Curves — The Language of Feel
-- ============================================================
-- A tween is a trip from A to B over a duration. The EASING curve
-- reshapes the normalized t (0→1) so the trip does not feel linear:
-- it can start slow and rush (ease-in), rush then settle
-- (ease-out), both (ease-in-out), or overshoot the end (back).
--
-- Five boxes travel the same distance in the same 1.5 seconds.
-- Only their easing curve differs — and the FEEL is completely
-- different. This is game feel: identical mechanics, different
-- emotion.
--
-- SPACE: replay the tween

local utils = require("utils")
local fmt = utils.fmt
local drawTextBox = utils.drawTextBox

local M = {}

local DUR = 1.5
local t = 0
local playing = true

local curves = {
    { name = "linear",       fn = utils.easeLinear },
    { name = "outQuad",      fn = utils.easeOutQuad },
    { name = "inQuad",       fn = utils.easeInQuad },
    { name = "inOutCubic",   fn = utils.easeInOutCubic },
    { name = "outBack",      fn = utils.easeOutBack },
}

local X0, X1 = 60, 960
local ROWS = { 80, 190, 300, 410, 520 }

function M.init()
    t = 0
    playing = true
end

function M.update(dt)
    if playing then
        t = math.min(1, t + dt / DUR)
        if t >= 1 then playing = false end
    end
end

function M.keypressed(key)
    if key == " " then
        t = 0
        playing = true
    end
end

function M.draw()
    utils.drawGrid()

    for i, c in ipairs(curves) do
        local y = ROWS[i]
        local e = c.fn(t)

        -- Travel line
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.line(X0, y, X1, y)

        -- Box at eased position
        local x = X0 + (X1 - X0) * e
        local color = {i / 6, 0.5, 1 - i / 6}
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", x - 14, y - 14, 28, 28)

        -- Name + raw t
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontSmall)
        love.graphics.print(c.name .. "  eased=" .. fmt(e, 2), X0, y + 22)

        -- Progress ticks every 10%
        for p = 1, 9 do
            local tx = p / 10
            local ex = c.fn(tx)
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.circle("fill", X0 + (X1 - X0) * ex, y, 2)
        end
    end

    -- Current raw t marker
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", X0 + (X1 - X0) * t - 2, 60, 4, 560)

    -- Live panel
    love.graphics.setFont(fontSmall)
    drawTextBox(10, 640, 1000, 90, "", {0, 0, 0, 0.8})
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LIVE VALUES", 15, 642)
    love.graphics.print("t = " .. fmt(t, 3) .. "  of 1.0   duration = " .. DUR .. "s   [SPACE] replay", 15, 658)
    love.graphics.print("outBack overshoots the target, then settles back — beloved for UI pop.", 15, 674)

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.print("Feynman: easing does not change the motion, it changes the TIME-EXCHANGE — it", 10, 744)
    love.graphics.print("spends t slowly where the eye needs reading time and quickly where it does not.", 10, 758)
end

return M