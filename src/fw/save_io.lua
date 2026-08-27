local save = require("src.core.save")

local save_io = {}

local FILE = "save.txt"
local cache = {}
local loaded = false

function save_io.load()
  if not loaded then
    loaded = true
    if love.filesystem.getInfo(FILE) then
      cache = save.parse(love.filesystem.read(FILE))
    end
  end
  return cache
end

function save_io.get(key, default)
  save_io.load()
  local v = cache[key]
  if v == nil then
    return default
  end
  return v
end

function save_io.set(key, value)
  save_io.load()
  cache[key] = value
  love.filesystem.write(FILE, save.serialize(cache))
end

return save_io