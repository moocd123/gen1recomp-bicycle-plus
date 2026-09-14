# Hardware colour scope

## One catalogue, no duplicate colour values

There are **32,768 unique RGB555 words**. Red, green and blue each have 32 possible values. The catalogue identity is `gbc:HHHH`, where the word is `red + 32*green + 1024*blue`. Bit 15 is never set.

Each component is expanded for the modern display using `round(component * 255 / 31)`, matching the engine's existing GBC-style colour values. Every word maps to a different displayed RGB triplet. The full grid covers all words. Presets are labelled references into the same catalogue, not extra 24-bit colours. Duplicate preset references are combined, even when they come from different games, trainer palettes or LCD approximations.

**Original is different:** it means do not replace this part's source pixels. It remains available even when one of the palette swatches happens to match some or all of the original pixels for the current character. Changing trainer skins can change what Original looks like.

## What the presets include

- The twelve existing Bicycle Plus colours, without changing their displayed RGB values.
- Four-shade DMG, Pocket and Light LCD-look references from SameBoy, projected onto RGB555. The LCD-off fifth entry is not included.
- A four-shade greyscale reference, likewise projected onto RGB555.
- The engine's `GB Color (Combo Palettes)`, `GB Color (Unique Palettes)` and `GB Color (Unused Palettes)` groups. These cover its GBC boot colourisations of original Game Boy software; unrelated creative palette packs are not imported.
- The available built-in Advanced/Yellow GBC colour packs, plus the loaded game's Gen 2 palette registry. The exact preset count can therefore depend on the engine and loaded game.
- Trainer Skins 0.1.0 and 0.2.0 reference accents/highlight. Non-RGB555 displayed triplets are rounded to the nearest RGB555 colour rather than creating off-grid exceptions. The existing trainer-rendering code itself is not changed.

Every possible GBC game palette colour is available in the full RGB555 grid, even when that particular palette is not a named preset. The complete palette data of every commercial game is not bundled.

## What is and is not hardware-accurate

DMG, Pocket and Light hardware exposes four monochrome shade levels. Its physical LCD tint, contrast, lighting and backlight are not fixed RGB888 colour registers. The preset tints are therefore labelled approximations, not exact measurements. A modern screen's colour correction can also affect perceived colours.

The picker limits **individual selected colour values**. It does not impose the original hardware's per-tile palette or simultaneous-colour limits on the mod's five independent bicycle parts. It does not resize the sprites, change their masks, or replace the trainer's colours.

## Sources

- [Pan Docs: palettes and RGB555](https://gbdev.io/pandocs/Palettes.html)
- [SameBoy: built-in DMG/Pocket/Light palette definitions](https://github.com/LIJI32/SameBoy/blob/master/Core/display.c)
- [SameBoy: explanation of the LCD-look presets](https://github.com/LIJI32/SameBoy/wiki/Built%E2%80%90In-DMG-Palettes)
- [Gen1ReComp++ v0.2.60 built-in Game Boy palettes](https://github.com/bryanthaboi/gen1recomp/blob/v0.2.60/data/gb_palettes.lua)

Only numerical colour references and source code are shipped, not ROMs, extracted sprites, or soundtrack files.
