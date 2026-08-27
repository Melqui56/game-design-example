local camera = {}

function camera.new(world_w, world_h, view_w, view_h)
  return {
    world_w = world_w,
    world_h = world_h,
    view_w  = view_w,
    view_h  = view_h,
    x       = 0,
    y       = 0,
  }
end

function camera.follow(self, target)
  local cx = target.x - self.view_w * 0.5
  local cy = target.y - self.view_h * 0.5
  cx = math.max(0, math.min(cx, self.world_w - self.view_w))
  cy = math.max(0, math.min(cy, self.world_h - self.view_h))
  self.x = math.floor(cx)
  self.y = math.floor(cy)
  return self
end

return camera