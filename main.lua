local App = require("src.fw.app")

local app = App.new()

function love.load()
  app:load()
end

function love.update(dt)
  app:update(dt)
end

function love.draw()
  app:draw()
end

function love.keypressed(key)
  app:keypressed(key)
end