-- render.lua — draw everything through a single SpriteBatch.
--
-- The renderer collects sprite draws during a frame, sorts them by world Y
-- (painter's algorithm), and flushes them in ONE SpriteBatch draw call. The
-- outline and hit-flash effects are applied via a pixel shader instead of
-- baked sprites.

local palette      = require("src.core.palette")
local sprite_atlas = require("src.fw.sprite_atlas")
local shaders      = require("src.fw.shaders")

local render = {}

local VERTICAL = 0.82

local function sy(y)
  return math.floor(y * VERTICAL)
end

local function set_color(c)
  love.graphics.setColor(c[1], c[2], c[3])
end

local function shadow(x, y, rx, ry)
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", x, y, rx, ry)
end

-- ---------------------------------------------------------------------------
-- SpriteBatch pipeline
-- ---------------------------------------------------------------------------

local batch = nil
local sprites = {}
local shadows = {}
local overlays = {}
local MAX_SPRITES = 1024

-- Preload GPU resources (image, quads, sprite batch). Must run OUTSIDE any
-- active canvas (i.e. from love.load / app.load), because creating textures
-- while a canvas is bound silently fails on some LÖVE backends.
function render.preload()
  sprite_atlas.load()
  if not batch then
    batch = love.graphics.newSpriteBatch(sprite_atlas.image(), MAX_SPRITES, "stream")
  end
end

function render.begin()
  sprites = {}
  shadows = {}
  overlays = {}
end

-- Diagnostic helper (used by the screenshot/debug mode).
function render.debug_count()
  return #sprites, #shadows, #overlays
end

-- Queues a sprite. set_name/frame index into the atlas; flash uses the shader.
local function add_sprite(set_name, frame, x, y, flip, scale, flash, outline)
  local fw, fh = sprite_atlas.frame_size(set_name, frame)
  table.insert(sprites, {
    set_name = set_name,
    frame = frame,
    x = x,
    dy = sy(y),
    y = y,
    flip = flip or 1,
    scale = scale or 1,
    fw = fw,
    fh = fh,
    flash = flash or false,
    outline = outline,
  })
end

function render.cowboy(p, moving, muzzle, flash)
  local set_name
  if p.recoil > 0 then
    set_name = "cowboy_shoot"
  elseif moving then
    set_name = "cowboy_walk"
  else
    set_name = "cowboy_idle"
  end
  local a = moving and p.walk_anim or p.idle_anim
  if p.recoil > 0 then
    a = p.shoot_anim
  end
  local flip = p.aim.x < 0 and -1 or 1
  table.insert(shadows, { x = p.position.x, y = p.position.y, rx = 5, ry = 2 })
  add_sprite(set_name, a.frame, p.position.x, p.position.y, flip, 1, flash or p.flash)

  -- muzzle flash overlay drawn on top of the sprite
  if muzzle and muzzle > 0 then
    local mx = p.position.x + p.aim.x * 10
    local my = p.position.y + p.aim.y * 10
    table.insert(overlays, {
      x = mx - 2, y = sy(my) - 2, w = 4, h = 4,
      color = palette.muzzle,
    })
  end
end

function render.zombie(e, flash)
  local set_name = e.attacking and "zombie_attack" or "zombie_walk"
  local a = e.attacking and e.attack_anim or e.walk_anim
  local flip = (e.target.x < e.position.x) and -1 or 1
  table.insert(shadows, { x = e.position.x, y = e.position.y, rx = 5 * e.scale, ry = 2 * e.scale })
  add_sprite(set_name, a.frame, e.position.x, e.position.y, flip, e.scale, flash or e.flash)
end

function render.prop(pr)
  table.insert(shadows, { x = pr.x, y = pr.y, rx = 4, ry = 2 })
  add_sprite("prop_" .. pr.kind, 1, pr.x, pr.y, 1, 1, false)
end

-- ---------------------------------------------------------------------------
-- Primitives (ground, buildings, bullets, pickups, particles, effects)
-- ---------------------------------------------------------------------------

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

function render.bullet(b)
  local dy = sy(b.position.y)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.rectangle("fill", b.position.x - b.radius, dy - b.radius, b.radius * 2, b.radius * 2)
  set_color(palette.muzzle)
  love.graphics.rectangle("fill", b.position.x - 1, dy - 1, 2, 2)
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

-- O outlines the shape, X is the body, H the specular the light catches.
local HEART = {
  ".OO.OO.",
  "OHXOXXO",
  "OXXXXXO",
  "OXXXXXO",
  ".OXXXO.",
  "..OXO..",
  "...O...",
}

function render.icon(sprite, x, y, color, outline, hi)
  for row, line in ipairs(sprite) do
    for col = 1, #line do
      local ch = line:sub(col, col)
      local c = (ch == "X" and color) or (ch == "O" and outline)
        or (ch == "H" and hi) or nil
      if c then
        love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
        love.graphics.rectangle("fill", x + col - 1, y + row - 1, 1, 1)
      end
    end
  end
end

-- Hearts beat faster the closer the player is to dying, so the HUD carries
-- the danger instead of just reporting it. `pulse` is a free-running clock.
function render.hearts(amount, max, x, y, pulse)
  local low = amount <= math.max(1, math.floor(max * 0.34))
  local beat = 0
  if low and pulse then
    beat = math.max(0, math.sin(pulse * 7))
  end
  for i = 1, max do
    local filled = i <= amount
    local bx = x + (i - 1) * 9
    local by = y
    local body, hi = palette.muted, palette.muted
    if filled then
      body, hi = palette.danger, palette.bone
      if low then
        by = y - math.floor(beat * 1.5)
        body = {
          palette.danger[1] + beat * 0.15,
          palette.danger[2] + beat * 0.10,
          palette.danger[3] + beat * 0.10,
        }
      end
    end
    render.icon(HEART, bx, by, body, palette.outline, hi)
  end
end

function render.particles(list)
  for _, p in ipairs(list) do
    local t = p.life / p.max_life
    love.graphics.setColor(palette.zombie[1], palette.zombie[2], palette.zombie[3], t)
    love.graphics.rectangle("fill", p.x - p.size * 0.5, sy(p.y) - p.size * 0.5, p.size, p.size)
  end
end

-- ---------------------------------------------------------------------------
-- Flush
-- ---------------------------------------------------------------------------

-- Flushes the queued sprites sorted by world Y, with shadows below and
-- overlays above.
function render.flush()
  -- ground shadows under the sprites
  love.graphics.setColor(0, 0, 0, 0.35)
  for _, sh in ipairs(shadows) do
    love.graphics.ellipse("fill", sh.x, sh.y, sh.rx, sh.ry)
  end

  -- sprites, sorted by Y, one SpriteBatch draw call
  table.sort(sprites, function(a, b) return a.y < b.y end)
  batch:clear()

  local batch_outline = nil
  local batch_flash = nil
  local use_shader = os.getenv("LOVE_NOSHADER") == nil
  local function begin_segment(outline, flash)
    if batch_outline == outline and batch_flash == flash then
      return
    end
    batch:flush()
    if use_shader then
      if flash then
        shaders.flash()
      else
        shaders.outline(outline or palette.outline)
      end
    end
    batch_outline = outline
    batch_flash = flash
  end

  love.graphics.setColor(1, 1, 1, 1)
  if os.getenv("LOVE_NOSHADER") == nil then
    love.graphics.setShader(shaders.sprite)
  end
  for _, s in ipairs(sprites) do
    local quad = sprite_atlas.quad(s.set_name, s.frame)
    if quad then
      begin_segment(s.outline, s.flash)
      batch:add(quad, s.x, s.dy, 0, s.flip * s.scale, s.scale, s.fw * 0.5, s.fh * 0.5)
    end
  end
  batch:flush()
  love.graphics.draw(batch)
  love.graphics.setShader()

  -- overlays on top (muzzle flash, etc.)
  for _, o in ipairs(overlays) do
    love.graphics.setColor(o.color[1], o.color[2], o.color[3])
    love.graphics.rectangle("fill", o.x, o.y, o.w, o.h)
  end
end

return render