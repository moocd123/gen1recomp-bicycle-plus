# AUTOBIKE+ v2.0.0 — promotion and verification

## Change boundary

User-approved baseline: AUTOBIKEplus_Unified_Test_2.0.0-test.3.zip, SHA-256 `552401b9bbad5baa3c50f6e0ebc750f313968e88f5ad544856b07e9f3e2533c9`.

35 of its 36 runtime Lua modules are byte-for-byte unchanged. main.lua adds the public-upgrade bootstrap, with one new public_upgrade.lua. The metadata restores bicycle_plus / AUTOBIKE+ / version 2.0.0 and its existing GitHub update source, requires >=0.3.36, and conflicts with the local test and earlier FireRed beta. The 37 runtime hashes and approved-change boundary are recorded in verification/v2.0.0/runtime-sha256.json.

The new handoff adopts valid local-test profile journals once when no public profile already exists, copies test audio through the production decoder/library, and preserves verified GBA cache mirrors. Auto Bike OFF, off-bike SFX filter and language are copied with the native options-only writer. Existing test originals are never deleted. Checkpoints make an interrupted adoption retryable; existing public 2.x profiles win on subsequent starts. No progress-save writer or ROM patch is added.

## New local checks executed for the public identity

Environment: extracted official Gen1ReComp++ v0.3.36 source at 8cb3677a8a28df68a678fdac741ca1de216e0168; LÖVE 11.5/Linux/Xvfb, native Loader/Sandbox/graphics/decoders, OpenAL null output. Private ROM caches for the nine supported soundtrack sources were extracted locally from the owner's supplied files; none are redistributed.

- All 37 runtime modules compile.
- Shared profile storage suite: 7,342 assertions and 2,697 simulated-cache writes, including failures and recovery.
- Public upgrade suite: 548 assertions for all eight game contexts, source isolation, one-time adoption, false/zero, delayed options, corrupt journals, checksum rejection and failed-write retries. Storage/device boundaries are simulated.
- Public-ID native profile/menu integration: all eight games, 722/723 assertions per game, including colour drafts/apply/cancel, profiles and unchanged native mono/stereo preference.
- Public-ID local-file import integration: all eight games, 120 assertions each, with actual WAV/MP3/Ogg/FLAC decoding, streaming, seeking, rename and native bounded-reader paths. The six Android/iOS return callbacks per game are simulated, not physical OS dialogs.
- Public-ID mounted audio/profile routing: all eight games against all nine available soundtracks (72 mounted combinations); 281/291 assertions per game. Real native game state and audio synthesis are used with silent device output.
- Native migration fixture: the original Test 3 package created shared profiles, explicit Auto Bike OFF, all four local audio formats and three GBA cache mirrors. The public package then adopted them in Red and reopened them in FireRed, verifying unchanged test-source hashes, retained selectors/values and actual playback/seek of the four formats.
- Native manifest/updater check: stable ID, public version, minimum engine, conflicts, expected release ZIP selection and ordering after v1.4.2/v1.7.0/v1.8.0/v1.9.3.

One migration test initially enabled both mod IDs; the fixture was corrected to explicitly disable the other ID. A cross-process test initially compared unordered JSON strings; actual decoded data was equal and the assertion was corrected to compare field values. Neither correction changed production gameplay code or removed a safety gate.

## Prior Test 3 evidence (not new claims of complete replay here)

Test 3's report recorded actual Auto Field Moves 1.1.5 / Running Shoes 1.1.2 / Trainer Skins 0.2.0 Gen 1 Surf checks, generation-specific remount tests, 2,558 mount-state assertions, 2,048 imported/missing soundtrack combinations, 40 game-suite integration cases and 32 installed-package acceptance runs. These concern the unchanged Surf/catalogue/gameplay modules. The user subsequently tested and approved that ZIP for public release.

## Publishing checks

The release workflow reconstitutes exact reviewed source from pinned repository snapshots and hash-checked edits, runs Lua compilation/profile/public-upgrade/updater checks against pinned v0.3.36, builds an allowlisted ZIP, commits without a forced push, publishes only if v2.0.0 does not already exist, and downloads its own assets for byte and SHA-256 comparison. Read the Actions result for the actual outcome; the presence of a workflow alone does not prove it ran.

The public package's native installation and post-install checks are recorded in the release's package acceptance record. An installable ZIP is never claimed solely because a builder exists.

## Limits and known host issue

No universal compatibility guarantee is made. Native OS picker responses were simulated; audio output was null, so this is not speaker/headphone listening. Full playthroughs, every location/cutscene, every modern companion-mod release and the entire user's mod stack were not tested. User testing is additional evidence, not an exhaustive certification.

The v0.3.36 process sometimes hung on shutdown after FireRed/LeafGreen switching, including an all-mods-disabled reproduction in the Test 3 session. This release does not modify engine teardown or claim to fix that host issue. Save before exiting; restarting between GBA games is a conservative workaround. Never force-close while a save or import is writing.

No uploaded ROM, game font/art, extracted soundtrack or personal recording is included. Back up progress before installing updates: source isolation does not eliminate crashes or loss of unsaved progress.
