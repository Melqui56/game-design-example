local waves = {}

local SPAWN_INTERVAL = 1.0
local EDGE_MARGIN   = 32

local function pick(rng, n)
  return (rng or math.random)(n)
end

local function random_point(area, rng)
  local maxX = area.maxX
  local maxY = area.maxY
  local side = pick(rng, 4)
  local x, y
  if side == 1 then
    x = area.minX + pick(rng, maxX - area.minX + 1)
    y = area.minY - EDGE_MARGIN
  elseif side == 2 then
    x = area.minX + pick(rng, maxX - area.minX + 1)
    y = maxY + EDGE_MARGIN
  elseif side == 3 then
    x = area.minX - EDGE_MARGIN
    y = area.minY + pick(rng, maxY - area.minY + 1)
  else
    x = maxX + EDGE_MARGIN
    y = area.minY + pick(rng, maxY - area.minY + 1)
  end
  return x, y
end

local function pick_kind(wave_number, rng)
  local r = rng or math.random
  if wave_number >= 4 and r(100) <= 25 then
    return "tank"
  end
  if wave_number >= 2 and r(100) <= 30 then
    return "runner"
  end
  return "chaser"
end

function waves.plan(wave_number, area, rng)
  area = area or { minX = 0, minY = 0, maxX = 960, maxY = 540 }
  local count = 3 + (wave_number - 1)
  local events = {}
  for i = 1, count do
    local x, y = random_point(area, rng)
    table.insert(events, {
      time = (i - 1) * SPAWN_INTERVAL,
      kind = pick_kind(wave_number, rng),
      x    = x,
      y    = y,
    })
  end
  return events
end

return waves