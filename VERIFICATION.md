# AUTOBIKE+ v1.9.2 verification

## Change boundary

Baseline: published v1.9.1 commit `1d2c0e51aec99042ac4827d077b6410dc076154b`. Only `main.lua` changes at runtime. The other 14 runtime modules are checked unchanged. This patch changes missing-mode defaults to BICYCLE, initialises missing bike volume from normal Music once, and persists the existing/default auto-bike value without overriding false.

## Executed local checks

The local runner used texlua and engine Lua source extracted from the supplied v0.2.59 Windows executable, not a running game executable. The extracted Loader and Music modules' Git blob hashes match the pinned v0.2.60 source inspected for this change.

- `check_defaults.lua`: 1,266 install/upgrade cases over six editions and 34,248 assertions. Uses the actual Loader `_api` options define/get methods, native sandbox, event bus and screen stack. Audio/movement/graphics/filesystem are test doubles. Covers initial Music 0–7, stored bike 0–7, all three routes, stored false/zero, separate raw stores, older markers, legacy mode aliases, missing/invalid native values, delayed options availability, one-time persistence, mode switching, safe mode and retained settings on a new mod instance.
- `check_first_ride.lua`: 48 initial-volume/edition cases and 564 assertions. Loads the production main/audio/library and native Loader/Music modules. Sources and movement are simulated. Checks bicycle-only initial routing, inherited gain including OFF, restoration on foot, independent later Music changes, AREA/BOTH switching and audio cleanup.
- `check_updater.lua`: native manifest/update metadata, stable mod ID/repository, preferred installable ZIP and ordering.

The publishing workflow repeats these checks against upstream v0.2.60 commit `4dadfd55a88e796c15fa7549b7c56e60e7c9b6d5` and runs the existing sandbox/import/routing suites. See Actions for actual outcomes; configuring a workflow is not proof that it passed.

## Integrity and limits

The builder checks all runtime hashes, 14 unchanged modules and an explicit source/document allowlist. It creates a deterministic ZIP and per-file metadata. Publication downloads its own uploaded assets to compare bytes and verify SHA-256.

These checks are not a hardware-device, file-picker, decoder-listening or complete gameplay test. No new audio engine, movement, import or progress-save path is introduced. New preferences use the existing options-only writer. A crash or host failure can still lose unsaved progress. Backups remain appropriate when testing.

A saved OFF volume is never raised. The initial normal Music value is a one-time copy rather than ongoing inheritance. Existing presets keep their mode and levels; old v1.9.0 values already changed to zero cannot be safely reconstructed.
