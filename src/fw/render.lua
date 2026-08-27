local render = {}

function render.player(p)
  love.graphics.setColor(0.95, 0.85, 0.25)
  love.graphics.rectangle(
    "fill",
    p.position.x - p.size * 0.5,
    p.position.y - p.size * 0.5,
    p.size,
    p.size
  )
end

function render.text_centered(text, x, y)
  local font = love.graphics.getFont()
  love.graphics.setColor(0.9, 0.9, 0.9, 1)
  love.graphics.print(text, x - font:getWidth(text) * 0.5, y)
end

function render.text(text, x, y)
  love.graphics.setColor(0.9, 0.9, 0.9, 1)
  love.graphics.print(text, x, y)
end

function render.enemy(e)
  love.graphics.setColor(0.85, 0.30, 0.30)
  love.graphics.circle("fill", e.position.x, e.position.y, e.radius)
end

return render