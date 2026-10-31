-- luacheck: globals script game

-- Recipe defaults do not update saved force state when startup settings change.
script.on_configuration_changed(function(event)
  if not (event.mod_changes["yi_engines"] or event.mod_startup_settings_changed or event.migration_applied) then
    return
  end

  for _, force in pairs(game.forces) do
    local recipe = force.recipes["y-rmvpol"]
    recipe.enabled = recipe.prototype.enabled
  end
end)
