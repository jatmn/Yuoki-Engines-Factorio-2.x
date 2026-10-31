# Development checks

The lightweight CI ports the parent mod's merged
[Pullfrog PR #14](https://github.com/jatmn/Yuoki-Factorio-2.x/pull/14) and
[CI PR #16](https://github.com/jatmn/Yuoki-Factorio-2.x/pull/16), adapted for
Yuoki Engines. It runs on pull requests and pushes to `main` and `release/1.3.0`. The dispatcher reads the
complete Git diff and calls only affected reusable workflows. It avoids
GitHub's capped event path filters, does not duplicate runs on topic-branch
pushes, and cancels superseded runs for the same PR. Each `main` or `release/1.3.0` push has a
separate concurrency group so a later documentation-only push cannot cancel
an earlier push's full Lua checks. The router is loaded from the
comparison revision, so edits to the PR's router cannot disable their own
validation. Initial installation runs all checks when that revision has no router.

## Which checks run

| Changed surface | Checks |
| --- | --- |
| Shipped Lua | Lua syntax, Luacheck, StyLua and packaging |
| Test-only Lua | Lua checks |
| Python | Python AST syntax and CI/Pullfrog/package/release regressions |
| Release Please config, hidden manifest or version file | Python checks, including release-contract validation |
| Pullfrog helper or its tests | Python checks and actionlint |
| Package builder or validator | Python checks and packaging |
| Metadata, locale, graphics and other shipped files | Packaging |
| `.luacheckrc` or `.stylua.toml` | Lua checks/configuration probes |
| A workflow | actionlint, Python regressions and the affected validation workflow |
| Dispatcher (`ci.yml`) or `tools/ci_changes.py` | All four workflows |
| `docs/` or `CONTRIBUTING.md` | Change detection only |

The README, changelog and license/acknowledgment files ship, so changes to them
select packaging. Mixed changes run the union of checks. Renames consider both
old and new paths; deletions select their affected surface. Missing comparison
revisions fail CI. The change job also checks diff whitespace.

Lua checks use **Lua 5.2**, **Luacheck 1.2.0**, and **StyLua 2.5.2**. They check
all tracked Lua files on relevant pushes to `main` and `release/1.3.0`. Pull requests check only
added/modified Lua files, including renamed files and regular-file/symlink type
changes. Deleted Lua files are excluded from the file manifest on both events.
Configuration is parsed even when no Lua files changed. Filenames are passed
as NUL-delimited data rather than shell source, with option termination for tools.

The repository-wide formatting and lint baseline is complete. Factorio stage
globals and intentional Engines exports are declared in `.luacheckrc`; an
exact-file declaration also preserves the archived data-stage script's optional
electric-machine flags. Other warnings remain actionable; no blanket warning
suppression is used.

## Local commands

Install the versions above plus **actionlint 1.7.12** and Python 3. Run from the
repository root, substituting your changed Lua paths:

```sh
git diff --check
luac5.2 -p .luacheckrc
luac5.2 -p data.lua
luacheck data.lua
stylua --config-path .stylua.toml data.lua
stylua --check --config-path .stylua.toml data.lua
actionlint
python3 tools/test_ci_changes.py
python3 tools/test_pullfrog_command.py
python3 tools/test_package.py
python3 tools/test_prepare_release.py
python3 tools/package.py
python3 tools/validate_package.py
```

To reproduce the full baseline enforced by relevant `main` and `release/1.3.0` pushes:

```sh
git ls-files -z -- '*.lua' | xargs -0 -r -n1 luac5.2 -p --
git ls-files -z -- '*.lua' | xargs -0 -r luacheck --
git ls-files -z -- '*.lua' | xargs -0 -r stylua --check --config-path .stylua.toml --
```

Python CI parses every tracked `.py` file with `ast.parse` without importing
game code. Its syntax block in `.github/workflows/python.yml` can also be run
locally. Routing regressions use real Git histories, including a Lua change
after 3,500 documentation files, unusual filenames, renames, deletions,
missing revisions, router self-disable attempts, and both file-type transition
directions on both events. Selection tests also prove that an untouched Lua
syntax error fails push checks but is excluded from PR checks, including on a
configuration-only change, and that untracked files are excluded. Lua CI runs the focused file-selection and compiler
tests even on Lua-workflow-only changes, including filenames beginning with `-`.
Every workflow edit retains the existing Pullfrog authorization regression gate;
Pullfrog helper edits also retain workflow linting.

## Installable package

`tools/package.py` builds `build/dist/yi_engines_<version>.zip` and `SHA256SUMS` from
tracked release sources. Ordering, timestamps and file modes are deterministic.
It preserves `LICENSE.md` (including acknowledgments), gameplay sources, migrations,
locale and graphics. It excludes hidden files, developer docs/tools/tests,
contributor/agent guidance and generated output. Untracked files never ship;
stage new release files before building a local development ZIP. Both package
tools require regular source files contained within the checkout, including
metadata, and reject symlinks, backslashes, drive prefixes and traversal paths.
The builder checks the mod name and version against the validator's rules
before deriving or opening the output ZIP, so malformed metadata cannot
overwrite files outside the requested output directory.

The validator checks metadata, the versioned archive root, exact tracked
release membership and bytes, required entrypoints and notices, CRC integrity
and the SHA256 checksum. Python CI also tests source escapes and archive-path
safety through both real tools. CI attaches the ZIP/checksum for seven days;
reruns replace the same run's artifact. It does not publish releases or change
mod versions.

CI has read-only contents permissions and downloads no Factorio binaries or
dependency mods. These checks do not prove game API compatibility, save
migration, recipe correctness, graphics or gameplay. Engine validation remains
local and must use the appropriate Factorio/mod versions for behavioral work.
The separate [Pullfrog workflow](pullfrog.md) retains its owner-command policy.
