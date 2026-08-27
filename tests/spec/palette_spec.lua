local palette = require("src.core.palette")

local REQUIRED = {
  "night", "dusk", "panel", "player", "accent",
  "enemy", "danger", "text", "muted", "star", "eye", "outline", "shadow",
  "skin", "hat", "bandana", "denim", "boot",
  "zombie", "zombie_dark", "mouth", "muzzle",
  "cactus", "rock", "skull", "bush",
}

describe("palette", function()
  it("defines every required color", function()
    for _, name in ipairs(REQUIRED) do
      assert.is_not_nil(palette[name], "missing color: " .. name)
    end
  end)

  it("stores RGB triples in the 0..1 range", function()
    for name, color in pairs(palette) do
      assert.are.equal(3, #color, "color must be RGB: " .. name)
      for _, channel in ipairs(color) do
        assert.is_true(channel >= 0 and channel <= 1)
      end
    end
  end)
end)