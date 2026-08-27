local anim = {}

function anim.new(frame_count, fps, opts)
  return {
    frame_count = frame_count,
    frame_time  = 1 / (fps or 8),
    timer       = 0,
    frame       = 1,
    loop        = opts == nil or opts.loop ~= false,
    done        = false,
  }
end

function anim.update(self, dt)
  if self.done and not self.loop then
    return self
  end
  self.timer = self.timer + dt
  while self.timer >= self.frame_time do
    self.timer = self.timer - self.frame_time
    self.frame = self.frame + 1
    if self.frame > self.frame_count then
      if self.loop then
        self.frame = 1
      else
        self.frame = self.frame_count
        self.done = true
      end
    end
  end
  return self
end

return anim