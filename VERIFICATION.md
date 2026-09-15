# Bicycle Plus v1.7.0 verification

## Scope

A colour-interface update based on the published v1.6.0. It adds an exact RGB value adapter and compact UI helper, replaces the picker, updates colour-menu persistence, and crops the published three-view preview to show a chosen facing. `audio.lua`, `audio_menu.lua`, `automount.lua`, `bike_parts.lua`, `colours.lua` and `hardware_colours.lua` are unchanged from published v1.6.0. The original renderer's palette, mask and world-paint paths remain intact.

## Automated checks

- All 32,768 old RGB555 values preserve their expansion. RGB555/HSV round trips, unrounded RGB values, hex validation, invalid channel rejection and exact known-colour references are checked.
- The real Screens and StateStack modules construct the menus across six game contexts. Input, device and graphics boundaries are simulated. Checks cover all six Original/Custom controls, last-custom persistence, draft cancellation, reset isolation, keyboard/paste/keypad entry, pointer coordinate transforms, drag cancellation, UI text bounds/overlap and safe-mode write rejection.
- The native SpriteRenderer is exercised using software ImageData/graphics. Every part can receive a non-RGB555 value; other pixels and alpha remain unchanged relative to the published masks. Front-facing handlebar preview, three-view preview, Original restoration and resolver cleanup are checked.
- Native Manifest and ModUpdate code validates the retained GitHub source, minimum engine/API requirement, version ordering and preferred release asset. This test does not perform a real end-user network installation.
- The builder checks an explicit runtime hash list and packages only reviewed source/documents. The workflow downloads the published ZIP and verifies its exact bytes/checksum.

Local checks used modules extracted from the supplied v0.2.59 Windows executable and 26 true-colour/quantised cases from the uploaded Trainer Skins v0.2.0 archive, plus two procedural sprite cases. Publication checks use upstream v0.2.60 commit `4dadfd55a88e796c15fa7549b7c56e60e7c9b6d5`, and hash-checked native/Trainer Skins test fixtures prepared by the existing v1.6.0 fixture script. No test artwork is bundled in the release.

See [Actions](https://github.com/moocd123/gen1recomp-bicycle-plus/actions) for actual publication outcomes and logs. Test assertion counts are implementation details, not coverage guarantees.

## Limits

No new physical phone, OS clipboard/keyboard, hardware GPU, controller driver, network updater or full gameplay session was tested here. Software tests cannot prove that every device or companion mod combination behaves correctly. Real-device feedback remains necessary. The open engine range is a version declaration, not a promise that future breaking API changes will be compatible.

Colour descriptions are exact matches to recorded digital references. LCD-look labels are approximations; unmatched colours are not assigned a historical name. New custom paint supports 24-bit RGB; old hardware-limited selections are neither discarded nor silently reinterpreted.
