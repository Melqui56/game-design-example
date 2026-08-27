local pickup = require("src.core.pickup")
local upgrades = require("src.core.upgrades")

describe("pickup", function()
  it("expires after its lifetime", function()
    local pk = pickup.new(upgrades.pool()[1], 0, 0)
    pickup.update(pk, 5)
    assert.is_false(pk.dead)
    pickup.update(pk, 20)
    assert.is_true(pk.dead)
  end)

  it("is collected when the player touches it", function()
    local pk = pickup.new(upgrades.pool()[1], 0, 0)
    local player = { position = { x = 6, y = 0 }, radius = 12 }
    assert.is_true(pickup.touches(pk, player))
  end)

  it("is not collected when far away", function()
    local pk = pickup.new(upgrades.pool()[1], 0, 0)
    local player = { position = { x = 60, y = 0 }, radius = 12 }
    assert.is_false(pickup.touches(pk, player))
  end)
end)