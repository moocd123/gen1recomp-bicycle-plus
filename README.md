# Bicycle Plus

A quality-of-life and customisation mod for **Gen1ReComp++**.

**Current release: v1.4.2 — in-app updates and no upper engine-version limit.** Requires **Gen1ReComp++ v0.2.59 or newer** and an engine that supports **mod API 2**. New engine version numbers alone no longer exclude the mod; this does not guarantee that future engine changes will be compatible.

**[Download the installable mod ZIP](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/download/v1.4.2/bicycle_plus-1.4.2.zip)** · **[Release notes](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/tag/v1.4.2)**

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
- GitHub release discovery through the launcher's **Check for updates / Update All** controls after installing v1.4.2 or newer.

## Platform support

Bicycle Plus is written in portable Lua and is intended to work on **any platform supported by Gen1ReComp++** that provides the required mod API and normal mod-loading system.

It does not contain platform-specific executables, libraries, file paths or keyboard-only controls. Not every device and operating system has been tested. In-app downloading also requires the host app's network/download support and access to GitHub; the ZIP remains available for manual installation.

## Requirements and future engine versions

- **Gen1ReComp++ v0.2.59 or newer**, with **mod API 2** support.
- A legally obtained supported Pokémon ROM imported through Gen1ReComp++.
- Trainer Skins is optional.

The engine declaration is `>=0.2.59`, with **no upper version limit**. An engine-number bump no longer requires a new Bicycle Plus release simply to remove the old maximum. The minimum engine version, required API, six-game targeting and permission checks are retained.

**Allowing a version is not the same as testing it.** Future changes to rendering, audio, menus, movement or the mod API may still need a code update. Full gameplay on v0.2.60 and later has not been newly verified for this metadata-only release. See [VERIFICATION.md](VERIFICATION.md).

This repository contains **no ROMs, extracted ROM data or replacement Pokémon game assets**.

## First installation

1. Download **`bicycle_plus-1.4.2.zip`** from the [release](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/tag/v1.4.2) and **leave it zipped**.
2. Open the launcher and go to **MODS → Import mod .zip**.
3. Import the ZIP and enable **Bicycle Plus** for each edition you use.
4. Launch the game and open **OPTION/OPTIONS → BICYCLE +**.

Use the attached mod ZIP, **not GitHub's automatic Source code ZIP**. `SHA256SUMS.txt` is an optional download-integrity check, not another mod.

## One-time update from v1.4.0 or v1.4.1

Those packages did not declare the GitHub repository used for update discovery. They cannot discover this new release through that missing field. Install **v1.4.2 once manually** to add it:

1. Save your game and return to the launcher's **MODS** tab.
2. Delete **only the old Bicycle Plus mod entry**, then import `bicycle_plus-1.4.2.zip`.
3. Enable the editions you use and fully close/reopen the app.

Do not delete your saves, app data or the whole mods folder. The inspected launcher retains the mod-options table when removing an installed mod. The mod ID and every runtime Lua file/settings key are unchanged, so existing settings keep the same namespace.

## Keeping the mod updated afterwards

Use the launcher's **Update All** (or its individual mod-update control). The manifest now declares:

```json
"github": "moocd123/gen1recomp-bicycle-plus"
```

The app checks this repository's GitHub releases, compares the installed version with the release tag, and selects the attached installable ZIP. The preferred asset name is **`bicycle_plus-<version>.zip`**. Future releases must keep increasing the mod version, match it in the `v<version>` tag, and attach that ZIP.

**Update All is user-triggered, not an always-running background updater.** Updates only become available after a newer release is published. No extra updater code or network permission is added to Bicycle Plus; the host launcher owns fetching and installation.

## Controls

Open **OPTION/OPTIONS → BICYCLE + → BIKE COLOUR**.

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

`ON BIKE` can be **BICYCLE** (bicycle music while riding, normal area music after dismounting), **AREA** (area music while riding) or **BOTH** (area and bicycle music together).

Cycling-only area/SFX settings can be set to **SAME** to inherit the normal setting, or overridden independently. This allows quieter filtered area music underneath louder unfiltered bicycle music while cycling, with normal audio restored after dismounting.

Area and bicycle music have independent volume and filter controls, and cycling SFX can use separate volume/filter settings.

## Compatibility and release history

The runtime code is unchanged from **v1.4.0**, the first public release. Historical companion-mod checks were on **Gen1ReComp++ v0.2.59** and must not be read as a complete retest on every newer engine. Known compatibility work includes **Trainer Skins, Running Shoes, Auto Field Moves, HM Field Unlock and Wilds of Kanto**.

See [COMPATIBILITY.md](COMPATIBILITY.md), [VERIFICATION.md](VERIFICATION.md) and [CHANGELOG.md](CHANGELOG.md). Compatibility with every third-party mod cannot be guaranteed.

## Source and release packaging

The production Lua files in the repository are the same files packaged into the release ZIP. The scoped publishing workflow verifies the manifest and runtime hashes, builds an explicit allowlist into the installable ZIP, and publishes it with a SHA-256 checksum. It does not overwrite existing releases and downloads the published asset to verify it. Packaging checks are not gameplay tests.

## License

Bicycle Plus source code is released under the **MIT License**. See [LICENSE](LICENSE).

Gen1ReComp++ is a separate project. Pokémon and related names, characters and game content are the property of their respective owners. This is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Creatures Inc. or GAME FREAK.

## Upstream

- [Gen1ReComp++ / Gen1Recomp](https://github.com/bryanthaboi/gen1recomp)
