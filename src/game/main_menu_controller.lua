local menu      = require("src.core.menu")
local starfield = require("src.core.starfield")
local ui        = require("src.fw.ui")

local main_menu = {}

function main_menu.new(sm)
  return setmetatable({
    sm    = sm,
    menu  = menu.new({ "Play", "Quit" }),
    stars = starfield.new(60),
  }, { __index = main_menu })
end

function main_menu.enter(_)
end

function main_menu.update(self, dt)
  starfield.update(self.stars, dt)
end

function main_menu.draw(self)
  local w, h = love.graphics.getDimensions()
  love.graphics.clear(0.07, 0.07, 0.12)
  for _, s in ipairs(self.stars.stars) do
    love.graphics.setColor(0.7, 0.7, 0.75, 0.8)
    love.graphics.rectangle("fill", s.x * w, s.y * h, s.size, s.size)
  end
  ui.title("Game Design Example U", w * 0.5, h * 0.32)
  ui.menu_items(self.menu, w * 0.5, h * 0.52, 28)
  love.graphics.setColor(0.45, 0.45, 0.5)
  love.graphics.print("v0.1.0", 8, h - 20)
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