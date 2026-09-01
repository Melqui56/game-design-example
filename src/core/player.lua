local vec2 = require("src.core.vec2")
local fsm  = require("src.core.fsm")
local anim = require("src.core.anim")

local player = {}

local DEFAULTS = {
  size          = 24,
  speed         = 260,
  hp            = 3,
  damage        = 1,
  fire_interval = 0.16,
  bullet_speed  = 320,
  bullet_radius = 2,
}

local HIT_DURATION = 0.8

local states = {
  alive = {},
  hit = {
    enter = function(self)
      self.hit_timer = HIT_DURATION
    end,
    update = function(self, dt)
      self.hit_timer = self.hit_timer - dt
      self.flash = (math.floor(self.hit_timer * 12) % 2) == 0
      if self.hit_timer <= 0 then
        self.flash = false
        fsm.change(self.fsm, "alive")
      end
    end,
  },
  dead = {},
}

function player.new(opts)
  local o = opts or {}
  local size = o.size or DEFAULTS.size
  local self = {
    position = vec2.new(o.x or 0, o.y or 0),
    size     = size,
    radius   = size * 0.5,
    speed    = o.speed or DEFAULTS.speed,
    hp            = o.hp or DEFAULTS.hp,
    max_hp        = o.hp or DEFAULTS.hp,
    damage        = o.damage or DEFAULTS.damage,
    fire_interval = o.fire_interval or DEFAULTS.fire_interval,
    bullet_speed  = o.bullet_speed or DEFAULTS.bullet_speed,
    bullet_radius = o.bullet_radius or DEFAULTS.bullet_radius,
    flash    = false,
    aim      = { x = 0, y = -1 },
    recoil   = 0,
    idle_anim = anim.new(2, 4),
    walk_anim = anim.new(2, 8),
    shoot_anim = anim.new(2, 24),
  }
  self.fsm = fsm.new(states, "alive", self)
  return self
end

function player.update(self, input, dt, bounds)
  local dir = vec2.new(0, 0)
  if input.up    then dir.y = dir.y - 1 end
  if input.down  then dir.y = dir.y + 1 end
  if input.left  then dir.x = dir.x - 1 end
  if input.right then dir.x = dir.x + 1 end

  dir = vec2.normalize(dir)

  self.position.x = self.position.x + dir.x * self.speed * dt
  self.position.y = self.position.y + dir.y * self.speed * dt

  if bounds then
    local hw = self.size * 0.5
    self.position.x = math.min(math.max(self.position.x, bounds.minX + hw), bounds.maxX - hw)
    self.position.y = math.min(math.max(self.position.y, bounds.minY + hw), bounds.maxY - hw)
  end

  fsm.update(self.fsm, dt)
  anim.update(self.idle_anim, dt)
  anim.update(self.walk_anim, dt)
  anim.update(self.shoot_anim, dt)
  if self.recoil > 0 then
    self.recoil = self.recoil - dt
  end
  return self
end

function player.shoot(self)
  self.recoil = 0.12
  anim.restart(self.shoot_anim)
end

function player.take_damage(self, amount)
  if self.fsm.current == "hit" or self.fsm.current == "dead" then
    return false
  end
  self.hp = self.hp - (amount or 1)
  if self.hp <= 0 then
    fsm.change(self.fsm, "dead")
    return true
  end
  fsm.change(self.fsm, "hit")
  return true
end

function player.facing(input)
  local dir = vec2.new(0, 0)
  if input.up    then dir.y = dir.y - 1 end
  if input.down  then dir.y = dir.y + 1 end
  if input.left  then dir.x = dir.x - 1 end
  if input.right then dir.x = dir.x + 1 end
  if vec2.length(dir) == 0 then
    return { x = 0, y = -1 }
  end
  return vec2.normalize(dir)
end

return player