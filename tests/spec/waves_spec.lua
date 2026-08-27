local waves = require("src.core.waves")

local function top_rng(_n)
  return 1
end

describe("waves.plan", function()
  it("spawns 3 chasers on wave 1", function()
    local events = waves.plan(1, { minX = 0, minY = 0, maxX = 960, maxY = 540 }, top_rng)
    assert.are.equal(3, #events)
    for _, ev in ipairs(events) do
      assert.are.equal("chaser", ev.kind)
    end
  end)

  it("scales the count with the wave number", function()
    local w1 = waves.plan(1, nil, top_rng)
    local w3 = waves.plan(3, nil, top_rng)
    assert.is_true(#w3 > #w1)
  end)

  it("schedules the first spawn at time 0 and the rest staggered", function()
    local events = waves.plan(1, nil, top_rng)
    assert.are.equal(0, events[1].time)
    assert.is_true(events[2].time > events[1].time)
    assert.is_true(events[3].time > events[2].time)
  end)

  it("spawns at the edges, outside the arena", function()
    local events = waves.plan(1, { minX = 10, minY = 10, maxX = 100, maxY = 100 }, top_rng)
    for _, ev in ipairs(events) do
      assert.is_true(ev.y < 10)
      assert.are.equal(11, ev.x)
    end
  end)
end)