local shake = {}

function shake.new()
  return { trauma = 0 }
end

function shake.add(self, amount)
  self.trauma = math.min(1, self.trauma + (amount or 0))
end

function shake.update(self, dt)
  self.trauma = math.max(0, self.trauma - dt * 2.5)
end

function shake.offset(self, rng)
  local r = rng or math.random
  local m = math.floor(self.trauma * self.trauma * 6)
  if m == 0 then
    return { x = 0, y = 0 }
  end
  return { x = r(m * 2 + 1) - (m + 1), y = r(m * 2 + 1) - (m + 1) }
end

return shake