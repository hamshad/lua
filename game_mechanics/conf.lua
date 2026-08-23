-- conf.lua: LÖVE2D project configuration. LÖVE runs this file before
-- anything else — it fills the config table `t` that controls the
-- window, version, and modules.

function love.conf(t)
  t.title = "Feynman Game Mechanics - LÖVE2D"
  t.version = "11.4"
  t.window.width = 1024
  t.window.height = 768
  t.window.resizable = true
  t.window.vsync = 1
end
