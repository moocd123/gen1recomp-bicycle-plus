# Bicycle Plus

A quality-of-life and customisation mod for **Gen1ReComp++**.

**Current release: v1.4.1 — engine-version compatibility hotfix.** The manifest now accepts **v0.2.59 and v0.2.60**. This corrects the version restriction; full gameplay on v0.2.60 has not been verified. See [VERIFICATION.md](VERIFICATION.md).

**[Download the installable mod ZIP](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/download/v1.4.1/Bicycle_Plus-1.4.1-Gen1ReComp-0.2.60.zip)** · **[Release notes](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/tag/v1.4.1)**

Bicycle Plus automatically mounts the Bicycle when entering an area where cycling is allowed, remembers deliberate dismounts for the current area, adds separate normal/cycling audio profiles, and lets you customise five visible parts of the bicycle while preserving the original pixel scale and animation.

## Features

- **Automatic cycling** when entering an eligible area while the Bicycle is in your inventory.
- **Manual dismount memory:** getting off deliberately keeps you on foot until you remount or enter a new eligible area.
- **Normal and cycling audio profiles** with independent area music, bicycle music and SFX behaviour.
- **Cycling mix modes:** Bicycle, Area or Both.
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

Bicycle Plus is written in portable Lua and is intended to work on **any platform supported by the declared Gen1ReComp++ versions** that provides the normal mod-loading system.

It does not contain platform-specific executables, libraries, file paths or keyboard-only controls. Not every physical device and operating system has been individually tested; platform-specific issues can be reported through [GitHub Issues](https://github.com/moocd123/gen1recomp-bicycle-plus/issues).

## Requirements

- **Gen1ReComp++ v0.2.59 or v0.2.60**, with the verification limits above.
- A legally obtained supported Pokémon ROM imported through Gen1ReComp++.
- Trainer Skins is optional.

This repository contains **no ROMs, extracted ROM data or replacement Pokémon game assets**.

## Installation

Download the ready-to-import ZIP from the [Releases page](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/latest).

1. Download `Bicycle_Plus-1.4.1-Gen1ReComp-0.2.60.zip` and **leave it zipped**.
2. Open the Gen1ReComp++ launcher and go to **MODS**.
3. Choose **Import mod .zip** and select the downloaded ZIP.
4. Enable **Bicycle Plus** for each game edition you use.
5. Launch the game and open **OPTION/OPTIONS → BICYCLE +**.

Do **not** import GitHub's automatic Source code ZIP or a repository-upload ZIP; use the installable ZIP attached to a release. Despite the filename, v1.4.1 permits both declared engine versions.

## Updating from v1.4.0

The mod ID remains `bicycle_plus`, and all six production Lua files are unchanged. Your colour selections, normal/cycling audio profiles, language preference and automatic-cycling setting keep the same storage keys.

For a local ZIP update, return to the launcher, select the old **Bicycle Plus** entry and choose **Delete**, then import the new release ZIP and enable the editions you use. Delete only this mod entry, not your saves or the whole mods folder. The supplied launcher's Delete action removes the installed mod and its enable flags, but retains the mod-options table. Fully close and reopen the application after replacing it.

## Controls

Open **OPTION/OPTIONS → BICYCLE +**.

### Bicycle colour editor

Open **BIKE COLOUR** and use:

- **Up / Down** — select WHEEL, STRIPE, CENTRE, EDGE or DETAILS.
- **Left / Right** — change that part's colour.
- **B / Start** — return.

Available choices are **Original, Red, Orange, Yellow, Green, Cyan, Blue, Purple, Pink, Brown, Silver, Black and White**.

The game sprite remains on its original **16×16 pixel grid**. The mod recolours bicycle pixels rather than resizing the sprite. The preview is enlarged only so the individual pixels are easier to see.

## Automatic cycling

If you own the Bicycle, entering an area where cycling is permitted gives the mod one automatic-mount opportunity. It waits until player control is available and follows the game's existing cycling restrictions.

If you deliberately dismount, Bicycle Plus remembers that choice for the current area. It will not automatically remount you there unless you mount manually or enter another eligible area.

## Audio

The normal **AUDIO** menu contains your normal area/SFX controls. **AUDIO → CYCLING** contains the riding profile.

`ON BIKE` can be:

- **BICYCLE** — original-style behaviour: bicycle music while riding, area music when you get off.
- **AREA** — area music continues while riding.
- **BOTH** — area and bicycle music play together.

Cycling-only area/SFX settings can be set to **SAME** to inherit the normal setting, or overridden independently. This allows quieter filtered area music underneath louder unfiltered bicycle music while cycling, with normal audio restored after dismounting.

Area and bicycle music have independent volume and filter controls, and cycling SFX can use separate volume/filter settings.

## Compatibility

Bicycle Plus was developed for **Gen1ReComp++ v0.2.59**. Version **1.4.1** extends its engine-version declaration to **v0.2.60**, without changing the runtime code. Existing companion-mod checks are historical v0.2.59 evidence, not a fresh full-stack test on v0.2.60. See [COMPATIBILITY.md](COMPATIBILITY.md).

Known compatibility work includes **Trainer Skins, Running Shoes, Auto Field Moves, HM Field Unlock and Wilds of Kanto**. Compatibility with every possible third-party mod cannot be guaranteed.

## Release history

**v1.4.0 was the first public release of Bicycle Plus.** See [CHANGELOG.md](CHANGELOG.md) for the public release history.

## Source and release packaging

The mod is written in Lua. Production source files in the repository are the same files packaged into the release ZIP.

The scoped v1.4.1 publishing workflow verifies the manifest and all six runtime-file hashes, builds an installable ZIP from an explicit file allowlist, and publishes it with a SHA-256 checksum. It does not overwrite an existing release. This packaging check is not a gameplay test.

## License

Bicycle Plus source code is released under the **MIT License**. See [LICENSE](LICENSE).

Gen1ReComp++ is a separate project. Pokémon and related names, characters and game content are the property of their respective owners. This is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Creatures Inc. or GAME FREAK.

## Upstream

- [Gen1ReComp++ / Gen1Recomp](https://github.com/bryanthaboi/gen1recomp)
