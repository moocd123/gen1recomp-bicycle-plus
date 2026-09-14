# Bicycle Plus v1.6.0 — Handlebars and organised colour controls

**Already on v1.4.2 or v1.5.0? Use MODS → Update All.** The mod ID and GitHub source are unchanged. No delete/reimport is needed for those versions.

## Changes

- **HANDLEBARS** is a sixth independent colour control. It covers the exposed front crossbar and projecting side-view bar end. Foreground clothing pixels remain original, including the cutouts in Dawn/Hilda's artwork.
- Correct the front/rear wheel borders to **EDGE**, instead of DETAILS. The tiny remaining side stem/outline is **DETAILS**. Shared shoe/wheel boundaries are excluded.
- Separate **Gen 1 and Gen 2-shaped artwork mappings**, chosen automatically from the active sprite. This does not replace your trainer or offer a sprite-style swap. The editor displays the detected artwork family.
- **RESET COLOURS** below the six controls, with a NO/YES confirmation that defaults to NO. It resets only the six bicycle colours to Original, not the trainer, audio, language or automatic-cycling preferences.
- Preset sections: **DMG → POCKET → LIGHT → GBC → TRAINER**, plus ALL PRESETS and FULL GBC GRID. Each colour is sorted by displayed **RRGGBB hex code** within its section.
- Exact duplicate presets are merged. Each has one section; ALL PRESETS is a view of that same catalogue, not duplicate stored colours.
- Full labels such as **TRAINER RED, TRAINER GREEN and TRAINER BLUE**. All ten named v0.2.0 trainer accents, older distinct references and the shared peach reference are present. The uploaded v0.2.0 code has more colours than its outdated README described.
- **Original** and the full 32,768-colour RGB555 grid remain available. Existing colour values and audio settings are retained.

## Controls

Open **OPTION/OPTIONS → BICYCLE + → BIKE COLOUR**. Up/Down selects a part; Left/Right cycles quick colours; **A** opens the section chooser. Choose a section with Up/Down and A, then browse its swatches with the D-pad. A applies; B goes back; Start cancels the picker. Select opens the full RGB555 grid; inside that grid it switches blue-channel focus.

The corrected regions may look different with an existing EDGE/DETAILS selection. The new handlebars setting starts at Original. The native pixel grid, geometry and frame timing are unchanged. Sprite files have no official bike/person labels: these are conservative visual-region mappings, not proof of every shared black outline's intended anatomy.

## Download and checks

New/manual installations: download **bicycle_plus-1.6.0.zip**, leave it zipped, import it in MODS. Do not import GitHub's Source code ZIP. Versions v1.4.0/v1.4.1 need a one-time manual update to acquire the GitHub update source.

Tests exercise actual sprite PNGs with the native SpriteRenderer at software graphics boundaries, native menus/persistence, the colour catalogue and simulated Update All transitions. They are **not a physical-device or complete gameplay test**. The workflow also verifies runtime hashes, ZIP contents and downloaded release bytes. Full details are in VERIFICATION.md and docs/BICYCLE_REGIONS.md.
