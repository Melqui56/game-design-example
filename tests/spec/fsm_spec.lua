local fsm = require("src.core.fsm")

describe("fsm", function()
  it("calls enter when entering a state and exit when leaving", function()
    local calls = {}
    local states = {
      idle = {},
      run  = {
        enter = function() table.insert(calls, "run.enter") end,
        exit  = function() table.insert(calls, "run.exit") end,
      },
      done = {},
    }
    local machine = fsm.new(states, "idle")
    fsm.change(machine, "run")
    fsm.change(machine, "done")
    assert.are.same({ "run.enter", "run.exit" }, calls)
  end)

  it("updates only the current state, passing the owner", function()
    local seen = nil
    local owner = { name = "hero" }
    local states = {
      idle = { update = function(o, _dt) seen = o end },
    }
    local machine = fsm.new(states, "idle", owner)
    fsm.update(machine, 0.1)
    assert.are.equal(owner, seen)
  end)

  it("ignores changing to the current state", function()
    local enters = 0
    local states = {
      idle = {},
      run  = { enter = function() enters = enters + 1 end },
    }
    local machine = fsm.new(states, "idle")
    fsm.change(machine, "run")
    fsm.change(machine, "run")
    assert.are.equal(1, enters)
  end)

  it("errors on an unknown state", function()
    local machine = fsm.new({ idle = {} }, "idle")
    local ok = pcall(fsm.change, machine, "nope")
    assert.is_false(ok)
  end)
end)