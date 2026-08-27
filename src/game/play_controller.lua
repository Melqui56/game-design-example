local bullet    = require("src.core.bullet")
local enemy     = require("src.core.enemy")
local palette   = require("src.core.palette")
local particles = require("src.core.particles")
local player    = require("src.core.player")
local shake     = require("src.core.shake")
local waves     = require("src.core.waves")
local backdrop  = require("src.fw.backdrop")
local input     = require("src.fw.input")
local render    = require("src.fw.render")
local retro     = require("src.fw.retro")
local ui        = require("src.fw.ui")

local FIRE_INTERVAL = 0.22

local play = {}

function play.new(sm)
  return setmetatable({ sm = sm }, { __index = play })
end

function play.enter(self)
  local w, h = retro.getDimensions()
  retro.reset_offset()
  self.area       = { minX = 0, minY = 0, maxX = w, maxY = h }
  self.wave       = 1
  self.spawns     = waves.plan(self.wave, self.area)
  self.wave_timer = 0
  self.enemies    = {}
  self.bullets    = {}
  self.fire_timer = 0
  self.particles  = particles.new()
  self.shake      = shake.new()
  self.player     = player.new({ x = w * 0.5, y = h * 0.5 })
end

function play.update(self, dt)
  local state = input.snapshot()
  player.update(self.player, state, dt, self.area)

  self.fire_timer = self.fire_timer - dt
  if state.shoot and self.fire_timer <= 0 then
    local aim = player.facing(state)
    table.insert(self.bullets, bullet.new(self.player.position.x, self.player.position.y, aim))
    self.fire_timer = FIRE_INTERVAL
  end

  self.wave_timer = self.wave_timer + dt
  while self.spawns[1] and self.wave_timer >= self.spawns[1].time do
    local ev = table.remove(self.spawns, 1)
    table.insert(self.enemies, enemy.new(ev.kind, ev.x, ev.y))
  end

  for _, e in ipairs(self.enemies) do
    enemy.update(e, self.player.position, dt)
  end

  local bi = #self.bullets
  while bi >= 1 do
    local b = self.bullets[bi]
    bullet.update(b, dt, self.area)
    if b.dead then
      table.remove(self.bullets, bi)
    end
    bi = bi - 1
  end

  local ei = #self.enemies
  while ei >= 1 do
    local e = self.enemies[ei]
    local hit = false
    for j = #self.bullets, 1, -1 do
      if bullet.touches(self.bullets[j], e) then
        table.remove(self.bullets, j)
        hit = true
      end
    end
    if hit and enemy.take_damage(e, 1) then
      particles.burst(self.particles, e.position.x, e.position.y, { count = 10 })
      shake.add(self.shake, 0.3)
      table.remove(self.enemies, ei)
    end
    ei = ei - 1
  end

  local ci = #self.enemies
  while ci >= 1 do
    local e = self.enemies[ci]
    if enemy.touches(e, self.player) then
      player.take_damage(self.player, 1)
      shake.add(self.shake, 0.45)
      table.remove(self.enemies, ci)
    end
    ci = ci - 1
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

  particles.update(self.particles, dt)
  shake.update(self.shake, dt)
  local off = shake.offset(self.shake)
  retro.set_offset(off.x, off.y)
end

function play.draw(self)
  local w, h = retro.getDimensions()
  backdrop.draw(palette, w, h)
  render.player(self.player)
  for _, b in ipairs(self.bullets) do
    render.bullet(b)
  end
  render.particles(self.particles.list)
  for _, e in ipairs(self.enemies) do
    render.enemy(e)
  end
  ui.hud_text("HP " .. self.player.hp .. "  WAVE " .. self.wave, 4, 4)
end

function play.keypressed(self, key)
  if key == "escape" then
    self.sm:switch("pause")
  end
end

return play