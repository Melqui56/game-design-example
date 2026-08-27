local palette = require("src.core.palette")

local render = {}

local function set_color(c)
  love.graphics.setColor(c[1], c[2], c[3])
end

function render.player(p)
  local x = p.position.x - p.size * 0.5
  local y = p.position.y - p.size * 0.5
  if p.flash then
    love.graphics.setColor(1, 1, 1, 0.85)
  else
    set_color(palette.player)
  end
  love.graphics.rectangle("fill", x, y, p.size, p.size)
  set_color(palette.outline)
  love.graphics.rectangle("line", x, y, p.size, p.size)
  love.graphics.setColor(1, 1, 1, 0.25)
  love.graphics.rectangle("fill", x + 2, y + 2, p.size - 4, 3)

  local nx = p.position.x + p.aim.x * (p.size * 0.5)
  local ny = p.position.y + p.aim.y * (p.size * 0.5)
  love.graphics.setColor(palette.eye[1], palette.eye[2], palette.eye[3])
  love.graphics.rectangle("fill", nx - 1, ny - 1, 2, 2)
end

function render.enemy(e)
  if e.flash then
    love.graphics.setColor(palette.eye[1], palette.eye[2], palette.eye[3])
  else
    set_color(palette.enemy)
  end
  love.graphics.circle("fill", e.position.x, e.position.y, e.radius)
  set_color(palette.outline)
  love.graphics.circle("line", e.position.x, e.position.y, e.radius)

  love.graphics.setColor(palette.outline[1], palette.outline[2], palette.outline[3], 0.5)
  love.graphics.circle("fill", e.position.x, e.position.y, e.radius * 0.35)

  local dx = e.target.x - e.position.x
  local dy = e.target.y - e.position.y
  local len = math.sqrt(dx * dx + dy * dy)
  local ux, uy = 0, -1
  if len > 0 then
    ux, uy = dx / len, dy / len
  end
  local px, py = -uy, ux
  local cx = e.position.x + ux * e.radius * 0.55
  local cy = e.position.y + uy * e.radius * 0.55
  set_color(palette.eye)
  love.graphics.rectangle("fill", cx + px * 2 - 1, cy + py * 2 - 1, 2, 2)
  love.graphics.rectangle("fill", cx - px * 2 - 1, cy - py * 2 - 1, 2, 2)
end

function render.bullet(b)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.rectangle("fill", b.position.x - b.radius, b.position.y - b.radius, b.radius * 2, b.radius * 2)
  set_color(palette.accent)
  love.graphics.rectangle("fill", b.position.x - 1, b.position.y - 1, 2, 2)
end

local HEART = {
  ".XX.XX.",
  "XXXXXXX",
  "XXXXXXX",
  ".XXXXX.",
  "..XXX..",
  "...X...",
}

function render.icon(sprite, x, y, color)
  love.graphics.setColor(color[1], color[2], color[3])
  for row, line in ipairs(sprite) do
    for col = 1, #line do
      if line:sub(col, col) == "X" then
        love.graphics.rectangle("fill", x + col - 1, y + row - 1, 1, 1)
      end
    end
  end
end

function render.hearts(amount, max, x, y)
  for i = 1, max do
    if i <= amount then
      render.icon(HEART, x + (i - 1) * 9, y, palette.danger)
    else
      render.icon(HEART, x + (i - 1) * 9, y, palette.muted)
    end
  end
end

function render.particles(list)
  for _, p in ipairs(list) do
    local t = p.life / p.max_life
    love.graphics.setColor(palette.enemy[1], palette.enemy[2], palette.enemy[3], t)
    love.graphics.rectangle("fill", p.x - p.size * 0.5, p.y - p.size * 0.5, p.size, p.size)
  end
end

return render