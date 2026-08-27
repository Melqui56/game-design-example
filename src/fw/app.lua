local scene_manager       = require("src.fw.scene_manager")
local title_controller    = require("src.game.title_controller")
local play_controller     = require("src.game.play_controller")
local gameover_controller = require("src.game.gameover_controller")
local hotreload           = require("src.fw.hotreload")

local app = {}

function app.new()
  return setmetatable({
    scenes = scene_manager.new(),
  }, { __index = app })
end

function app.load(self)
  self.hotreload = hotreload.setup()
  self.scenes:add("title",    title_controller.new(self.scenes))
  self.scenes:add("play",     play_controller.new(self.scenes))
  self.scenes:add("gameover", gameover_controller.new(self.scenes))
  self.scenes:switch("title")
end

function app.update(self, dt)
  if self.hotreload then
    hotreload.tick()
  end
  self.scenes:update(dt)
end

function app.draw(self)
  self.scenes:draw()
end

function app.keypressed(self, key)
  self.scenes:keypressed(key)
end

return app