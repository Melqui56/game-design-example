local menu     = require("src.core.menu")
local palette  = require("src.core.palette")
local backdrop = require("src.fw.backdrop")
local retro    = require("src.fw.retro")
local ui       = require("src.fw.ui")

local pause = {}

function pause.new(sm)
  return setmetatable({
    sm   = sm,
    menu = menu.new({ "Resume", "Menu" }),
  }, { __index = pause })
end

function pause.enter(_)
  retro.reset_offset()
end

function pause.update(self, dt)
  menu.update(self.menu, dt)
end

function pause.draw(self)
  local w, h = retro.getDimensions()
  backdrop.draw(palette, w, h)
  ui.title("PAUSED", w * 0.5, 80)
  ui.slant_menu(self.menu, w * 0.5 - 80, 132, { w = 150, step = 34 })
end

function pause.keypressed(self, key)
  if key == "up" then
    menu.move(self.menu, -1)
  elseif key == "down" then
    menu.move(self.menu, 1)
  elseif key == "escape" then
    self.sm:switch("play")
  elseif key == "return" or key == "kpenter" then
    if menu.current(self.menu) == "Resume" then
      self.sm:switch("play")
    else
      self.sm:switch("menu")
    end
  end
end

return pause