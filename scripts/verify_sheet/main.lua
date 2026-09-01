function love.load()
  local repo = love.filesystem.getSource():gsub("/scripts/verify_sheet$", "")

  local function load_data(rel)
    return assert(loadfile(repo .. "/" .. rel))()
  end

  local atlas = load_data("assets/sprites/atlas.lua")
  local palette = load_data("src/core/palette.lua")
  local pixelmod = load_data("scripts/pixel.lua")

  local function near(a, b, eps)
    eps = eps or 0.12
    return math.abs(a - b) <= eps
  end

  local function match_ramp(c, ramp, step)
    local t = ramp[step]
    return near(c[1], t[1]) and near(c[2], t[2]) and near(c[3], t[3])
  end

  local f = io.open(repo .. "/assets/sprites/sheet.png", "rb")
  if not f then
    print("ERROR: cannot open sheet.png from " .. repo)
    love.event.quit()
    return
  end
  local bytes = f:read("*a")
  f:close()
  local filedata = love.filesystem.newFileData(bytes, "sheet.png")
  local img = love.image.newImageData(filedata)

  local failures = 0
  local checks = 0

  local function pixel(rect, px, py)
    local x = rect.x + px - 1
    local y = rect.y + py - 1
    return { img:getPixel(x, y) }
  end

  local function expect(cond, msg)
    checks = checks + 1
    if not cond then
      print("FAIL " .. msg)
      failures = failures + 1
    end
  end

  -- cowboy idle frame 1: hat near top (bright ramp step), outline border
  local rect = atlas.cowboy_idle[1]
  local hat_ramp = pixelmod.make_ramp(palette.hat)
  local skin_ramp = pixelmod.make_ramp(palette.skin)
  -- hat pixel near top -> brighter ramp step
  expect(match_ramp(pixel(rect, 5, 2), hat_ramp, 4), "cowboy_idle[1] hat top bright")
  -- hat pixel one row lower -> base step
  expect(match_ramp(pixel(rect, 6, 3), hat_ramp, 3), "cowboy_idle[1] hat mid")
  -- face/skin pixel (row 5, cheek skin)
  expect(match_ramp(pixel(rect, 5, 5), skin_ramp, 3), "cowboy_idle[1] face mid")
  -- outline top-left
  expect(match_ramp(pixel(rect, 1, 1), { palette.outline }, 1), "cowboy_idle[1] outline top-left")

  -- zombie walk frame 1: zombie green head, outline
  local zrect = atlas.zombie_walk[1]
  local zombie_ramp = pixelmod.make_ramp(palette.zombie)
  expect(match_ramp(pixel(zrect, 6, 3), zombie_ramp, 3), "zombie_walk[1] head color")
  expect(match_ramp(pixel(zrect, 3, 1), { palette.outline }, 1), "zombie_walk[1] outline")

  -- prop cactus: cactus green, outline
  local crect = atlas.prop_cactus[1]
  local cactus_ramp = pixelmod.make_ramp(palette.cactus)
  expect(match_ramp(pixel(crect, 2, 2), cactus_ramp, 4), "prop_cactus color")
  expect(match_ramp(pixel(crect, 1, 1), { palette.outline }, 1), "prop_cactus outline")

  -- title portrait: flat-shaded, so every tone must be a ramp base step and
  -- the bust must still be the size title_art places its anchors against
  local hrect = atlas.hero_body[1]
  expect(hrect.w == 80 and hrect.h == 100, "hero_body is 80x100")
  local hat_deep_ramp = pixelmod.make_ramp(palette.hat_deep)
  expect(match_ramp(pixel(hrect, 45, 40), hat_deep_ramp, 3), "hero_body brim shadow flat")
  local eye_ramp = pixelmod.make_ramp(palette.eye_glow)
  expect(match_ramp(pixel(hrect, 32, 43), eye_ramp, 3), "hero_body eye burning")
  expect(atlas.hero_idle[1].w == 40 and atlas.hero_idle[1].h == 46,
    "hero_idle revolver is 40x46")

  -- logo words: composed from the glyph font and bevelled from their own
  -- edges, so a letter's top-left is the bright step and its inside the base
  local lrect = atlas.logo_cowboy[1]
  expect(lrect.w == 92 and lrect.h == 16, "logo_cowboy is 92x16")
  expect(atlas.logo_zombies[1].w == 103, "logo_zombies is 103 wide")
  local gold_ramp = pixelmod.make_ramp(palette.gold)
  -- C of COWBOY: row 3 is "####.....####", so x4 is the lit left edge and
  -- x2..x3 sit inside the stroke
  expect(match_ramp(pixel(lrect, 1, 3), gold_ramp, 5), "logo_cowboy bevel highlight")
  expect(match_ramp(pixel(lrect, 2, 4), gold_ramp, 3), "logo_cowboy bevel interior")

  -- all sets have at least one frame
  for k, v in pairs(atlas) do
    expect(type(v) == "table" and #v >= 1, "atlas set has frames: " .. k)
  end

  print(string.format("verify_sheet: %d checks, %d failures", checks, failures))
  love.event.quit()
end

function love.draw()
end