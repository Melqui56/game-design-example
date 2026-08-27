local map = require("src.core.map")

local function stub_rng(_n)
  return 1
end

describe("map", function()
  it("places the requested number of props", function()
    local area = { minX = 0, minY = 0, maxX = 480, maxY = 270 }
    local props = map.decorate(area, 14, stub_rng)
    assert.are.equal(14, #props)
  end)

  it("keeps props inside the arena", function()
    local area = { minX = 0, minY = 0, maxX = 480, maxY = 270 }
    for _, prop in ipairs(map.decorate(area, 30, stub_rng)) do
      assert.is_true(prop.x >= area.minX and prop.x <= area.maxX)
      assert.is_true(prop.y >= area.minY and prop.y <= area.maxY)
    end
  end)

  it("uses only known prop kinds", function()
    local area = { minX = 0, minY = 0, maxX = 480, maxY = 270 }
    for _, prop in ipairs(map.decorate(area, 30, stub_rng)) do
      assert.is_true(prop.kind == "cactus" or prop.kind == "rock"
        or prop.kind == "skull" or prop.kind == "bush")
    end
  end)
end)