# Bicycle Plus v1.6.0 compatibility

The manifest retains **Gen1ReComp++ >=0.2.59**, mod API 2, and Red, Blue, Yellow, Gold, Silver and Crystal. The open version range prevents version-number-only rejection; it does not guarantee compatibility with future breaking engine changes.

The GitHub source remains `moocd123/gen1recomp-bicycle-plus`. Users with v1.4.2 or later can use Check for updates / Update All. Older packages need a one-time manual installation to acquire that source. In-app downloads depend on the host's network support; the mod contains portable Lua rather than platform-specific binaries.

## This update

The audio, audio-menu and automatic-mounting modules are unchanged. HANDLEBARS is added with separate Gen 1/Gen 2-shaped mappings selected from the active artwork, including Trainer Skins in Gen 1 games. Wheel-border ownership and protected shared shoe pixels are corrected. RESET COLOURS affects only six bicycle-colour settings. Existing values are retained, but the corrected regions can look different under an existing EDGE/DETAILS selection.

The supplied Trainer Skins v0.2.0 archive is verified by hash and its actual code supplies the ten accent references. The old README is not used to infer how many colours exist. Native source-pixel checks include true-colour and quantised trainer sheets; the publication workflow also checks the earlier v0.1.0 artwork. See [VERIFICATION.md](VERIFICATION.md) and [BICYCLE_REGIONS.md](docs/BICYCLE_REGIONS.md).

These tests use actual source images and native Lua modules, with software graphics/input/network boundaries. They are not a new physical-device gameplay or complete companion-mod-stack test.

## Historical companion checks on Gen1ReComp++ v0.2.59

The following versions were checked during development, not freshly verified across every later engine.

| Companion mod | Version checked | Package scope |
| --- | --- | --- |
| Access PC Anywhere | 1.0.1 | Gen 1 |
| Auto Field Moves | 1.1.5 | Gen 1 |
| Bill's PC Plus | 0.15.1 | Gen 1 + Gen 2 |
| Caught Indicator | 1.4.1 | Gen 1 |
| EXP Bar | 1.1.2 | Gen 1 |
| HM Field Unlock | 1.1.0 | Gen 1 |
| Mute Low HP Alarm | 1.1.0 | Gen 1 |
| Pokeball Colors | 0.1.73 | Gen 1 + Gen 2 |
| Repel Reuse Prompt | 1.0.1 | Gen 1 |
| Running Shoes | 1.1.2 | Gen 1 |
| Shiny Pokemon | 1.0.1 | Gen 1 |
| TM/HM Move Names | 1.0.0 | Gen 1 |
| Trainer Skins | 0.1.0 and 0.2.0 | Gen 1 + Gen 2 |
| Unique Menu Icons | 1.5.0 | Gen 1 + Gen 2 |
| Wilds of Kanto | 2.1.9 | Gen 1 + Gen 2 |

Additional rendering checks were performed with Dramaless Shape 2.0.4. Kanto First Person 1.8.3 had a separate dependency/activation issue with that Dramaless pairing even without Bicycle Plus; Bicycle Plus does not modify either mod.


## Compatibility behaviour

- **Trainer Skins:** bicycle recolouring preserves supported trainer clothing, hair, skin, hands and shoes.
- **Running Shoes:** Bicycle Plus does not replace movement-speed handling.
- **Auto Field Moves / HM Field Unlock:** cycling can transition into supported field actions such as Surf.
- **Wilds of Kanto:** automatic mounting waits while controlling a Pokémon instead of the trainer.
- **Unknown replacement bicycle artwork:** the mod avoids blindly recolouring artwork it cannot safely classify.

Supporting all six games does not extend a companion mod beyond the editions its own manifest permits. Compatibility with every third-party mod cannot be guaranteed.
