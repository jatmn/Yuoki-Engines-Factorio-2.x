-- luacheck: globals script game storage prototypes
script.on_init(function()
  storage.quality = prototypes.quality.rare and "rare" or "normal"
  game.create_force("fatmice-regression")
  for _, name in ipairs({ "player", "fatmice-regression" }) do
    game.forces[name].recipes["wooden-chest"].enabled = false
  end
  storage.machine = game.surfaces[1].create_entity({
    name = "y-electric-air-heater",
    position = { 0, 0 },
    force = "player",
    quality = storage.quality,
  })
  storage.machine.disabled_by_script = true
  storage.machine.set_recipe("y-rmvpol", storage.quality)
  storage.fluids = {}
  for index = 1, 2 do
    local fluid = storage.machine.get_fluid_filter(index).name
    assert(fluid == "water" or fluid == "y-mechanical-force")
    local amount = fluid == "water" and 50 or 0.5
    assert(storage.machine.set_fluid(index, { name = fluid, amount = amount }) == amount)
    storage.fluids[index] = storage.machine.get_fluid(index)
  end
  assert(
    storage.machine.get_output_inventory().insert({ name = "y-pol-waste", count = 7, quality = storage.quality }) == 7
  )
  log("FATMICE_SAVE_SEEDED")
end)

script.on_configuration_changed(function(event)
  for _, name in ipairs({ "player", "fatmice-regression" }) do
    local force = game.forces[name]
    assert(
      force.recipes["y-rmvpol"].enabled == not settings.startup["j_fatmice_behaviour"].value,
      "Saved Fatmice recipe availability must follow the setting"
    )
    -- Startup changes may reset flags before this callback; compare unchanged settings only.
    if not event.mod_startup_settings_changed then
      assert(not force.recipes["wooden-chest"].enabled, "Do not reset unrelated recipes")
    end
  end
  local machine = storage.machine
  local recipe, quality = machine.get_recipe()
  assert(recipe.name == "y-rmvpol" and quality.name == storage.quality, "Existing selected recipe must survive")
  assert(machine.quality.name == storage.quality, "Machine quality must survive")
  assert(
    machine.get_output_inventory().get_item_count({ name = "y-pol-waste", quality = storage.quality }) == 7,
    "Stored item counts and quality must survive"
  )
  for index, fluid in ipairs(storage.fluids) do
    local contents = machine.get_fluid(index)
    assert(
      contents
        and contents.name == fluid.name
        and contents.amount == fluid.amount
        and contents.temperature == fluid.temperature,
      "Stored fluid must survive"
    )
  end
  log("FATMICE_SAVE_PASSED")
end)
