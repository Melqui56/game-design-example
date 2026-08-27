local enemy = require("src.core.enemy")

describe("enemy", function()
  it("moves toward the target by speed * dt", function()
    local e = enemy.new("chaser", 0, 0)
    enemy.update(e, { x = 200, y = 0 }, 1)
    assert.are.near(90, e.position.x, 0.001)
    assert.are.near(0, e.position.y, 0.001)
  end)

  it("snaps to the target when close instead of overshooting", function()
    local e = enemy.new("chaser", 0, 0)
    enemy.update(e, { x = 30, y = 0 }, 1)
    assert.are.equal(30, e.position.x)
    assert.are.equal(0, e.position.y)
  end)

  it("keeps chasing after reaching the target", function()
    local e = enemy.new("chaser", 0, 0)
    local target = { x = 30, y = 0 }
    enemy.update(e, target, 1)
    target.x = 60
    enemy.update(e, target, 1)
    assert.are.equal(60, e.position.x)
  end)

  it("reports death only after hp reaches zero", function()
    local e = enemy.new("chaser", 0, 0, { hp = 2 })
    assert.is_true(enemy.take_damage(e, 1))
    assert.are.equal("chase", e.fsm.current)
    assert.is_true(enemy.take_damage(e, 1))
    assert.are.equal("dying", e.fsm.current)
    assert.is_false(enemy.take_damage(e, 1))
  end)

  it("marks itself dead once the dying timer expires", function()
    local e = enemy.new("chaser", 0, 0, { hp = 1 })
    enemy.take_damage(e, 1)
    enemy.update(e, { x = 0, y = 0 }, 0.5)
    assert.is_true(e.dead)
  end)

  it("detects circular contact with another body", function()
    local e = enemy.new("chaser", 0, 0)
    local other = { position = { x = 20, y = 0 }, radius = 10 }
    assert.is_true(enemy.touches(e, other))
    other.position.x = 60
    assert.is_false(enemy.touches(e, other))
  end)
end)