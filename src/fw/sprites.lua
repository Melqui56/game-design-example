local palette = require("src.core.palette")

local sprites = {}

local COWBOY = {
  {
    "....HHHH....",
    "...HHHHHH...",
    "..HHHHHHHH..",
    "....FFFF....",
    "....FEFE....",
    "....BBBB....",
    "...TTTTTT...",
    "..TTTTTTTT..",
    "..GGGGGGGG..",
    "...LL..LL...",
    "...LL..LL...",
    "..SS....SS..",
    "............",
  },
  {
    "....HHHH....",
    "...HHHHHH...",
    "..HHHHHHHH..",
    "....FFFF....",
    "....FEFE....",
    "....BBBB....",
    "...TTTTTT...",
    "..TTTTTTTT..",
    "..GGGGGGGG..",
    "...LL..LL...",
    "...LL..LL...",
    "..SS..SS....",
    "............",
  },
  {
    "....HHHH....",
    "...HHHHHH...",
    "..HHHHHHHH..",
    "....FFFF....",
    "....FEFE....",
    "....BBBB....",
    "...TTTTTT...",
    "..TTTTTTTT..",
    "..GGGGGGGG..",
    "..LL...LL...",
    "..LL...LL...",
    ".SS.....S...",
    "............",
  },
  {
    "....HHHH....",
    "...HHHHHH...",
    "..HHHHHHHH..",
    "....FFFF....",
    "....FEFE....",
    "....BBBB....",
    "...TTTTTT...",
    "..TTTTTTTT..",
    "..GGGGGGGG..",
    "...LL...LL..",
    "...LL...LL..",
    "...S.....SS.",
    "............",
  },
}

local COWBOY_MAP = {
  H = palette.hat,
  F = palette.skin,
  E = palette.eye,
  B = palette.bandana,
  T = palette.denim,
  G = palette.boot,
  L = palette.denim,
  S = palette.boot,
}

local ZOMBIE = {
  {
    "....ZZZZ....",
    "...ZZZZZZ...",
    "..ZZZZZZZZ..",
    "...ZEEZ.....",
    "...ZEEZ.....",
    "..M....M....",
    "..RRRRRRRR..",
    "..R......R..",
    "..ZZZZZZZZ..",
    "..ZZ..ZZ....",
    "..ZZ..ZZ....",
    "..DD..DD....",
    "............",
  },
  {
    "....ZZZZ....",
    "...ZZZZZZ...",
    "..ZZZZZZZZ..",
    "...ZEEZ.....",
    "...ZEEZ.....",
    "..M....M....",
    "..RRRRRRRR..",
    ".R........R.",
    ".Z........Z.",
    "..ZZ..ZZ....",
    "..ZZ..ZZ....",
    "..DD..DD....",
    "............",
  },
}

local ZOMBIE_MAP = {
  Z = palette.zombie,
  E = palette.eye,
  M = palette.mouth,
  R = palette.zombie_dark,
  D = palette.zombie_dark,
}

local function build_image(rows, map)
  local h = #rows
  local w = #rows[1]
  local c = love.graphics.newCanvas(w, h)
  c:setFilter("nearest", "nearest")
  love.graphics.setCanvas(c)
  for y, line in ipairs(rows) do
    for x = 1, #line do
      local color = map[line:sub(x, x)]
      if color then
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill", x - 1, y - 1, 1, 1)
      end
    end
  end
  love.graphics.setCanvas()
  return c
end

local function build_flash(rows)
  local h = #rows
  local w = #rows[1]
  local c = love.graphics.newCanvas(w, h)
  c:setFilter("nearest", "nearest")
  love.graphics.setCanvas(c)
  for y, line in ipairs(rows) do
    for x = 1, #line do
      if line:sub(x, x) ~= "." then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", x - 1, y - 1, 1, 1)
      end
    end
  end
  love.graphics.setCanvas()
  return c
end

local built = false

function sprites.ensure()
  if built then
    return
  end
  built = true
  sprites.cowboy = {}
  sprites.cowboy_flash = {}
  for _, rows in ipairs(COWBOY) do
    table.insert(sprites.cowboy, build_image(rows, COWBOY_MAP))
    table.insert(sprites.cowboy_flash, build_flash(rows))
  end
  sprites.zombie = {}
  sprites.zombie_flash = {}
  for _, rows in ipairs(ZOMBIE) do
    table.insert(sprites.zombie, build_image(rows, ZOMBIE_MAP))
    table.insert(sprites.zombie_flash, build_flash(rows))
  end
end

return sprites