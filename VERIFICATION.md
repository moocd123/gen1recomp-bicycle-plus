# AUTOBIKE+ v1.9.3 release verification

## Change boundary

Baseline: published v1.9.2, commit `de0d5f277f114c635ea8a426b027c3f650015125`.
The five changed runtime modules are import_picker.lua, song_library.lua (poll-time forwarding only), main.lua (poll timing and combined-handlebar preferences), colours.lua (one shared paint key) and colour_controls.lua (five visible components). The other ten modules, including the audio player, auto-mounting, foreign-game sound handling, colour picker, and bike-part pixel masks, are byte-for-byte unchanged.

The renderer algorithm is unchanged except that its existing Details group uses the Handlebars colour key. The builder reconstructs the previous renderer text and verifies its baseline SHA-256. No extra hand or clothing pixels are added to the masks.

## Release-gate checks

The previously prepared draft ZIP supplied the runtime changes. Its runtime hashes were rechecked against v1.9.2 before publication. These repeatable checks were added for this publishing pass:

- `check_release.lua`: 295 assertions using actual native Sandbox/LegacyCompat, import reader and scoped cache, with virtual files, OS responses and decoder. Covers current/legacy/markerless returns, stable and changing copies, partial files, checksum/count errors, corrupt audio, cancellation, retry, timeout, prior pending-record recovery, and protected progress/options/original/other-mod staging sentinels. Windows/macOS/Linux desktop dialog branches and picker-less fallbacks are included; the OS dialogs themselves are simulated.
- `check_options.lua`: 1,008 assertions using the actual Loader option API and native screen stack across 24 edition/preference cases. Covers five appearance controls, merge precedence, remembered custom colour, reset/safe mode, old setter alias, tap-only navigation and preservation of existing music, native options and progress fields. Graphics, audio and movement are doubled.
- `check_regions.lua`: 3,078 source-region transparency/combined-ownership assertions. This is classification testing, not a hardware render test. Unchanged mask geometry and the exact renderer-only change are checked separately by the build script.
- `love_test`: real LÖVE/PhysFS/FileData/MD5/SHA-256 and WAV, MP3, Ogg and FLAC decoders with the native mod sandbox and import reader. It simulates Android/iOS direct, legacy and markerless callbacks, then checks import completion, streaming, seeking, persistence, cleanup and protected files. Audio output uses OpenAL's null backend. No real phone chooser, speaker or full song listening is involved.
- Previously published library-isolation, first-ride and independent music-routing suites are rerun against this source. Tests that assert the obsolete six-control UI or only the old completion-marker format are not used as acceptance criteria for the new behaviour.

The local text-only runs use engine Lua/data extracted from the supplied v0.2.59 Windows build, not the running game executable. The GitHub workflow repeats them against pinned upstream v0.2.60 commit `4dadfd55a88e796c15fa7549b7c56e60e7c9b6d5` and runs the real-decoder test there. Consult the release's GitHub Actions run for the actual outcome; configuration alone is not proof that CI passed.

## Storage/safety assessment

No new progress-save writer, save-format conversion, ROM patch, active-game switch or permission is introduced. Handlebars preferences use the existing options-only writer. Imported songs remain in the existing mod-scoped cache. Native import cleanup is limited to the current mod request or its owned required-import slot; pre-existing unrelated staging blocks a new picker instead of being consumed. Original selected source files are never removed. The source hash/file allowlist excludes ROMs, trainer artwork, user audio and generated test tones from release packages.

The tests identified no direct progress-save corruption path in this patch. That is not a guarantee against crashes, lost unsaved progress, host bugs, exhausted storage or interrupted saves. Back up/export progress and save before testing new imports.

## Remaining device testing

The markerless-return defect is reproduced at a software boundary and matches the user's symptom; no phone log proves which native callback their installed build uses. Physical file-provider/chooser behaviour, cloud-download timing, every companion mod, full gameplay and complete-song listening still require user testing. Failure messages and retries exist for unsupported or unsuccessful imports. The public release is explicitly for further device testing, not a claim of universal compatibility.

The workflow publishes only after its checks and source-only build succeed, never overwrites previous releases, then downloads its own ZIP and verifies exact bytes and SHA-256. The Update All identity remains `bicycle_plus` in `moocd123/gen1recomp-bicycle-plus`.
