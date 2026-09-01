local menu     = require("src.core.menu")
local palette  = require("src.core.palette")
local backdrop = require("src.fw.backdrop")
local retro    = require("src.fw.retro")
local save_io  = require("src.fw.save_io")
local sfx      = require("src.fw.sfx")
local ui       = require("src.fw.ui")

local gameover = {}

function gameover.new(sm)
  return setmetatable({
    sm   = sm,
    menu = menu.new({ "Retry", "Menu" }),
  }, { __index = gameover })
end

function gameover.enter(self, score)
  retro.reset_offset()
  self.score = score or 0
  self.best  = save_io.get("high_score", 0)
end

function gameover.update(self, dt)
  menu.update(self.menu, dt)
end

function gameover.draw(self)
  local w, h = retro.getDimensions()
  backdrop.draw(palette, w, h)
  ui.title("GAME OVER", w * 0.5, 60)
  ui.hud_text_centered("SCORE " .. self.score, w * 0.5, 108)
  ui.hud_text_centered("BEST " .. self.best, w * 0.5, 126)
  ui.slant_menu(self.menu, w * 0.5 - 80, 154, { w = 150, step = 34 })
end

function gameover.keypressed(self, key)
  if key == "up" then
    menu.move(self.menu, -1)
    sfx.play("ui", 0.3)
  elseif key == "down" then
    menu.move(self.menu, 1)
    sfx.play("ui", 0.3)
  elseif key == "escape" then
    self.sm:switch("menu")
  elseif key == "return" or key == "kpenter" then
    sfx.play("ui", 0.3)
    if menu.current(self.menu) == "Retry" then
      self.sm:switch("play")
    else
      self.sm:switch("menu")
    end
  end
end

return gameover