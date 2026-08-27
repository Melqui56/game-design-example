local fsm = {}

function fsm.new(states, initial, owner)
  assert(type(states) == "table", "fsm requires a states table")
  return {
    states  = states,
    current = initial or "idle",
    owner   = owner,
  }
end

function fsm.change(self, name)
  if self.current == name then
    return self
  end
  local state = self.states[name]
  if not state then
    error("fsm: unknown state: " .. tostring(name))
  end
  local old = self.states[self.current]
  if old and old.exit then
    old.exit(self.owner)
  end
  self.current = name
  if state.enter then
    state.enter(self.owner)
  end
  return self
end

function fsm.update(self, dt)
  local state = self.states[self.current]
  if state and state.update then
    state.update(self.owner, dt)
  end
  return self
end

return fsm