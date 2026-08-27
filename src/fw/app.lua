local scene_manager       = require("src.fw.scene_manager")
local main_menu_controller = require("src.game.main_menu_controller")
local play_controller     = require("src.game.play_controller")
local pause_controller    = require("src.game.pause_controller")
local gameover_controller = require("src.game.gameover_controller")
local hotreload           = require("src.fw.hotreload")
local retro               = require("src.fw.retro")
local save_io             = require("src.fw.save_io")
local sfx                 = require("src.fw.sfx")

local app = {}

function app.new()
  return setmetatable({
    scenes = scene_manager.new(),
  }, { __index = app })
end

function app.load(self)
  self.hotreload = hotreload.setup()
  sfx.init()
  save_io.load()
  self.scenes:add("menu",     main_menu_controller.new(self.scenes))
  self.scenes:add("play",     play_controller.new(self.scenes))
  self.scenes:add("pause",    pause_controller.new(self.scenes))
  self.scenes:add("gameover", gameover_controller.new(self.scenes))
  self.scenes:switch("menu")
end

function app.update(self, dt)
  if self.hotreload then
    hotreload.tick()
  end
  self.scenes:update(dt)
end

function app.draw(self)
  retro.begin()
  self.scenes:draw()
  retro.finish()
end

function app.keypressed(self, key)
  self.scenes:keypressed(key)
end

return app