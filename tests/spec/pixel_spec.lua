local pixel = require("scripts.pixel")

describe("pixel", function()
  describe("rgb/hsl round-trip", function()
    it("round-trips a mid color", function()
      local h, s, l = pixel.rgb_to_hsl(0.5, 0.3, 0.7)
      local r, g, b = pixel.hsl_to_rgb(h, s, l)
      assert.is_true(math.abs(r - 0.5) < 0.001)
      assert.is_true(math.abs(g - 0.3) < 0.001)
      assert.is_true(math.abs(b - 0.7) < 0.001)
    end)

    it("handles gray (zero saturation)", function()
      local h, s, l = pixel.rgb_to_hsl(0.4, 0.4, 0.4)
      assert.are.equal(0, s)
      local r, g, b = pixel.hsl_to_rgb(h, s, l)
      assert.is_true(math.abs(r - 0.4) < 0.001)
      assert.is_true(math.abs(g - 0.4) < 0.001)
      assert.is_true(math.abs(b - 0.4) < 0.001)
    end)
  end)

  describe("make_ramp", function()
    it("produces 5 steps with step 3 equal to the base color", function()
      local base = { 0.5, 0.4, 0.3 }
      local ramp = pixel.make_ramp(base)
      assert.are.equal(5, #ramp)
      for _, c in ipairs(ramp) do
        assert.are.equal(3, #c)
      end
      assert.is_true(math.abs(ramp[3][1] - base[1]) < 0.001)
      assert.is_true(math.abs(ramp[3][2] - base[2]) < 0.001)
      assert.is_true(math.abs(ramp[3][3] - base[3]) < 0.001)
    end)

    it("darkens lower steps and brightens higher steps", function()
      local ramp = pixel.make_ramp({ 0.5, 0.5, 0.5 })
      local l1 = (ramp[1][1] + ramp[1][2] + ramp[1][3]) / 3
      local l5 = (ramp[5][1] + ramp[5][2] + ramp[5][3]) / 3
      assert.is_true(l1 < 0.5)
      assert.is_true(l5 > 0.5)
    end)
  end)

  describe("shade_step", function()
    it("is brightest at the top-left", function()
      assert.are.equal(5, pixel.shade_step(12, 13, 1, 1))
    end)

    it("is darkest at the bottom-right", function()
      assert.are.equal(1, pixel.shade_step(12, 13, 12, 13))
    end)

    it("is monotonic along the main diagonal (away from top-left light)", function()
      local prev = pixel.shade_step(12, 13, 1, 1)
      for i = 2, 12 do
        local s = pixel.shade_step(12, 13, i, i)
        assert.is_true(s >= 1 and s <= 5)
        assert.is_true(s <= prev, "step must not increase moving away from light")
        prev = s
      end
    end)

    it("handles 1x1 without dividing by zero (returns base step)", function()
      assert.are.equal(3, pixel.shade_step(1, 1, 1, 1))
    end)
  end)
end)