# AUTOBIKE+ v1.9.1 verification

## Change boundary

Baseline: published v1.9.0 commit `636856e2adee19a32296c06415726e5c740b14d6`.

Only `main.lua` and `audio_menu.lua` change at runtime: restore the routing choice in the option schema and Bike Audio menu, and replace mode-to-zero-volume migration with a routing-only migration. The existing audio engine already supports independent routing. The other 13 runtime modules are unchanged and checked by SHA-256 during packaging.

## Executed local regression checks

Tests ran using texlua and the engine Lua modules extracted from the supplied v0.2.59 Windows executable. This is not running the complete game executable.

- `check_mode_menu.lua`: native Sandbox/LegacyCompat, Screens/StateStack and both native OptionsMenu implementations. Nine initial-settings cases across six editions check old routing preservation, v1.9.0 zero-value retention, both saved/live options stores, repeated mode toggles and events, no gain/filter/song/resume changes, SAME/schema behaviour, tap-only input, selector layout, last-row reachability, idempotence, safe mode and untouched native Audio. Graphics, services and input are software doubles.
- `check_mode_audio.lua`: native Music/Hooks/Events with the production sandboxed library/audio modules and simulated playback Sources. Exercises six editions, original/current/imported-file songs, all 64 area/bike volume pairs, repeated AREA/BICYCLE/BOTH transitions, distinct filters, OFF, SAME inheritance, dismounting, battles and cleanup. This is not a real decoder or listening test.

The publishing workflow repeats these against pinned v0.2.60 engine commit `4dadfd55a88e796c15fa7549b7c56e60e7c9b6d5`, and reruns the existing v1.9.0 library/importer/audio regression tests. Consult Actions for the actual workflow outcome; configuration alone is not proof of execution.

## Integrity and limitations

The builder validates the manifest, exact runtime hashes, all 13 unchanged modules and a source-only file allowlist. The released ZIP is downloaded and compared byte-for-byte with the build.

No new physical phone, operating-system picker, GPU, speaker/listening or complete gameplay session was tested here. The real decoder checks from v1.9.0 remain historical evidence for the unchanged playback/import modules, not newly executed physical-device checks. Progress saves and imported library data are not migrated by this patch. Mode migration writes only the routing option and its layout marker via the existing options writer.

v1.9.0 did not retain gains it replaced with zero. Those values cannot be inferred safely; this patch preserves them instead of guessing. A user may need to raise an affected OFF channel once. Thereafter, changing the selector does not change either slider or filter.
