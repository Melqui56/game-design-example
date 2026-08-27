local pickup = {}

function pickup.new(def, x, y)
  return {
    def      = def,
    position = { x = x, y = y },
    age      = 0,
    ttl      = 12,
    radius   = 8,
    dead     = false,
  }
end

function pickup.update(self, dt)
  self.age = self.age + dt
  if self.age >= self.ttl then
    self.dead = true
  end
  return self
end

function pickup.touches(self, other)
  local dx = self.position.x - other.position.x
  local dy = self.position.y - other.position.y
  local rr = self.radius + other.radius
  return dx * dx + dy * dy <= rr * rr
end

return pickup