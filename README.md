# Bicycle Plus

Automatic cycling, independent cycling audio settings and bicycle colour customisation for Gen1ReComp++.

**Current release: v1.8.0 — Custom cycling songs.**

[Download and release notes](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/latest) · [Report an issue](https://github.com/moocd123/gen1recomp-bicycle-plus/issues)

## Install or update

Already using v1.4.2 or later? In the launcher, choose **MODS → Check for updates → Update All**. Relaunch the game after updating. The mod ID remains `bicycle_plus` and its update source remains this repository.

New users: download **bicycle_plus-1.8.0.zip** from the release assets, leave it zipped, import it in **MODS**, then enable Bicycle Plus for the editions you play. Do not import GitHub's automatically generated Source code ZIP.

Users on v1.4.0/v1.4.1 need a one-time manual update because those versions lack the GitHub update source. Delete only the old Bicycle Plus entry in MODS, import the new package and enable it. Do not delete saves or app data.

## Custom cycling songs

Open **OPTION/OPTIONS → BICYCLE + → AUDIO → BIKE SONG**. Choose the original bicycle theme, the current game's soundtrack, another imported Red/Blue/Yellow/Gold/Silver/Crystal soundtrack, or your own **MP3 / Ogg Vorbis / WAV** file. No songs or ROMs are supplied by the mod.

Use **Up/Down** to browse, **Left/Right** to page, **Select** to preview and **A → USE FOR CYCLING** to select. **B** returns. Personal audio can be renamed or removed after confirmation. **ON MOUNT** offers **RESTART / RESUME** within the current session.

The selected song still uses **BIKE VOL / BIKE FILTER** and **BICYCLE / AREA / BOTH**. Normal music returns when you dismount. A preview does not save a song selection.

**IMPORT AUDIO FILE** uses the host's available picker: desktop dialogs on Windows/macOS/Linux, or the engine's native document bridge on supported mobile builds. **AUDIO INBOX** provides a controller/mouse/touch file selector on builds without a usable dialog: copy files into `mods/bicycle_plus/baseroms/audio_inbox/` in the app's game-data directory first. Native dialog availability depends on the platform/build.

Imported files remain local and live outside the replaceable code folder, so ordinary mod updates preserve the library. Limits are **64 MiB per file and 128 files**. See [CUSTOM_MUSIC.md](docs/CUSTOM_MUSIC.md) for platform routes, controls, storage and limits.

## Features

- Automatically mounts the Bicycle when you enter an eligible area and have the Bicycle in your inventory.
- Remembers deliberate dismounting until you enter a new area or mount manually; follows native restrictions and waits for player control.
- Separate normal and cycling audio profiles: area/bicycle/both music, independent volumes and filters, plus cycling-specific area/SFX overrides. The bicycle layer can use the original theme, another imported-game track or a personal audio file.
- Six independent bicycle paint regions: **WHEEL, STRIPE, CENTRE, EDGE, DETAILS and HANDLEBARS**.
- An animated preview of your active trainer and bicycle, on the original sprite grid.
- **Original / Custom** per part, an RGB/hex colour editor, and a confirmed **Reset Colours** action.
- English UK / English US spelling.
- Native update discovery through this repository's releases.

Supports **Red, Blue, Yellow, Gold, Silver and Crystal**. Requires Gen1ReComp++ **v0.2.59 or newer** with mod API 2 support. There is no upper version limit, but that is not a guarantee against future breaking engine changes.

The mod uses portable Lua and is intended for any supported platform exposing the normal mod system. Not every physical device has been tested. No ROMs, game executables or replacement trainer artwork are included.

## Bicycle colours

Open **OPTION/OPTIONS → BICYCLE + → BIKE COLOUR**.

All six parts and Reset Colours are visible together. **Up/Down** chooses a row. **Left/Right** switches between **Original** and the remembered **Custom** colour. **A** confirms Original or opens the Custom editor. Clicking/tapping the type column switches it; clicking/tapping the part label activates it.

Original preserves the current trainer/bicycle artwork. Switching to Original does not discard the last custom colour. Reset Colours restores all six parts to Original after confirmation; it does not reset your trainer, language, audio or automatic-cycling options.

### One colour chart

The editor has a rainbow **hue/saturation** chart and a separate **brightness** slider. It accepts exact R, G and B values from **0 to 255** or a six-digit **RRGGBB hex code**, with an optional `#` when pasted. New values are stored as exact 24-bit RGB, not rounded to the GBC's RGB555 steps. Existing saved colours retain their old RGB values.

**Controller:** D-pad moves within the selected control. **Select** cycles through chart, brightness, R, G, B, hex, Apply and Cancel. **A** opens a field's on-screen keypad or applies the colour. **B** cancels the editor. Inside a field, the keypad has OK and BACK; confirming a field changes the draft, not the saved part, until you apply the whole colour.

**Mouse/touch:** Select/drag the chart and slider, or select a numeric field/button directly. Native virtual D-pad/buttons retain first refusal where they cover the screen. The footer leaves its centre clear of Apply/Cancel so those actions are away from the usual Select/Start overlay.

**Keyboard:** Tab cycles focus. Enter edits the selected field or applies; Escape cancels. While editing a field, type digits/hex, use Backspace/Delete, Enter to accept, Escape to cancel, or Ctrl/Cmd+V to paste where clipboard access exists. Engine hotkeys are suppressed while a numeric field owns keyboard input; controller buttons still drive its keypad.

The sprite preview changes while you browse. **Apply saves the draft; Cancel leaves the previous saved colour untouched.** The Original/Custom switch itself immediately changes that part's saved type/colour, separately from the editor's draft.

### Recognised colours

Descriptions below the hex code preserve the palette-reference work without forcing you through preset pages. An exact match may display **TRAINER SKINS GREEN**, **GBC BOOT**, **GBC GAME**, or a recorded LCD-look reference. Multiple names for one value rotate. Other RGB555 values display **GBC RGB555 COLOUR**; otherwise the description is **CUSTOM RGB**.

All ten named Trainer Skins v0.2.0 accents can now be matched exactly, including the six that previously needed hardware rounding. True Colour is an artwork mode, not one additional paint swatch; not every colour from every replacement sprite has a source label. DMG, Pocket and Light references are LCD-look approximations rather than calibrated physical-screen measurements.

The six regions describe visible pixel groups. Shared outlines are inherently ambiguous in this art. The Gen 1 and Gen 2-style mappings are selected automatically; this editor does not swap the bicycle style or assert official anatomical labels. See [the region notes](https://github.com/moocd123/gen1recomp-bicycle-plus/blob/v1.6.0/docs/BICYCLE_REGIONS.md).

## Audio and automatic cycling

The **AUDIO** page sets normal area/SFX volume and filtering. **AUDIO → CYCLING** sets **BICYCLE / AREA / BOTH**, bicycle volume/filter, and riding-only area/SFX overrides. **SAME** follows your normal setting. Dismounting restores normal audio. Choosing Bicycle gives original-style music switching without silencing the walking area's track.

The automatic-mount controller and all colour-editor/renderer modules remain unchanged in v1.8.0. The audio layer now supports song selection. Previous compatibility work for Trainer Skins, Running Shoes, Auto Field Moves, HM Field Unlock and Wilds of Kanto is retained; not every companion version/combination has been freshly retested.

## Verification and development

[VERIFICATION.md](VERIFICATION.md) describes the automated checks and limitations. The workflow tests the actual source before packaging, checks the runtime hashes and download bytes, and publishes an installable ZIP. Software-boundary tests are not a physical-device gameplay claim. [CHANGELOG.md](CHANGELOG.md) records public releases; v1.4.0 was the first.

Source is under the [MIT License](LICENSE). Pokémon and associated game content belong to their respective owners. This is an unofficial fan-made mod, not affiliated with Nintendo, Creatures Inc. or GAME FREAK. [Gen1ReComp++ upstream](https://github.com/bryanthaboi/gen1recomp).
