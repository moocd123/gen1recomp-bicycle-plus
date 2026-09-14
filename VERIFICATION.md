# Bicycle Plus v1.5.0 verification

## Scope

The colour editor and colour lookup now use a unique RGB555 catalogue. `hardware_colours.lua` and `colour_picker.lua` are new; `main.lua` and `colours.lua` integrate them. The **audio.lua, audio_menu.lua, automount.lua and bike_parts.lua files are byte-for-byte unchanged** from public v1.4.2. The mod ID, API requirement, open engine range, GitHub source and saved option names stay the same.

This is not a fresh full-gameplay or physical-device test. The app's graphics driver, touch layout, installed companion-mod stack and network/installer behaviour still need normal user testing. The new feature is not a promise of compatibility with untested future engines.

## Reproducible checks

From the repository root, using Lua 5.3 or `texlua` and an engine source directory containing `src/` and `data/`:

```sh
lua5.3 verification/v1.5.0/check_colours.lua /path/to/engine
lua5.3 verification/v1.5.0/check_menu.lua /path/to/engine
lua5.3 verification/v1.5.0/check_renderer.lua /path/to/engine
lua5.3 verification/v1.5.0/check_updater.lua /path/to/engine
python3 .github/scripts/build_release.py
```

- **Colour math:** enumerate all 32,768 words; verify packing, stored IDs, unique RGB expansion and exact round-trips. Check legacy appearance, strict input rejection, Original, all shipped GBC boot-palette references, preset deduplication and bounded/cyclic optional data.
- **Menus/persistence:** execute the actual main/picker code with native `Screens` and `StateStack` across six edition contexts. Graphics, button input and unchanged services are test doubles. Exercise pending previews, cancellation, confirmation into both native options stores, held directions, all blue slices, Original for every part, safe mode, UK/US labels and text bounds.
- **Rendering:** use the native `SpriteRenderer` with software ImageData/graphics. Verify target colour pixels, unchanged rider/other-component pixels and alpha, Original restoration, staged previews and resolver shutdown. Public fixtures are procedural, not extracted game assets.
- **Updater:** exercise the native manifest/range/discovery/Update All state machine for an installed v1.4.2 updating to a v1.5.0 release fixture. Transport, preferences persistence, UI and final filesystem installation are simulated. Current-version and offline cases must not reinstall/downgrade.

Local checks used the supplied v0.2.59 engine modules. The native SpriteRenderer Git blob was also checked against the official v0.2.60 tag and matched `2b74ea6936911b16e7e871573112e02105767264`. The publication workflow repeats the public suites using engine source from tag v0.2.60. Consult the actual [Actions run](https://github.com/moocd123/gen1recomp-bicycle-plus/actions) for its outcome.

An additional local software-pixel run covered the 13 bicycle sheets in the supplied Trainer Skins 0.2.0 package, both with their true-colour pixels and with its luminance-quantised form. These supplied-art fixtures are **not committed or packaged**. This is not a claim that every feature of Trainer Skins or all other mods was rerun on a phone.

## Release integrity

The builder checks all eight runtime SHA-256 hashes, the exact v1.5.0 manifest, unchanged update source, game targets, permission list and stable mod ID. It packs an explicit source/documentation allowlist, makes per-file integrity records and checks the ZIP. The publishing workflow downloads published assets again and compares their bytes and SHA-256 checksum. Existing releases are not overwritten.

Historical v1.4.x test records remain historical. No ROMs, engine executables, supplied trainer images, extracted sprites, songs or private data are included in the release.
