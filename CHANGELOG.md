# Changelog

## 1.6.0 — Handlebars and organised colours

- Add independent HANDLEBARS and a colour-only, default-NO confirmed reset.
- Correct EDGE/DETAILS ownership, protect shared pedal/shoe boundaries and report the automatically selected Gen 1/Gen 2 artwork family.
- Organise hex-sorted unique presets into DMG, Pocket, Light, GBC and Trainer sections, with an All Presets view and the complete RGB555 grid.
- Replace SKIN abbreviations with full TRAINER colour names and verify all ten accents against the supplied v0.2.0 code.
- Retain existing saved values, Original, the updater source and all audio/automatic-mounting code.
- Add actual-source pixel checks and native menu/reset/section tests; no new physical-device gameplay claim.

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
