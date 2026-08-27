local save = {}

function save.serialize(flat)
  local parts = {}
  for k, v in pairs(flat) do
    table.insert(parts, k .. "=" .. tostring(v))
  end
  table.sort(parts)
  return table.concat(parts, "\n")
end

function save.parse(text)
  local out = {}
  for line in (text or ""):gmatch("[^\n]+") do
    local k, v = line:match("^([^=]+)=(.*)$")
    if k then
      local n = tonumber(v)
      out[k] = n or v
    end
  end
  return out
end

return save