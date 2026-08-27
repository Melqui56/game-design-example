local vec2 = require("src.core.vec2")

local enemy = {}

enemy.TYPES = {
  chaser = { speed = 90, hp = 1, radius = 14 },
}

function enemy.new(kind, x, y, opts)
  local t = enemy.TYPES[kind or "chaser"]
  if not t then
    error("unknown enemy kind: " .. tostring(kind))
  end
  local o = opts or {}
  return {
    kind     = kind or "chaser",
    position = { x = x, y = y },
    speed    = o.speed or t.speed,
    hp       = o.hp or t.hp,
    radius   = o.radius or t.radius,
  }
end

function enemy.update(self, target, dt)
  local delta = vec2.sub(target, self.position)
  local dist  = vec2.length(delta)
  local step  = self.speed * dt
  if step >= dist then
    self.position.x = target.x
    self.position.y = target.y
    return self
  end
  local move = vec2.scale(vec2.normalize(delta), step)
  self.position = vec2.add(self.position, move)
  return self
end

function enemy.take_damage(self, amount)
  self.hp = self.hp - (amount or 1)
  return self.hp <= 0
end

function enemy.touches(self, other)
  local dx = self.position.x - other.position.x
  local dy = self.position.y - other.position.y
  local rr = self.radius + other.radius
  return dx * dx + dy * dy <= rr * rr
end

return enemy