# Changelog

## 1.9.2 — First-install defaults

- Default to AUTO BIKE ON, BICYCLE routing and the original bicycle theme.
- Initialise only a missing bicycle volume from normal Music once, retaining OFF.
- Preserve saved mode, auto-bike choice, volume, filters and all unrelated preferences on update/reinstall.
- Read raw saved/live stores before option-schema fallbacks; initialise when game options are ready.
- Keep AREA/BICYCLE/BOTH independent from volume/filter choices.
- Only main.lua changes at runtime; playback, file importing, colours and movement modules are unchanged.

## 1.9.1 — Restore the quick cycling-music selector

- Add ON BIKE: AREA / BICYCLE / BOTH at the top of BIKE AUDIO.
- Preserve every saved volume, filter, song and restart/resume choice when switching modes.
- Replace destructive mode-to-volume migration with routing-only migration.
- Preserve direct upgrades from older mode-based versions and do not guess gains already overwritten by v1.9.0.
- Keep native Audio unmodified, AUTO BIKE first, one Bike Song path and tap-only settings navigation.
- Add regression checks for migration, mode switching, mix preservation, native menu isolation and all six audio contexts.

## 1.9.0 — AUTOBIKE+ rebrand and music repair

- Display name AUTOBIKE+; keep update identity, repository and saved keys.
- AUTO BIKE first, normal SFX FILTER, BIKE APPEARANCE and BIKE AUDIO in one root menu.
- Restore native Audio menu and labels; no duplicate song/cycling/settings injections.
- One cycling audio page and one song chooser; direct Import Song, automatic selection on success and single-line marquee names.
- Replace compatibility-overlay paths with scoped cache/FileData audio; recover old imports and expose foreign sound banks to the real synthesiser.
- Route picking/reading through native engine APIs in the genuine sandbox; isolate generated staging and cancelled requests.
- Press-edge menu/appearance navigation; retain continuous colour-chart adjustments.
- Migrate older mix modes to equivalent cycling volumes without changing normal music/SFX preferences.
- Add real-sandbox tests and a real LÖVE codec/stream/storage test gate.

## 1.8.0 — Custom cycling music

- Local audio import, preview, rename and confirmed library-copy removal.
- Current-game and other imported Pokémon soundtrack selection with isolated sound-program cache keys.
- Desktop/mobile system-picking routes, scoped portable inbox browser, nested folders and chained file-drop import.
- Durable library outside the installed mod directory, duplicate-content checks and alternating index snapshots.
- Restart/resume in-session, native-scale bicycle volume/filter and missing-file fallback.
- Native Audio/Cycling menu openers; preserve the colour/automatic-cycling code and update source.
- Add platform adapter, library, menu, audio-state, updater and optional local-ROM synthesis tests.

## 1.7.0 — Original/Custom RGB editor

- Replace system/preset navigation with one hue/saturation chart and brightness slider.
- Exact 0–255 RGB and six-digit hex fields with controller keypad, keyboard/paste and mouse/touch input.
- Original/Custom per part, remembered custom values and all six controls plus reset on one screen.
- Solid selection arrow/highlight, compact labels, no redundant title/artwork/page counter.
- Exact matching palette descriptions below the hex code; unknown values are not given historical names.
- Preserve all saved RGB555/alias values, audio, automatic cycling, bicycle masks and update metadata.
- Keep previews staged until Apply; add input/layout/persistence/pixel regression checks.


## v1.6.0 — Grouped palettes and handlebars

- System sections in DMG, Pocket, Light, Color order, followed by Trainer references and the full GBC grid.
- Presets and quick colours sorted by displayed RRGGBB hex, not the packed RGB555 word.
- Unique shared swatches across preset sections; full TRAINER colour labels on their own line.
- Separate HANDLEBARS control, with native Gen 1/Gen 2-style source mappings and a forward-facing full-grid preview.
- Shared side hand outlines and occluded lower boundaries protected; Dawn/Hilda clothing rows preserved.
- RESET COLOURS below the six controls, with Cancel-first confirmation and no unrelated-setting changes.
- Existing paint IDs, Original, audio, automatic cycling and the in-app update source retained.

## 1.5.0 — Hardware-limited colour picker

- Add all 32,768 RGB555 colours and a native-button colour-grid editor.
- Merge duplicate preset colours from supported game/LCD/trainer references.
- Keep Original independently available for all five bicycle parts.
- Preserve exact old colour values and aliases; rename the off-black/off-white quick labels for clarity.
- Preview edits without saving until confirmed; retain quick Left/Right colour choices.
- Keep automatic mounting, audio and part-mask modules byte-for-byte unchanged.
- Retain native Update All discovery from v1.4.2, the mod ID and all existing settings keys.
- Add exhaustive colour, native-screen, software-pixel and updater-state tests with explicit device-testing limits.

## 1.4.2 — In-app updates and open-ended engine range

- Add `github: moocd123/gen1recomp-bicycle-plus` so the native launcher can discover releases for Check for updates / Update All.
- Publish the installable asset as `bicycle_plus-1.4.2.zip`, matching the updater's preferred `<id>-<version>.zip` naming.
- Replace the two-version engine declaration with `>=0.2.59`, with no upper version limit.
- Retain the minimum engine requirement, API 2 requirement, six-game targets, permissions, mod ID and settings namespace.
- Leave all six runtime Lua files unchanged from v1.4.0.
- Document the one-time manual installation needed for older packages that lack the GitHub field.
- Add native launcher/updater headless checks and scoped release packaging verification.
- An accepted future engine version is not a guarantee of gameplay compatibility. Future breaking changes can still need fixes.

## 1.4.1 — Engine-version compatibility hotfix

- Replace the exact `=0.2.59` engine requirement with `=0.2.59 || =0.2.60`.
- Remove the version-gate rejection of v0.2.60 while retaining the v0.2.59 declaration.
- Keep all six production Lua files byte-for-byte identical to v1.4.0.
- Preserve the mod ID, settings keys, optional Trainer Skins dependency and six-game targeting.
- Refresh public documentation and per-file packaging integrity hashes.
- Record the prepared hotfix's headless regression and launcher-version checks.
- Add a scoped v1.4.1 release builder that verifies the runtime hashes before publishing.
- Full v0.2.60 gameplay and physical-device verification remain pending. This release does not certify unrelated future engine versions.

## 1.4.0 — Initial public release

- Automatic Bicycle mounting when entering eligible areas while carrying the Bicycle.
- Deliberate dismount memory for the current area.
- Native cycling restrictions preserved across Red, Blue, Yellow, Gold, Silver and Crystal.
- Separate normal and cycling audio profiles.
- Bicycle, Area and Both cycling-music modes.
- Independent area/bicycle music volume and filter controls.
- Cycling-specific area and SFX overrides with SAME inheritance.
- Five independently configurable bicycle colour regions: WHEEL, STRIPE, CENTRE, EDGE and DETAILS.
- Animated three-direction colour preview on the original 16×16 sprite grid.
- English UK and English US spelling options.
- Trainer Skins compatibility work for versions 0.1.0 and 0.2.0.
- Compatibility safeguards for Wilds of Kanto and tested interactions with several other Gen1ReComp++ mods.
