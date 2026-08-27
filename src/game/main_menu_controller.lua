local menu      = require("src.core.menu")
local palette   = require("src.core.palette")
local starfield = require("src.core.starfield")
local backdrop  = require("src.fw.backdrop")
local retro     = require("src.fw.retro")
local ui        = require("src.fw.ui")

local main_menu = {}

function main_menu.new(sm)
  return setmetatable({
    sm    = sm,
    menu  = menu.new({ "Play", "Quit" }),
    stars = starfield.new(50),
  }, { __index = main_menu })
end

function main_menu.enter(_)
  retro.reset_offset()
end

function main_menu.update(self, dt)
  starfield.update(self.stars, dt)
end

function main_menu.draw(self)
  local w, h = retro.getDimensions()
  backdrop.draw(palette, w, h)
  for _, s in ipairs(self.stars.stars) do
    love.graphics.setColor(palette.star[1], palette.star[2], palette.star[3])
    love.graphics.rectangle("fill", s.x * w, s.y * h, s.size, s.size)
  end
  ui.title("GAME DESIGN", w * 0.5, 40)
  ui.title("EXAMPLE U", w * 0.5, 68)
  ui.menu_items(self.menu, w * 0.5, 140, 26)
  ui.hud_text("v0.3.0", 4, h - 14)
end

function main_menu.keypressed(self, key)
  if key == "up" then
    menu.move(self.menu, -1)
  elseif key == "down" then
    menu.move(self.menu, 1)
  elseif key == "return" or key == "kpenter" then
    if menu.current(self.menu) == "Play" then
      self.sm:switch("play")
    else
      love.event.quit()
    end
  end
end

return main_menu