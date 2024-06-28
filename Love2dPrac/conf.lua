function love.conf(t)
    t.identity = "data/saves"
    t.appendidentity = true
    t.version = "11.5"
    t.console = true
    t.gammacorrect = true

    t.window.title = "Practice 1"
    t.window.width = 1000
    t.window.height = 600
    t.window.display = 1
    t.window.resizable = true
    t.window.minwidth = 1
    t.window.minheight = 1
    t.window.x = 5
    t.window.y = 35
    -- t.window.fullscreen = true
    -- t.window.fullscreentype = "desktop"

    t.modules.keyboard = true
end
