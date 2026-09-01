-- title_scene.lua — pure animation state for the main menu.
--
-- Owns everything that moves on the title screen: the intro timeline (logo
-- letters flying in, hero rising, menu fading up), the ambient life of the
-- desert (shambling silhouettes, tumbleweed, dust motes, twinkling stars,
-- ooze dripping off the logo) and the "draw your gun" flourish played when
-- the player confirms PLAY.
--
-- No love.* here: the drawing lives in src/fw/title_art.lua and reads this
-- state. Every value is a plain number so the whole thing is testable.

local anim  = require("src.core.anim")
local shake = require("src.core.shake")

local title_scene = {}

-- Intro timeline (seconds).
local INTRO_DUR = 1.6

-- Menu plates fly in one after another once the intro is nearly done.
local MENU_START   = 0.74
local MENU_STAGGER = 0.07
local MENU_SLIDE   = 0.26
local MENU_OFFSET  = 160

-- Gun flourish: raise, bang, then hand control back to the caller.
local FIRE_SHOT = 0.22
local FIRE_END  = 0.60
local MUZZLE_DUR = 0.14

local STAR_COUNT     = 60
local SHAMBLER_COUNT = 6
local MOTE_COUNT     = 18
local DRIP_COUNT     = 6

local TUMBLE_SPEED = 0.22

local function clamp01(v)
  if v < 0 then return 0 end
  if v > 1 then return 1 end
  return v
end

local function ease_out(t)
  local u = 1 - clamp01(t)
  return 1 - u * u * u
end

-- Overshoots past 1 before settling, so a plate slides in and snaps back.
local function ease_back(t)
  local u = clamp01(t) - 1
  return u * u * (2.7 * u + 1.7) + 1
end

local function range(rnd, lo, hi)
  return lo + rnd() * (hi - lo)
end

-- ---------------------------------------------------------------------------
-- Construction
-- ---------------------------------------------------------------------------

function title_scene.new(opts)
  opts = opts or {}
  local rnd = opts.rng or math.random

  local self = {
    t          = 0,
    intro      = 0,
    vs_landed  = false,
    fire       = nil,          -- seconds since the flourish started
    idle_anim  = anim.new(2, 2),
    draw_anim  = anim.new(2, 9, { loop = false }),
    shake      = shake.new(),
    stars      = {},
    shamblers  = {},
    motes      = {},
    drips      = {},
    tumbleweed = { x = -0.08, spin = 0, wait = range(rnd, 1.5, 5) },
  }

  for i = 1, STAR_COUNT do
    self.stars[i] = {
      x     = rnd(),
      y     = rnd() * 0.40,
      size  = rnd() < 0.18 and 2 or 1,
      phase = rnd() * 6.28,
      speed = range(rnd, 1.2, 3.4),
    }
  end

  -- Silhouettes shambling along the horizon, half of them heading each way.
  for i = 1, SHAMBLER_COUNT do
    self.shamblers[i] = {
      x     = rnd(),
      dir   = (i % 2 == 0) and 1 or -1,
      speed = range(rnd, 0.010, 0.026),
      lane  = (i % 3),
      bob   = rnd() * 6.28,
    }
  end

  for i = 1, MOTE_COUNT do
    self.motes[i] = {
      x     = rnd(),
      y     = rnd(),
      speed = range(rnd, 0.02, 0.07),
      drift = range(rnd, -0.02, 0.02),
      size  = rnd() < 0.25 and 2 or 1,
    }
  end

  -- Ooze running off the bottom of the ZOMBIES word.
  for i = 1, DRIP_COUNT do
    self.drips[i] = {
      offset = (i - 0.5) / DRIP_COUNT,
      len    = rnd() * 4,
      speed  = range(rnd, 3, 9),
      max    = range(rnd, 5, 13),
    }
  end

  return self
end

-- Rewinds the intro and cancels any flourish in flight.
--
-- The scene object outlives the menu scene, so without this the `fire` timer
-- from the last PLAY is still finished when the player comes back from pause
-- or game over, and `fire_done` sends them straight into the game again.
function title_scene.reset(self)
  self.t = 0
  self.intro = 0
  self.vs_landed = false
  self.fire = nil
  anim.restart(self.idle_anim)
  anim.restart(self.draw_anim)
  self.shake = shake.new()
  return self
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------

local function update_tumbleweed(tw, dt, rnd)
  if tw.wait > 0 then
    tw.wait = tw.wait - dt
    return
  end
  tw.x = tw.x + TUMBLE_SPEED * dt
  tw.spin = tw.spin + dt * 7
  if tw.x > 1.12 then
    tw.x = -0.08
    tw.wait = range(rnd, 4, 11)
  end
end

function title_scene.update(self, dt, rnd)
  rnd = rnd or math.random
  self.t = self.t + dt
  self.intro = math.min(1, self.intro + dt / INTRO_DUR)

  anim.update(self.idle_anim, dt)
  shake.update(self.shake, dt)

  -- the VS badge lands with a thump
  if not self.vs_landed and self.intro >= 0.70 then
    self.vs_landed = true
    shake.add(self.shake, 0.42)
  end

  if self.fire then
    local was = self.fire
    self.fire = self.fire + dt
    anim.update(self.draw_anim, dt)
    if was < FIRE_SHOT and self.fire >= FIRE_SHOT then
      shake.add(self.shake, 0.75)
    end
  end

  for _, s in ipairs(self.shamblers) do
    s.x = s.x + s.dir * s.speed * dt
    if s.x > 1.08 then s.x = -0.08 end
    if s.x < -0.08 then s.x = 1.08 end
  end

  for _, m in ipairs(self.motes) do
    m.y = m.y - m.speed * dt
    m.x = m.x + m.drift * dt
    if m.y < 0 then
      m.y = 1
      m.x = rnd()
    end
  end

  for _, d in ipairs(self.drips) do
    d.len = d.len + d.speed * dt
    if d.len > d.max then
      d.len = 0
    end
  end

  update_tumbleweed(self.tumbleweed, dt, rnd)
  return self
end

-- ---------------------------------------------------------------------------
-- Gun flourish
-- ---------------------------------------------------------------------------

-- Starts the draw-and-fire flourish. Returns false when one is already running.
function title_scene.start_fire(self)
  if self.fire then
    return false
  end
  self.fire = 0
  anim.restart(self.draw_anim)
  return true
end

function title_scene.firing(self)
  return self.fire ~= nil
end

-- True once the flourish has played out and the caller may change scene.
function title_scene.fire_done(self)
  return self.fire ~= nil and self.fire >= FIRE_END
end

-- Which atlas set and frame the hero shows right now.
function title_scene.hero_frame(self)
  if self.fire then
    return "hero_draw", self.fire < FIRE_SHOT and 1 or 2
  end
  return "hero_idle", self.idle_anim.frame
end

-- Muzzle flash intensity, 0..1.
function title_scene.muzzle(self)
  if not self.fire or self.fire < FIRE_SHOT then
    return 0
  end
  return clamp01(1 - (self.fire - FIRE_SHOT) / MUZZLE_DUR)
end

-- ---------------------------------------------------------------------------
-- Derived layout (pure functions of t / intro)
-- ---------------------------------------------------------------------------

-- Logo transform for the box-art block in the top right: COWBOY slams down
-- from above the frame, ZOMBIES slides in from the right under it, and the VS
-- badge punches in on top. Everything keeps a slow counter-sway afterwards.
function title_scene.logo(self)
  local p = self.intro
  local a = ease_out(p / 0.40)
  local b = ease_out((p - 0.14) / 0.42)
  local c = clamp01((p - 0.42) / 0.28)
  local sway = math.sin(self.t * 1.5)
  return {
    cowboy_dx  = -30 * (1 - a),
    cowboy_dy  = -120 * (1 - a) + sway * 1.2,
    zombies_dx = 260 * (1 - b),
    zombies_dy = -sway * 1.2,
    vs_scale   = 1 + 3.5 * (1 - ease_out(c)),
    vs_alpha   = c,
    alpha      = clamp01(p / 0.18),
  }
end

-- Hero rises into frame and keeps breathing once the intro is over.
--
-- `bob` is the one-pixel breath of the whole bust: the portrait is a single
-- frame, so the movement is in the offset rather than in the art.
function title_scene.hero(self)
  local p = ease_out((self.intro - 0.22) / 0.5)
  return {
    dy    = 34 * (1 - p),
    bob   = math.sin(self.t * 1.8) < 0 and 1 or 0,
    alpha = p,
    glow  = 0.55 + 0.45 * math.sin(self.t * 2.1),
  }
end

function title_scene.menu_alpha(self)
  return clamp01((self.intro - MENU_START) / (1 - MENU_START))
end

-- Per-item slide-in: each plate leaves later than the one above it and
-- overshoots slightly on arrival. Returns `count` entries of { dx, alpha }.
--
-- Timed off `t` rather than `intro`, because the stagger runs past the end of
-- the intro -- keyed to `intro` the last plate would freeze mid-flight when
-- the intro clamps at 1.
function title_scene.menu_items(self, count)
  local out = {}
  for i = 1, count do
    local start = MENU_START * INTRO_DUR + (i - 1) * MENU_STAGGER
    local p = clamp01((self.t - start) / MENU_SLIDE)
    out[i] = {
      dx    = MENU_OFFSET * (1 - ease_back(p)),
      alpha = clamp01(p * 1.6),
    }
  end
  return out
end

-- Screen offset for the current trauma; rng is injectable for tests.
function title_scene.shake_offset(self, rnd)
  return shake.offset(self.shake, rnd)
end

return title_scene
