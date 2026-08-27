local particles = require("src.core.particles")
local shake     = require("src.core.shake")

local function stub_rng(_n)
  return 1
end

describe("particles", function()
  it("emits the requested number of particles at a point", function()
    local sys = particles.new()
    particles.burst(sys, 10, 20, { count = 6 }, stub_rng)
    assert.are.equal(6, #sys.list)
    for _, p in ipairs(sys.list) do
      assert.are.equal(10, p.x)
      assert.are.equal(20, p.y)
    end
  end)

  it("moves particles over time", function()
    local sys = particles.new()
    particles.burst(sys, 0, 0, { count = 1, speed_min = 100, speed_max = 100, life = 1 }, stub_rng)
    local before = sys.list[1].x
    particles.update(sys, 0.1)
    assert.is_true(sys.list[1].x ~= before)
  end)

  it("removes particles once their lifetime expires", function()
    local sys = particles.new()
    particles.burst(sys, 0, 0, { count = 3, life = 0.05 }, stub_rng)
    particles.update(sys, 0.1)
    assert.are.equal(0, #sys.list)
  end)
end)

describe("shake", function()
  it("caps trauma at 1", function()
    local s = shake.new()
    shake.add(s, 10)
    assert.are.equal(1, s.trauma)
  end)

  it("decays trauma over time", function()
    local s = shake.new()
    shake.add(s, 1)
    shake.update(s, 0.4)
    assert.is_true(s.trauma < 1)
  end)

  it("returns zero offset with no trauma", function()
    local off = shake.offset(shake.new(), stub_rng)
    assert.are.equal(0, off.x)
    assert.are.equal(0, off.y)
  end)

  it("returns bounded integer offsets when shaken", function()
    local s = shake.new()
    shake.add(s, 1)
    local off = shake.offset(s, stub_rng)
    assert.are.equal(-6, off.x)
    assert.are.equal(-6, off.y)
  end)
end)