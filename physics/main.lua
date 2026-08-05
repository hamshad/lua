-- ============================================================
-- FEYNMAN PHYSICS — LÖVE2D
-- ============================================================
-- A LÖVE2D game that teaches game physics, maths, and Box2D
-- through 13 interactive chapters. Each chapter is a module in
-- chapters/ that exports init()/update()/draw() and optionally
-- mousepressed()/keypressed().
--
-- Shared resources live in:
--   vec2.lua   — a tiny 2D vector library (Chapter 1)
--   utils.lua  — timestep, formatting, body factories, draw helpers
--
-- Controls:
--   1-9,0      Switch to chapter 1-10
--   -  =  ⌅   Switch to chapters 11, 12, 13
--   SPACE      Reset current chapter
--   ESC        Quit
--   MOUSE / arrow keys — vary per chapter
-- ============================================================

local utils = require("utils")

local chapters = {
    require("chapters.chapter1"),
    require("chapters.chapter2"),
    require("chapters.chapter3"),
    require("chapters.chapter4"),
    require("chapters.chapter5"),
    require("chapters.chapter6"),
    require("chapters.chapter7"),
    require("chapters.chapter8"),
    require("chapters.chapter9"),
    require("chapters.chapter10"),
    require("chapters.chapter11"),
    require("chapters.chapter12"),
    require("chapters.chapter13"),
}

-- Globals shared with chapters (set inside each init):
--   world  — the current Box2D world object
--   fontSmall/Medium/Large — UI fonts (created in love.load)
--   FIXED_DT — physics timestep (fixed, from utils)
--   accumulator — left-over frame time carried to next frame
local currentChapter = 1
local totalChapters = 13
local accumulator = 0
FIXED_DT = utils.FIXED_DT
world = nil

-- ============================================================
-- LOVE2D CALLBACKS
-- ============================================================
function love.load()
    fontSmall = love.graphics.newFont(12)
    fontMedium = love.graphics.newFont(14)
    fontLarge = love.graphics.newFont(18)

    initChapter(currentChapter)
end

function love.update(dt)
    accumulator = accumulator + dt
    if accumulator > 0.25 then accumulator = 0.25 end
    while accumulator >= FIXED_DT do
        chapters[currentChapter].update()
        accumulator = accumulator - FIXED_DT
    end
end

function love.draw()
    drawHeader()
    chapters[currentChapter].draw()
    drawControls()
end

function love.keypressed(key)
    -- Chapter-specific key first, so chapters with their own keys work
    local ch = chapters[currentChapter]
    if ch.keypressed then
        ch.keypressed(key)
    end

    -- Global navigation keys
    local keyMap = {
        ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5,
        ["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9, ["0"] = 10,
        ["-"] = 11, ["="] = 12, ["return"] = 13,
    }
    if keyMap[key] then
        initChapter(keyMap[key])
        return
    end

    if key == "escape" then
        love.event.quit()
    elseif key == " " then
        initChapter(currentChapter)
    end
end

function love.mousepressed(x, y, button)
    local ch = chapters[currentChapter]
    if ch.mousepressed then
        ch.mousepressed(x, y, button)
    end
end

-- ============================================================
-- CHAPTER DISPATCH
-- ============================================================
function initChapter(ch)
    if world then
        world:destroy()
        world = nil
    end
    currentChapter = ch
    chapters[ch].init()
end

-- ============================================================
-- HEADER / CONTROLS
-- ============================================================
function drawHeader()
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.print("FEYNMAN PHYSICS — LÖVE2D", 10, 5)
    love.graphics.print("Chapter " .. currentChapter .. "/" .. totalChapters, 10, 20)
    love.graphics.setColor(1, 1, 1)
end

function drawControls()
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.print("[1-9,0] Ch1-10  [-] Ch11  [=] Ch12  [Enter] Ch13  [SPACE] Reset  [ESC] Quit", 10, 755)
    love.graphics.setColor(1, 1, 1)
end