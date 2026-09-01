-- title_art.lua — every pixel of the main menu.
--
-- Layout on the 480x270 virtual canvas:
--
--   y   0..152  sky (gradient, moon, mesas, distant town) -- baked once
--   y 152..270  desert floor, foreground props            -- baked once
--   on top      stars, shambling silhouettes, tumbleweed, dust,
--               the hero, the COWBOY vs ZOMBIES logo, the menu
--
-- Static layers live in a canvas built by `preload()` (called from
-- app.load, i.e. outside any bound canvas). Animated layers read their
-- numbers from src/core/title_scene.lua and only draw.

local palette      = require("src.core.palette")
local retro        = require("src.fw.retro")
local sprite_atlas = require("src.fw.sprite_atlas")
local title_scene  = require("src.core.title_scene")
local ui           = require("src.fw.ui")

local title_art = {}

local VW, VH  = retro.getDimensions()
local HORIZON = 152

-- Box-art composition: the bust bleeds off the bottom left, the logo sits in
-- a block across the top right, the menu comes in under it on the diagonal.
local PORTRAIT_X     = -2
local PORTRAIT_Y     = 104
local PORTRAIT_SCALE = 2
local GUN_OX         = 28      -- gun sprite origin, in bust pixels; muzzle of
local GUN_OY         = 25      -- idle frame 1 lands on body px (54,35)

local MENU_X    = 278
local MENU_Y    = 152
local MENU_STEP = 32
local MENU_OPTS = { w = 178, h = 26, step = MENU_STEP, skew = 18, size = 10 }

local LOGO_SCALE   = 2
local COWBOY_X     = 168
local COWBOY_Y     = 12
local ZOMBIES_X    = 196
local ZOMBIES_Y    = 48
local VS_X         = 176
local VS_Y         = 54

local bg, glow, vig, slant = nil, nil, nil, nil

-- ---------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------

local function set_color(c, a)
  love.graphics.setColor(c[1], c[2], c[3], a or 1)
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function mix(c1, c2, t)
  return {
    lerp(c1[1], c2[1], t),
    lerp(c1[2], c2[2], t),
    lerp(c1[3], c2[3], t),
  }
end

-- ---------------------------------------------------------------------------
-- Baked layers
-- ---------------------------------------------------------------------------

local function draw_sky()
  local ember_from = HORIZON - 22
  for y = 0, HORIZON - 1 do
    local t = y / (HORIZON - 1)
    local c
    if t < 0.62 then
      c = mix(palette.sky_top, palette.sky_mid, t / 0.62)
    else
      c = mix(palette.sky_mid, palette.sky_horizon, (t - 0.62) / 0.38)
    end
    if y > ember_from then
      c = mix(c, palette.sky_ember, ((y - ember_from) / 22) * 0.8)
    end
    set_color(c)
    love.graphics.rectangle("fill", 0, y, VW, 1)
  end
end

local function draw_moon(cx, cy, r)
  for i = r * 3, r, -1 do
    local a = (1 - i / (r * 3)) ^ 2 * 0.16
    love.graphics.setColor(0.95, 0.85, 0.70, a)
    love.graphics.circle("fill", cx, cy, i)
  end
  set_color(palette.moon)
  love.graphics.circle("fill", cx, cy, r)
  set_color(palette.moon_dark)
  love.graphics.circle("fill", cx - 5, cy - 4, 3)
  love.graphics.circle("fill", cx + 4, cy + 3, 2)
  love.graphics.circle("fill", cx + 1, cy - 7, 1)
end

-- A butte: flat top, sloped shoulders, sitting on `base`.
local function mesa(x, w, h, base, color)
  local s = h * 0.42
  set_color(color)
  love.graphics.polygon("fill",
    x, base,
    x + s, base - h,
    x + w - s, base - h,
    x + w, base)
end

local function draw_town(x, base)
  local function block(bx, bw, bh)
    set_color(palette.town)
    love.graphics.rectangle("fill", x + bx, base - bh, bw, bh)
  end
  local function window(wx, wy)
    love.graphics.setColor(palette.glass[1], palette.glass[2], palette.glass[3], 0.85)
    love.graphics.rectangle("fill", x + wx, base - wy, 2, 2)
  end

  block(0, 30, 20)                       -- saloon
  set_color(palette.town)
  love.graphics.polygon("fill", x - 3, base - 20, x + 33, base - 20, x + 15, base - 27)
  block(32, 20, 14)                      -- store
  block(54, 16, 22)                      -- church body
  block(60, 5, 32)                       -- steeple
  set_color(palette.town)
  love.graphics.rectangle("fill", x + 61, base - 36, 3, 5)   -- cross post
  love.graphics.rectangle("fill", x + 59, base - 35, 7, 2)   -- cross arm
  block(76, 3, 16)                       -- water-tower legs
  block(86, 3, 16)
  block(74, 17, 10)                      -- water tank

  window(6, 14)
  window(20, 14)
  window(38, 9)
  window(58, 15)
end

local function scatter_props()
  local img = sprite_atlas.image()
  if not img then
    return
  end
  local function prop(kind, x, y, scale, color)
    local key = "prop_" .. kind
    local q = sprite_atlas.quad(key, 1)
    if not q then
      return
    end
    local fw, fh = sprite_atlas.frame_size(key, 1)
    set_color(color)
    love.graphics.draw(img, q, x, y, 0, scale, scale, fw * 0.5, fh)
  end

  local far = palette.mesa_near
  prop("cactus", 26, HORIZON + 16, 3, far)
  prop("cactus", 452, HORIZON + 26, 4, far)
  prop("bush", 300, HORIZON + 12, 2, far)
  prop("bush", 190, HORIZON + 9, 2, far)
  prop("rock", 400, HORIZON + 40, 3, palette.sand_dark)
  prop("rock", 62, HORIZON + 58, 3, palette.sand_dark)
  prop("skull", 176, HORIZON + 92, 3, palette.bone_dark)
  prop("bush", 430, HORIZON + 86, 3, palette.sand_dark)
  prop("cactus", 20, HORIZON + 104, 5, palette.sand_dark)
end

local function draw_ground()
  set_color(palette.sand_dark)
  love.graphics.rectangle("fill", 0, HORIZON, VW, VH - HORIZON)

  -- warm sand catching the last of the sunset, fading downwards
  for y = 0, 26 do
    local a = (1 - y / 26) ^ 1.6 * 0.85
    love.graphics.setColor(palette.sand[1], palette.sand[2], palette.sand[3], a)
    love.graphics.rectangle("fill", 0, HORIZON + y, VW, 1)
  end

  -- trail running to the horizon
  love.graphics.setColor(palette.sand_light[1], palette.sand_light[2], palette.sand_light[3], 0.22)
  love.graphics.polygon("fill", 188, VH, 292, VH, 248, HORIZON, 232, HORIZON)

  -- grit
  love.math.setRandomSeed(20250901)
  for _ = 1, 340 do
    local x = love.math.random(VW)
    local y = HORIZON + love.math.random(VH - HORIZON)
    local depth = (y - HORIZON) / (VH - HORIZON)
    local c = love.math.random() < 0.5 and palette.sand_light or palette.sand_dark
    love.graphics.setColor(c[1], c[2], c[3], 0.20 + depth * 0.35)
    love.graphics.rectangle("fill", x, y, 1 + math.floor(depth * 2), 1)
  end
end

local function build_background()
  local c = love.graphics.newCanvas(VW, VH)
  c:setFilter("nearest", "nearest")
  love.graphics.push()
  love.graphics.origin()
  love.graphics.setCanvas(c)
  love.graphics.clear(0, 0, 0, 1)

  draw_sky()
  draw_moon(398, 42, 17)

  mesa(-16, 96, 40, HORIZON, palette.mesa_far)
  mesa(70, 54, 24, HORIZON, palette.mesa_far)
  mesa(330, 104, 46, HORIZON, palette.mesa_far)
  mesa(424, 72, 28, HORIZON, palette.mesa_far)

  mesa(-20, 74, 20, HORIZON, palette.mesa_near)
  mesa(392, 108, 24, HORIZON, palette.mesa_near)

  draw_town(214, HORIZON)
  draw_ground()
  scatter_props()

  love.graphics.setCanvas()
  love.graphics.pop()
  return c
end

-- Soft warm radial, used for the backlight, the muzzle flash and the eyes.
local function build_glow()
  local size = 64
  local c = love.graphics.newCanvas(size, size)
  c:setFilter("linear", "linear")
  love.graphics.push()
  love.graphics.origin()
  love.graphics.setCanvas(c)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setBlendMode("add")
  for r = size / 2, 1, -1 do
    local t = r / (size / 2)
    love.graphics.setColor(1, 0.88, 0.62, (1 - t) ^ 2 * 0.9)
    love.graphics.circle("fill", size / 2, size / 2, r)
  end
  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
  love.graphics.pop()
  return c
end

local function build_vignette()
  local c = love.graphics.newCanvas(VW, VH)
  c:setFilter("nearest", "nearest")
  love.graphics.push()
  love.graphics.origin()
  love.graphics.setCanvas(c)
  love.graphics.clear(0, 0, 0, 0)
  for i = 0, 33 do
    love.graphics.setColor(0, 0, 0, (1 - i / 33) ^ 2 * 0.13)
    love.graphics.rectangle("line", i + 0.5, i + 0.5, VW - 2 * i - 1, VH - 2 * i - 1)
  end
  love.graphics.setCanvas()
  love.graphics.pop()
  return c
end

-- The kinetic band the menu sits on: hard diagonal stripes with a halftone
-- field over them, baked once and then scrolled sideways at runtime. It is
-- twice the canvas width so the scroll can wrap without a seam.
local function build_slant()
  local w = VW * 2
  local c = love.graphics.newCanvas(w, VH)
  c:setFilter("nearest", "nearest")
  love.graphics.push()
  love.graphics.origin()
  love.graphics.setCanvas(c)
  love.graphics.clear(0, 0, 0, 0)

  local skew = 46
  for x = -skew, w, 34 do
    set_color(palette.outline, 0.30)
    love.graphics.polygon("fill", x, VH, x + skew, 0, x + skew + 15, 0, x + 15, VH)
    set_color(palette.leather, 0.14)
    love.graphics.polygon("fill", x + 17, VH, x + skew + 17, 0,
      x + skew + 20, 0, x + 20, VH)
  end

  -- halftone: dot size falls off downwards, the way a screen print fades
  for gy = 0, VH, 4 do
    local t = 1 - gy / VH
    for gx = (gy % 8 == 0) and 0 or 2, w, 4 do
      love.graphics.setColor(palette.gold[1], palette.gold[2], palette.gold[3],
        0.10 * t)
      love.graphics.rectangle("fill", gx, gy, t > 0.5 and 2 or 1, t > 0.5 and 2 or 1)
    end
  end

  love.graphics.setCanvas()
  love.graphics.pop()
  return c
end

-- Must run outside a bound canvas (app.load), never mid-frame.
function title_art.preload()
  sprite_atlas.load()
  bg = bg or build_background()
  glow = glow or build_glow()
  vig = vig or build_vignette()
  slant = slant or build_slant()
end

local function blob(x, y, radius, color, alpha)
  if alpha <= 0 or not glow then
    return
  end
  love.graphics.setBlendMode("add")
  love.graphics.setColor(color[1], color[2], color[3], alpha)
  love.graphics.draw(glow, x - radius, y - radius, 0, radius * 2 / 64, radius * 2 / 64)
  love.graphics.setBlendMode("alpha")
end

-- ---------------------------------------------------------------------------
-- Animated scenery
-- ---------------------------------------------------------------------------

local function draw_stars(st)
  for _, s in ipairs(st.stars) do
    local a = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(st.t * s.speed + s.phase))
    love.graphics.setColor(palette.star[1], palette.star[2], palette.star[3], a)
    love.graphics.rectangle("fill", math.floor(s.x * VW), math.floor(s.y * VH), s.size, s.size)
  end
end

local function draw_shamblers(st)
  local img = sprite_atlas.image()
  local count = sprite_atlas.frame_count("zombie_walk")
  if not img or count == 0 then
    return
  end
  for _, s in ipairs(st.shamblers) do
    local frame = (math.floor(st.t * 4 + s.bob) % count) + 1
    local q = sprite_atlas.quad("zombie_walk", frame)
    local fw, fh = sprite_atlas.frame_size("zombie_walk", frame)
    local x = math.floor(s.x * VW)
    local y = HORIZON + 4 + s.lane * 5
    love.graphics.setColor(0.06, 0.05, 0.07, 0.92)
    love.graphics.draw(img, q, x, y, 0, s.dir, 1, fw * 0.5, fh)
  end
end

local function draw_tumbleweed(st)
  local tw = st.tumbleweed
  if tw.wait > 0 then
    return
  end
  local x = tw.x * VW
  local y = 238 - math.abs(math.sin(tw.spin * 0.5)) * 3
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(tw.spin)
  set_color(palette.wood, 0.75)
  for i = 0, 4 do
    local a = i * math.pi / 5
    love.graphics.line(-6 * math.cos(a), -6 * math.sin(a), 6 * math.cos(a), 6 * math.sin(a))
  end
  love.graphics.pop()
end

local function draw_motes(st)
  for _, m in ipairs(st.motes) do
    local y = HORIZON + m.y * (VH - HORIZON)
    local a = (1 - m.y) * 0.30
    love.graphics.setColor(0.85, 0.72, 0.52, a)
    love.graphics.rectangle("fill", math.floor(m.x * VW), math.floor(y), m.size, m.size)
  end
end

function title_art.background(st)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(bg, 0, 0)
  draw_stars(st)
  draw_shamblers(st)
  draw_tumbleweed(st)
  draw_motes(st)
end

-- ---------------------------------------------------------------------------
-- Hero
-- ---------------------------------------------------------------------------

-- Anchors into the portrait art, in sprite pixels. See assets/sprites/hero.lua:
-- the eye sits in the bust, the muzzle in whichever revolver frame is up.
local EYE_PX  = { 34, 26 }
local MUZZLE_PX = {
  hero_idle = { { 26, 10 }, { 26, 9 } },
  hero_draw = { { 21, 6 }, { 16, 2 } },
}

function title_art.hero(st)
  local img = sprite_atlas.image()
  local body = sprite_atlas.quad("hero_body", 1)
  if not img or not body then
    return
  end
  local set, frame = title_scene.hero_frame(st)
  local h = title_scene.hero(st)
  local s = PORTRAIT_SCALE
  local x = PORTRAIT_X
  local y = math.floor(PORTRAIT_Y + h.dy + h.bob)

  -- the sunset burning behind him, and a slab of shadow he stands against
  blob(x + 56, y + 80, 132, palette.sky_ember, 0.30 * h.alpha)
  set_color(palette.outline, 0.30 * h.alpha)
  love.graphics.polygon("fill", x - 8, VH, x + 14, y - 6, x + 110, y - 6,
    x + 132, VH)

  love.graphics.setColor(1, 1, 1, h.alpha)
  love.graphics.draw(img, body, x, y, 0, s, s)

  -- the revolver, its own sprite so it can cock and kick
  local gq = sprite_atlas.quad(set, frame)
  if gq then
    love.graphics.setColor(1, 1, 1, h.alpha)
    love.graphics.draw(img, gq, x + GUN_OX * s, y + GUN_OY * s, 0, s, s)
  end

  -- the one eye burning in the shadow under the brim
  local ex = x + EYE_PX[1] * s
  local ey = y + EYE_PX[2] * s
  blob(ex + s, ey + s, 14, palette.eye_glow, 0.5 * h.glow * h.alpha)
  set_color(palette.eye_glow, (0.65 + 0.35 * h.glow) * h.alpha)
  love.graphics.rectangle("fill", ex, ey, s * 5, s * 2)

  -- muzzle flash, thrown up and to the right along the barrel
  local m = title_scene.muzzle(st)
  if m > 0 then
    local a = (MUZZLE_PX[set] or MUZZLE_PX.hero_idle)[frame] or { 27, 12 }
    local mx = x + (GUN_OX + a[1]) * s
    local my = y + (GUN_OY + a[2]) * s
    blob(mx, my, 40 * m, palette.muzzle, 0.9 * m)
    set_color(palette.muzzle, m)
    love.graphics.polygon("fill", mx, my, mx + 20 * m, my - 14 * m,
      mx + 26 * m, my - 4 * m, mx + 10 * m, my + 6 * m)
    set_color(palette.bone, m)
    love.graphics.polygon("fill", mx + 2, my, mx + 12 * m, my - 7 * m,
      mx + 14 * m, my - 1 * m, mx + 5 * m, my + 3 * m)
  end
end

-- ---------------------------------------------------------------------------
-- Logo
-- ---------------------------------------------------------------------------

-- The words are real sprites now, baked from the glyph font in
-- assets/sprites/logo.lua, so all this does is place them and hang the
-- animated ooze off the bottom of ZOMBIES.
local function logo_word(key, x, y, alpha, shadow)
  local img = sprite_atlas.image()
  local q = img and sprite_atlas.quad(key, 1)
  if not q then
    return 0, 0
  end
  local w, h = sprite_atlas.frame_size(key, 1)
  if shadow then
    love.graphics.setColor(palette.shadow[1], palette.shadow[2], palette.shadow[3],
      0.7 * alpha)
    love.graphics.draw(img, q, x + 5, y + 6, 0, LOGO_SCALE, LOGO_SCALE)
  end
  love.graphics.setColor(1, 1, 1, alpha)
  love.graphics.draw(img, q, x, y, 0, LOGO_SCALE, LOGO_SCALE)
  return w * LOGO_SCALE, h * LOGO_SCALE
end

local function draw_drips(st, x, w, y, alpha)
  for _, d in ipairs(st.drips) do
    local dx = math.floor(x + d.offset * w)
    set_color(palette.rot_dark, alpha)
    love.graphics.rectangle("fill", dx, y, 3, d.len)
    set_color(palette.rot, alpha)
    love.graphics.rectangle("fill", dx, y + d.len - 2, 3, 2)
  end
end

-- A torn red slash behind ZOMBIES, the way a poster gets a banner ripped
-- across it. Drawn under the word so the letters sit on top of the tear.
local function draw_slash(x, y, w, alpha)
  set_color(palette.blood_dark, 0.9 * alpha)
  love.graphics.polygon("fill", x - 14, y + 30, x + 8, y - 6, x + w + 18, y - 2,
    x + w - 2, y + 34)
  set_color(palette.blood, 0.85 * alpha)
  love.graphics.polygon("fill", x - 10, y + 26, x + 10, y - 2, x + w + 12, y + 2,
    x + w - 6, y + 30)
end

local function draw_vs(cx, cy, scale, alpha)
  if alpha <= 0 then
    return
  end
  local img = sprite_atlas.image()
  local q = img and sprite_atlas.quad("logo_vs", 1)
  love.graphics.push()
  love.graphics.translate(cx, cy)
  love.graphics.scale(scale, scale)
  -- a jagged shard rather than a tidy badge
  set_color(palette.outline, alpha)
  love.graphics.polygon("fill", -30, -2, -12, -19, 6, -14, 30, -18, 22, 1,
    32, 16, 8, 13, -10, 20, -14, 5)
  set_color(palette.blood, alpha)
  love.graphics.polygon("fill", -26, -2, -10, -16, 6, -11, 26, -15, 19, 1,
    27, 13, 7, 10, -9, 16, -12, 4)
  if q then
    local w, h = sprite_atlas.frame_size("logo_vs", 1)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(img, q, -w * 0.5, -h * 0.5)
  end
  love.graphics.pop()
end

function title_art.logo(st)
  local l = title_scene.logo(st)

  local zx = ZOMBIES_X + l.zombies_dx
  local zy = ZOMBIES_Y + l.zombies_dy
  local zw = sprite_atlas.frame_size("logo_zombies", 1) or 0
  draw_slash(zx, zy, zw * LOGO_SCALE, l.alpha)

  logo_word("logo_cowboy", COWBOY_X + l.cowboy_dx, COWBOY_Y + l.cowboy_dy,
    l.alpha, true)
  local zpw, zph = logo_word("logo_zombies", zx, zy, l.alpha, true)
  draw_drips(st, zx, zpw, zy + zph - 2, l.alpha * l.vs_alpha)

  draw_vs(VS_X, VS_Y, l.vs_scale, l.vs_alpha)
end

-- ---------------------------------------------------------------------------
-- Menu
-- ---------------------------------------------------------------------------

-- The stripe field the menu block sits on, scrolling slowly sideways.
function title_art.slant(st, alpha)
  if not slant or alpha <= 0 then
    return
  end
  local off = -(st.t * 7) % VW
  love.graphics.setColor(1, 1, 1, alpha)
  love.graphics.draw(slant, math.floor(off) - VW, 0)
end

function title_art.menu(m, st, alpha)
  if alpha <= 0 then
    return
  end
  ui.slant_menu(m, MENU_X, MENU_Y, {
    w = MENU_OPTS.w, h = MENU_OPTS.h, step = MENU_OPTS.step,
    skew = MENU_OPTS.skew, size = MENU_OPTS.size,
    alpha = alpha, anim = title_scene.menu_items(st, #m.items),
  })
end

function title_art.footer(best, version, alpha)
  if best and best > 0 then
    local f = ui.font(10)
    love.graphics.setFont(f)
    local text = "BEST  " .. best
    local x = math.floor(MENU_X + MENU_OPTS.w * 0.5 - f:getWidth(text) * 0.5)
    set_color(palette.shadow, alpha)
    love.graphics.print(text, x + 1, 251)
    set_color(palette.bone, 0.85 * alpha)
    love.graphics.print(text, x, 250)
  end
  ui.hud_text(version, 5, VH - 14)
  ui.hud_text_right("ARROWS  ENTER", VW - 5, VH - 14)
end

function title_art.vignette()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(vig, 0, 0)
end

-- ---------------------------------------------------------------------------
-- How-to-play overlay
-- ---------------------------------------------------------------------------

local HELP_ROWS = {
  { "MOVE", "W A S D" },
  { "AIM", "AUTOMATIC" },
  { "SHOOT", "AUTOMATIC" },
  { "PAUSE", "ESC" },
}

function title_art.help()
  love.graphics.setColor(0, 0, 0, 0.78)
  love.graphics.rectangle("fill", 0, 0, VW, VH)

  local pw, ph = 320, 164
  local px = math.floor((VW - pw) * 0.5)
  local py = math.floor((VH - ph) * 0.5)

  set_color(palette.outline)
  love.graphics.rectangle("fill", px - 2, py - 2, pw + 4, ph + 4)
  set_color(palette.panel)
  love.graphics.rectangle("fill", px, py, pw, ph)
  set_color(palette.leather)
  love.graphics.rectangle("fill", px + 4, py + 4, pw - 8, 1)
  love.graphics.rectangle("fill", px + 4, py + ph - 5, pw - 8, 1)

  ui.title("HOW TO PLAY", VW * 0.5, py + 16, 12)

  local f = ui.font(10)
  love.graphics.setFont(f)
  for i, row in ipairs(HELP_ROWS) do
    local y = py + 48 + (i - 1) * 18
    set_color(palette.muted)
    love.graphics.print(row[1], px + 26, y)
    set_color(palette.bone)
    love.graphics.print(row[2], px + pw - 26 - f:getWidth(row[2]), y)
  end

  ui.hud_text_centered("SURVIVE THE WAVES", VW * 0.5, py + ph - 34)
  ui.hud_text_centered("ESC  BACK", VW * 0.5, py + ph - 20)
end

return title_art
