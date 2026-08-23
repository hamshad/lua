local utils = {}

utils.SCREEN_W = 1024
utils.SCREEN_H = 768
utils.FIXED_DT = 1 / 60

function utils.fmt(n, decimals)
    decimals = decimals or 3
    if n == nil then return "nil" end
    local mult = 10 ^ decimals
    return tostring(math.floor(n * mult + 0.5) / mult)
end

function utils.drawText(text, x, y, font, color)
    love.graphics.setColor(color or {1, 1, 1, 1})
    if font then love.graphics.setFont(font) end
    love.graphics.print(text, x, y)
end

function utils.drawTextBox(x, y, w, h, lines, bgColor, textColor)
    love.graphics.setColor(bgColor or {0, 0, 0, 0.75})
    love.graphics.rectangle("fill", x, y, w, h, 6, 6)
    love.graphics.setColor(textColor or {1, 1, 1, 1})
    local lineH = 18
    for i, line in ipairs(lines) do
        love.graphics.print(line, x + 10, y + 8 + (i - 1) * lineH)
    end
end

function utils.drawFeynman(text, font)
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    local boxH = #lines * 18 + 20
    local boxY = utils.SCREEN_H - boxH - 10
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 10, boxY, utils.SCREEN_W - 20, boxH, 8, 8)
    love.graphics.setColor(0.7, 0.9, 0.7, 1)
    if font then love.graphics.setFont(font) end
    for i, line in ipairs(lines) do
        love.graphics.print(line, 20, boxY + 10 + (i - 1) * 18)
    end
end

function utils.drawButton(x, y, w, h, label, active)
    if active then
        love.graphics.setColor(0.2, 0.6, 0.2, 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    end
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(label, x, y + h / 2 - 8, w, "center")
end

function utils.inRect(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

function utils.clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

function utils.lerp(a, b, t)
    return a + (b - a) * t
end

function utils.mixColor(c1, c2, t)
    return {
        utils.lerp(c1[1], c2[1], t),
        utils.lerp(c1[2], c2[2], t),
        utils.lerp(c1[3], c2[3], t),
        utils.lerp(c1[4] or 1, c2[4] or 1, t)
    }
end

function utils.newCanvas(w, h)
    return love.graphics.newCanvas(w or utils.SCREEN_W, h or utils.SCREEN_H)
end

return utils
