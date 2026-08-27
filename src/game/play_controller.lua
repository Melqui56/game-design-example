local enemy  = require("src.core.enemy")
local player = require("src.core.player")
local waves  = require("src.core.waves")
local input  = require("src.fw.input")
local render = require("src.fw.render")

local play = {}

function play.new(sm)
  return setmetatable({ sm = sm }, { __index = play })
end

function play.enter(self)
  local w, h = love.graphics.getDimensions()
  self.area       = { minX = 0, minY = 0, maxX = w, maxY = h }
  self.wave       = 1
  self.spawns     = waves.plan(self.wave, self.area)
  self.wave_timer = 0
  self.enemies    = {}
  self.player     = player.new({ x = w * 0.5, y = h * 0.5 })
end

function play.update(self, dt)
  player.update(self.player, input.snapshot(), dt, self.area)

  self.wave_timer = self.wave_timer + dt
  while self.spawns[1] and self.wave_timer >= self.spawns[1].time do
    local ev = table.remove(self.spawns, 1)
    table.insert(self.enemies, enemy.new(ev.kind, ev.x, ev.y))
  end

  for _, e in ipairs(self.enemies) do
    enemy.update(e, self.player.position, dt)
  end

  local i = #self.enemies
  while i >= 1 do
    local e = self.enemies[i]
    if enemy.touches(e, self.player) then
      player.take_damage(self.player, 1)
      table.remove(self.enemies, i)
    end
    i = i - 1
  end

  if self.player.hp <= 0 then
    self.sm:switch("gameover")
    return
  end

  if #self.spawns == 0 and #self.enemies == 0 then
    self.wave       = self.wave + 1
    self.spawns     = waves.plan(self.wave, self.area)
    self.wave_timer = 0
  end
end

function play.draw(self)
  love.graphics.clear(0.10, 0.10, 0.14)
  render.player(self.player)
  for _, e in ipairs(self.enemies) do
    render.enemy(e)
  end
  render.text("HP " .. self.player.hp .. "   Wave " .. self.wave, 12, 12)
end

function play.keypressed(self, key)
  if key == "escape" then
    self.sm:switch("title")
  end
end

return play