-- luacheck: globals script game storage prototypes
local shafts = {
  { "y-shaft", "y-mftrans-shaft" },
  { "y-shaft-r", "y-mftrans-shaft-red" },
  { "y-shaft-ground", "y-mftrans-shaft-ground" },
  { "y-shaft-ground-r", "y-mftrans-shaft-ground-red" },
}

script.on_init(function()
  local surface = game.surfaces[1]
  storage.machines = {}
  storage.chest = surface.create_entity({ name = "steel-chest", position = { 0, 8 }, force = "player" })
  for index, names in ipairs(shafts) do
    local legacy = prototypes.recipe[names[1] .. "-recipe"] and names[1] .. "-recipe" or names[1]
    assert(prototypes.recipe[legacy], "Seed must contain the historical recipe: " .. legacy)
    local entity = surface.create_entity({
      name = "assembling-machine-3",
      position = { index * 5, 0 },
      force = "player",
      quality = "rare",
    })
    entity.set_recipe(legacy, "rare")
    assert(entity.get_recipe().name == legacy)
    storage.machines[index] = entity
    assert(storage.chest.insert({ name = names[2], quality = "rare", count = index + 7 }) == index + 7)
  end
  log("SHAFT_MIGRATION_SEED_READY")
end)

script.on_configuration_changed(function()
  for index, names in ipairs(shafts) do
    local entity = storage.machines[index]
    assert(entity.valid and entity.quality.name == "rare", "Machine quality changed")
    local recipe, quality = entity.get_recipe()
    assert(recipe and recipe.name == names[2], "Lost shaft recipe: " .. names[2])
    assert(quality.name == "rare", "Recipe quality changed: " .. names[2])
    assert(storage.chest.get_item_count({ name = names[2], quality = "rare" }) == index + 7, "Rare shaft count changed")
    assert(storage.chest.get_item_count({ name = names[2], quality = "normal" }) == 0, "Shaft quality changed")
  end
  log("SHAFT_MIGRATION_PASSED")
end)
