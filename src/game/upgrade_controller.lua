local menu     = require("src.core.menu")
local palette  = require("src.core.palette")
local upgrades = require("src.core.upgrades")
local backdrop = require("src.fw.backdrop")
local retro    = require("src.fw.retro")
local sfx      = require("src.fw.sfx")
local ui       = require("src.fw.ui")

local upgrade = {}

function upgrade.new(sm)
  return setmetatable({ sm = sm }, { __index = upgrade })
end

function upgrade.enter(self, player)
  retro.reset_offset()
  self.player  = player
  self.choices = upgrades.choose(upgrades.pool(), 2)
  local labels = {}
  for _, u in ipairs(self.choices) do
    table.insert(labels, u.label)
  end
  self.menu = menu.new(labels)
end

function upgrade.update(_, _dt)
end

function upgrade.draw(self)
  local w, h = retro.getDimensions()
  backdrop.draw(palette, w, h)
  ui.title("LEVEL UP", w * 0.5, 60)
  local cy = 140
  ui.menu_items(self.menu, w * 0.5, cy, 44)
  for i, u in ipairs(self.choices) do
    ui.hud_text_centered(u.desc, w * 0.5, cy + (i - 1) * 44 + 18)
  end
end

function upgrade.keypressed(self, key)
  if key == "up" then
    menu.move(self.menu, -1)
    sfx.play("ui", 0.3)
  elseif key == "down" then
    menu.move(self.menu, 1)
    sfx.play("ui", 0.3)
  elseif key == "return" or key == "kpenter" then
    sfx.play("ui", 0.3)
    upgrades.apply(self.choices[self.menu.cursor], self.player)
    self.sm:switch("play")
  end
end

return upgrade