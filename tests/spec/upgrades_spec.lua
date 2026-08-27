local upgrades = require("src.core.upgrades")

local function stub_rng(_n)
  return 1
end

describe("upgrades", function()
  it("offers distinct choices", function()
    local picks = upgrades.choose(upgrades.pool(), 3, stub_rng)
    assert.are.equal(3, #picks)
    local seen = {}
    for _, u in ipairs(picks) do
      assert.is_nil(seen[u.id])
      seen[u.id] = true
    end
  end)

  it("applies an upgrade to the player", function()
    local p = { damage = 1, max_hp = 3, hp = 3 }
    local picks = upgrades.choose(upgrades.pool(), 1, stub_rng)
    upgrades.apply(picks[1], p)
    assert.is_true(p.damage > 1 or p.max_hp > 3 or p.hp > 3)
  end)

  it("never offers more choices than the pool size", function()
    local picks = upgrades.choose(upgrades.pool(), 99, stub_rng)
    assert.is_true(#picks <= #upgrades.pool())
  end)
end)