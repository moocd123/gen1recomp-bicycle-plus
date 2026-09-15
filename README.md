# Bicycle Plus

> **Testing notice:** Custom-song playback and file importing have passed automated checks but have not yet had in-depth real-device testing. **Export/back up your progress save before updating, and save your game before trying imports.** A crash can still lose unsaved progress. Custom music is opt-in: the new song setting defaults to **Original**.

Automatic cycling, independent cycling audio settings and bicycle colour customisation for Gen1ReComp++.

**Current release: v1.8.0 — Custom cycling songs.**

[Download and release notes](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/latest) · [Report an issue](https://github.com/moocd123/gen1recomp-bicycle-plus/issues)

## Install or update

Already using v1.4.2 or later? In the launcher, choose **MODS → Check for updates → Update All**. Relaunch the game after updating. The mod ID remains `bicycle_plus` and its update source remains this repository.

New users: download **bicycle_plus-1.8.0.zip** from the release assets, leave it zipped, import it in **MODS**, then enable Bicycle Plus for the editions you play. Do not import GitHub's automatically generated Source code ZIP.

Users on v1.4.0/v1.4.1 need a one-time manual update because those versions lack the GitHub update source. Delete only the old Bicycle Plus entry in MODS, import the new package and enable it. Do not delete saves or app data.

## Features

- Automatically mounts the Bicycle when you enter an eligible area and have the Bicycle in your inventory.
- Remembers deliberate dismounting until you enter a new area or mount manually; follows native restrictions and waits for player control.
- Separate normal and cycling audio profiles: area/bicycle/both music, independent volumes and filters, plus cycling-specific area/SFX overrides. Choose the original bicycle theme, another imported game track, or a local audio file for the bicycle layer.
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

The automatic-mount and colour modules have not changed for v1.8.0. The independent bicycle audio layer now supports song selection. Previous compatibility work for Trainer Skins, Running Shoes, Auto Field Moves, HM Field Unlock and Wilds of Kanto is retained; not every companion version/combination has been freshly retested.

## Custom cycling songs

Open **OPTION/OPTIONS → AUDIO → BIKE SONG**, or **BICYCLE + → AUDIO → BIKE SONG**. The same opener is also available in **AUDIO → CYCLING**.

- **ORIGINAL BICYCLE THEME** restores the normal bicycle soundtrack.
- **CURRENT GAME SONGS** lists music from the current game's loaded audio registry.
- **OTHER IMPORTED GAMES** lists Red, Blue, Yellow, Gold, Silver and Crystal. An edition must have been imported through the launcher first. This does not extract music from unrelated GB/GBC games or contact an online soundtrack service.
- **MY AUDIO FILES** lists imported songs. Open one for **PREVIEW SONG / STOP PREVIEW**, **USE FOR CYCLING**, **RENAME**, or **REMOVE LOCAL COPY** (confirmation defaults to Cancel).
- **IMPORT AUDIO FILE** opens the host file picker when available. Choose **MP3, Ogg Vorbis, WAV or FLAC**, up to **64 MiB per file**. The actual decoder must accept the file. M4A/AAC, streaming-service links and DRM-protected downloads are not supported.
- **BROWSE MUSIC INBOX** opens the portable in-app file browser. Files and subfolders in the dedicated inbox can be selected with the controller, mouse or touch. This browser does not scan your home directory or bypass OS access permissions.
- **ON MOUNT: RESTART / RESUME** chooses whether the selected song starts over or resumes between rides in the current game session. It does not save the playback position across quitting/restarting the application.
- **FILE IMPORT HELP** displays the inbox location and provides folder-opening/path-copy actions when the platform supports them.

Song lists use **Up/Down** to select, **Left/Right** to move eight entries, **A** to open/activate, and **B/Start** to return. Pointer selection and an on-screen rename keyboard are included. Long track descriptions scroll horizontally. Preview is explicit and temporary; browsing does not save a new song until **USE FOR CYCLING**.

The selected song replaces **only the bicycle layer**. **BICYCLE / AREA / BOTH**, **BIKE VOL**, **BIKE FILTER**, the area/SFX controls and normal/cycling profiles keep their meanings. In AREA mode the selected bicycle song is not played. Preview uses BIKE VOL/FILTER, so raise BIKE VOL above OFF to hear it. Imported recordings are not loudness-normalised; different files can sound louder than the original soundtrack at the same slider level.

Missing/unreadable selected files fall back to the original theme without deleting the selected ID. Battles, Surf, music interruptions and dismounting use the existing native/profile rules. Reimporting the missing song or choosing a new song restores it. Use Preview to inspect an import before selecting it.

**File picking across platforms:** Windows uses the native desktop dialog; macOS uses the macOS picker; Linux tries Zenity then KDialog. Android/iOS use the app's advertised `required_import` native bridge, not an assumed Android-only path. A missing/refused picker opens the in-app inbox browser. Console and other builds without a picker use that same browser after you copy files into the inbox using the platform's supported file-transfer mechanism. Desktop builds can also accept MP3/OGG/WAV/FLAC dragged onto an open Bicycle Song menu. Unsupported files and other screens retain their existing drop handlers.

Imported audio is copied locally to **`mod_data/bicycle_plus/music` under LÖVE's save directory**, outside `mods/bicycle_plus`, so replacing the mod through Update All does not replace the music library. The actual path is shown by FILE IMPORT HELP. This location follows LÖVE's save root even when the engine uses a separate portable-mode save/cache location; back up the music directory too when moving a portable installation. Removing a library track removes only the copied file, not the original file you selected. The library supports **128 imported files**, deduplicated by exact file content. Clearing application data or uninstalling the app can still remove its local storage.

See [CUSTOM_MUSIC.md](docs/CUSTOM_MUSIC.md) for platform requirements, storage and playback details.

## Verification and development

[VERIFICATION.md](VERIFICATION.md) describes the automated checks and limitations. The publishing workflow is configured to test the source before packaging, checks the runtime hashes and download bytes, and publishes an installable ZIP. Software-boundary tests are not a physical-device gameplay claim. [CHANGELOG.md](CHANGELOG.md) records public releases; v1.4.0 was the first.

Source is under the [MIT License](LICENSE). Pokémon and associated game content belong to their respective owners. This is an unofficial fan-made mod, not affiliated with Nintendo, Creatures Inc. or GAME FREAK. [Gen1ReComp++ upstream](https://github.com/bryanthaboi/gen1recomp).
