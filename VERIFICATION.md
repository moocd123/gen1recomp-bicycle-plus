# Bicycle Plus v1.8.0 verification

## What changed

This build starts from published v1.7.0 (`ba08de57e2715cb28dae59b3b118cc004b4c62d5`). It adds `song_library.lua` and `music_menu.lua` and modifies `audio.lua`, `audio_menu.lua` and `main.lua`. Eight existing runtime files (the entire colour implementation and automatic mounting) remain byte-for-byte unchanged.

## Executed local checks

The tests in `verification/v1.8.0` run under Lua 5.3 / texlua against the Lua modules extracted from the supplied v0.2.59 Windows build. Key modules (FilePicker, Music, ChipSynth, Manifest and ModUpdate) were checked by Git blob hash against the v0.2.60 repository and are identical. This is not running a complete v0.2.60 executable.

- Library tests: bounded imports, byte deduplication, rename/remove, persistence, corrupt index fallback, missing files, safe-mode rejection, native pick markers and cross-game cache validation.
- Cross-platform picker tests: actual engine FilePicker branches for Windows, macOS and Linux with dialog/process responses simulated; native mobile capability and completion contracts; no-shell fallbacks for NX/UWP/unknown builds; nested inbox browsing and path rejection.
- Audio tests: actual Music and hook/event modules, with audio Sources and device boundaries simulated. All 64 area/bike level combinations, filters, modes, dismount, battle, fanfare, device-suspension state, restart/resume, preview, missing/failed file fallback and cleanup. Executed for all six edition contexts.
- Menu tests: actual Screens/StateStack, with software graphics and selected services mocked. Choosing tracks, rename/remove confirmation, saved-setting isolation, inbox fallback, help and file-drop ownership. Executed for all six contexts.
- Native Audio/OptionsMenu integration: both normal and cycling BIKE SONG openers, without duplicate rows, for all six editions.
- Native manifest/updater metadata: retained ID/repository, game/API declarations, version ordering and exact preferred ZIP name. No actual end-user network update is claimed.
- Optional ROM test: native ROM audio extraction and ChipSynth with the six separately supplied ROMs. 425 track starts rendered (512 stereo frames each), plus 36 current/selected game pairings with 2,048-frame exact PCM comparisons and active-game bank rechecks. The short silent starts are reported, not treated as proof of a fully audible complete song. No ROM bytes or generated audio are included in the ZIP or source-update archive.

Recorded local results are in `verification/v1.8.0/results`. The publishing workflow is configured to repeat the non-ROM checks against pinned v0.2.60 source. Until that workflow actually runs, its success must not be assumed.

## Packaging

The build script validates a source allowlist, runtime SHA-256 values, unchanged baseline Git hashes, manifest/update metadata and ZIP round-trip/CRC checks. `.modkit/pack.json` records per-file integrity; SHA256SUMS.txt covers the installable archive. Neither original audio files nor test ROMs are packaged.

## Not established by these checks

No physical Android/iOS/Desktop/console file dialog or full hardware gameplay session was run here. Operating-system picker permissions, audio-device codecs/drivers, actual user-file decoding, controllers/touch drivers and every companion-mod combination remain device-test items. Mocked decoding is not labelled a real MP3/FLAC decode test; generated PCM is not labelled a listening test. Future engine changes may require adaptation despite the open minimum-version declaration.

## Pre-publication safety review

The custom-music code has no progress-save writer, save-format migration, ROM patch or active-game switch. Song choices use the existing options-only writer. Imported tracks, alternating index files and foreign sound-program copies use `mod_data/bicycle_plus/music`; native picking uses only this mod's separate temporary destination and matching completion flags. Original user-selected files are read, not deleted.

The added `check_safety.lua` guards every mocked filesystem write/delete/directory creation, with protected progress-save, global-options, original-audio, ROM/save/mod-staging and unrelated-mod sentinels. Import, rename, remove, malformed-index/path rejection and interrupted-index recovery passed without changing those sentinels. This is a software-boundary test, not a disk/power-loss or physical-device guarantee. The library/index and all six audio-context tests were repeated before publication.

There is no identified direct progress-save corruption path in this review, but a mod crash, host bug, exhausted storage or interrupted host save cannot be ruled out. Importing a large file uses bounded memory and disk space. Back up/export saves and save current progress before trying new features. The release is intentionally offered through ordinary Update All with a prominent testing notice; new custom songs are not selected automatically.
