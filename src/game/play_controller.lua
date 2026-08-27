local bullet    = require("src.core.bullet")
local enemy     = require("src.core.enemy")
local palette   = require("src.core.palette")
local particles = require("src.core.particles")
local player    = require("src.core.player")
local shake     = require("src.core.shake")
local waves     = require("src.core.waves")
local backdrop  = require("src.fw.backdrop")
local input     = require("src.fw.input")
local light     = require("src.fw.light")
local render    = require("src.fw.render")
local retro     = require("src.fw.retro")
local ui        = require("src.fw.ui")

local FIRE_INTERVAL = 0.16
local BULLET_SPEED  = 320

local play = {}

function play.new(sm)
  return setmetatable({ sm = sm }, { __index = play })
end

local function nearest_enemy(self)
  local target = nil
  local best = math.huge
  for _, e in ipairs(self.enemies) do
    local dx = e.position.x - self.player.position.x
    local dy = e.position.y - self.player.position.y
    local d = dx * dx + dy * dy
    if d < best then
      best = d
      target = e
    end
  end
  return target
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
  self.muzzle     = 0
  self.moving     = false
  self.particles  = particles.new()
  self.shake      = shake.new()
  self.score      = 0
  self.player     = player.new({ x = w * 0.5, y = h * 0.5 })
end

function play.update(self, dt)
  local state = input.snapshot()
  player.update(self.player, state, dt, self.area)

  self.moving = state.up or state.down or state.left or state.right
  local target = nearest_enemy(self)
  if target then
    local dx = target.position.x - self.player.position.x
    local dy = target.position.y - self.player.position.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
      self.player.aim = { x = dx / len, y = dy / len }
    end
  else
    self.player.aim = player.facing(state)
  end

  self.fire_timer = self.fire_timer - dt
  self.muzzle     = self.muzzle - dt
  if state.shoot and self.fire_timer <= 0 then
    table.insert(self.bullets, bullet.new(
      self.player.position.x, self.player.position.y, self.player.aim, { speed = BULLET_SPEED }))
    self.fire_timer = FIRE_INTERVAL
    self.muzzle     = 0.08
  end

  self.wave_timer = self.wave_timer + dt
  while self.spawns[1] and self.wave_timer >= self.spawns[1].time do
    local ev = table.remove(self.spawns, 1)
    table.insert(self.enemies, enemy.new(ev.kind, ev.x, ev.y))
  end

  local ei = #self.enemies
  while ei >= 1 do
    local e = self.enemies[ei]
    enemy.update(e, self.player.position, dt)
    if e.dead then
      table.remove(self.enemies, ei)
    end
    ei = ei - 1
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

  local k = #self.enemies
  while k >= 1 do
    local e = self.enemies[k]
    local hit = false
    for j = #self.bullets, 1, -1 do
      if bullet.touches(self.bullets[j], e) then
        table.remove(self.bullets, j)
        hit = true
      end
    end
    if hit then
      if enemy.take_damage(e, 1) then
        particles.burst(self.particles, e.position.x, e.position.y, { count = 10 })
        shake.add(self.shake, 0.3)
        self.score = self.score + 10
      end
    end
    k = k - 1
  end

  local ci = #self.enemies
  while ci >= 1 do
    local e = self.enemies[ci]
    if enemy.touches(e, self.player) then
      if player.take_damage(self.player, 1) then
        shake.add(self.shake, 0.45)
      end
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
  render.cowboy(self.player, self.moving, self.muzzle)
  for _, b in ipairs(self.bullets) do
    render.bullet(b)
  end
  render.particles(self.particles.list)
  for _, e in ipairs(self.enemies) do
    render.zombie(e)
  end

  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.rectangle("fill", 0, 0, w, h)
  light.draw(self.player.position)

  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.rectangle("fill", 0, 0, w, 13)
  render.hearts(self.player.hp, self.player.max_hp, 4, 3)
  ui.hud_text_centered("WAVE " .. self.wave, w * 0.5, 2)
  ui.hud_text_right("SCORE " .. self.score, w - 4, 2)
end

function play.keypressed(self, key)
  if key == "escape" then
    self.sm:switch("pause")
  end
end

return play