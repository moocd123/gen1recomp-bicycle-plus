# Bicycle Plus v1.4.2 compatibility

## Engine range and update discovery

The manifest declares **Gen1ReComp++ `>=0.2.59`**, **mod API 2**, and all six editions: **Red, Blue, Yellow, Gold, Silver and Crystal**. There is no upper engine-version limit. This avoids rejection solely because a newer engine version number was not listed; it does not certify future gameplay compatibility or bypass the required API/permission checks.

The `github` field is **`moocd123/gen1recomp-bicycle-plus`**. The native launcher uses that field for update discovery and prefers the asset `bicycle_plus-<version>.zip`. Older Bicycle Plus packages lack the field and need one manual installation of v1.4.2 before future updates can be discovered this way.

The mod is portable Lua and is intended for any supported host platform with the necessary mod API. In-app download availability additionally depends on the host platform's network transport. Manual ZIP installation remains available.

## Verification scope

All six runtime Lua files remain identical to the first public v1.4.0 source. The new checks exercise the actual supplied launcher and updater Lua modules in a headless harness, with network/download/UI boundaries simulated. The v0.2.60 source blobs for Manifest, ModUpdate and RomImporter match those in the supplied v0.2.59 package. This does not constitute running the complete v0.2.60 application or every device.

Future changes to internal audio, rendering, menus, movement or mod interfaces can still require a code update. The open version range cannot prevent those changes. See [VERIFICATION.md](VERIFICATION.md).

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
