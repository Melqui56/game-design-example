local map = {}

local KINDS = { "cactus", "rock", "skull", "bush" }

function map.decorate(area, count, rng)
  local r = rng or math.random
  local props = {}
  for _ = 1, count do
    local x = area.minX + 10 + r(area.maxX - area.minX - 20)
    local y = area.minY + 10 + r(area.maxY - area.minY - 20)
    table.insert(props, {
      x    = x,
      y    = y,
      kind = KINDS[r(#KINDS)],
    })
  end
  return props
end

function map.town(area, count, rng)
  local r = rng or math.random
  local buildings = {}
  local w = area.maxX - area.minX
  local h = area.maxY - area.minY
  for _ = 1, count do
    local edge = r(4)
    local bw = 28 + r(14)
    local bh = 26 + r(10)
    local x, y
    if edge == 1 then
      x = area.minX + 20 + r(w - 40)
      y = area.minY + 18 + r(30)
    elseif edge == 2 then
      x = area.minX + 20 + r(w - 40)
      y = area.maxY - 18 - r(30)
    elseif edge == 3 then
      x = area.minX + 18 + r(30)
      y = area.minY + 20 + r(h - 40)
    else
      x = area.maxX - 18 - r(30)
      y = area.minY + 20 + r(h - 40)
    end
    table.insert(buildings, { x = x, y = y, w = bw, h = bh })
  end
  return buildings
end

return map