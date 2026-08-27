local backdrop = {}

local canvas = nil

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function build(palette, w, h)
  local c = love.graphics.newCanvas(w, h)
  love.graphics.setCanvas(c)
  for y = 0, h - 1 do
    local t = y / (h - 1)
    love.graphics.setColor(
      lerp(palette.night[1], palette.dusk[1], t),
      lerp(palette.night[2], palette.dusk[2], t),
      lerp(palette.night[3], palette.dusk[3], t)
    )
    love.graphics.rectangle("fill", 0, y, w, 1)
  end
  love.graphics.setCanvas()
  return c
end

function backdrop.draw(palette, w, h)
  if not canvas then
    canvas = build(palette, w, h)
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canvas, 0, 0)
end

return backdrop