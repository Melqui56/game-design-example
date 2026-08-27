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

describe("map.town", function()
  it("places buildings inside the world", function()
    local area = { minX = 0, minY = 0, maxX = 960, maxY = 540 }
    local buildings = map.town(area, 8, stub_rng)
    assert.are.equal(8, #buildings)
    for _, b in ipairs(buildings) do
      assert.is_true(b.x >= area.minX and b.x <= area.maxX)
      assert.is_true(b.y >= area.minY and b.y <= area.maxY)
      assert.is_true(b.w > 0 and b.h > 0)
    end
  end)
end)