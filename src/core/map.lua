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

return map