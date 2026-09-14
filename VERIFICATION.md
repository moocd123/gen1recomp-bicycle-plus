# Bicycle Plus v1.6.0 verification

## Scope

This release changes the colour controls, palette organisation and bicycle pixel masks. **audio.lua, audio_menu.lua and automount.lua are byte-for-byte unchanged** from v1.5.0. Mod ID `bicycle_plus`, settings keys, API 2, the `>=0.2.59` range and the GitHub update source are retained. The only new per-part setting is `bike_handlebars_colour`, default Original.

The user-supplied Trainer Skins v0.2.0 ZIP has SHA-256 `9295d0f2749d9e5519257fdb6609f781af3b8482cfc91e28fcd2a0437cd5ce36`. Its actual Lua palette table contains ten named accents plus a separate True Color mode. Its older README's three-colour description is not used as the source of truth.

## Reproducible tests

From the repository root, with Lua 5.3 or texlua and an engine directory:

```sh
python3 verification/v1.6.0/prepare_fixtures.py ../fixtures/sheets.lua
lua5.3 verification/v1.6.0/check_colours.lua /path/to/engine
lua5.3 verification/v1.6.0/check_menu.lua /path/to/engine
lua5.3 verification/v1.6.0/check_renderer.lua /path/to/engine ../fixtures/sheets.lua
lua5.3 verification/v1.6.0/check_updater.lua /path/to/engine
python3 .github/scripts/build_release.py
```

The fixture preparer needs Pillow and network access to fetch three immutable PNG Git blobs and two hash-pinned Trainer Skins archives. It creates temporary data outside the mod. Optional `--native-dir` and `--trainer-zip` arguments allow local testing with the provided v0.2.0 archive instead of downloading both companion versions.

- **Colour catalogue:** exhaustive 32,768-word round trips, unique RGB output, deduplication, Original, section partition/order, per-section RRGGBB ordering, exact saved-value aliases and full trainer labels.
- **Native menus:** actual Screens/StateStack with production menu code in six edition contexts. Input, drawing and unchanged audio/movement services are test doubles. Tests cover every section and label, text bounds/overlap, pending previews, cancellation, one-write colour application, colour-only reset, default-NO confirmation, failed-write rollback, safe mode, UK/US spelling and untouched trainer/audio settings.
- **Source pixels:** actual PNG sheets through the native SpriteRenderer with software ImageData/graphics. Each part is recoloured alone; every other pixel/alpha is compared with the original resolved image. Separately specified handlebar/hand coordinates are checked, including Dawn/Hilda foreground cutouts. Both true-colour and luminance-quantised trainer sheets are checked. These are not GPU or device tests.
- **Updater:** native Manifest, launcher and Update All code. Release lookup/network and filesystem installation are simulated; versions 1.4.2 and 1.5.0 queue 1.6.0, current/newer versions do not reinstall/downgrade, and offline failure does not install. The engine version is an explicit test input, not a gameplay claim.

Local tests use the supplied v0.2.59 Windows package's extracted Lua modules. The publication workflow repeats them against the official v0.2.60 source pinned to commit `4dadfd55a88e796c15fa7549b7c56e60e7c9b6d5`, including both companion releases' artwork. Consult the actual Actions run for its outcome.

## Release integrity and limitations

The builder checks the exact manifest and SHA-256 of all nine production Lua modules, packages an explicit allowlist, creates per-file integrity metadata and checks the ZIP. The workflow downloads the published ZIP and checksum and compares their bytes with the build. Existing releases are never overwritten.

No ROMs, engine executables, sprite fixtures, trainer images, fonts, songs or private save data are included. No fresh full-gameplay, full-mod-stack or physical S24 Ultra test is claimed. The open engine range is not a guarantee against future breaking changes. Pixel-region interpretation and conservative exclusions are documented in docs/BICYCLE_REGIONS.md.
