local palette = require("src.core.palette")

local render = {}

local function set_color(c)
  love.graphics.setColor(c[1], c[2], c[3])
end

function render.player(p)
  local x = p.position.x - p.size * 0.5
  local y = p.position.y - p.size * 0.5
  set_color(palette.player)
  love.graphics.rectangle("fill", x, y, p.size, p.size)
  set_color(palette.outline)
  love.graphics.rectangle("line", x, y, p.size, p.size)
  love.graphics.setColor(1, 1, 1, 0.25)
  love.graphics.rectangle("fill", x + 2, y + 2, p.size - 4, 3)
end

function render.enemy(e)
  set_color(palette.enemy)
  love.graphics.circle("fill", e.position.x, e.position.y, e.radius)
  set_color(palette.outline)
  love.graphics.circle("line", e.position.x, e.position.y, e.radius)
end

function render.bullet(b)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.rectangle("fill", b.position.x - b.radius, b.position.y - b.radius, b.radius * 2, b.radius * 2)
  set_color(palette.accent)
  love.graphics.rectangle("fill", b.position.x - 1, b.position.y - 1, 2, 2)
end

return render