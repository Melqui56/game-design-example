local title_scene = require("src.core.title_scene")

local function fixed_rng(_n)
  return 0.5
end

describe("title_scene", function()
  it("starts with the logo hidden (intro 0)", function()
    local s = title_scene.new({ rng = fixed_rng })
    assert.are.equal(0, s.intro)
    local l = title_scene.logo(s)
    assert.are.equal(0, l.alpha)
  end)

  it("intro eases to 1 over time", function()
    local s = title_scene.new({ rng = fixed_rng })
    title_scene.update(s, 1.6, fixed_rng)
    assert.are.near(1, s.intro, 0.001)
  end)

  it("plays the idle hero set before firing", function()
    local s = title_scene.new({ rng = fixed_rng })
    local set = title_scene.hero_frame(s)
    assert.are.equal("hero_idle", set)
  end)

  it("switches to the draw set while firing", function()
    local s = title_scene.new({ rng = fixed_rng })
    assert.is_true(title_scene.start_fire(s))
    local set = title_scene.hero_frame(s)
    assert.are.equal("hero_draw", set)
  end)

  it("ignores a second start_fire while one is running", function()
    local s = title_scene.new({ rng = fixed_rng })
    title_scene.start_fire(s)
    assert.is_false(title_scene.start_fire(s))
  end)

  it("reports the flourish finished after FIRE_END", function()
    local s = title_scene.new({ rng = fixed_rng })
    title_scene.start_fire(s)
    title_scene.update(s, 0.7, fixed_rng)
    assert.is_true(title_scene.fire_done(s))
  end)

  it("muzzle flash peaks after the shot and fades", function()
    local s = title_scene.new({ rng = fixed_rng })
    title_scene.start_fire(s)
    assert.are.equal(0, title_scene.muzzle(s))
    title_scene.update(s, 0.25, fixed_rng)
    assert.is_true(title_scene.muzzle(s) > 0)
    title_scene.update(s, 0.6, fixed_rng)
    assert.are.equal(0, title_scene.muzzle(s))
  end)

  it("menu fades in after the intro", function()
    local s = title_scene.new({ rng = fixed_rng })
    title_scene.update(s, 1.6, fixed_rng)
    assert.is_true(title_scene.menu_alpha(s) > 0.99)
  end)
end)

describe("title_scene reset", function()
  local function rng(_n) return 0.5 end

  it("cancels a finished flourish so the menu does not bounce into play", function()
    local s = title_scene.new({ rng = rng })
    title_scene.start_fire(s)
    title_scene.update(s, 0.7, rng)
    assert.is_true(title_scene.fire_done(s))
    title_scene.reset(s)
    assert.is_false(title_scene.fire_done(s))
    assert.is_false(title_scene.firing(s))
  end)

  it("rewinds the intro", function()
    local s = title_scene.new({ rng = rng })
    title_scene.update(s, 2, rng)
    assert.are.equal(1, s.intro)
    title_scene.reset(s)
    assert.are.equal(0, s.intro)
  end)
end)

describe("title_scene menu_items", function()
  local function rng(_n) return 0.5 end

  it("holds every plate offscreen until the intro is nearly done", function()
    local s = title_scene.new({ rng = rng })
    local items = title_scene.menu_items(s, 3)
    assert.are.equal(3, #items)
    for _, it in ipairs(items) do
      assert.are.equal(0, it.alpha)
      assert.is_true(it.dx > 100)
    end
  end)

  it("staggers them, later plates trailing the earlier ones", function()
    local s = title_scene.new({ rng = rng })
    title_scene.update(s, 1.6 * 0.80, rng)
    local items = title_scene.menu_items(s, 3)
    assert.is_true(items[1].alpha > items[2].alpha)
    assert.is_true(items[2].alpha >= items[3].alpha)
  end)

  it("settles every plate in place once the intro is over", function()
    local s = title_scene.new({ rng = rng })
    title_scene.update(s, 3, rng)
    for _, it in ipairs(title_scene.menu_items(s, 3)) do
      assert.are.equal(1, it.alpha)
      assert.are.equal(0, it.dx)
    end
  end)
end)
