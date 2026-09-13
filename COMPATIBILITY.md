# Bicycle Plus 1.4.0 compatibility

Bicycle Plus targets **Gen1ReComp++ v0.2.59** and supports **Pokémon Red, Blue, Yellow, Gold, Silver and Crystal**.

The mod is written in portable Lua and is intended to work on any platform supported by Gen1ReComp++ v0.2.59 that exposes the normal mod-loading system. It does not depend on a platform-specific executable, native library, fixed path or keyboard-only control scheme. Not every physical platform or device has been individually tested.

## Companion mods checked during development

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
- **Auto Field Moves / HM Field Unlock:** Cycling can transition normally into game-supported field actions such as Surf.
- **Wilds of Kanto:** Automatic mounting waits while Wilds is controlling a Pokémon rather than the trainer.
- **Unknown replacement bicycle artwork:** Bicycle Plus avoids blindly recolouring artwork it cannot safely classify.

## Scope

Compatibility testing covers the versions and interactions listed above. It cannot guarantee compatibility with every future version or every third-party mod, especially mods that completely replace the same rendering, world-control, menu or audio hooks without chaining their predecessors.

Supporting all six games does not force another mod to work in a game that its own manifest excludes.
