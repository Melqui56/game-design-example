local particles = {}

function particles.new()
  return { list = {} }
end

function particles.burst(self, x, y, opts, rng)
  local o = opts or {}
  local r = rng or math.random
  local count = o.count or 8
  local life  = o.life or 0.35
  local min_speed = o.speed_min or 30
  local max_speed = o.speed_max or 90
  for _ = 1, count do
    local ang = (r(1000) / 1000) * math.pi * 2
    local spd = min_speed + (r(1000) / 1000) * (max_speed - min_speed)
    table.insert(self.list, {
      x = x,
      y = y,
      vx = math.cos(ang) * spd,
      vy = math.sin(ang) * spd,
      life    = life,
      max_life = life,
      size    = o.size or 2,
    })
  end
  return self
end

function particles.update(self, dt)
  local i = #self.list
  while i >= 1 do
    local p = self.list[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    if p.life <= 0 then
      table.remove(self.list, i)
    end
    i = i - 1
  end
  return self
end

return particles