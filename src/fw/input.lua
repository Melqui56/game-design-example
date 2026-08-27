local fw_input = {}

local MAPPING = {
  up    = { "w", "up" },
  down  = { "s", "down" },
  left  = { "a", "left" },
  right = { "d", "right" },
  shoot = { "space" },
}

local snapshot = {}

function fw_input.snapshot()
  for action, keys in pairs(MAPPING) do
    local pressed = false
    for _, key in ipairs(keys) do
      if love.keyboard.isDown(key) then
        pressed = true
        break
      end
    end
    snapshot[action] = pressed
  end
  return snapshot
end

return fw_input