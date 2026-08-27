local palette = require("src.core.palette")
local sprites = require("src.fw.sprites")

local render = {}

local function set_color(c)
  love.graphics.setColor(c[1], c[2], c[3])
end

function render.cowboy(p, moving, muzzle)
  sprites.ensure()
  local frames = p.flash and sprites.cowboy_flash or sprites.cowboy
  local a = moving and p.walk_anim or p.idle_anim
  local img = frames[a.frame]
  local w = img:getWidth()
  local h = img:getHeight()
  local sx = 1
  if p.aim.x < 0 then
    sx = -1
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, p.position.x, p.position.y, 0, sx, 1, w * 0.5, h * 0.5)

  local bx = p.position.x + p.aim.x * 6
  local by = p.position.y + p.aim.y * 6
  set_color(palette.boot)
  love.graphics.rectangle("fill", bx - 1, by - 1, 2, 4)

  if muzzle and muzzle > 0 then
    set_color(palette.muzzle)
    love.graphics.rectangle("fill", p.position.x + p.aim.x * 10 - 2, p.position.y + p.aim.y * 10 - 2, 4, 4)
  end
end

function render.zombie(e)
  sprites.ensure()
  local frames = e.flash and sprites.zombie_flash or sprites.zombie
  local img = frames[e.anim.frame] or frames[1]
  local w = img:getWidth()
  local h = img:getHeight()
  local sx = 1
  if e.target.x < e.position.x then
    sx = -1
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, e.position.x, e.position.y, 0, sx, 1, w * 0.5, h * 0.5)
end

function render.bullet(b)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.rectangle("fill", b.position.x - b.radius, b.position.y - b.radius, b.radius * 2, b.radius * 2)
  set_color(palette.muzzle)
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
    love.graphics.setColor(palette.zombie[1], palette.zombie[2], palette.zombie[3], t)
    love.graphics.rectangle("fill", p.x - p.size * 0.5, p.y - p.size * 0.5, p.size, p.size)
  end
end

return render