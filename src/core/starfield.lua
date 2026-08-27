local starfield = {}

function starfield.new(count, rng)
  local pick = rng or math.random
  local stars = {}
  for i = 1, count do
    stars[i] = {
      x     = pick(1000) / 1000,
      y     = pick(1000) / 1000,
      speed = 0.02 + (pick(10) / 10) * 0.06,
      size  = pick(2) + 1,
    }
  end
  return { stars = stars }
end

function starfield.update(self, dt)
  for _, s in ipairs(self.stars) do
    s.y = s.y + s.speed * dt
    if s.y > 1 then
      s.y = (s.y - 1) % 1
    end
  end
  return self
end

return starfield