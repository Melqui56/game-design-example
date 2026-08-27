local sfx = {}

local RATE = 22050
local sources = {}

local function new_sound(duration, sample_fn)
  local count = math.floor(RATE * duration)
  local data = love.sound.newSoundData(count, RATE, 16, 1)
  for i = 0, count - 1 do
    data:setSample(i, sample_fn(i / RATE))
  end
  return love.audio.newSource(data, "static")
end

local function decay(t, dur)
  return 1 - t / dur
end

local function sine(freq, t)
  return math.sin(2 * math.pi * freq * t)
end

local function build_all()
  sources.shoot = new_sound(0.08, function(t)
    return (love.math.random() * 2 - 1) * decay(t, 0.08) * 0.5
  end)
  sources.kill = new_sound(0.16, function(t)
    return (sine(160, t) * 0.6 + (love.math.random() * 2 - 1) * 0.4) * decay(t, 0.16)
  end)
  sources.hurt = new_sound(0.3, function(t)
    local freq = 380 - 200 * (t / 0.3)
    return sine(freq, t) * decay(t, 0.3) * 0.8
  end)
  sources.ui = new_sound(0.06, function(t)
    return sine(700, t) * decay(t, 0.06) * 0.6
  end)
end

function sfx.init()
  if not sources.shoot then
    build_all()
  end
end

function sfx.play(name, volume)
  local src = sources[name]
  if not src then
    return
  end
  local c = src:clone()
  c:setVolume(volume or 0.4)
  c:play()
end

return sfx