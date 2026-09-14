# Bicycle Plus

A quality-of-life and customisation mod for **Gen1ReComp++**.

**Current release: v1.6.0 — handlebars and organised colour controls.** Includes a six-part editor, a confirmed colour reset and hex-sorted system/trainer sections. See [verification limits](VERIFICATION.md).

**[Download the installable mod ZIP](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/download/v1.6.0/bicycle_plus-1.6.0.zip)** · **[Release notes](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/tag/v1.6.0)**

Bicycle Plus automatically mounts the Bicycle when entering an area where cycling is allowed, remembers deliberate dismounts for the current area, adds separate normal/cycling audio profiles, and lets you customise six visible parts of the bicycle while preserving the original pixel scale and animation.

## Features

- **Automatic cycling** when entering an eligible area while the Bicycle is in your inventory.
- **Manual dismount memory:** getting off deliberately keeps you on foot until you remount or enter a new eligible area.
- **Normal and cycling audio profiles** with independent area music, bicycle music and SFX behaviour.
- **Cycling mix modes:** Bicycle, Area or Both.
- Independent **volume** and **filter** controls for area music, bicycle music and cycling SFX.
- Six independent bicycle colour controls:
  - **WHEEL** — main coloured wheel area.
  - **STRIPE** — animated moving accent around the wheel.
  - **CENTRE** — small centre block of each wheel.
  - **EDGE** — outer wheel outline.
  - **DETAILS** — the small remaining side stem/grip-adjacent outline.
  - **HANDLEBARS** — the exposed front crossbar and projecting side-view end.
- **All 32,768 GBC RGB555 colours**, plus deduplicated game/LCD/trainer presets and **Original** for every part.
- Animated three-direction preview; a compact side preview in the full colour grid.
- Preview a choice before saving it: **A** applies, **B** goes back and **Start** cancels the picker.
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

**Allowing a version is not the same as testing it.** Future changes to rendering, audio, menus, movement or the mod API may still need a code update. The v1.6.0 checks are headless colour/menu/render/updater checks, not full gameplay certification on every engine or device. See [VERIFICATION.md](VERIFICATION.md).

This repository contains **no ROMs, extracted ROM data or replacement Pokémon game assets**.

## First installation

1. Download **`bicycle_plus-1.6.0.zip`** from the [release](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/tag/v1.6.0) and **leave it zipped**.
2. Open the launcher and go to **MODS → Import mod .zip**.
3. Import the ZIP and enable **Bicycle Plus** for each edition you use.
4. Launch the game and open **OPTION/OPTIONS → BICYCLE +**.

Use the attached mod ZIP, **not GitHub's automatic Source code ZIP**. `SHA256SUMS.txt` is an optional download-integrity check, not another mod.

## Updating

**Already on v1.4.2 or v1.5.0? Use the launcher's MODS → Check for updates / Update All.** The installed mod already knows this GitHub repository; you do not need to delete it or import a ZIP again to obtain v1.6.0. Keep the app online and let the update complete, then relaunch the game as directed by the launcher.

For **v1.4.0 or v1.4.1**, one manual update is still necessary because those packages lack the GitHub field. Return to the launcher, delete only the old Bicycle Plus mod entry, import the current installable ZIP, and re-enable the editions you use. Do not delete saves, preferences, or app data. Fully close/reopen after a manual replacement.

The mod ID, repository, settings keys and original-colour aliases remain the same. Subsequent published releases with a higher version and an installable `bicycle_plus-<version>.zip` can be discovered by **Update All**. Network access and the host app's updater support are required. It is a user-triggered updater, not a background service.

## Controls

### Bicycle colour editor

Open **BIKE COLOUR**. Up/Down selects WHEEL, STRIPE, CENTRE, EDGE, DETAILS or HANDLEBARS. The list scrolls without reducing the animated preview. Left/Right cycles the quick colours; A opens the full picker.

The picker starts with **Original**, then sections in hardware release order: **DMG → POCKET → LIGHT → GBC**, followed by **TRAINER**, **ALL PRESETS** and **FULL GBC GRID**. Each section is sorted by the displayed **RRGGBB hex code**, not by the packed RGB555 word. Exact matches are merged into one preset and assigned to one section. All Presets is a view of the same catalogue, not a second set of stored choices.

Choose a section with Up/Down and A, then browse its grid with the D-pad. **A** applies the previewed colour; **B** goes back; **Start** cancels. **Select** opens the full RGB555 grid, where Select toggles blue-channel focus. All 32,768 GBC colours remain available; the compact sections are preset references. Full labels include TRAINER RED, TRAINER GREEN and TRAINER BLUE, along with the other v0.2.0 accents.

**RESET COLOURS** sits beneath the six controls. It asks NO/YES (default NO) and changes only those six bicycle colours to Original. It does not reset your trainer, audio, automatic cycling or spelling preference.

The sprite stays on its original 16×16 pixel grid. Gen 1/Gen 2-shaped mappings are selected from the active artwork automatically; the ART readout is not a bike-style replacement switch. The corrected regions may change the appearance of an existing EDGE/DETAILS selection; saved colour values themselves are retained and new handlebars start Original.

DMG/Pocket/Light display tints are documented RGB555 approximations, not exact calibrated LCD measurements. Trainer values between hardware steps are snapped to the nearest permitted colour. Original retains the active artwork rather than forcing it to one palette swatch. See [hardware colours](docs/HARDWARE_COLOURS.md) and [exact pixel regions](docs/BICYCLE_REGIONS.md).

## Automatic cycling

If you own the Bicycle, entering an area where cycling is permitted gives the mod one automatic-mount opportunity. It waits until player control is available and follows the game's existing cycling restrictions.

If you deliberately dismount, Bicycle Plus remembers that choice for the current area. It will not automatically remount you there unless you mount manually or enter another eligible area.

## Audio

The normal **AUDIO** menu contains your normal area/SFX controls. **AUDIO → CYCLING** contains the riding profile.

`ON BIKE` can be **BICYCLE** (bicycle music while riding, normal area music after dismounting), **AREA** (area music while riding) or **BOTH** (area and bicycle music together).

Cycling-only area/SFX settings can be set to **SAME** to inherit the normal setting, or overridden independently. This allows quieter filtered area music underneath louder unfiltered bicycle music while cycling, with normal audio restored after dismounting.

Area and bicycle music have independent volume and filter controls, and cycling SFX can use separate volume/filter settings.

## Compatibility and release history

Version 1.6.0 changes colour-region mappings and the colour UI. The audio, audio-menu and auto-mount modules are unchanged from v1.5.0. The part-mask changes are documented separately. Historical companion-mod checks were on **Gen1ReComp++ v0.2.59** and must not be read as a complete retest on every newer engine. Known compatibility work includes **Trainer Skins, Running Shoes, Auto Field Moves, HM Field Unlock and Wilds of Kanto**.

See [COMPATIBILITY.md](COMPATIBILITY.md), [VERIFICATION.md](VERIFICATION.md) and [CHANGELOG.md](CHANGELOG.md). Compatibility with every third-party mod cannot be guaranteed.

## Source and release packaging

The production Lua files in the repository are the same files packaged into the release ZIP. The scoped v1.6.0 publishing workflow runs the public headless suites against pinned v0.2.60 engine source, verifies the manifest and all nine runtime hashes, builds an explicit allowlist into the installable ZIP, and publishes it with a SHA-256 checksum. It does not overwrite existing releases and downloads the published asset to verify it. Packaging checks are not gameplay tests.

## License

Bicycle Plus source code is released under the **MIT License**. See [LICENSE](LICENSE).

Gen1ReComp++ is a separate project. Pokémon and related names, characters and game content are the property of their respective owners. This is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Creatures Inc. or GAME FREAK.

## Upstream

- [Gen1ReComp++ / Gen1Recomp](https://github.com/bryanthaboi/gen1recomp)
