-- Cursor state shared by every menu in the game.
--
-- `pop` is the punch the selected plate gets each time the cursor moves: set
-- to 1 by `move`, decayed by `update`. Drawing code reads it to jitter and
-- overshoot the highlight, which is what makes the slanted plates in
-- src/fw/ui.lua feel kinetic instead of static.

local menu = {}

local POP_DECAY = 6

function menu.new(items)
  if type(items) ~= "table" or #items == 0 then
    error("menu requires a non-empty array of items")
  end
  return {
    items  = items,
    cursor = 1,
    pop    = 0,
  }
end

function menu.move(self, delta)
  local n = #self.items
  self.cursor = ((self.cursor - 1 + delta) % n) + 1
  self.pop = 1
  return self.cursor
end

function menu.update(self, dt)
  if self.pop and self.pop > 0 then
    self.pop = math.max(0, self.pop - dt * POP_DECAY)
  end
  return self.pop or 0
end

function menu.current(self)
  return self.items[self.cursor]
end

return menu