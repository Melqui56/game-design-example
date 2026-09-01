local bullet    = require("src.core.bullet")
local camera    = require("src.core.camera")
local enemy     = require("src.core.enemy")
local map       = require("src.core.map")
local particles = require("src.core.particles")
local palette   = require("src.core.palette")
local pickup    = require("src.core.pickup")
local player    = require("src.core.player")
local shake     = require("src.core.shake")
local upgrades  = require("src.core.upgrades")
local waves     = require("src.core.waves")
local input     = require("src.fw.input")
local light     = require("src.fw.light")
local render    = require("src.fw.render")
local retro     = require("src.fw.retro")
local save_io   = require("src.fw.save_io")
local sfx       = require("src.fw.sfx")
local ui        = require("src.fw.ui")

local WORLD_W = 960
local WORLD_H = 540

-- how long the new-wave banner takes to fly through, in seconds
local BANNER_TIME = 1.6

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
  retro.reset_offset()
  local vw, vh = retro.getDimensions()
  self.area       = { minX = 0, minY = 0, maxX = WORLD_W, maxY = WORLD_H }
  self.camera     = camera.new(WORLD_W, WORLD_H, vw, vh)
  self.wave       = 1
  self.spawns     = waves.plan(self.wave, self.area)
  self.wave_timer = 0
  self.enemies    = {}
  self.bullets    = {}
  self.pickups    = {}
  self.props      = map.decorate(self.area, 40)
  self.buildings  = map.town(self.area, 10)
  self.fire_timer = 0
  self.muzzle     = 0
  self.moving     = false
  self.particles  = particles.new()
  self.shake      = shake.new()
  self.score      = 0
  self.hud_t      = 0
  self.banner     = 0
  self.score_pop  = 0
  self.player     = player.new({ x = WORLD_W * 0.5, y = WORLD_H * 0.5 })
end

function play.update(self, dt)
  self.hud_t = self.hud_t + dt
  if self.banner > 0 then
    self.banner = math.max(0, self.banner - dt / BANNER_TIME)
  end
  if self.score_pop > 0 then
    self.score_pop = math.max(0, self.score_pop - dt * 4)
  end

  local state = input.snapshot()
  player.update(self.player, state, dt, self.area)
  camera.follow(self.camera, self.player.position)

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
      self.player.position.x, self.player.position.y, self.player.aim,
      { speed = self.player.bullet_speed, radius = self.player.bullet_radius, damage = self.player.damage }))
    self.fire_timer = self.player.fire_interval
    self.muzzle     = 0.08
    player.shoot(self.player)
    sfx.play("shoot", 0.5)
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
      if enemy.take_damage(e, self.player.damage) then
        particles.burst(self.particles, e.position.x, e.position.y, { count = 10 })
        shake.add(self.shake, 0.3)
        self.score = self.score + 10 * self.player.damage
        self.score_pop = 1
        sfx.play("kill", 0.45)
        if love.math.random() < 0.22 then
          local picks = upgrades.choose(upgrades.pool(), 1)
          table.insert(self.pickups, pickup.new(picks[1], e.position.x, e.position.y))
        end
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
        sfx.play("hurt", 0.5)
      end
      table.remove(self.enemies, ci)
    end
    ci = ci - 1
  end

  if self.player.hp <= 0 then
    if self.score > save_io.get("high_score", 0) then
      save_io.set("high_score", self.score)
    end
    sfx.play("kill", 0.5)
    self.sm:switch("gameover", self.score)
    return
  end

  if #self.spawns == 0 and #self.enemies == 0 then
    self.wave       = self.wave + 1
    self.spawns     = waves.plan(self.wave, self.area)
    self.wave_timer = 0
    self.banner     = 1
    self.wave_total = nil
  end

  local pi = #self.pickups
  while pi >= 1 do
    local pk = self.pickups[pi]
    pickup.update(pk, dt)
    if pk.dead or pickup.touches(pk, self.player) then
      if not pk.dead then
        upgrades.apply(pk.def, self.player)
        sfx.play("ui", 0.4)
      end
      table.remove(self.pickups, pi)
    end
    pi = pi - 1
  end

  particles.update(self.particles, dt)
  shake.update(self.shake, dt)
  local off = shake.offset(self.shake)
  retro.set_offset(off.x, off.y)
end

function play.draw(self)
  local vw, vh = retro.getDimensions()
  love.graphics.push()
  love.graphics.translate(-self.camera.x, -self.camera.y)

  render.ground(WORLD_W, WORLD_H)
  render.begin()

  for _, b in ipairs(self.buildings) do
    render.building(b)
  end
  for _, pr in ipairs(self.props) do
    render.prop(pr)
  end
  render.cowboy(self.player, self.moving, self.muzzle)
  for _, e in ipairs(self.enemies) do
    render.zombie(e)
  end

  render.flush()

  for _, b in ipairs(self.bullets) do
    render.bullet(b)
  end
  render.particles(self.particles.list)
  for _, pk in ipairs(self.pickups) do
    render.pickup(pk)
  end

  love.graphics.pop()

  love.graphics.setColor(0, 0, 0, 0.16)
  love.graphics.rectangle("fill", 0, 0, vw, vh)
  light.draw({ x = self.player.position.x - self.camera.x, y = self.player.position.y - self.camera.y })

  -- HUD: the same slanted plates the menus are built from, so the title
  -- screen and the play scene read as one piece of design.
  local hp_w = math.max(66, self.player.max_hp * 9 + 14)
  ui.slant_panel(4, 4, hp_w, 26, {
    skew = 8, fill = palette.outline, fill_alpha = 0.80,
    rule = palette.leather, tip = palette.blood,
  })
  love.graphics.setFont(ui.font(8))
  love.graphics.setColor(palette.muted[1], palette.muted[2], palette.muted[3], 0.85)
  love.graphics.print("HP", 16, 9)
  render.hearts(self.player.hp, self.player.max_hp, 16, 19, self.hud_t)

  ui.hud_stat(vw - 196, 4, 80, "WAVE", tostring(self.wave), { tip = palette.gold })
  ui.hud_stat(vw - 104, 4, 92, "SCORE", tostring(self.score),
    { pop = self.score_pop })

  -- how much of the wave is still out there, as a hairline under the plates
  local left = #self.spawns + #self.enemies
  if left > 0 then
    local total = math.max(left, self.wave_total or left)
    self.wave_total = total
    love.graphics.setColor(palette.rot[1], palette.rot[2], palette.rot[3], 0.8)
    love.graphics.rectangle("fill", vw - 188, 32, 72 * (left / total), 2)
    love.graphics.setColor(palette.outline[1], palette.outline[2], palette.outline[3], 0.6)
    love.graphics.rectangle("fill", vw - 188 + 72 * (left / total), 32,
      72 * (1 - left / total), 2)
  end

  ui.banner("WAVE " .. self.wave, vw, vw * 0.5, 92, 1 - self.banner)
end

function play.keypressed(self, key)
  if key == "escape" then
    self.sm:switch("pause")
  end
end

return play