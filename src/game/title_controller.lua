local render = require("src.fw.render")

local title = {}

function title.new(sm)
  return setmetatable({ sm = sm }, { __index = title })
end

function title.enter(_)
end

function title.update(_, _dt)
end

function title.draw(_)
  local w, h = love.graphics.getDimensions()
  love.graphics.clear(0.08, 0.08, 0.12)
  render.text_centered("Game Design Example U", w * 0.5, h * 0.5 - 24)
  render.text_centered("Press Enter to play", w * 0.5, h * 0.5 + 16)
end

function title.keypressed(self, key)
  if key == "return" or key == "kpenter" then
    self.sm:switch("play")
  end
end

return title