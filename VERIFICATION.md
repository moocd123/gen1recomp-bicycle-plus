# Bicycle Plus v1.8.0 verification

## Changes and baseline

This update is based on public v1.7.0. It adds bike_songs.lua, song_import.lua and song_menu.lua and updates main.lua, audio.lua and audio_menu.lua. All eight automatic-mount/colour modules are verified byte-identical to the v1.7.0 baseline by the builder. No ROM, extracted sound program, artwork or test-tone file is included in the installable archive.

## Executable automated tests

- **check_library:** ID/path validation, supported signature/decoder handling, duplicate detection, metadata backup, shared-session persistence, rename/remove, missing/corrupt files, donor lookup and unchanged active edition. Filesystem/codec boundaries are doubles in this suite.
- **check_importer:** capability routing for Windows, macOS, Linux, Android, iOS, NX, UWP and unknown builds; explicit inbox selection, path confinement, native completion/cancellation and ownership of transfer receipts. OS calls are simulated.
- **check_native_picker:** the engine's actual FilePicker and RomImporter picker-selection code, with HostShell/native-dialog boundaries simulated; Windows/macOS/Linux commands and Linux fallback, Android/iOS scoped destinations and picker refusal.
- **check_audio:** real native Music, event and hook chains, with Source and synth doubles, across six game contexts. Independent gains, cycling area/SFX overrides, filters, dismount/battle/fanfare/suspension, preview ownership, restart/resume and missing/bad-file fallback are checked.
- **check_menu:** real Screens/StateStack with input/render/library boundaries simulated. Six contexts cover all song pages, text bounds/overlap, paging, selection/preview, import, rename, confirmation and reset isolation.
- **check_sandbox:** the actual mod entrypoint in Sandbox/LegacyCompat with selected service doubles; settings validation, screen wiring and FileData/cache use.
- **check_updater:** actual Manifest/ModUpdate validation and preferred asset/version selection. This is not an end-user network installation.
- **codec:** real LÖVE imports, decodes and creates streaming Sources from newly generated WAV, MP3 and Vorbis tones, checks pause/resume/loop/source methods, SHA-256 duplicate detection and actual filesystem persistence. CI uses the null audio driver, not physical playback hardware.

CI uses upstream v0.2.60 commit 4dadfd55a88e796c15fa7549b7c56e60e7c9b6d5. Local headless checks used the Lua modules in the supplied v0.2.59 release. The optional local-ROM test additionally extracted sound metadata/banks with the native extractors and constructed/synthesised initial PCM for **425 registered song definitions**: 45 Red, 45 Blue, 49 Yellow, 92 Gold, 92 Silver, 102 Crystal. It used the actual user-supplied ROM bytes and ChipSynth with a software PCM sink; it did not play every complete song or validate full gameplay.

The release workflow runs its checks before packaging and publishing; see the repository's Actions result for what actually completed. It checks the runtime SHA-256 allowlist, unchanged baseline files and archive CRCs, then downloads the published asset and verifies its exact bytes.

## Limits

Native OS dialogs, file-transfer tools, physical controllers/touchscreens, phone lifecycle behaviour and every audio device are not physically tested here. A platform without an OS file picker uses the scoped audio inbox instead; a locked-down build with neither a picker nor a file-transfer route needs host support. A mod cannot conjure missing native APIs.

No new full-gameplay or all-companion-mod certification is claimed. Large imports may pause briefly while being validated/copied. Native dialog filenames may be unavailable, in which case the Rename action supplies a friendly name. Resume is in-session; clearing app data/mod cache deletes personal audio. Back up important originals.
