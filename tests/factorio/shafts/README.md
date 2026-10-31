# Shaft migration regression

`control.lua` is a small test-only mod control script; no new test runner is needed. Run once with original names and once with intermediate names. Enable base, Yuoki, yi_engines, quality, recycler and migration_probe; disable space-age and elevated-rails. Use separate mod and write-data directories for each case. Quality requires Recycler even though the test does not recycle anything.

1. Package the candidate Engines mod normally, retaining its new `migrations/1.3.1.json`. Prepare the upgrade mod directory from that package plus the real Yuoki dependency.
2. Add a directory named `migration_probe_1.0.0` to both seed and upgrade mod directories. Copy `control.lua` into it and use this `info.json`:

```json
{"name":"migration_probe","version":"1.0.0","title":"Shaft migration regression","author":"Yuoki Engines contributors","factorio_version":"2.1","dependencies":["yi_engines","quality"]}
```

3. Create a separate extracted copy of the candidate Engines package for each seed. This one-time inline command alters only the extracted seed, never the source checkout. `SEED_ADDON` is the extracted directory, named `yi_engines_1.2.1`. `SEED_MODE` is `original` or `intermediate`:

```bash
SEED_ADDON=/absolute/path/to/seed/mods/yi_engines_1.2.1 SEED_MODE=original python3 - <<'PY'
import json, os
from pathlib import Path
addon = Path(os.environ['SEED_ADDON'])
original = os.environ['SEED_MODE'] == 'original'
info = json.loads((addon / 'info.json').read_text())
info['version'] = '1.2.1'
(addon / 'info.json').write_text(json.dumps(info))
(addon / 'migrations/1.3.1.json').unlink()
if original:
    (addon / 'migrations/1.2.2.json').unlink()
pairs = [
    ('y-shaft', 'y-mftrans-shaft'),
    ('y-shaft-r', 'y-mftrans-shaft-red'),
    ('y-shaft-ground', 'y-mftrans-shaft-ground'),
    ('y-shaft-ground-r', 'y-mftrans-shaft-ground-red'),
]
with (addon / 'data-final-fixes.lua').open('a') as stream:
    for legacy, current in pairs:
        if original:
            legacy += '-recipe'
        stream.write(f'\nlocal p = data.raw.recipe["{current}"]\n'
                     f'data.raw.recipe["{current}"] = nil\n'
                     f'p.name = "{legacy}"\ndata:extend{{p}}\n')
PY
```

4. Create the actual seed save. Each config sets read-data to the installed Factorio data directory and write-data to an isolated owned case directory:

```bash
"$FACTORIO" --config "$SEED_CONFIG" --mod-directory "$SEED_MODS" --create "$SEED_SAVE"
"$FACTORIO" --config "$UPGRADE_CONFIG" --mod-directory "$UPGRADE_MODS" --test-save "$SEED_SAVE" --test-ticks 10
```

Run these finite commands with your normal local process supervision. Seed creation must exit zero with `SHAFT_MIGRATION_SEED_READY`; upgrading must exit zero with `SHAFT_MIGRATION_PASSED`. The intermediate seed intentionally retains 1.2.2.json, proving that the new migration works when the old migration is already recorded. The original seed removes it, proving that both the old bad migration and the new correction can run together.

For a negative control, make a separate upgrade package lacking only `migrations/1.3.1.json`. Loading either seed must fail with `Lost shaft recipe`, showing that the fixture catches the actual baseline defect. These are real engine saves containing controlled historical prototype identifiers, not native Factorio 1.1/2.0 saves. No fixture or data-final-fixes rename code belongs in the production mod.
