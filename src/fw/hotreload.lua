local hotreload = {}

local tracked = nil

local function scan(path, out)
  for _, name in ipairs(love.filesystem.getDirectoryItems(path)) do
    local full = path .. "/" .. name
    local info = love.filesystem.getInfo(full)
    if info then
      if info.type == "directory" then
        scan(full, out)
      elseif name:match("%.lua$") then
        out[full] = info.modtime
      end
    end
  end
  return out
end

local function dev_requested()
  if os.getenv("LOVE_DEV") ~= nil then
    return true
  end
  for _, a in ipairs(love.arg or {}) do
    if a == "--dev" then
      return true
    end
  end
  for _, a in ipairs(arg or {}) do
    if a == "--dev" then
      return true
    end
  end
  return false
end

function hotreload.setup()
  if not dev_requested() then
    return false
  end
  tracked = scan("src", {})
  tracked["main.lua"] = love.filesystem.getInfo("main.lua").modtime
  tracked["conf.lua"] = love.filesystem.getInfo("conf.lua").modtime
  print("hot reload: watching src/, main.lua, conf.lua")
  return true
end

function hotreload.tick()
  for path, stamp in pairs(tracked) do
    local info = love.filesystem.getInfo(path)
    if info and info.modtime ~= stamp then
      print("hot reload: restarting on " .. path)
      love.event.quit("restart")
      return
    end
  end
end

return hotreload