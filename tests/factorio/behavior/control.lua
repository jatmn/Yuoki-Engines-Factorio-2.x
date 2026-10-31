-- luacheck: globals script game prototypes
local failures = {}
local generators = {}
local winding
local winding_count = 0
local function check(condition, message)
  if not condition then
    failures[#failures + 1] = message
    log("FAIL: " .. message)
  end
end

script.on_init(function()
  local surface = game.surfaces[1]
  surface.request_to_generate_chunks({ 0, 0 }, 5)
  surface.force_generate_chunk_requests()
  local quality = prototypes.quality.rare and "rare" or "normal"
  for index, name in ipairs({ "ye_smoker", "ye_dnasplicer" }) do
    local entity = surface.create_entity({ name = name, position = { index * 10, -15 }, force = "player" })
    local inventory = entity.get_module_inventory()
    check(inventory and #inventory == 2, name .. " must have two module slots")
    if inventory then
      check(inventory.insert({ name = "speed-module", count = 2, quality = quality }) == 2, name .. " accepts modules")
      check(
        inventory.get_item_count({ name = "speed-module", quality = quality }) == 2,
        name .. " preserves module quality"
      )
    end
  end

  for _, name in ipairs({
    "y-iron-case",
    "y-quantrinum-charge",
    "ye_center",
    "ye_sealing",
    "y-winding",
    "yie_pureiron",
    "yie_hard_metals",
    "ye_buechsenblech",
  }) do
    check(prototypes.recipe[name].allowed_effects.productivity, name .. " must allow productivity")
  end
  winding = surface.create_entity({ name = "assembling-machine-3", position = { 0, 0 }, force = "player" })
  winding.set_recipe("y-winding")
  local inventory = winding.get_module_inventory()
  check(
    inventory.insert({ name = "productivity-module", count = 1 }) == 1,
    "Listed recipe accepts vanilla productivity"
  )
  inventory.clear()
  check(inventory.insert({ name = "y_modul_science", count = 1 }) == 1, "Listed recipe accepts Yuoki productivity")
  winding.insert({ name = "iron-plate", count = 20 })
  winding.insert({ name = "copper-cable", count = 140 })
  local source = surface.create_entity({ name = "electric-energy-interface", position = { 0, 6 }, force = "player" })
  source.power_production = 1000000000
  source.power_usage = 0
  surface.create_entity({ name = "substation", position = { 5, 3 }, force = "player" })

  local negative = surface.create_entity({ name = "assembling-machine-3", position = { -10, 0 }, force = "player" })
  negative.set_recipe("wooden-chest")
  check(
    negative.get_module_inventory().insert({ name = "productivity-module", count = 1 }) == 0,
    "Unlisted recipe still rejects vanilla productivity"
  )
  -- This category exists only with the parent's unrestricted-productivity fix.
  if prototypes.item["y_modul_science"].category == "yuoki-unrestricted-productivity" then
    check(
      negative.get_module_inventory().insert({ name = "y_modul_science", count = 1 }) == 1,
      "Unrestricted Yuoki productivity remains usable on unlisted recipes"
    )
  end

  local overhaul = settings.startup["j_fatmice_behaviour"].value
  check(game.forces.player.recipes["y-rmvpol"].enabled == not overhaul, "Fatmice recipe availability follows setting")
  if overhaul then
    check(game.forces.player.recipes["j-airfilter_dirty"].enabled, "Reusable-filter recipe remains available")
  end

  for index, spec in ipairs({
    { "ye_tfmw_generator-s", "y-mechanical-force", 100 },
    { "ye_tfmw_turbine-s", "steam", 500 },
  }) do
    local x = index * 40 + 40
    local generator = surface.create_entity({ name = spec[1], position = { x, 0 }, force = "player" })
    local filter = generator.get_fluid_filter(1)
    check(filter and filter.name == spec[2], spec[1] .. " retains fluid type restriction")
    surface.create_entity({ name = "substation", position = { x + 5, 0 }, force = "player" })
    local sink =
      surface.create_entity({ name = "electric-energy-interface", position = { x + 5, 5 }, force = "player" })
    sink.power_production = 0
    sink.power_usage = 10000000
    sink.electric_buffer_size = 10000000
    generator.set_fluid(1, { name = spec[2], amount = 200, temperature = spec[3] - 1 })
    generators[#generators + 1] = { entity = generator, fluid = spec[2], minimum = spec[3], energy = 0 }
  end
end)

script.on_event(defines.events.on_tick, function(event)
  local output = winding.get_output_inventory()
  winding_count = winding_count + output.get_item_count("y-winding")
  output.clear() -- Empty the output buffer so its crafting limit cannot stall the test.
  if event.tick <= 240 then
    for _, test in ipairs(generators) do
      test.energy = test.energy + test.entity.energy_generated_last_tick
      if event.tick == 120 then
        check(test.energy == 0, test.entity.name .. " rejects fluid below minimum temperature")
        local cold = test.entity.get_fluid(1)
        check(cold and cold.amount == 200, test.entity.name .. " preserves rejected cold fluid")
        test.entity.set_fluid(1, { name = test.fluid, amount = 200, temperature = test.minimum })
        test.energy = 0
      elseif event.tick == 240 then
        check(test.energy > 0, test.entity.name .. " produces power at minimum temperature")
      end
    end
  end
  if event.tick == 1200 then
    check(
      winding.get_inventory(defines.inventory.crafter_input).is_empty(),
      "Ten winding crafts consume the supplied ingredients"
    )
    check(winding_count == 36, "Ten winding crafts yield 30 items plus 6 productivity items")
    log("ENGINES_BEHAVIOR: " .. #failures .. " failures")
    script.finish_test(#failures == 0)
  end
end)
