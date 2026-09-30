# AUTOBIKE+

Automatic Bicycle, Custom Bike Colours & Music for **Gen1ReComp++**.

**v2.0.0** brings the user-approved unified test build to the public release: Red, Blue, Yellow, Gold, Silver, Crystal, FireRed and LeafGreen in one mod. Gen 3 remains a beta feature of the host engine. **Requires Gen1ReComp++ v0.3.36 or newer, mod API 2.** Future engine changes may require another compatibility update.

## Install or update

Update the game first. Existing public AUTOBIKE+/Bicycle Plus v1.4.2+ users can use **MODS → Check for updates → Update All**, approve the requested permissions, then fully close and reopen the app. Do not delete saves or app data.

New installations: download **bicycle_plus-2.0.0.zip** from the v2.0.0 GitHub release, leave it zipped, import through MODS and enable it for your games. GitHub's automatic Source code archive is not the installer.

The display name is AUTOBIKE+; the established internal ID `bicycle_plus` and repository are retained so existing installations receive updates. The permissions are **engine_internals** and **compute**. Compute runs the independent GBA soundtrack player locally; it is not an online/paid service.

**Local testers:** disable AUTOBIKE+ Local Test and the earlier FireRed-only beta, enable the public AUTOBIKE+, then restart. Leave their data/cache in place for the first public launch. The one-time handoff adopts valid Test 2/3 profiles and copies its local songs without deleting the test originals. Existing public 2.x profiles take precedence on later launches. Missing, corrupt or previously deleted data cannot be recovered automatically. Export/back up saves before updating.

## Automatic cycling

When enabled and the Bicycle is owned, mount on entering a cycling-permitted area. Deliberate dismounting keeps you walking until you mount manually or enter another eligible area. Surf temporarily interrupting a ride is different: the mod remembers the bike, waits for safe permitted land and player control, and remounts. Auto Bike OFF, missing ownership, native restrictions, scripts and cutscenes remain respected.

New installations default to Auto Bike ON. Saved ON/OFF choices are not reset.

## Menu structure

Open **OPTIONS → AUTOBIKE+**:

- AUTO BIKE
- SFX FILTER (off-bike)
- BIKE APPEARANCE
- BIKE AUDIO
- LANGUAGE (UK/US spelling)

The game's ordinary Audio menu remains separate. Gen 1/2 keep the compact pixel UI; FireRed/LeafGreen use their native font/windows with the same labels/order.

### BIKE APPEARANCE

Five parts: **WHEEL, STRIPE, CENTRE, EDGE, HANDLEBARS**, followed by RESET COLOURS. The front, rear and side bike previews animate using the current game's/selected trainer's artwork. Gen 3 recolouring retains highlights, shadows and transparency. Original bypasses recolouring.

Each part cycles through **ORIGINAL**, the current game's named profile, then the other seven games in Red/Blue/Yellow/Gold/Silver/Crystal/FireRed/LeafGreen order. A confirms Original or opens the named profile's colour editor. The picker has a rainbow chart, brightness, RGB 0–255 and six-digit hex entry. APPLY saves; CANCEL discards the draft. Menu navigation is tap-only; continuous adjustment is available inside the picker.

A profile is shared on the same installation. Editing RED while playing FireRed also changes the RED paint used in Red. Other games keep their selected profiles; selecting ORIGINAL never overwrites a preset. Each bike component can use a different profile. Reset restores only the current game's five selections to Original; it does not erase shared presets.

### BIKE AUDIO

**ON BIKE: AREA / BICYCLE / BOTH**, area volume/filter, SFX volume/filter, cycling music volume/filter, BIKE SONG, ON MOUNT (restart/resume), then **PROFILE**.

The routing selector never rewrites saved levels, filters or song choices. Volumes are OFF–7; filters OFF/1X/2X/3X. SAME follows the normal setting where offered. Getting off restores normal audio.

Named audio profiles remember the complete cycling mix/song/restart preference and are shared across games. Each game remembers its own profile selection. Editing a setting while Original is selected changes to the current game's profile. First visits begin with original artwork/theme and BICYCLE routing, while taking the latest starting volume levels. Already-customised profiles retain their own mix.

### BIKE SONG

Keep the original bicycle theme, select current-game music, another **available imported** soundtrack, or import an MP3, Ogg Vorbis, WAV or FLAC. Only imported/available other soundtracks appear; unimported placeholders are hidden. The current game has its own Current Game Songs menu. Supported source formats include the six GB/GBC games and imported FireRed/LeafGreen/Emerald audio caches; this does not add Emerald gameplay or Ruby/Sapphire import support.

Press IMPORT SONG to open the host file picker (or host-visible browser fallback). Long names scroll on one line. The library supports preview, selection, rename and confirmed removal of its local copy. Original files are not deleted. The limits remain 64 MiB per file and 128 tracks. Imported copies are stored outside the installed mod so Update All does not replace them. Resume is within the current session, not a promise to retain sample position after closing the app.

ROM-derived cycling music follows the current game's native mono/stereo option where supported. Imported recordings keep their encoded channels; the mod does not rewrite the original file.

## Existing settings and compatibility

The shared-profile migration reads existing saved evidence and keeps settings-only backups. Played games can inherit their previous shared customisation; first-time games start Original. Old versions did not retain every historical per-game choice, so overwritten/unsaved values cannot be reconstructed.

Actual companion-mod checks include **Auto Field Moves 1.1.5, Running Shoes 1.1.2 and Trainer Skins 0.2.0**, including the Gen 1 Surf sequence with all three. This is not certification of every mod or combination. Chained hooks, player-only paint and native movement actions minimise interference; unknown future engine/mod changes can still conflict.

## Testing and known limits

The owner tested and approved 2.0.0-test.3 for public release. v2.0.0 preserves its gameplay/UI/audio/profile implementation, apart from the entry-point handoff needed to restore the public ID. Publication adds checks for public/test-data adoption, old preferences, native installation and the public updater identity. See **VERIFICATION.md** for precise executed checks and their limits.

**Known host issue:** the v0.3.36 test environment intermittently hung during process exit after switching FireRed and LeafGreen in one session. An all-mods-disabled control reproduced it. This release does not change engine teardown or claim to fix it. Save before exiting; restarting between GBA games is a conservative workaround. Never force-close during an active save or import.

No universal no-crash/no-save-loss guarantee is made. Back up saves, report your engine/mod versions and reproduction steps, and distinguish a failed import from a missing host feature.

## Credits and source

Created for moocd123's AUTOBIKE+ project. Mod source is available under the accompanying MIT licence. No ROM, extracted game artwork/font, soundtrack or personal recording is included.

Based on the Pokemon Gen 1 Recompilation Project by BOIS CLUB GAMES, LLC (https://github.com/bryanthaboi/gen1recomp).
