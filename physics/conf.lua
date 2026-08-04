-- conf.lua: LÖVE2D project configuration
-- Target: 60 FPS, fixed timestep physics

function love.conf(t)
  t.title = "Feynman Physics - LÖVE2D"
  t.version = "11.4"
  t.window.width = 1024
  t.window.height = 768
  t.window.resizable = true
  t.window.vsync = 1
  t.physics = t.physics or {}
  t.physics.meter = 30 -- 1 meter = 30 pixels
end
