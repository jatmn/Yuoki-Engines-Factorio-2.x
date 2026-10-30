# Yuoki Industries - Engines (Addon)

The current build is **Engines 1.3.1** for **Factorio 2.1**. It requires Factorio **2.1.20 or newer** and **Yuoki Industries 1.3.0 or newer**. Engines 1.3.1 does not target Factorio 2.0.

## Installation

Install and enable both `Yuoki` and `yi_engines`. For a source checkout, put the source files in a `yi_engines_1.3.1` directory inside Factorio's mods directory, with `info.json` directly inside it. Use a compatible [Yuoki Industries release](https://github.com/jatmn/Yuoki-Factorio-2.x) alongside it.

Space Age is optional; when enabled, it must also be 2.1.20 or newer. With Space Age, the green transport tubes require tungsten plates and a foundry. Back up existing saves before upgrading the game and mods together.

See the [official download page](https://factorio.com/download) for the current game releases. As of October 8, 2026, 2.1.21 is experimental; 2.0.77 remains stable.

## Compatibility verification

Checked against the [Factorio 2.1.21 API](https://lua-api.factorio.com/2.1.21/) and the official 2.1.21 headless engine, using Yuoki 1.3.0. Fresh map creation, save loading, a 600-tick simulation, and prototype data generation pass in these configurations:

| Configuration (all include Yuoki and Engines) | Result |
| --- | --- |
| Base game | Pass |
| Base + Recycler + Quality | Pass |
| Space Age + Elevated Rails + Recycler + Quality | Pass |
| Space Age + Elevated Rails + Recycler, Quality disabled | Pass |

The port updates recipe and fuel categories, factory module inventories and assembler pictures, generator pictures, and shaft connection overlays. It preserves the existing 1000-degree steam production used by Rheinsberg and the turbine recipes.

Headless checks do not verify rendered graphics, migration of an existing 2.0 save, complete production-chain balance, or third-party mod combinations. Legacy unused-prototype-field warnings remain; successful loading does not establish that every older field still has an effect.

Contributor checks and CI: [CONTRIBUTING.md](CONTRIBUTING.md) and
[development guide](docs/development.md).
Pullfrog usage and maintenance: [owner commands](docs/pullfrog.md).
