local menu     = require("src.core.menu")
local palette  = require("src.core.palette")
local backdrop = require("src.fw.backdrop")
local retro    = require("src.fw.retro")
local ui       = require("src.fw.ui")

local gameover = {}

function gameover.new(sm)
  return setmetatable({
    sm   = sm,
    menu = menu.new({ "Retry", "Menu" }),
  }, { __index = gameover })
end

function gameover.enter(_)
  retro.reset_offset()
end

function gameover.update(_, _dt)
end

function gameover.draw(self)
  local w, h = retro.getDimensions()
  backdrop.draw(palette, w, h)
  ui.title("GAME OVER", w * 0.5, 80)
  ui.menu_items(self.menu, w * 0.5, 140, 26)
end

function gameover.keypressed(self, key)
  if key == "up" then
    menu.move(self.menu, -1)
  elseif key == "down" then
    menu.move(self.menu, 1)
  elseif key == "escape" then
    self.sm:switch("menu")
  elseif key == "return" or key == "kpenter" then
    if menu.current(self.menu) == "Retry" then
      self.sm:switch("play")
    else
      self.sm:switch("menu")
    end
  end
end

return gameover