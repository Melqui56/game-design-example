local retro = {}

local VW, VH = 480, 270
local SCALE = 2
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
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canvas, 0, 0, 0, SCALE, SCALE)
end

return retro