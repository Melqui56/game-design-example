local palette = require("src.core.palette")

local ui = {}

local FONT_PATH = "assets/fonts/PressStart2P.ttf"
local fonts = {}

local function font(size)
  local f = fonts[size]
  if not f then
    f = love.graphics.newFont(FONT_PATH, size)
    fonts[size] = f
  end
  return f
end

-- Public: shared font cache, so other modules draw with the same pixel font.
function ui.font(size)
  return font(size)
end

local function set_color(c, alpha)
  love.graphics.setColor(c[1], c[2], c[3], alpha or 1)
end

local function print_with_shadow(text, x, y, size, color)
  love.graphics.setFont(font(size))
  set_color(palette.shadow)
  love.graphics.print(text, x + 2, y + 2)
  set_color(color)
  love.graphics.print(text, x, y)
end

function ui.title(text, cx, y, size)
  local fs = size or 24
  love.graphics.setFont(font(fs))
  local x = cx - love.graphics.getFont():getWidth(text) * 0.5
  print_with_shadow(text, x, y, fs, palette.accent)
end

function ui.menu_items(m, cx, y, spacing, size)
  local fs = size or 12
  love.graphics.setFont(font(fs))
  local f = love.graphics.getFont()
  for i, label in ipairs(m.items) do
    local selected = i == m.cursor
    local x = cx - f:getWidth(label) * 0.5
    local ty = y + (i - 1) * spacing
    print_with_shadow(label, x, ty, fs, selected and palette.accent or palette.muted)
    if selected then
      local mid = ty + f:getHeight() * 0.5
      set_color(palette.accent)
      love.graphics.polygon("fill", x - 26, mid, x - 15, mid - 8, x - 15, mid + 8)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Slanted plate menu
-- ---------------------------------------------------------------------------

-- Every menu in the game draws through this: a stack of skewed parallelograms
-- with a hard offset drop shadow. The selected one inverts -- gold plate,
-- black label -- slides towards the reader and jitters on `m.pop`, while the
-- rest sit back in black with muted text. The skew and the inversion are the
-- whole grammar; the labels stay upright so the pixel font keeps its edges.
--
-- opts: w, h, step, skew, size, alpha, anim
--   anim is an optional array of { dx, alpha } per item (see
--   title_scene.menu_items) so the title screen can stagger them in. Pass
--   nothing and the menu simply draws in place.
local SLANT = {
  w = 190, h = 26, step = 30, skew = 10, size = 10, alpha = 1,
}

local function plate(x, y, w, h, skew)
  return { x, y + h, x + skew, y, x + skew + w, y, x + w, y + h }
end

-- The one shape the whole game is built from: a right-leaning parallelogram
-- with a hard offset shadow. Menus, HUD readouts and banners all use it, so
-- the title screen and the play scene read as the same object.
function ui.slant_panel(x, y, w, h, opts)
  opts = opts or {}
  local skew = opts.skew or 10
  local a = opts.alpha or 1
  if a <= 0 then
    return
  end
  if opts.shadow ~= false then
    set_color(palette.outline, 0.70 * a)
    love.graphics.polygon("fill", plate(x + 3, y + 4, w, h, skew))
  end
  set_color(opts.fill or palette.outline, (opts.fill_alpha or 0.78) * a)
  love.graphics.polygon("fill", plate(x, y, w, h, skew))
  if opts.rule then
    set_color(opts.rule, 0.9 * a)
    love.graphics.line(x + skew, y + 0.5, x + skew + w, y + 0.5)
    love.graphics.line(x, y + h - 0.5, x + w, y + h - 0.5)
  end
  if opts.tip then
    set_color(opts.tip, a)
    love.graphics.polygon("fill", x, y + h, x + skew, y,
      x + skew + 4, y, x + 4, y + h)
  end
end

-- A HUD readout: small muted caption over a big value, on a slanted plate.
-- `pop` (0..1) swells the value for a moment when it changes.
function ui.hud_stat(x, y, w, label, value, opts)
  opts = opts or {}
  local a = opts.alpha or 1
  local h = opts.h or 26
  local skew = opts.skew or 8
  ui.slant_panel(x, y, w, h, {
    skew = skew, alpha = a, fill = palette.outline, fill_alpha = 0.78,
    rule = palette.leather, tip = opts.tip,
  })

  local lf = font(8)
  love.graphics.setFont(lf)
  set_color(palette.muted, 0.85 * a)
  love.graphics.print(label, math.floor(x + skew + 7), math.floor(y + 5))

  local vf = font(opts.size or 10)
  love.graphics.setFont(vf)
  local vx = math.floor(x + skew + 7)
  local vy = math.floor(y + h - vf:getHeight() - 5)
  local pop = opts.pop or 0
  set_color(palette.shadow, a)
  love.graphics.print(value, vx + 1, vy + 1)
  set_color(opts.color or palette.gold, a)
  if pop > 0 then
    love.graphics.print(value, vx, vy - math.floor(pop * 2))
  else
    love.graphics.print(value, vx, vy)
  end
end

-- The full-width announcement that slides through on a new wave: black band,
-- gold rules, the text punched out in the middle. `t` is 0..1 across its life.
function ui.banner(text, vw, cx, y, t)
  if t <= 0 or t >= 1 then
    return
  end
  -- ease in from the left, hold, then fly out to the right
  local slide
  if t < 0.22 then
    local p = t / 0.22
    slide = -vw * (1 - p * p)
  elseif t > 0.78 then
    local p = (t - 0.78) / 0.22
    slide = vw * p * p
  else
    slide = 0
  end
  local alpha = t < 0.1 and t / 0.1 or (t > 0.92 and (1 - t) / 0.08 or 1)

  local f = font(16)
  love.graphics.setFont(f)
  local tw = f:getWidth(text)
  local bh = 34
  local bx = slide
  set_color(palette.outline, 0.88 * alpha)
  love.graphics.polygon("fill", bx - 20, y + bh, bx + 14, y,
    bx + vw + 40, y, bx + vw + 6, y + bh)
  set_color(palette.blood, alpha)
  love.graphics.polygon("fill", bx - 20, y + bh, bx - 12, y + bh,
    bx + 22, y, bx + 14, y)
  set_color(palette.gold, 0.9 * alpha)
  love.graphics.line(bx + 14, y + 0.5, bx + vw + 40, y + 0.5)
  love.graphics.line(bx - 20, y + bh - 0.5, bx + vw + 6, y + bh - 0.5)

  local tx = math.floor(cx + slide - tw * 0.5)
  local ty = math.floor(y + (bh - f:getHeight()) * 0.5)
  set_color(palette.shadow, alpha)
  love.graphics.print(text, tx + 2, ty + 2)
  set_color(palette.bone, alpha)
  love.graphics.print(text, tx, ty)
end

function ui.slant_menu(m, x, y, opts)
  opts = opts or {}
  local w    = opts.w or SLANT.w
  local h    = opts.h or SLANT.h
  local step = opts.step or SLANT.step
  local skew = opts.skew or SLANT.skew
  local size = opts.size or SLANT.size
  local base = opts.alpha or SLANT.alpha
  local anim = opts.anim
  local pop  = m.pop or 0

  if base <= 0 then
    return
  end

  local f = font(size)
  love.graphics.setFont(f)

  for i, label in ipairs(m.items) do
    local selected = i == m.cursor
    local a = base * (anim and anim[i] and anim[i].alpha or 1)
    if a > 0 then
      local px = x + (anim and anim[i] and anim[i].dx or 0)
      local py = y + (i - 1) * step
      -- the selected plate steps out towards the reader, the rest retreat
      px = px + (selected and -12 or 10)
      if selected and pop > 0 then
        px = px + math.sin(pop * 30) * pop * 3
      end

      if selected then
        ui.slant_panel(px, py, w, h, {
          skew = skew, alpha = a, fill = palette.gold, fill_alpha = 1,
          rule = palette.bone, tip = palette.blood,
        })
      else
        ui.slant_panel(px, py, w, h, {
          skew = skew, alpha = a, fill = palette.outline, fill_alpha = 0.72,
          rule = palette.leather,
        })
      end

      local tx = math.floor(px + skew + 20)
      local ty = math.floor(py + (h - f:getHeight()) * 0.5)
      if selected then
        set_color(palette.outline, a)
        love.graphics.print(label, tx, ty)
      else
        set_color(palette.shadow, a)
        love.graphics.print(label, tx + 1, ty + 1)
        set_color(palette.muted, a)
        love.graphics.print(label, tx, ty)
      end
    end
  end
end

-- Where the left tip of item `i` sits, so callers can point at it.
function ui.slant_tip(x, y, i, opts)
  opts = opts or {}
  local h    = opts.h or SLANT.h
  local step = opts.step or SLANT.step
  return x - 12, y + (i - 1) * step + h * 0.5
end

function ui.hud_text(text, x, y)
  love.graphics.setFont(font(10))
  set_color(palette.shadow)
  love.graphics.print(text, x + 1, y + 1)
  set_color(palette.text)
  love.graphics.print(text, x, y)
end

function ui.hud_text_right(text, x_right, y)
  love.graphics.setFont(font(10))
  local x = x_right - love.graphics.getFont():getWidth(text)
  set_color(palette.shadow)
  love.graphics.print(text, x + 1, y + 1)
  set_color(palette.text)
  love.graphics.print(text, x, y)
end

function ui.hud_text_centered(text, cx, y)
  love.graphics.setFont(font(10))
  local x = cx - love.graphics.getFont():getWidth(text) * 0.5
  set_color(palette.shadow)
  love.graphics.print(text, x + 1, y + 1)
  set_color(palette.text)
  love.graphics.print(text, x, y)
end

return ui