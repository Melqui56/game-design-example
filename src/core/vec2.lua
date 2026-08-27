local vec2 = {}

function vec2.new(x, y)
  return { x = x or 0, y = y or 0 }
end

function vec2.add(a, b)
  return { x = a.x + b.x, y = a.y + b.y }
end

function vec2.sub(a, b)
  return { x = a.x - b.x, y = a.y - b.y }
end

function vec2.scale(a, s)
  return { x = a.x * s, y = a.y * s }
end

function vec2.length(a)
  return math.sqrt(a.x * a.x + a.y * a.y)
end

function vec2.normalize(a)
  local len = vec2.length(a)
  if len == 0 then
    return { x = 0, y = 0 }
  end
  return { x = a.x / len, y = a.y / len }
end

function vec2.clamp(a, min, max)
  return {
    x = math.min(math.max(a.x, min), max),
    y = math.min(math.max(a.y, min), max),
  }
end

return vec2