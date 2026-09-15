# Bicycle Plus v1.7.0 — Original/Custom colour editor

**Already on v1.4.2 or later? Use MODS → Check for updates → Update All.** The mod ID and update repository are unchanged.

## New colour interface

- All six bicycle parts and **RESET COLOURS** fit on one screen. No redundant title, artwork-family label or page counter.
- Each part has **ORIGINAL / CUSTOM**. Left/Right switches the type and remembers the last custom colour. **A** confirms Original or opens the Custom editor.
- A clear solid arrow and highlighted row replace the unreliable font cursor.
- One rainbow hue/saturation chart, a brightness slider, an animated preview, and exact **R/G/B (0–255)** and **RRGGBB hex** fields. No section or preset-page navigation.
- Mouse/touch selection and dragging, controller/D-pad navigation and an on-screen keypad, plus keyboard typing/paste in numeric fields.
- Exact palette matches are described below the hex code, for example **TRAINER SKINS GREEN** or **GBC BOOT**. Multiple source names rotate; unrecognised values show CUSTOM RGB or GBC RGB555 COLOUR.
- Full 24-bit RGB: new colours are **not rounded to RGB555**. Existing named and `gbc:` colours keep their old appearance. This includes exact matches to all ten named Trainer Skins v0.2.0 accents.
- In the editor, browsing changes only the preview; **APPLY saves, CANCEL discards**. Numeric/hex edits have their own OK/BACK step before applying the whole colour.

## Controls

Component screen: D-pad Up/Down chooses a part, Left/Right changes colour type, A picks/confirms, B returns. With a mouse/touch, the type column switches the type; selecting the part name activates it.

Custom editor: D-pad moves in the chart; **Select** cycles chart → brightness → R → G → B → hex → Apply → Cancel. A edits a field or applies the colour, B cancels the editor. Inside a numeric field use the on-screen keypad, or type and press Enter; Escape cancels that field. Mouse/touch can select the controls directly. Ctrl/Cmd+V pastes an RGB channel or six-digit hex code into the selected field where clipboard access is available.

## Unchanged and verification limits

Audio, automatic mounting and bicycle pixel masks are unchanged from the published v1.6.0. Reset still affects only the six bicycle colours. The selected trainer and sprite geometry are not replaced.

Automated checks cover RGB/hex values, legacy preservation, menu layout/input, save isolation, software-rendered sprite pixels and native update metadata. They use pinned engine source with simulated graphics, input, clipboard and device boundaries. **This is not a physical-device or full gameplay test.** Please report your game, engine version, device and enabled mods when reporting problems.

DMG/Pocket/Light references describe LCD-look approximations, not exact measurements of historical screens. Future engine changes can still require fixes despite the open version range.

Manual installation: download **bicycle_plus-1.7.0.zip**, leave it zipped, and import it through MODS. Do not use GitHub's Source code ZIP. Older v1.4.0/v1.4.1 installations need the one-time manual update to obtain the GitHub update source.
