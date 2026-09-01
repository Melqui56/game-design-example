local vec2 = require("src.core.vec2")
local fsm  = require("src.core.fsm")
local anim = require("src.core.anim")

local enemy = {}

enemy.TYPES = {
  chaser = { speed = 90,  hp = 1, radius = 14, scale = 1.0, attack_range = 28 },
  runner = { speed = 170, hp = 1, radius = 10, scale = 0.85, attack_range = 24 },
  tank   = { speed = 55,  hp = 3, radius = 18, scale = 1.5, attack_range = 32 },
}

local states = {
  chase = {
    update = function(self, dt)
      local delta = vec2.sub(self.target, self.position)
      local dist  = vec2.length(delta)
      self.attacking = dist <= self.attack_range
      local step  = self.speed * dt
      if step >= dist then
        self.position.x = self.target.x
        self.position.y = self.target.y
        return
      end
      local move = vec2.scale(vec2.normalize(delta), step)
      self.position = vec2.add(self.position, move)
    end,
  },
  dying = {
    enter = function(self)
      self.dying_timer = 0.25
    end,
    update = function(self, dt)
      self.dying_timer = self.dying_timer - dt
      if self.dying_timer <= 0 then
        self.dead = true
      end
    end,
  },
}

function enemy.new(kind, x, y, opts)
  local t = enemy.TYPES[kind or "chaser"]
  if not t then
    error("unknown enemy kind: " .. tostring(kind))
  end
  local o = opts or {}
  local self = {
    kind     = kind or "chaser",
    position = { x = x, y = y },
    speed    = o.speed or t.speed,
    hp       = o.hp or t.hp,
    radius   = o.radius or t.radius,
    scale    = o.scale or t.scale,
    target   = { x = 0, y = 0 },
    attack_range = o.attack_range or t.attack_range,
    attacking = false,
    dead     = false,
    flash    = false,
    walk_anim   = anim.new(2, 5),
    attack_anim = anim.new(2, 10),
  }
  self.fsm = fsm.new(states, "chase", self)
  return self
end

function enemy.update(self, target, dt)
  self.target = target
  fsm.update(self.fsm, dt)
  anim.update(self.walk_anim, dt)
  anim.update(self.attack_anim, dt)
  return self
end

function enemy.take_damage(self, amount)
  if self.fsm.current == "dying" then
    return false
  end
  self.hp = self.hp - (amount or 1)
  self.flash = true
  if self.hp <= 0 then
    fsm.change(self.fsm, "dying")
  end
  return true
end

function enemy.touches(self, other)
  local dx = self.position.x - other.position.x
  local dy = self.position.y - other.position.y
  local rr = self.radius + other.radius
  return dx * dx + dy * dy <= rr * rr
end

return enemy