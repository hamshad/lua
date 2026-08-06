-- conf.lua: LÖVE2D project configuration. LÖVE runs this file before
-- anything else — it fills the config table `t` that controls the
-- window, version, and modules. There is no code beyond these
-- settings; they tune the app before love.load() ever runs.

function love.conf(t)
    -- t.title: the window title bar text.
    t.title = "Feynman Procedural Animation - LÖVE2D"
    -- t.version: the LÖVE version this project targets (11.4+).
    t.version = "11.4"
    -- Window size in pixels. 1024x768 matches the physics book app
    -- so both projects share the same canvas and coordinates.
    t.window.width = 1024
    t.window.height = 768
    -- Resizable lets the window be dragged bigger/smaller; chapters
    -- are laid out for 1024x768, so keep it at that size for the
    -- intended look.
    t.window.resizable = true
    -- vsync = 1 locks the swap to the monitor's refresh rate, so the
    -- frame clock is steady and the fixed timestep stays predictable.
    t.window.vsync = 1
end