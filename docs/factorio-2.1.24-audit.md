# Factorio 2.1.24 compatibility audit

The audit started from Engines `2c0069be752c51a2000a15e2aaa1dfebd0805e35`
(version 1.3.1), tracing the 1.2.x history and the existing 2.1 port. All four
baseline mod configurations loaded successfully; runtime and saved-game tests
revealed silent failures that startup alone did not detect.

## Confirmed repairs

| Contract | Root cause | Repair |
| --- | --- | --- |
| Smoker and DNA Splicer have two module slots | Obsolete `module_specification` is ignored | Use `module_slots = 2`; preserve effects and crafting restrictions |
| Eight listed intermediates accept productivity | The loop depends on removed `module.limitation` | Enable productivity on the same eight recipes at the original data stage |
| Generators enforce their minimum temperatures | `fluid_input` is ignored | Set 100°C mechanical force / 500°C steam minima, retaining the fluid filters |
| Fatmice overhaul hides/disables the legacy recipe | `recipe.disabled` is ignored; saved force flags do not follow changed prototype defaults | Use `enabled = false` and synchronize only that force recipe on relevant configuration changes |
| Historical shaft selections migrate to current recipes | Four destinations in `1.2.2.json` were already obsolete when written | New `1.3.1.json` directly maps both historical naming schemes to current recipes |

The temperature API moved in Factorio 2.1.22: `minimum_input_temperature` now
belongs to the generator. The existing 2.1.20 minimum dependency is retained by
selecting the older fluid-box field on 2.1.20–2.1.21. The turbine's 500°C minimum
is distinct from the separate crafting recipe requiring 950°C steam.

The original eight-recipe list remains unchanged. Setting eligibility before
the parent's final-fixes phase preserves both ordinary productivity and the
parent's unrestricted Yuoki module categories. Other recipes do not acquire
vanilla productivity through this change.

Fatmice changes recipe availability; existing selected recipes and machine
contents stay intact. There is no tick handler, world scan, inventory conversion
or force-wide recipe reset. The handler copies the final prototype flag, so
other mods' data-stage overrides remain authoritative. Later startup setting
changes work after the new migration has already run.

The new JSON migration intentionally leaves the old file intact. Eight direct
mappings work when either the original `*-recipe` or intermediate `y-shaft*`
identifiers are saved. A four-entry chain through the old incorrect destinations
still loses original-name selections in 2.1.24. Selections already erased and
resaved cannot be reconstructed.

## Audit coverage and unchanged behavior

The review covered all 27 original Lua files (including the inactive `_old`
script), data/settings load order, both Space Age integrations, every JSON
migration mapping, and the old Lua recipe-reset migration. The original mod
has no runtime control script. Prototype references, recipe ingredients/results,
module effects, crafting categories, fluid types/temperatures and optional-mod
branches were checked against the loaded 2.1.24 prototypes and versioned API.

The relevant 1.2.x changes already include farm modules, factory mode settings,
Fatmice filters, sheet-metal options and Space Age transport/factory behavior.
Those contracts remain: factory slot modes 3/3/2, 5/6/8 and 6/8/10; the original
Space Age-only factory Quality effect; metallurgy/tungsten requirements on green
tubes; 1000°C steam support; recipe amounts and machine fluid restrictions.

Unused-data diagnostics also report legacy group/request metadata, mining
hardness, old fluid pressure/area/level fields, zero-slot specifications, sound
fields and redundant graphics fields. Explicit current volumes, graphics sets
and equivalent defaults already supply the relevant behavior; this repair does
not rebalance volumes or remove dormant fields merely to silence diagnostics.
The archived data-update script is not required by an active entrypoint.
The two HP gearbox recipes were already commented out in the oldest imported
source, so their obsolete migration entries do not justify inventing recipes.
The ancient `y-tut` item/entity targets and recipe-reset API still exist.

## Validation and limits

The exact packaged candidate was exercised on official Factorio **2.1.24 build
87808**, with Yuoki main `0b4296a83f780a0f904b9f46d8df45d3024737f6` and the
production-equivalent package for [parent PR #24](https://github.com/jatmn/Yuoki-Factorio-2.x/pull/24)
at `6e8d3cd99fc0f743492bf163b58d2a55e72d2ed9` for unrestricted integration.
Eight behavior cases cover base, Quality, Space Age with/without Quality,
both boolean settings, all factory modes and unrestricted productivity.
Full prototype comparisons allow only the admitted recipe, slot and temperature
field changes; every other loaded prototype field is identical to its baseline.

[Persistent engine fixtures](../tests/factorio/README.md) cover actual bonus
production, cold/hot generators, settings on existing saves, both historical
shaft routes and counts/quality. The baseline fails the corresponding
regressions. Lua syntax/lint/format and deterministic package validation are
separate required checks; lightweight CI does not run Factorio.

The 2.1.20/2.1.21 temperature branch was checked through the real source with a
minimal data-stage fixture, not those older executables. Saved shaft tests use
controlled historical identifiers in real 2.1.24 saves, not native old-engine
save files. Headless testing does not verify graphical appearance or arbitrary
third-party mod combinations. This is not a claim of zero remaining diagnostic
warnings or compatibility with future Factorio releases.

References: [2.1 release history](https://wiki.factorio.com/Version_history/2.1.0),
[generator prototype](https://lua-api.factorio.com/2.1.24/prototypes/GeneratorPrototype.html),
[recipe prototype](https://lua-api.factorio.com/2.1.24/prototypes/RecipePrototype.html),
[saved recipe state](https://lua-api.factorio.com/2.1.24/classes/LuaRecipe.html),
[configuration lifecycle](https://lua-api.factorio.com/2.1.24/classes/LuaBootstrap.html).
