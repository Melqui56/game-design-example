-- pixel.lua — pure-Lua helpers for procedural pixel-art shading.
--
-- Used by the sprite build tool (gen_sprites) to give each material a
-- 5-step light ramp with hue-shift, and to shade pixels from a top-left
-- light direction. No love.* — usable from busted specs too.

local pixel = {}

-- ---------------------------------------------------------------------------
-- Color space: RGB (0..1) <-> HSL
-- ---------------------------------------------------------------------------

function pixel.rgb_to_hsl(r, g, b)
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local l = (max + min) / 2
  local h, s = 0, 0
  if max ~= min then
    local d = max - min
    s = l > 0.5 and d / (2 - max - min) or d / (max + min)
    if max == r then
      h = ((g - b) / d + (g < b and 6 or 0)) / 6
    elseif max == g then
      h = ((b - r) / d + 2) / 6
    else
      h = ((r - g) / d + 4) / 6
    end
  end
  return h, s, l
end

local function hue_to_rgb(p, q, t)
  if t < 0 then t = t + 1 end
  if t > 1 then t = t - 1 end
  if t < 1 / 6 then return p + (q - p) * 6 * t end
  if t < 1 / 2 then return q end
  if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
  return p
end

function pixel.hsl_to_rgb(h, s, l)
  if s == 0 then
    return l, l, l
  end
  local q = l < 0.5 and l * (1 + s) or l + s - l * s
  local p = 2 * l - q
  return hue_to_rgb(p, q, h + 1 / 3), hue_to_rgb(p, q, h), hue_to_rgb(p, q, h - 1 / 3)
end

-- ---------------------------------------------------------------------------
-- 5-step material ramp with hue-shift (deep shadow -> bright highlight)
-- ---------------------------------------------------------------------------

-- Hue-shift per step: shadows shift cool (blue/purple), highlights warm.
local RAMP_STEPS = {
  { dh = -0.028, ds = -0.10, dl = -0.34 },  -- 1 deep shadow
  { dh = -0.014, ds = -0.05, dl = -0.16 },  -- 2 shadow
  { dh =  0.000, ds =  0.00, dl =  0.00 },  -- 3 base
  { dh =  0.014, ds = -0.04, dl =  0.14 },  -- 4 highlight
  { dh =  0.028, ds = -0.08, dl =  0.30 },  -- 5 bright highlight
}

-- Returns a 5-color ramp (index 1..5) for a base {r,g,b} color.
function pixel.make_ramp(base)
  local h, s, l = pixel.rgb_to_hsl(base[1], base[2], base[3])
  local ramp = {}
  for i = 1, 5 do
    local st = RAMP_STEPS[i]
    local nh = (h + st.dh) % 1
    local ns = math.max(0, math.min(1, s + st.ds))
    local nl = math.max(0, math.min(1, l + st.dl))
    ramp[i] = { pixel.hsl_to_rgb(nh, ns, nl) }
  end
  return ramp
end

-- ---------------------------------------------------------------------------
-- Top-left directional shading: pick a ramp step for pixel (x,y) in w x h
-- ---------------------------------------------------------------------------

-- Light comes from the top-left corner. Returns ramp index 1..5.
function pixel.shade_step(w, h, x, y)
  local fx = (w <= 1) and 0.5 or ((x - 1) / (w - 1))
  local fy = (h <= 1) and 0.5 or ((y - 1) / (h - 1))
  -- combined distance from top-left, weighted so vertical dominates
  local t = (1 - fy) * 0.65 + (1 - fx) * 0.35
  local step = math.floor(t * 4) + 1
  return math.max(1, math.min(5, step))
end

-- ---------------------------------------------------------------------------
-- Bevel shading: emboss a shape from its own edges
-- ---------------------------------------------------------------------------

-- Unlike shade_step, which only knows the bounding box, this looks at the four
-- neighbours of a pixel: edges facing the top-left light get the bright end of
-- the ramp, edges facing away get the dark end, the interior stays at base.
-- That turns a flat one-colour glyph map into a chiselled arcade logo without
-- authoring the highlights by hand. `rows` is the ASCII map, "." = empty.
function pixel.bevel_step(rows, x, y)
  local function solid(px, py)
    local line = rows[py]
    if not line or px < 1 or px > #line then
      return false
    end
    return line:sub(px, px) ~= "."
  end

  local up, left = solid(x, y - 1), solid(x - 1, y)
  if not up and not left then
    return 5
  elseif not up or not left then
    return 4
  end

  local down, right = solid(x, y + 1), solid(x + 1, y)
  if not down and not right then
    return 1
  elseif not down or not right then
    return 2
  end

  return 3
end

return pixel