-- conf.lua: LÖVE2D project configuration
-- Target: 60 FPS, fixed timestep so procedural motion is deterministic

function love.conf(t)
  t.title = "Feynman Procedural Animation - LÖVE2D"
  t.version = "11.4"
  t.window.width = 1024
  t.window.height = 768
  t.window.resizable = true
  t.window.vsync = 1
end