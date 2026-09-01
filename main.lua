local App = require("src.fw.app")

local app = App.new()

-- --screenshot mode: enters the play scene, captures a frame after a moment,
-- and writes screenshot_report.txt + screenshot.png to the LÖVE save dir.
-- Useful as a QA tool for the play scene.
local screenshot_frames = nil

function love.load()
  app:load()
  for _, a in ipairs(arg or {}) do
    if a == "--screenshot" then
      screenshot_frames = 0
      app.scenes:switch("play")
    end
  end
end

-- Counts pixels of a target color only inside a region (x0,y0)-(x1,y1).
local function count_in_region(img, x0, y0, x1, y1, target, tol)
  local found = 0
  tol = tol or 0.15
  for y = y0, y1 do
    for x = x0, x1 do
      local r, g, b, a = img:getPixel(x, y)
      if a > 0.5
        and math.abs(r - target[1]) <= tol
        and math.abs(g - target[2]) <= tol
        and math.abs(b - target[3]) <= tol then
        found = found + 1
      end
    end
  end
  return found
end

function love.update(dt)
  app:update(dt)
  if screenshot_frames then
    screenshot_frames = screenshot_frames + 1
    if screenshot_frames == 30 then
      love.graphics.captureScreenshot(function(img)
        local palette = require("src.core.palette")
        local w, h = img:getDimensions()
        local cx, cy = w * 0.5, h * 0.5
        local hat = count_in_region(img, cx - 120, cy - 120, cx + 120, cy + 120, palette.hat)
        local skin = count_in_region(img, cx - 120, cy - 120, cx + 120, cy + 120, palette.skin)
        local bandana = count_in_region(img, cx - 120, cy - 120, cx + 120, cy + 120, palette.bandana)
        local denim = count_in_region(img, cx - 120, cy - 120, cx + 120, cy + 120, palette.denim)
        local zombie = count_in_region(img, cx - 120, cy - 120, cx + 120, cy + 120, palette.zombie)
        local out = string.format(
          "hat=%d skin=%d bandana=%d denim=%d zombie=%d", hat, skin, bandana, denim, zombie)
        print(out)
        love.filesystem.write("screenshot_report.txt", out .. "\n")
        img:encode("png", "screenshot.png")
        love.event.quit()
      end)
    end
  end
end

function love.draw()
  app:draw()
end

function love.keypressed(key)
  app:keypressed(key)
end