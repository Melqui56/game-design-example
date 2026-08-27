local retro = {}

local VW, VH = 480, 270
local canvas = nil

function retro.getDimensions()
  return VW, VH
end

function retro.begin()
  if not canvas then
    canvas = love.graphics.newCanvas(VW, VH)
    canvas:setFilter("nearest", "nearest")
  end
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0)
end

function retro.finish()
  love.graphics.setCanvas()
  love.graphics.clear(0, 0, 0)
  local w, h = love.graphics.getDimensions()
  local scale = math.max(1, math.floor(math.min(w / VW, h / VH)))
  local ox = math.floor((w - VW * scale) * 0.5)
  local oy = math.floor((h - VH * scale) * 0.5)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canvas, ox, oy, 0, scale, scale)
end

return retro