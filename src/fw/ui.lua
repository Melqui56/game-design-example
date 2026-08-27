local ui = {}

local fonts = {}

local function font(size)
  local f = fonts[size]
  if not f then
    f = love.graphics.newFont(size)
    fonts[size] = f
  end
  return f
end

function ui.title(text, cx, y, size)
  love.graphics.setFont(font(size or 36))
  love.graphics.setColor(0.95, 0.85, 0.25)
  love.graphics.print(text, cx - love.graphics.getFont():getWidth(text) * 0.5, y)
end

function ui.menu_items(m, cx, y, spacing, size)
  love.graphics.setFont(font(size or 28))
  local f = love.graphics.getFont()
  for i, label in ipairs(m.items) do
    local selected = i == m.cursor
    local tx = cx - f:getWidth(label) * 0.5
    local ty = y + (i - 1) * spacing
    love.graphics.setColor(selected and 1 or 0.6, selected and 0.85 or 0.6, selected and 0.3 or 0.6)
    love.graphics.print(label, tx, ty)
    if selected then
      local mid = ty + f:getHeight() * 0.5
      love.graphics.setColor(1, 0.85, 0.3)
      love.graphics.polygon("fill", tx - 28, mid, tx - 16, mid - 8, tx - 16, mid + 8)
    end
  end
end

return ui