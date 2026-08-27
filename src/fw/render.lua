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

local ground_tile_cache = nil

local function ground_tile()
  if not ground_tile_cache then
    ground_tile_cache = love.graphics.newCanvas(16, 16)
    ground_tile_cache:setFilter("nearest", "nearest")
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(ground_tile_cache)
    love.graphics.setColor(0.13, 0.12, 0.10)
    love.graphics.rectangle("fill", 0, 0, 16, 16)
    for _ = 1, 10 do
      love.graphics.setColor(0.09, 0.08, 0.07)
      love.graphics.rectangle("fill", love.math.random(15), love.math.random(15), 2, 1)
    end
    love.graphics.setCanvas()
    love.graphics.pop()
  end
  return ground_tile_cache
end

function render.ground(world_w, world_h)
  local tile = ground_tile()
  love.graphics.setColor(1, 1, 1, 1)
  for y = 0, world_h - 1, 16 do
    for x = 0, world_w - 1, 16 do
      love.graphics.draw(tile, x, y)
    end
  end

  love.graphics.setColor(palette.wood[1], palette.wood[2], palette.wood[3])
  for x = 8, world_w - 8, 24 do
    love.graphics.rectangle("fill", x, 0, 3, 6)
    love.graphics.rectangle("fill", x, world_h - 6, 3, 6)
  end
  for y = 8, world_h - 8, 24 do
    love.graphics.rectangle("fill", 0, y, 6, 3)
    love.graphics.rectangle("fill", world_w - 6, y, 6, 3)
  end
end

function render.building(b)
  local gx = b.x
  local gy = b.y
  shadow(gx, gy, b.w * 0.6, 3)
  local dy = sy(gy)

  love.graphics.setColor(palette.wood[1], palette.wood[2], palette.wood[3])
  love.graphics.rectangle("fill", gx - b.w * 0.5, dy - b.h, b.w, b.h)
  love.graphics.setColor(palette.roof[1], palette.roof[2], palette.roof[3])
  love.graphics.polygon("fill", gx - b.w * 0.5 - 2, dy - b.h, gx + b.w * 0.5 + 2, dy - b.h, gx, dy - b.h - 9)
  love.graphics.setColor(palette.door[1], palette.door[2], palette.door[3])
  love.graphics.rectangle("fill", gx - 3, dy - 10, 6, 10)
  love.graphics.setColor(palette.glass[1], palette.glass[2], palette.glass[3])
  love.graphics.rectangle("fill", gx - b.w * 0.5 + 3, dy - b.h + 4, 4, 4)
  love.graphics.rectangle("fill", gx + b.w * 0.5 - 7, dy - b.h + 4, 4, 4)
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
  shadow(gx, gy, 5 * e.scale, 2 * e.scale)
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
  love.graphics.draw(img, gx, dy, 0, sx * e.scale, e.scale, w * 0.5, h * 0.5)
end

function render.prop(pr)
  sprites.ensure()
  local img = sprites.props[pr.kind]
  if not img then
    return
  end
  local gx = pr.x
  local gy = pr.y
  shadow(gx, gy, 4, 2)
  local dy = sy(gy)
  local w = img:getWidth()
  local h = img:getHeight()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, gx, dy, 0, 1, 1, w * 0.5, h * 0.5)
end

function render.pickup(pk)
  local gx = pk.position.x
  local gy = pk.position.y
  shadow(gx, gy, 4, 2)
  local dy = sy(gy)
  local bob = math.floor(math.sin(pk.age * 4) * 2)
  love.graphics.setColor(pk.def.color[1], pk.def.color[2], pk.def.color[3])
  love.graphics.polygon("fill",
    gx, dy + bob - 5,
    gx + 5, dy + bob,
    gx, dy + bob + 5,
    gx - 5, dy + bob)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.rectangle("fill", gx - 1, dy + bob - 1, 2, 2)
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