local upgrades = {}

local POOL = {
  { id = "damage",  label = "SHARPSHOOTER", desc = "+1 damage",
    apply = function(p) p.damage = p.damage + 1 end },
  { id = "heart",   label = "IRON HEART",   desc = "+1 max HP and heal",
    apply = function(p) p.max_hp = p.max_hp + 1; p.hp = math.min(p.max_hp, p.hp + 1) end },
  { id = "deadeye", label = "DEADEYE",      desc = "Fire faster",
    apply = function(p) p.fire_interval = p.fire_interval * 0.75 end },
  { id = "boom",    label = "HEAVY SHOT",   desc = "Bigger bullets",
    apply = function(p) p.bullet_radius = p.bullet_radius + 1 end },
}

function upgrades.pool()
  return POOL
end

function upgrades.choose(pool, count, rng)
  local r = rng or math.random
  local copy = {}
  for _, u in ipairs(pool) do
    table.insert(copy, u)
  end
  local picked = {}
  for _ = 1, math.min(count, #copy) do
    table.insert(picked, table.remove(copy, r(#copy)))
  end
  return picked
end

function upgrades.apply(def, player)
  def.apply(player)
end

return upgrades