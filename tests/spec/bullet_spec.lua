local bullet = require("src.core.bullet")
local vec2   = require("src.core.vec2")

describe("bullet", function()
  it("normalizes its direction", function()
    local b = bullet.new(0, 0, { x = 1, y = 1 })
    local len = vec2.length(b.dir)
    assert.are.near(1, len, 0.0001)
  end)

  it("moves at speed * dt along its direction", function()
    local b = bullet.new(0, 0, { x = 1, y = 0 }, { speed = 100 })
    bullet.update(b, 1)
    assert.are.near(100, b.position.x, 0.0001)
    assert.are.equal(0, b.position.y)
  end)

  it("marks itself dead outside the bounds", function()
    local b = bullet.new(0, 0, { x = -1, y = 0 }, { speed = 100 })
    bullet.update(b, 1, { minX = 0, minY = 0, maxX = 100, maxY = 100 })
    assert.is_true(b.dead)
  end)

  it("touches a nearby body and misses a far one", function()
    local b = bullet.new(0, 0, { x = 1, y = 0 })
    local near = { position = { x = 10, y = 0 }, radius = 14 }
    local far  = { position = { x = 40, y = 0 }, radius = 14 }
    assert.is_true(bullet.touches(b, near))
    assert.is_false(bullet.touches(b, far))
  end)
end)