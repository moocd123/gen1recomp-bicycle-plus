# Bicycle Plus v1.5.0 — Game Boy colour picker

**Already installed v1.4.2? Use MODS → Check for updates / Update All.** This is a feature release you can use to try the existing in-app updater. No manual delete/reimport is needed for an installed v1.4.2 copy with the GitHub update source.

## New colour controls

- All **32,768 Game Boy Color RGB555 colours**, with exactly 32 steps each for red, green and blue.
- A deduplicated preset grid covering familiar bicycle/game colours, GBC boot palettes, LCD-look ramps and Trainer Skins references.
- **Original remains available separately for every part.** Existing selections retain their appearance.
- Stage colours in the animated preview before confirming. No repeated preference writes while scrolling.
- A complete 32 × 32 red/green grid with 32 blue slices, plus hex/RGB555 readouts.
- The original quick colours remain accessible with Left/Right on the five-part screen. The old off-black/off-white shades are now labelled CHARCOAL/OFFWHITE.

Open **OPTION/OPTIONS → BICYCLE + → BIKE COLOUR**, select a part and press **A**. In the preset picker, **Select** opens the full grid. In that grid, **Select** switches focus between red/green and blue. **A** applies; **B** returns/cancels; **Start** cancels directly.

DMG/Pocket/Light screen tints are approximations snapped to RGB555, not exact LCD measurements. The full grid also covers colours from GBC games whose palettes are not listed individually. Presets sharing an identical resulting colour are merged; Original is a preserve-artwork action and is intentionally not merged.

## Unchanged

Automatic cycling, deliberate dismount memory, the bicycle-part masks, audio profiles, the mod ID, GitHub update source and existing settings keys are retained. The audio, audio-menu, automatic-mount and part-mask modules are byte-for-byte unchanged. No custom-song feature or mod rename is included.

## Installation and verification

New users: download **bicycle_plus-1.5.0.zip** under Assets, leave it zipped, then import it in MODS. Do not import GitHub's Source code ZIP. Users on v1.4.0/v1.4.1 need one manual update to add the GitHub source; users on v1.4.2 can use Update All.

The release runs exhaustive colour checks plus headless menu, renderer, persistence and native updater checks. Network/input/graphics/install boundaries in those tests are simulated. These tests do not establish a fresh full gameplay test on every device or guarantee future engine compatibility.

[Verification](https://github.com/moocd123/gen1recomp-bicycle-plus/blob/v1.5.0/VERIFICATION.md) · [Colour details](https://github.com/moocd123/gen1recomp-bicycle-plus/blob/v1.5.0/docs/HARDWARE_COLOURS.md) · [Report an issue](https://github.com/moocd123/gen1recomp-bicycle-plus/issues)
