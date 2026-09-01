local menu        = require("src.core.menu")
local retro       = require("src.fw.retro")
local title_scene = require("src.core.title_scene")
local title_art   = require("src.fw.title_art")
local save_io     = require("src.fw.save_io")
local sfx         = require("src.fw.sfx")

local main_menu = {}

function main_menu.new(sm)
  return setmetatable({
    sm    = sm,
    menu  = menu.new({ "Play", "How to Play", "Quit" }),
    scene = title_scene.new(),
    help  = false,
  }, { __index = main_menu })
end

function main_menu.enter(self)
  retro.reset_offset()
  -- the scene object outlives the scene, so rewind it or the finished
  -- flourish from the last PLAY drops us straight back into the game
  title_scene.reset(self.scene)
  self.help = false
end

function main_menu.update(self, dt)
  title_scene.update(self.scene, dt)
  menu.update(self.menu, dt)
  if title_scene.fire_done(self.scene) then
    self.sm:switch("play")
  end
end

function main_menu.draw(self)
  local alpha = title_scene.menu_alpha(self.scene)

  title_art.background(self.scene)
  title_art.slant(self.scene, alpha)
  title_art.logo(self.scene)
  title_art.hero(self.scene)
  title_art.menu(self.menu, self.scene, alpha)
  title_art.footer(save_io.get("high_score", 0), "v0.1.0", alpha)
  title_art.vignette()

  if self.help then
    title_art.help()
  end

  local off = title_scene.shake_offset(self.scene)
  retro.set_offset(off.x, off.y)
end

function main_menu.keypressed(self, key)
  if self.help then
    if key == "escape" or key == "return" or key == "kpenter" then
      self.help = false
      sfx.play("ui", 0.3)
    end
    return
  end

  if title_scene.firing(self.scene) then
    return
  end

  if key == "up" then
    menu.move(self.menu, -1)
    sfx.play("ui", 0.3)
  elseif key == "down" then
    menu.move(self.menu, 1)
    sfx.play("ui", 0.3)
  elseif key == "return" or key == "kpenter" then
    sfx.play("ui", 0.3)
    local choice = menu.current(self.menu)
    if choice == "Play" then
      title_scene.start_fire(self.scene)
    elseif choice == "How to Play" then
      self.help = true
    else
      love.event.quit()
    end
  elseif key == "escape" then
    self.help = true
  end
end

return main_menu