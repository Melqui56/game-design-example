local menu = {}

function menu.new(items)
  if type(items) ~= "table" or #items == 0 then
    error("menu requires a non-empty array of items")
  end
  return {
    items  = items,
    cursor = 1,
  }
end

function menu.move(self, delta)
  local n = #self.items
  self.cursor = ((self.cursor - 1 + delta) % n) + 1
  return self.cursor
end

function menu.current(self)
  return self.items[self.cursor]
end

return menu