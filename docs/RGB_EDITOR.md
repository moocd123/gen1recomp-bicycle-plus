# RGB editor implementation

`colour_values.lua` extends the unchanged `hardware_colours.lua` catalogue. It accepts existing aliases and `gbc:XXXX` values unchanged, and adds exact `rgb:RRGGBB` values. The latter can represent any 24-bit RGB colour, including every expanded RGB555 entry and the exact software RGB values used by Trainer Skins.

`colour_ui.lua` supplies a small original bitmap alphabet and explicit selection markers in Lua, not a font asset. It routes pointer input through the engine's current viewport/letterbox and numeric keyboard capture through `input.key`; key releases and unrelated screens pass through. Native virtual controls have first refusal before pointer events reach the mod. Pointer tests simulate these boundaries; unusual external render-window transforms may need their own inverse mapping.

`colour_picker.lua` owns staged RGB/HSV values. Apply writes one part; cancel drops the draft. Hex/RGB fields are validated on acceptance. The keypad allows exact entry without a physical keyboard. Retained chart textures are released when changed or when the screen exits.

All six Original/Custom switches and Reset Colours live on one native 160x144 screen. Per-part `_custom` keys remember the last chosen custom value. The main saved part key remains Original or a colour ID, so the existing renderer and old save values remain compatible. Reset preserves these remembered values while restoring the visible paint to Original.

The description lookup is metadata rather than a palette selector. Recorded trainer accents, GBC boot/game palettes and LCD-look references contribute exact RGB keys. Aliases are deduplicated per value and shown in priority/name order. Unknown values say CUSTOM RGB, or GBC RGB555 COLOUR if exactly on the expanded hardware grid. No fictional colour name is generated from a near match.
