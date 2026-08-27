local render = require("src.fw.render")

local gameover = {}

function gameover.new(sm)
  return setmetatable({ sm = sm }, { __index = gameover })
end

function gameover.enter(_)
end

function gameover.update(_, _dt)
end

function gameover.draw(_)
  local w, h = love.graphics.getDimensions()
  love.graphics.clear(0.12, 0.05, 0.05)
  render.text_centered("Game Over", w * 0.5, h * 0.5 - 24)
  render.text_centered("Press Enter to retry", w * 0.5, h * 0.5 + 16)
end

function gameover.keypressed(self, key)
  if key == "return" or key == "kpenter" then
    self.sm:switch("play")
  elseif key == "escape" then
    self.sm:switch("title")
  end
end

return gameover