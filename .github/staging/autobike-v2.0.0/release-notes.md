# AUTOBIKE+ v2.0.0 — Gen 3 and shared profiles

**Update Gen1ReComp++ to v0.3.36 or newer first.** Then use **MODS → Check for updates → Update All**, approve the local compute permission and fully restart. The public mod ID and update source are unchanged. Manual installs use **bicycle_plus-2.0.0.zip**, not GitHub's Source code ZIP.

## New since v1.9.3

- **One mod, eight games:** Red, Blue, Yellow, Gold, Silver, Crystal, FireRed and LeafGreen.
- **Native Gen 3 menus and shaded bike paint:** same layout/controls and animated three-view preview, using the current trainer's original artwork.
- **Shared colour and audio profiles:** game-named presets are editable from any game. Each game remembers its own selected profiles; each paint part can select a different preset.
- **Original defaults for new games:** original artwork and bicycle theme with BICYCLE routing. Starting volume levels carry over without overwriting customised profiles.
- **Cross-generation music:** select available imported GB/GBC/GBA soundtracks from any supported game, or use local MP3/Ogg/WAV/FLAC. Missing imports are hidden rather than shown as unavailable placeholders.
- **Native sound mode:** ROM-derived cycling music follows mono/stereo where the game offers that setting; imported recordings keep their encoded channels.
- **Surf return repair:** a ride interrupted by Surf resumes on safe cycling-permitted land. Deliberate dismounting and Auto Bike OFF still take priority, including the tested Auto Field Moves integration.

All existing automatic cycling, five-part paint, RGB/hex entry, independent volumes/filters, AREA/BICYCLE/BOTH and restart/resume features remain.

## Settings, songs and local-test users

Existing v1.x preferences migrate into the shared profile model using available saved-game evidence. Previously overwritten or unsaved per-game history cannot be invented. Installation does not delete progress or music libraries.

**Test 2/3 users:** disable AUTOBIKE+ Local Test and the older FireRed-only beta, enable the public AUTOBIKE+, and restart. Keep their data/cache for the first public launch. The release adopts valid named profiles and copies local test songs once, using the normal library validation, leaving originals intact. Existing public 2.x profiles win on later starts. The two mod IDs must not run together.

## Verification and limits

This release promotes the owner's tested 2.0.0-test.3. The public-ID handoff is additionally checked before publication. Native-loader/menu/audio/import tests, profile failure tests and ZIP identity/hash checks are documented in VERIFICATION.md. Automated picker callbacks and silent audio output are not physical-device or speaker tests. Confirmed companion-mod coverage is Auto Field Moves 1.1.5, Running Shoes 1.1.2 and Trainer Skins 0.2.0; not every possible stack.

**Known v0.3.36 host issue:** shutdown sometimes hung after switching FireRed and LeafGreen, including with every mod disabled. This is not fixed here. Save first and restart between GBA games for conservative use. Never force-close during an active save/import.

**Back up your saves before updating.** No new progress-save writer or ROM patch is introduced, but a crash can lose unsaved progress. Gen 3 itself remains beta in the host.
