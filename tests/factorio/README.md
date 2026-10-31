# Factorio 2.1.24 regressions

These developer fixtures are excluded from the installable ZIP. They use the real
engine and dependency mods; lightweight CI only checks their Lua syntax/style.
Build and validate the candidate using `tools/package.py` and
`tools/validate_package.py`. Stage new production files before packaging.

Give every case its own mod directory and config:

```ini
[path]
read-data=/absolute/path/to/factorio/data
write-data=/absolute/path/to/case
```

Install the packaged Engines and Yuoki dependencies in that case's mod directory.
Use `mod-list.json` to explicitly enable base, Yuoki and yi_engines, plus each
case's official mods. Quality requires Recycler. Space Age cases enable
Space Age, Elevated Rails and Recycler, with Quality enabled or disabled.
Record exact game and dependency revisions. These fixtures were validated on
Factorio 2.1.24 build 87808.

## Fresh-game behavior

Copy `behavior/control.lua` to `WRITE_DATA/scenarios/engines-regression/control.lua`:

```sh
"$FACTORIO" --config "$CONFIG" --mod-directory "$MODS" \
  --test-scenario engines-regression --test-ticks 1201
```

Expect exit zero and `ENGINES_BEHAVIOR: 0 failures`. This checks restored module
slots and module quality, all eight productivity recipes, vanilla/Yuoki module
insertion, actual bonus output, a non-intermediate negative control, both
cold/hot generators and their fluid filters, and Fatmice recipe availability.
With the parent's unrestricted-productivity implementation, it also checks that
Yuoki modules remain usable on the negative-control recipe.

Run base, Quality, Space Age with Quality, and Space Age without Quality. Also
cover both Fatmice and special-sheet-metal settings, all three factory modes,
and the parent productivity toggle. Set startup settings in-game, or use a
fixture mod depending on `yi_engines` and `Yuoki` whose `settings-updates.lua`
changes defaults before the first launch in a fresh mod directory. For example:

```lua
data.raw["bool-setting"]["j_fatmice_behaviour"].default_value = true
data.raw["string-setting"]["j_factories_behaviour"].default_value = "Balanced"
data.raw["bool-setting"]["j_special_sheet_metal_behaviour"].default_value = false
data.raw["bool-setting"]["yuoki-prod-mod-behaviour"].default_value = false
```

Existing `mod-settings.dat` overrides defaults; use fresh case directories.
Compare `--dump-data` output before/after with identical settings to verify
unaffected prototypes, including fluid restrictions, capacities, crafting
categories, amounts, power, module effects and optional-mod behavior.

## Saved Fatmice setting

Make a test-only mod `save-probe_1.0.0` in both seed and upgrade mod directories,
using `fatmice/control.lua` and this metadata:

```json
{"name":"save-probe","version":"1.0.0","title":"Saved setting regression","author":"Yuoki Engines contributors","factorio_version":"2.1","dependencies":["yi_engines"]}
```

Run both with and without Quality/Recycler; the fixture checks rare quality when
available, normal otherwise. Enable the fixture alongside the real mods. Create seeds with the
baseline package and Fatmice enabled, then with the candidate and each Fatmice
setting. Use the same fixture name in each upgrade directory:

```sh
"$FACTORIO" --config "$SEED_CONFIG" --mod-directory "$SEED_MODS" --create "$SEED_SAVE"
"$FACTORIO" --config "$UPGRADE_CONFIG" --mod-directory "$UPGRADE_MODS" \
  --test-save "$SEED_SAVE" --test-ticks 10
```

Require `FATMICE_SAVE_SEEDED` and `FATMICE_SAVE_PASSED`, respectively, and exit
zero. Test baseline → candidate with the setting still on and switched off,
then candidate off → on and on → off. The last two transitions already have
the new migration recorded, so they exercise recurring configuration changes.
The fixture checks two forces and preservation of an unrelated disabled recipe
on same-setting upgrades. Startup changes can reset flags before mod callbacks,
so that assertion does not prescribe unrelated recipe state on a setting change.
It also checks existing machine/recipe quality, stored item counts/quality and fluids.
It deliberately preserves an already-selected legacy recipe; it does not
require destructive clearing of existing machines.

## Historical shaft recipes

Follow [the shaft save fixture](shafts/README.md). It checks both historical
naming schemes, a previously recorded migration, selected recipe and machine
quality, and exact rare item counts. The negative control must fail on the
baseline package. These are actual 2.1.24 saves seeded with historical names,
not native saves produced by an older Factorio executable.
