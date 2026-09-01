-- gen_sprites.lua — standalone LÖVE build tool.
--
-- Bakes the ASCII sprite maps in assets/sprites/*.lua into a single PNG
-- spritesheet plus a Lua atlas (frame -> rect in the sheet), written into the
-- repo so the game can load them with love.graphics.newImage.
--
-- Run from the repo root:
--   love scripts/gen_sprites
--
-- The generated files are:
--   assets/sprites/sheet.png
--   assets/sprites/atlas.lua
--
-- Sprites stay authored as ASCII (data-as-code); this tool is the only place
-- that turns them into binary assets.

local lovefs = love.filesystem

-- ---------------------------------------------------------------------------
-- Repo root: the parent of scripts/gen_sprites
-- ---------------------------------------------------------------------------

local REPO = love.filesystem.getSource()
-- scripts/gen_sprites -> repo root
REPO = REPO:gsub("/scripts/gen_sprites$", "")
if REPO == "" then
  REPO = "."
end

-- ---------------------------------------------------------------------------
-- Load sprite data from the repo
-- ---------------------------------------------------------------------------

local function load_data(rel)
  local chunk = loadfile(REPO .. "/" .. rel)
  if not chunk then
    error("cannot load sprite data: " .. REPO .. "/" .. rel)
  end
  return chunk()
end

local palette  = load_data("src/core/palette.lua")
local cowboy   = load_data("assets/sprites/cowboy.lua")
local hero     = load_data("assets/sprites/hero.lua")
local zombie   = load_data("assets/sprites/zombie.lua")
local props    = load_data("assets/sprites/props.lua")
local pixel    = load_data("scripts/pixel.lua")

-- ---------------------------------------------------------------------------
-- Bakers: ASCII rows -> array of {r,g,b,a} (0..1 floats)
-- ---------------------------------------------------------------------------

local OUTLINE_DIRS = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

local function pixel_at(rows, x, y)
  if y < 1 or y > #rows then return nil end
  local line = rows[y]
  if x < 1 or x > #line then return nil end
  local ch = line:sub(x, x)
  if ch == "." then return nil end
  return ch
end

-- rows: array of strings; colormap: char -> palette key (string)
-- flat: when true, every pixel uses the key's base color (ramp step 3) instead
-- of the top-left directional gradient. Used by sprites whose shading is
-- authored by hand through explicit light/dark keys (see hero.lua).
local function bake(rows, colormap, flat)
  local h = #rows
  local w = #rows[1]
  for _, line in ipairs(rows) do
    assert(#line == w, "rows must be same width")
  end

  local px = {}
  for i = 1, w * h do px[i] = { 0, 0, 0, 0 } end

  local ramps = {}
  local function ramp_for(key)
    local r = ramps[key]
    if not r then
      r = pixel.make_ramp(palette[key])
      ramps[key] = r
    end
    return r
  end

  local function set(x, y, color, a)
    if x < 1 or x > w or y < 1 or y > h then
      return
    end
    local i = (y - 1) * w + x
    px[i] = { color[1], color[2], color[3], a or 1 }
  end

  -- fill main pixels with directional shading (top-left light)
  for y = 1, h do
    local line = rows[y]
    for x = 1, #line do
      local ch = line:sub(x, x)
      local key = colormap[ch]
      if key then
        local ramp = ramp_for(key)
        local step = flat and 3 or pixel.shade_step(w, h, x, y)
        set(x, y, ramp[step])
      end
    end
  end

  -- outline pass: dark pixel on the outside of any filled pixel
  for y = 1, h do
    for x = 1, #rows[y] do
      if pixel_at(rows, x, y) ~= nil then
        for _, d in ipairs(OUTLINE_DIRS) do
          if pixel_at(rows, x + d[1], y + d[2]) == nil then
            set(x + d[1], y + d[2], palette.outline)
          end
        end
      end
    end
  end

  return w, h, px
end

-- ---------------------------------------------------------------------------
-- Spritesheet packing: place each frame in a grid (power-of-two width)
-- ---------------------------------------------------------------------------

local GAP = 1
local SHEET_W = 256

local function packer()
  local x, y = GAP, GAP
  local row_h = 0
  local max_h = 0
  return function(w, h)
    if x + w + GAP > SHEET_W then
      x = GAP
      y = y + row_h + GAP
      row_h = 0
    end
    local px, py = x, y
    x = x + w + GAP
    row_h = math.max(row_h, h)
    max_h = math.max(max_h, py + h + GAP)
    return px, py, SHEET_W, max_h
  end
end

-- ---------------------------------------------------------------------------
-- Assemble the sheet
-- ---------------------------------------------------------------------------

local function build_sheet()
  local place = packer()
  local frames = {}   -- ordered list: { key, w, h, px, x, y }
  local atlas = {}    -- key -> array of rects

  local function add_set(name, sprite, is_flash)
    local flat = sprite.shade == "flat"
    for set_name, set in pairs(sprite.sets) do
      local key = name .. "_" .. set_name .. (is_flash and "_flash" or "")
      atlas[key] = atlas[key] or {}
      for _, rows in ipairs(set.frames) do
        local w, h, px = bake(rows, sprite.palette, flat)
        local x, y = place(w, h)
        table.insert(frames, { key = key, w = w, h = h, px = px, x = x, y = y })
        table.insert(atlas[key], { x = x, y = y, w = w, h = h })
      end
    end
  end

  local function add_prop(name, prop)
    local w, h, px = bake(prop.rows, { X = prop.color })
    local x, y = place(w, h)
    local key = "prop_" .. name
    table.insert(frames, { key = key, w = w, h = h, px = px, x = x, y = y })
    atlas[key] = { { x = x, y = y, w = w, h = h } }
  end

  add_set("hero", hero, false)
  add_set("cowboy", cowboy, false)
  add_set("cowboy", cowboy, true)
  add_set("zombie", zombie, false)
  add_set("zombie", zombie, true)
  for name, prop in pairs(props) do
    add_prop(name, prop)
  end

  -- discover final sheet height
  local sheet_h = 1
  for _, f in ipairs(frames) do
    sheet_h = math.max(sheet_h, f.y + f.h + GAP)
  end

  local data = love.image.newImageData(SHEET_W, sheet_h, "rgba8")
  for _, f in ipairs(frames) do
    for i = 1, f.w * f.h do
      local c = f.px[i]
      local col = (i - 1) % f.w
      local row = math.floor((i - 1) / f.w)
      data:setPixel(f.x + col, f.y + row, c[1], c[2], c[3], c[4])
    end
  end

  return data, atlas
end

-- ---------------------------------------------------------------------------
-- Write outputs into the repo
-- ---------------------------------------------------------------------------

local function write_file(rel, filedata)
  local path = REPO .. "/" .. rel
  local f = io.open(path, "wb")
  if not f then
    error("cannot write " .. path)
  end
  f:write(filedata:getString())
  f:close()
  print("wrote " .. rel .. " (" .. #filedata:getString() .. " bytes)")
end

local function write_atlas(atlas)
  local parts = { "return {" }
  local keys = {}
  for k in pairs(atlas) do table.insert(keys, k) end
  table.sort(keys)
  for _, k in ipairs(keys) do
    local rects = atlas[k]
    table.insert(parts, "  [" .. string.format("%q", k) .. "] = {")
    for _, r in ipairs(rects) do
      table.insert(parts, string.format(
        "    { x = %d, y = %d, w = %d, h = %d },",
        r.x, r.y, r.w, r.h))
    end
    table.insert(parts, "  },")
  end
  table.insert(parts, "}")
  local path = REPO .. "/assets/sprites/atlas.lua"
  local f = io.open(path, "wb")
  if not f then
    error("cannot write " .. path)
  end
  f:write(table.concat(parts, "\n") .. "\n")
  f:close()
  print("wrote assets/sprites/atlas.lua")
end

function love.load()
  print("gen_sprites: baking spritesheet ...")
  local ok, err = pcall(function()
    local data, atlas = build_sheet()
    write_file("assets/sprites/sheet.png", data:encode("png"))
    write_atlas(atlas)
  end)
  if not ok then
    print("ERROR: " .. tostring(err))
  end
  print("done.")
  love.event.quit()
end

function love.draw()
end