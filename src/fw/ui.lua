local palette = require("src.core.palette")

local ui = {}

local FONT_PATH = "assets/fonts/PressStart2P.ttf"
local fonts = {}

local function font(size)
  local f = fonts[size]
  if not f then
    f = love.graphics.newFont(FONT_PATH, size)
    fonts[size] = f
  end
  return f
end

local function set_color(c, alpha)
  love.graphics.setColor(c[1], c[2], c[3], alpha or 1)
end

local function print_with_shadow(text, x, y, size, color)
  love.graphics.setFont(font(size))
  set_color(palette.shadow)
  love.graphics.print(text, x + 2, y + 2)
  set_color(color)
  love.graphics.print(text, x, y)
end

function ui.title(text, cx, y, size)
  local fs = size or 24
  love.graphics.setFont(font(fs))
  local x = cx - love.graphics.getFont():getWidth(text) * 0.5
  print_with_shadow(text, x, y, fs, palette.accent)
end

function ui.menu_items(m, cx, y, spacing, size)
  local fs = size or 12
  love.graphics.setFont(font(fs))
  local f = love.graphics.getFont()
  for i, label in ipairs(m.items) do
    local selected = i == m.cursor
    local x = cx - f:getWidth(label) * 0.5
    local ty = y + (i - 1) * spacing
    print_with_shadow(label, x, ty, fs, selected and palette.accent or palette.muted)
    if selected then
      local mid = ty + f:getHeight() * 0.5
      set_color(palette.accent)
      love.graphics.polygon("fill", x - 26, mid, x - 15, mid - 8, x - 15, mid + 8)
    end
  end
end

function ui.hud_text(text, x, y)
  love.graphics.setFont(font(10))
  set_color(palette.shadow)
  love.graphics.print(text, x + 1, y + 1)
  set_color(palette.text)
  love.graphics.print(text, x, y)
end

return ui