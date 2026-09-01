-- sprite_atlas.lua — loads the generated spritesheet + atlas into Images/Quads.
--
-- The sheet and atlas are produced by scripts/gen_sprites from the ASCII maps
-- in assets/sprites/*.lua. This module is the runtime bridge: it owns the
-- texture and exposes per-frame Quads indexed by "set" name.

local atlas_data = require("assets.sprites.atlas")

local sprite_atlas = {}

local image = nil
local quads = {}   -- set name -> array of Quads

function sprite_atlas.load()
  if image then
    return
  end
  image = love.graphics.newImage("assets/sprites/sheet.png")
  image:setFilter("nearest", "nearest")
  local iw, ih = image:getDimensions()
  for set_name, rects in pairs(atlas_data) do
    local list = {}
    for _, r in ipairs(rects) do
      table.insert(list, love.graphics.newQuad(r.x, r.y, r.w, r.h, iw, ih))
    end
    quads[set_name] = list
  end
end

function sprite_atlas.image()
  return image
end

-- Returns the Quad for set_name at frame index (1-based). Falls back to the
-- first frame when out of range so animations never draw nothing.
function sprite_atlas.quad(set_name, frame)
  local list = quads[set_name]
  if not list then
    return nil
  end
  return list[frame] or list[1]
end

-- Returns the width/height of a frame in a set (for centering/anchoring).
function sprite_atlas.frame_size(set_name, frame)
  local list = quads[set_name]
  if not list then
    return 0, 0
  end
  local q = list[frame] or list[1]
  local _, _, w, h = q:getViewport()
  return w, h
end

-- Returns true if the set exists (allows callers to pick defaults).
function sprite_atlas.has(set_name)
  return quads[set_name] ~= nil
end

function sprite_atlas.frame_count(set_name)
  local list = quads[set_name]
  if not list then
    return 0
  end
  return #list
end

return sprite_atlas