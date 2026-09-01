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
local sprite_atlas = require("src.fw.sprite_atlas")
local title_scene  = require("src.core.title_scene")
local ui           = require("src.fw.ui")

local title_art = {}

local VW, VH     = 480, 270
local HORIZON    = 152
local HERO_X     = 106
local HERO_FEET  = 250
local HERO_SCALE = 3
local MENU_X     = 344
local MENU_Y     = 166
local MENU_STEP  = 22

local LOGO_CX      = 240
local LOGO_SIZE    = 24
local COWBOY_Y     = 20
local ZOMBIES_Y    = 58
local LOGO_OUTLINE = 2

local bg, glow, vig = nil, nil, nil

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

-- Must run outside a bound canvas (app.load), never mid-frame.
function title_art.preload()
  sprite_atlas.load()
  bg = bg or build_background()
  glow = glow or build_glow()
  vig = vig or build_vignette()
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

-- Where the eyes sit inside the hero frames (sprite pixels, 1-based row).
local EYE_ROW = { hero_idle = { 11, 12 }, hero_draw = { 11, 11 } }
local EYE_X   = { 13, 17 }
-- Barrel tip row while the revolver is up (per hero_draw frame).
local BARREL_ROW = { 20, 19 }

function title_art.hero(st)
  local img = sprite_atlas.image()
  if not img then
    return
  end
  local set, frame = title_scene.hero_frame(st)
  local h = title_scene.hero(st)
  local q = sprite_atlas.quad(set, frame)
  if not q then
    return
  end
  local fw, fh = sprite_atlas.frame_size(set, frame)
  local x = math.floor(HERO_X - fw * HERO_SCALE * 0.5)
  local y = math.floor(HERO_FEET - fh * HERO_SCALE + h.dy)

  -- moonlit backlight and a soft ground shadow
  blob(HERO_X, HERO_FEET - 58, 74, palette.sky_ember, 0.20 * h.alpha)
  love.graphics.setColor(0, 0, 0, 0.42 * h.alpha)
  love.graphics.ellipse("fill", HERO_X, HERO_FEET - 4, 32, 7)

  love.graphics.setColor(1, 1, 1, h.alpha)
  love.graphics.draw(img, q, x, y, 0, HERO_SCALE, HERO_SCALE)

  -- eyes burning under the hat brim
  local row = (EYE_ROW[set] or EYE_ROW.hero_idle)[frame] or 11
  local ey = y + (row - 1) * HERO_SCALE
  for _, ex in ipairs(EYE_X) do
    local px = x + (ex - 1) * HERO_SCALE
    blob(px + HERO_SCALE, ey + HERO_SCALE * 0.5, 9, palette.eye_glow, 0.45 * h.glow * h.alpha)
    set_color(palette.eye_glow, (0.65 + 0.35 * h.glow) * h.alpha)
    love.graphics.rectangle("fill", px, ey, HERO_SCALE * 2, HERO_SCALE)
  end

  -- muzzle flash
  local m = title_scene.muzzle(st)
  if m > 0 then
    local by = y + (BARREL_ROW[frame] or 20) * HERO_SCALE
    blob(x - 2, by, 34 * m, palette.muzzle, 0.85 * m)
    set_color(palette.muzzle, m)
    love.graphics.rectangle("fill", x - 10, by - 2, 12, 4)
    love.graphics.rectangle("fill", x - 16, by - 1, 8, 2)
    set_color(palette.bone, m)
    love.graphics.rectangle("fill", x - 7, by - 1, 6, 2)
  end
end

-- ---------------------------------------------------------------------------
-- Logo
-- ---------------------------------------------------------------------------

local OUTLINE_OFFSETS = {
  { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 },
  { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 },
}

-- A chunky arcade word: hard outline, drop shadow, lighter top half.
-- The two-tone look is done by drawing the word once, then re-drawing only the
-- top half through a scissor-free overlay trick is unreliable with some
-- backends, so we use a full draw + a translucent band instead.
local function word(text, cx, y, size, top, bottom, alpha)
  local f = ui.font(size)
  love.graphics.setFont(f)
  local w = f:getWidth(text)
  local h = f:getHeight()
  local x = math.floor(cx - w * 0.5)

  set_color(palette.shadow, 0.65 * alpha)
  love.graphics.print(text, x + 3, y + 4)

  set_color(palette.outline, alpha)
  for _, o in ipairs(OUTLINE_OFFSETS) do
    love.graphics.print(text, x + o[1] * LOGO_OUTLINE, y + o[2] * LOGO_OUTLINE)
  end

  -- body in the base colour, then a translucent dark band over the bottom
  -- half to fake the two-tone depth without scissor clipping.
  set_color(bottom, alpha)
  love.graphics.print(text, x, y)
  local half = math.floor(h * 0.46)
  love.graphics.setColor(bottom[1] * 0.55, bottom[2] * 0.55, bottom[3] * 0.55, alpha * 0.85)
  love.graphics.rectangle("fill", x, y + half, w, h - half)
  set_color(top, alpha)
  love.graphics.print(text, x, y)

  return x, w, h
end

local function draw_drips(st, x, w, y, alpha)
  for _, d in ipairs(st.drips) do
    local dx = math.floor(x + d.offset * w)
    set_color(palette.rot_dark, alpha)
    love.graphics.rectangle("fill", dx, y, 2, d.len)
    set_color(palette.rot, alpha)
    love.graphics.rectangle("fill", dx, y + d.len - 2, 2, 2)
  end
end

local function draw_vs(cx, cy, scale, alpha)
  if alpha <= 0 then
    return
  end
  local f = ui.font(10)
  love.graphics.setFont(f)
  local tw = f:getWidth("VS")
  local th = f:getHeight()
  love.graphics.push()
  love.graphics.translate(cx, cy)
  love.graphics.scale(scale, scale)
  set_color(palette.outline, alpha)
  love.graphics.rectangle("fill", -21, -10, 42, 20)
  set_color(palette.blood_dark, alpha)
  love.graphics.rectangle("fill", -19, -8, 38, 16)
  set_color(palette.blood, alpha)
  love.graphics.rectangle("fill", -19, -8, 38, 12)
  set_color(palette.outline, alpha * 0.8)
  love.graphics.rectangle("fill", -16, -6, 2, 2)
  love.graphics.rectangle("fill", 14, 2, 2, 2)
  set_color(palette.bone, alpha)
  love.graphics.print("VS", -tw * 0.5, -th * 0.5)
  love.graphics.pop()
end

function title_art.logo(st)
  local l = title_scene.logo(st)

  word("COWBOY", LOGO_CX + l.cowboy_dx, COWBOY_Y + l.cowboy_dy, LOGO_SIZE,
    palette.gold, palette.leather, l.alpha)

  local zx, zw, zh = word("ZOMBIES", LOGO_CX + l.zombies_dx, ZOMBIES_Y + l.zombies_dy,
    LOGO_SIZE, palette.rot, palette.rot_dark, l.alpha)
  draw_drips(st, zx, zw, ZOMBIES_Y + l.zombies_dy + zh - 2, l.alpha * l.vs_alpha)

  draw_vs(LOGO_CX + 118, COWBOY_Y + 30, l.vs_scale, l.vs_alpha)

  -- hairline rule under the logo
  local a = l.vs_alpha * 0.7
  local ry = ZOMBIES_Y + zh + 12
  set_color(palette.leather, a)
  love.graphics.rectangle("fill", LOGO_CX - 104, ry, 208, 1)
  set_color(palette.gold, a)
  love.graphics.rectangle("fill", LOGO_CX - 106, ry - 2, 4, 4)
  love.graphics.rectangle("fill", LOGO_CX + 102, ry - 2, 4, 4)
end

-- ---------------------------------------------------------------------------
-- Menu
-- ---------------------------------------------------------------------------

local function bullet(x, y, alpha)
  set_color(palette.outline, alpha)
  love.graphics.rectangle("fill", x - 1, y - 1, 11, 7)
  set_color(palette.leather, alpha)
  love.graphics.rectangle("fill", x, y, 5, 5)
  set_color(palette.gold, alpha)
  love.graphics.polygon("fill", x + 5, y, x + 10, y + 2.5, x + 5, y + 5)
  set_color(palette.bone, alpha * 0.8)
  love.graphics.rectangle("fill", x + 1, y + 1, 3, 1)
end

function title_art.menu(m, st, alpha)
  if alpha <= 0 then
    return
  end
  local f = ui.font(10)
  love.graphics.setFont(f)
  local pulse = math.sin(st.t * 6) * 1.5

  for i, label in ipairs(m.items) do
    local selected = i == m.cursor
    local y = MENU_Y + (i - 1) * MENU_STEP
    local w = f:getWidth(label)
    local x = math.floor(MENU_X - w * 0.5)

    if selected then
      set_color(palette.leather_dark, 0.55 * alpha)
      love.graphics.rectangle("fill", MENU_X - 82, y - 5, 164, f:getHeight() + 9)
      set_color(palette.leather, 0.85 * alpha)
      love.graphics.rectangle("fill", MENU_X - 82, y - 5, 164, 1)
      love.graphics.rectangle("fill", MENU_X - 82, y + f:getHeight() + 3, 164, 1)
      bullet(math.floor(x - 22 + pulse), y + 2, alpha)
    end

    set_color(palette.shadow, alpha)
    love.graphics.print(label, x + 1, y + 1)
    set_color(selected and palette.gold or palette.muted, alpha)
    love.graphics.print(label, x, y)
  end
end

function title_art.footer(best, version, alpha)
  if best and best > 0 then
    local f = ui.font(10)
    love.graphics.setFont(f)
    local text = "BEST  " .. best
    local x = math.floor(MENU_X - f:getWidth(text) * 0.5)
    set_color(palette.shadow, alpha)
    love.graphics.print(text, x + 1, 239)
    set_color(palette.bone, 0.85 * alpha)
    love.graphics.print(text, x, 238)
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
