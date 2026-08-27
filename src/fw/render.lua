local palette = require("src.core.palette")
local sprites = require("src.fw.sprites")

local render = {}

local VERTICAL = 0.82

local function set_color(c)
  love.graphics.setColor(c[1], c[2], c[3])
end

local function sy(y)
  return math.floor(y * VERTICAL)
end

local function shadow(x, y, rx, ry)
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", x, y, rx, ry)
end

function render.ground(w, h)
  love.graphics.setColor(0, 0, 0, 0.10)
  local horizon = math.floor(h * 0.22)
  local depth = h - horizon
  for i = 1, 10 do
    local t = i / 10
    local y = horizon + depth * t * t
    love.graphics.line(0, y, w, y)
  end
  local cx = w * 0.5
  for i = 0, 12 do
    local bx = (i / 12) * w
    love.graphics.line(cx, horizon, bx, h)
  end
end

function render.cowboy(p, moving, muzzle)
  sprites.ensure()
  local gx = p.position.x
  local gy = p.position.y
  shadow(gx, gy, 5, 2)
  local dy = sy(gy)

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
  love.graphics.draw(img, gx, dy, 0, sx, 1, w * 0.5, h * 0.5)

  local bx = gx + p.aim.x * 6
  local by = dy + p.aim.y * 6
  set_color(palette.boot)
  love.graphics.rectangle("fill", bx - 1, by - 1, 2, 4)

  if muzzle and muzzle > 0 then
    set_color(palette.muzzle)
    love.graphics.rectangle("fill", gx + p.aim.x * 10 - 2, dy + p.aim.y * 10 - 2, 4, 4)
  end
end

function render.zombie(e)
  sprites.ensure()
  local gx = e.position.x
  local gy = e.position.y
  shadow(gx, gy, 5, 2)
  local dy = sy(gy)

  local frames = e.flash and sprites.zombie_flash or sprites.zombie
  local img = frames[e.anim.frame] or frames[1]
  local w = img:getWidth()
  local h = img:getHeight()
  local sx = 1
  if e.target.x < e.position.x then
    sx = -1
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, gx, dy, 0, sx, 1, w * 0.5, h * 0.5)
end

function render.bullet(b)
  local dy = sy(b.position.y)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.rectangle("fill", b.position.x - b.radius, dy - b.radius, b.radius * 2, b.radius * 2)
  set_color(palette.muzzle)
  love.graphics.rectangle("fill", b.position.x - 1, dy - 1, 2, 2)
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
    love.graphics.rectangle("fill", p.x - p.size * 0.5, sy(p.y) - p.size * 0.5, p.size, p.size)
  end
end

return render