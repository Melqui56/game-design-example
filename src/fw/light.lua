local light = {}

local GLOW = 112
local glow = nil

local function glow_image()
  if not glow then
    glow = love.graphics.newCanvas(GLOW * 2, GLOW * 2)
    glow:setFilter("linear", "linear")
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(glow)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendMode("add")
    for r = GLOW, 1, -1 do
      local t = r / GLOW
      local a = math.min(1, (1 - t) * (1 - t) * 1.4)
      love.graphics.setColor(1, 0.95, 0.8, a)
      love.graphics.circle("fill", GLOW, GLOW, r)
    end
    love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()
    love.graphics.pop()
  end
  return glow
end

function light.draw(position)
  love.graphics.setBlendMode("add")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(glow_image(), position.x - GLOW, position.y - GLOW)
  love.graphics.setBlendMode("alpha")
end

return light