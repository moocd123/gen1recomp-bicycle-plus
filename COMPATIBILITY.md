# Bicycle Plus 1.4.1 compatibility

The v1.4.1 manifest accepts **Gen1ReComp++ v0.2.59 or v0.2.60** and retains the six game targets: **Red, Blue, Yellow, Gold, Silver and Crystal**.

**Verification scope:** v1.4.1 is a version-gate hotfix, not an engine-port rewrite. Its six runtime Lua files are identical to v1.4.0. The prepared hotfix checks used the supplied v0.2.59 engine modules and test doubles. For the launcher check, `Version.engine` was varied as an input; this is not execution of a downloaded v0.2.60 runtime. Full v0.2.60 gameplay, rendering and audio-device verification remain pending.

The mod is written in portable Lua and is intended to work on any platform supported by the declared Gen1ReComp++ versions that exposes the normal mod-loading system. It does not depend on a platform-specific executable, native library, fixed path or keyboard-only control scheme. Not every physical platform or device has been individually tested.

## Historical companion checks on Gen1ReComp++ v0.2.59

The following table is retained from the first public release. These companion versions were not freshly exercised against a v0.2.60 runtime for this update.

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

- **Trainer Skins:** Bicycle recolouring is designed to preserve trainer clothing, hair, skin, hands and shoes while recolouring supported bicycle pixels.
- **Running Shoes:** Bicycle Plus does not replace movement-speed handling.
- **Auto Field Moves / HM Field Unlock:** Cycling can transition into game-supported field actions such as Surf.
- **Wilds of Kanto:** Automatic mounting waits while Wilds is controlling a Pokémon rather than the trainer.
- **Unknown replacement bicycle artwork:** Bicycle Plus avoids blindly recolouring artwork it cannot safely classify.

## Scope

These checks cover the versions and interactions listed above. They do not guarantee compatibility with every future version or every third-party mod, especially mods that replace the same rendering, world-control, menu or audio hooks without chaining their predecessors.

Supporting all six games does not force another mod to work in a game that its own manifest excludes. See [VERIFICATION.md](VERIFICATION.md) for this update's testing limits.
