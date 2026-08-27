local scene_manager = {}

function scene_manager.new()
  return setmetatable({
    scenes  = {},
    current = nil,
  }, { __index = scene_manager })
end

function scene_manager.add(self, name, scene)
  self.scenes[name] = scene
end

function scene_manager.switch(self, name, ...)
  local next_scene = self.scenes[name]
  if not next_scene then
    error("scene not registered: " .. tostring(name))
  end
  if self.current and self.current.exit then
    self.current.exit(self.current)
  end
  self.current = next_scene
  if self.current.enter then
    self.current.enter(self.current, ...)
  end
end

function scene_manager.update(self, dt)
  if self.current and self.current.update then
    self.current.update(self.current, dt)
  end
end

function scene_manager.draw(self)
  if self.current and self.current.draw then
    self.current.draw(self.current)
  end
end

function scene_manager.keypressed(self, key)
  if self.current and self.current.keypressed then
    self.current.keypressed(self.current, key)
  end
end

return scene_manager