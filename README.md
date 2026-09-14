# Bicycle Plus

A quality-of-life and customisation mod for **Gen1ReComp++**.

**Current release: v1.5.0 — hardware-limited bicycle colour picker.** Requires **Gen1ReComp++ v0.2.59 or newer** and an engine that supports **mod API 2**. New engine version numbers alone no longer exclude the mod; this does not guarantee that future engine changes will be compatible.

**[Download the installable mod ZIP](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/download/v1.5.0/bicycle_plus-1.5.0.zip)** · **[Release notes](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/tag/v1.5.0)**

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
- **All 32,768 GBC RGB555 colours**, plus deduplicated game/LCD/trainer presets and **Original** for every part.
- Animated three-direction preview; a compact side preview in the full colour grid.
- Preview a choice before saving it: **A** applies, **B** cancels or returns to presets.
- **English UK / English US** spelling option (`COLOUR/CENTRE` or `COLOR/CENTER`).
- Compatibility work for **Trainer Skins 0.1.0 and 0.2.0**.
- Supports **Pokémon Red, Blue, Yellow, Gold, Silver and Crystal** in Gen1ReComp++.
- GitHub release discovery through the launcher's **Check for updates / Update All** controls after installing v1.4.2 or newer.

## Platform support

Bicycle Plus is written in portable Lua and is intended to work on **any platform supported by Gen1ReComp++** that provides the required mod API and normal mod-loading system.

It does not contain platform-specific executables, libraries, file paths or keyboard-only controls. Not every device and operating system has been tested. In-app downloading also requires the host app's network/download support and access to GitHub; the ZIP remains available for manual installation.

## Requirements and future engine versions

- **Gen1ReComp++ v0.2.59 or newer**, with **mod API 2** support.
- A legally obtained supported Pokémon ROM imported through Gen1ReComp++.
- Trainer Skins is optional.

The engine declaration is `>=0.2.59`, with **no upper version limit**. An engine-number bump no longer requires a new Bicycle Plus release simply to remove the old maximum. The minimum engine version, required API, six-game targeting and permission checks are retained.

**Allowing a version is not the same as testing it.** Future changes to rendering, audio, menus, movement or the mod API may still need a code update. The v1.5.0 checks are headless colour/menu/render/updater checks, not full gameplay certification on every engine or device. See [VERIFICATION.md](VERIFICATION.md).

This repository contains **no ROMs, extracted ROM data or replacement Pokémon game assets**.

## First installation

1. Download **`bicycle_plus-1.5.0.zip`** from the [release](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/tag/v1.5.0) and **leave it zipped**.
2. Open the launcher and go to **MODS → Import mod .zip**.
3. Import the ZIP and enable **Bicycle Plus** for each edition you use.
4. Launch the game and open **OPTION/OPTIONS → BICYCLE +**.

Use the attached mod ZIP, **not GitHub's automatic Source code ZIP**. `SHA256SUMS.txt` is an optional download-integrity check, not another mod.

## Updating

**Already on v1.4.2? Use the launcher's MODS → Check for updates / Update All.** The installed mod already knows this GitHub repository; you do not need to delete it or import a ZIP again to obtain v1.5.0. Keep the app online and let the update complete, then relaunch the game as directed by the launcher.

For **v1.4.0 or v1.4.1**, one manual update is still necessary because those packages lack the GitHub field. Return to the launcher, delete only the old Bicycle Plus mod entry, import the current installable ZIP, and re-enable the editions you use. Do not delete saves, preferences, or app data. Fully close/reopen after a manual replacement.

The mod ID, repository, settings keys and original-colour aliases remain the same. Subsequent published releases with a higher version and an installable `bicycle_plus-<version>.zip` can be discovered by **Update All**. Network access and the host app's updater support are required. It is a user-triggered updater, not a background service.

## Controls

### Bicycle colour editor

Open **BIKE COLOUR**. **Up / Down** selects WHEEL, STRIPE, CENTRE or CENTER, EDGE, or DETAILS. **A** opens that part's colour picker. **Left / Right** on the part list still cycles the original quick choices.

**Preset picker:** Move with the D-pad. The list contains unique swatches drawn from the original Bicycle Plus colours, DMG/Pocket/Light-style LCD ramps, GBC boot palettes for original Game Boy games, the available game colour packs, and Trainer Skins colour references. Repeated RGB555 colours are merged. Pages change as the cursor moves through the grid; holding a direction repeats. **Original** is always the first option.

**Full GBC grid:** Press **Select** from the preset picker. **Left / Right** changes red and **Up / Down** changes green. Press **Select** again to focus the blue component, then use the D-pad to change it. Another **Select** returns focus to the grid. Every component has exactly **32 steps (0–31)**. The 32 × 32 grid and its 32 blue slices cover every RGB555 colour once. The display also shows its RGB hex value and RGB555 word.

**A** applies the previewed colour and returns to the parts menu. **B** returns from the full grid to presets, or cancels from presets. **Start** cancels the picker directly. Browsing never rewrites saved colours; settings are written when you confirm.

Existing named colours keep their exact appearance. The previous BLACK and WHITE quick presets are now labelled **CHARCOAL** and **OFFWHITE**, distinguishing them from pure GBC black and white. No colour has been removed. The original 16 × 16 sprite frames, bicycle-part masks and animation are retained.

The DMG, Pocket and Light are monochrome devices with four shade levels, not three programmable RGB palettes. Their screen-tint presets are **approximations snapped to RGB555**, not a claim of exact LCD colour calibration. Non-RGB555 Trainer Skins reference values are also snapped to the nearest allowed colour. [Colour scope, conversion and sources](docs/HARDWARE_COLOURS.md).

To display custom colours in the world, use **Advanced** for Gen 1 or **GBC** for Gen 2. The part menu offers an explicit **Select** shortcut when a change is needed. Merely opening the picker does not change the game's display mode.

## Automatic cycling

If you own the Bicycle, entering an area where cycling is permitted gives the mod one automatic-mount opportunity. It waits until player control is available and follows the game's existing cycling restrictions.

If you deliberately dismount, Bicycle Plus remembers that choice for the current area. It will not automatically remount you there unless you mount manually or enter another eligible area.

## Audio

The normal **AUDIO** menu contains your normal area/SFX controls. **AUDIO → CYCLING** contains the riding profile.

`ON BIKE` can be **BICYCLE** (bicycle music while riding, normal area music after dismounting), **AREA** (area music while riding) or **BOTH** (area and bicycle music together).

Cycling-only area/SFX settings can be set to **SAME** to inherit the normal setting, or overridden independently. This allows quieter filtered area music underneath louder unfiltered bicycle music while cycling, with normal audio restored after dismounting.

Area and bicycle music have independent volume and filter controls, and cycling SFX can use separate volume/filter settings.

## Compatibility and release history

Version 1.5.0 changes the colour picker and lookup. The audio, audio-menu, auto-mount and bicycle-part-mask modules are unchanged from the first public release. Historical companion-mod checks were on **Gen1ReComp++ v0.2.59** and must not be read as a complete retest on every newer engine. Known compatibility work includes **Trainer Skins, Running Shoes, Auto Field Moves, HM Field Unlock and Wilds of Kanto**.

See [COMPATIBILITY.md](COMPATIBILITY.md), [VERIFICATION.md](VERIFICATION.md) and [CHANGELOG.md](CHANGELOG.md). Compatibility with every third-party mod cannot be guaranteed.

## Source and release packaging

The production Lua files in the repository are the same files packaged into the release ZIP. The scoped v1.5.0 publishing workflow runs the public headless suites against pinned v0.2.60 engine source, verifies the manifest and all eight runtime hashes, builds an explicit allowlist into the installable ZIP, and publishes it with a SHA-256 checksum. It does not overwrite existing releases and downloads the published asset to verify it. Packaging checks are not gameplay tests.

## License

Bicycle Plus source code is released under the **MIT License**. See [LICENSE](LICENSE).

Gen1ReComp++ is a separate project. Pokémon and related names, characters and game content are the property of their respective owners. This is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Creatures Inc. or GAME FREAK.

## Upstream

- [Gen1ReComp++ / Gen1Recomp](https://github.com/bryanthaboi/gen1recomp)
