local vec2 = require("src.core.vec2")

local bullet = {}

function bullet.new(x, y, dir, opts)
  local o = opts or {}
  return {
    position = vec2.new(x, y),
    dir      = vec2.normalize(dir or { x = 0, y = -1 }),
    speed    = o.speed or 260,
    radius   = o.radius or 2,
    damage   = o.damage or 1,
    dead     = false,
  }
end

function bullet.update(self, dt, bounds)
  self.position = vec2.add(self.position, vec2.scale(self.dir, self.speed * dt))
  if bounds then
    if self.position.x < bounds.minX or self.position.x > bounds.maxX
      or self.position.y < bounds.minY or self.position.y > bounds.maxY then
      self.dead = true
    end
  end
  return self
end

function bullet.touches(self, other)
  local dx = self.position.x - other.position.x
  local dy = self.position.y - other.position.y
  local rr = self.radius + other.radius
  return dx * dx + dy * dy <= rr * rr
end

return bullet