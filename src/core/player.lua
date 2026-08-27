local vec2 = require("src.core.vec2")

local player = {}

local DEFAULTS = {
  size  = 24,
  speed = 260,
  hp    = 3,
}

function player.new(opts)
  local o = opts or {}
  local size = o.size or DEFAULTS.size
  return {
    position = vec2.new(o.x or 0, o.y or 0),
    size     = size,
    radius   = size * 0.5,
    speed    = o.speed or DEFAULTS.speed,
    hp       = o.hp or DEFAULTS.hp,
  }
end

function player.update(self, input, dt, bounds)
  local dir = vec2.new(0, 0)
  if input.up    then dir.y = dir.y - 1 end
  if input.down  then dir.y = dir.y + 1 end
  if input.left  then dir.x = dir.x - 1 end
  if input.right then dir.x = dir.x + 1 end

  dir = vec2.normalize(dir)

  self.position.x = self.position.x + dir.x * self.speed * dt
  self.position.y = self.position.y + dir.y * self.speed * dt

  if bounds then
    local hw = self.size * 0.5
    self.position.x = math.min(math.max(self.position.x, bounds.minX + hw), bounds.maxX - hw)
    self.position.y = math.min(math.max(self.position.y, bounds.minY + hw), bounds.maxY - hw)
  end

  return self
end

function player.take_damage(self, amount)
  self.hp = self.hp - (amount or 1)
  return self.hp <= 0
end

return player