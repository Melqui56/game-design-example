local menu = require("src.core.menu")
local ui   = require("src.fw.ui")

local pause = {}

function pause.new(sm)
  return setmetatable({
    sm   = sm,
    menu = menu.new({ "Resume", "Menu" }),
  }, { __index = pause })
end

function pause.enter(_)
end

function pause.update(_, _dt)
end

function pause.draw(self)
  local w, h = love.graphics.getDimensions()
  love.graphics.clear(0.05, 0.05, 0.08)
  ui.title("Paused", w * 0.5, h * 0.35)
  ui.menu_items(self.menu, w * 0.5, h * 0.55, 28)
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