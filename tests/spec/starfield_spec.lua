local starfield = require("src.core.starfield")

local function stub_rng(_n)
  return 1
end

describe("starfield", function()
  it("spawns the requested number of stars", function()
    local s = starfield.new(50, stub_rng)
    assert.are.equal(50, #s.stars)
  end)

  it("moves stars downward over time", function()
    local s = starfield.new(1, stub_rng)
    local before = s.stars[1].y
    starfield.update(s, 0.5)
    assert.is_true(s.stars[1].y > before)
  end)

  it("wraps stars back to the top after crossing the bottom", function()
    local s = starfield.new(1, stub_rng)
    s.stars[1].y = 0.99
    starfield.update(s, 0.5 / s.stars[1].speed)
    assert.is_true(s.stars[1].y < 0.99)
  end)

  it("keeps star coordinates in the unit range", function()
    local s = starfield.new(20, stub_rng)
    starfield.update(s, 1)
    for _, star in ipairs(s.stars) do
      assert.is_true(star.x >= 0 and star.x <= 1)
      assert.is_true(star.y >= 0 and star.y <= 1)
    end
  end)
end)