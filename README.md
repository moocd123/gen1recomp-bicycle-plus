# Bicycle Plus

A quality-of-life and customisation mod for **Gen1ReComp++ v0.2.59**.

Bicycle Plus automatically mounts the Bicycle when entering an area where cycling is allowed, remembers deliberate dismounts for the current area, adds separate normal/cycling audio profiles, and lets you customise five visible parts of the bicycle while preserving the original pixel scale and animation.

![Bicycle Plus animated colour editor](docs/bicycle-plus-preview.gif)

## Features

- **Automatic cycling** when entering an eligible area while the Bicycle is in your inventory.
- **Manual dismount memory**: if you get off deliberately, you stay on foot until you remount or enter a new eligible area.
- **Normal and cycling audio profiles** with independent area music, bicycle music and SFX behaviour.
- **Cycling mix modes**: Bicycle, Area or Both.
- Independent **volume** and **filter** controls for area music, bicycle music and cycling SFX.
- Five independent bicycle colour controls:
  - **WHEEL** — main coloured wheel area.
  - **STRIPE** — animated moving accent around the wheel.
  - **CENTRE** — small centre block of each wheel.
  - **EDGE** — outer wheel outline.
  - **DETAILS** — exposed bicycle details such as handlebars/front-fork lines.
- Animated three-direction colour preview.
- **English UK / English US** spelling option (`COLOUR/CENTRE` or `COLOR/CENTER`).
- Compatibility work for **Trainer Skins 0.1.0 and 0.2.0**.
- Supports **Pokémon Red, Blue, Yellow, Gold, Silver and Crystal** in Gen1ReComp++.

## Platform support

Bicycle Plus is written in portable Lua and is intended to work on **any platform supported by Gen1ReComp++ v0.2.59** that provides the normal mod-loading system.

It does not contain platform-specific executables, libraries, file paths or keyboard-only controls. Not every physical device and operating system can be individually tested, so platform-specific issues can still be reported through GitHub Issues.

## Requirements

- **Gen1ReComp++ v0.2.59**.
- A legally obtained supported Pokémon ROM imported through Gen1ReComp++.
- Trainer Skins is optional.

This repository contains **no ROMs, extracted ROM data or replacement Pokémon game assets**.

## Installation

Download the ready-to-import ZIP from the [Releases page](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/latest).

1. Download `Bicycle_Plus-1.4.0-Gen1ReComp-0.2.59.zip` and **leave it zipped**.
2. Open the Gen1ReComp++ launcher and go to **MODS**.
3. Choose **Import mod .zip** and select the downloaded ZIP.
4. Enable **Bicycle Plus** for each game edition you use.
5. Launch the game and open **OPTION/OPTIONS → BICYCLE +**.

Do **not** download the repository itself as a ZIP and import that into Gen1ReComp++; use the ZIP attached to a GitHub Release.

## Controls

Open **OPTION/OPTIONS → BICYCLE +**.

### Bicycle colour editor

Open **BIKE COLOUR** and use:

- **Up / Down** — select WHEEL, STRIPE, CENTRE, EDGE or DETAILS.
- **Left / Right** — change that part's colour.
- **B / Start** — return.

Available choices are **Original, Red, Orange, Yellow, Green, Cyan, Blue, Purple, Pink, Brown, Silver, Black and White**.

The game sprite remains on its original **16×16 pixel grid**. The mod recolours existing bicycle pixels rather than resizing the sprite. The preview is enlarged only so the individual pixels are easier to see.

## Automatic cycling

If you own the Bicycle, entering an area where cycling is permitted gives the mod one automatic-mount opportunity. It waits until player control is available and follows the game's existing cycling restrictions.

If you deliberately dismount, Bicycle Plus remembers that choice for the current area. It will not automatically remount you there unless you mount manually or enter another eligible area.

## Audio

The normal **AUDIO** menu contains your normal area/SFX controls. **AUDIO → CYCLING** contains the riding profile.

`ON BIKE` can be:

- **BICYCLE** — original-style behaviour: bicycle music while riding, area music when you get off.
- **AREA** — area music continues while riding.
- **BOTH** — area and bicycle music play together.

Cycling-only area/SFX settings can be set to **SAME** to inherit the normal setting, or overridden independently. This allows combinations such as quieter filtered area music underneath louder unfiltered bicycle music while cycling, with normal audio restored immediately after dismounting.

Area and bicycle music have independent volume and filter controls, and cycling SFX can also use separate volume/filter settings.

## Compatibility

Bicycle Plus was developed for **Gen1ReComp++ v0.2.59**. See [COMPATIBILITY.md](COMPATIBILITY.md) for the exact companion-mod versions and interactions checked during development.

Known compatibility work includes **Trainer Skins, Running Shoes, Auto Field Moves, HM Field Unlock and Wilds of Kanto**. Compatibility with every possible third-party mod cannot be guaranteed.

## First public release

**v1.4.0 is the first public release of Bicycle Plus.** Earlier version numbers were internal development iterations and were never published as public releases.

See [CHANGELOG.md](CHANGELOG.md) for the public release history.

## Source

The mod is written in Lua and uses the Gen1ReComp++ mod API. The production files in this repository are the same source files packaged into the release ZIP.

## License

Bicycle Plus source code is released under the **MIT License**. See [LICENSE](LICENSE).

Gen1ReComp++ is a separate project and is also distributed under the MIT License. Pokémon and related names, characters and game content are the property of their respective owners. This is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Creatures Inc. or GAME FREAK.

## Upstream

- [Gen1ReComp++ / Gen1Recomp](https://github.com/bryanthaboi/gen1recomp)
