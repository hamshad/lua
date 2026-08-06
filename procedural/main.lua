-- ============================================================
-- FEYNMAN PROCEDURAL ANIMATION — LÖVE2D
-- ============================================================
-- A LÖVE2D app that teaches procedural animation and game feel
-- through 14 interactive chapters. Each chapter is a module in
-- chapters/ exporting init()/update()/draw() and optionally
-- mousepressed()/keypressed().
--
-- Shared resources:
--   vec2.lua   — tiny 2D vector library
--   utils.lua  — clamp/lerp/damp, easing curves, draw helpers
--
-- Controls:
--   1-9,0      Chapters 1-10
--   -          Chapter 11
--   =          Chapter 12
--   ENTER      Chapter 13
--   ]          Chapter 14
--   SPACE      Reset current chapter
--   ESC        Quit
--   MOUSE / arrow keys — vary per chapter
-- ============================================================

-- The shared math helpers every chapter draws on.
local utils = require("utils")

-- chapters: ordered list of the 14 chapter modules, indexed by
-- chapter number. `chapters[1]` is chapter1.lua, `chapters[14]` is
-- chapter14.lua.
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
    require("chapters.chapter14"),
}

-- Globals shared with chapters (set inside each init):
--   fontSmall/Medium/Large — UI fonts (created in love.load)
--   FIXED_DT               — the fixed timestep (from utils)
--
-- currentChapter: the chapter number being shown right now.
--   Example: initChapter(4) → currentChapter = 4.
local currentChapter = 1
-- totalChapters: how many chapter modules exist (used by the header).
local totalChapters = 14
-- accumulator: leftover real time (seconds) not yet spent on a fixed
-- physics step. It lets us step at exact 1/60 s intervals no matter
-- what the frame rate is.
--   Example: dt = 0.016 (60fps) → accumulator grows by 0.016 each
--            frame and is drained in 1/60 pieces inside love.update.
local accumulator = 0
-- FIXED_DT: global copy of utils.FIXED_DT (1/60 s). Chapters read it
-- so their update() steps the same fixed interval as the dispatcher.
FIXED_DT = utils.FIXED_DT

-- ============================================================
-- LOVE2D CALLBACKS
-- ============================================================

-- love.load(): called once at startup. Creates the three UI fonts
-- (12/14/18 px) used by the header, chapters, and control hints,
-- then boots the first chapter.
function love.load()
    fontSmall = love.graphics.newFont(12)
    fontMedium = love.graphics.newFont(14)
    fontLarge = love.graphics.newFont(18)

    initChapter(currentChapter)
end

-- love.update(dt): the fixed-timestep heart. The real frame delta
-- `dt` is accumulated; once a full 1/60 s is owed, the active
-- chapter is stepped exactly once per owed slice. This makes every
-- chapter deterministic at any frame rate.
--   Example: a 100 fps display gives dt ≈ 0.01 s. After ~6 frames
--            the accumulator owes one full FIXED_DT, so the chapter
--            steps once; total steps still hit exactly 60/sec.
function love.update(dt)
    -- Bank the real time.
    accumulator = accumulator + dt
    -- Safety cap: if the game stalls (window drag, breakpoint),
    -- never try to catch up with more than 0.25 s of steps at once.
    if accumulator > 0.25 then accumulator = 0.25 end
    -- Spend the banked time in whole fixed steps.
    while accumulator >= FIXED_DT do
        chapters[currentChapter].update(FIXED_DT)
        accumulator = accumulator - FIXED_DT
    end
end

-- love.draw(): paint the persistent header, the active chapter's
-- scene, and the persistent control hints at the bottom.
function love.draw()
    drawHeader()
    chapters[currentChapter].draw()
    drawControls()
end

-- love.keypressed(key): first hand the key to the active chapter
-- (so chapters can define their own keys), then handle the global
-- navigation keys (1-9,0,-,=,ENTER,], SPACE, ESC).
function love.keypressed(key)
    -- Chapter-specific key first, so chapters can use their own keys.
    local ch = chapters[currentChapter]
    if ch.keypressed then
        ch.keypressed(key)
    end

    -- keyMap: maps each key name to the chapter number it opens.
    --   Example: pressing "3" → initChapter(3).
    local keyMap = {
        ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5,
        ["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9, ["0"] = 10,
        ["-"] = 11, ["="] = 12, ["return"] = 13, ["]"] = 14,
    }
    if keyMap[key] then
        initChapter(keyMap[key])
        return
    end

    if key == "escape" then
        love.event.quit()
    elseif key == " " then
        -- Reset the current chapter to a clean state.
        initChapter(currentChapter)
    end
end

-- love.mousepressed(x, y, button): forward clicks to the active
-- chapter if it has a mouse handler.
--   x, y:     click position in pixels
--   button:   1 = left, 2 = right
function love.mousepressed(x, y, button)
    local ch = chapters[currentChapter]
    if ch.mousepressed then
        ch.mousepressed(x, y, button)
    end
end

-- ============================================================
-- CHAPTER DISPATCH
-- ============================================================

-- initChapter(ch): switch to chapter number `ch`, resetting all its
-- state via its init(). Also updates currentChapter so the header
-- and key handlers point at the new chapter.
--   Example: initChapter(7) → currentChapter = 7, chapter7.init()
function initChapter(ch)
    currentChapter = ch
    chapters[ch].init()
end

-- ============================================================
-- HEADER / CONTROLS
-- ============================================================

-- drawHeader(): draw the persistent top bar — the app title and the
-- "Chapter N/14" readout. currentChapter feeds the N.
function drawHeader()
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.print("FEYNMAN PROCEDURAL ANIMATION — LÖVE2D", 10, 5)
    love.graphics.print("Chapter " .. currentChapter .. "/" .. totalChapters, 10, 20)
    love.graphics.setColor(1, 1, 1)
end

-- drawControls(): draw the persistent bottom bar listing the global
-- navigation keys.
function drawControls()
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.print("[1-9,0] Ch1-10  [-] Ch11  [=] Ch12  [13] Ch13  [14] Ch14  [SPACE] Reset  [ESC] Quit", 10, 752)
    love.graphics.setColor(1, 1, 1)
end