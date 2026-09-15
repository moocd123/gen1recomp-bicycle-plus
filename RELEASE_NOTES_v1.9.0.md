# AUTOBIKE+ v1.9.0 — audio fixes and one settings menu

Formerly Bicycle Plus. **Use MODS → Check for updates → Update All**, then **fully close/reopen the app**. The internal mod ID and update repository are unchanged; existing settings remain available. The attached installer is still named `bicycle_plus-1.9.0.zip` for updater compatibility.

## Rebuilt menus

**OPTIONS → AUTOBIKE+** now has **AUTO BIKE first**, then **SFX FILTER**, **BIKE APPEARANCE**, **BIKE AUDIO** and LANGUAGE.

The game's Audio menu is left original: Music volume, SFX volume and Music filter are not renamed, and no bike-song or mod SFX-filter rows are injected there. Native Music controls normal/area music independently of cycling music.

**BIKE AUDIO** contains AREA VOLUME, AREA FILTER, SFX VOLUME, SFX FILTER, CYCLING MUSIC VOLUME, CYCLING MUSIC FILTER, BIKE SONG, then ON MOUNT: RESTART/RESUME. SAME inherits normal area/SFX settings. Use OFF on either music volume to select one track, or nonzero values on both to mix. Old AREA/BICYCLE/BOTH choices migrate to equivalent cycling volumes.

There is just one **BIKE SONG** route. Its **IMPORT SONG** action opens the system picker directly, then selects a successful import. Current-game songs, other already-imported games and saved local songs are available there. No separate tutorial/help/inbox options. A built-in browser is used under the same Import action where the host has no usable native picker.

## Playback repairs

The v1.8 implementation wrote through the sandbox compatibility filesystem but gave the native decoder/synthesiser the same alias as if it were a real file path. Those paths differ. This release uses the engine's scoped mod cache and hands imported audio bytes directly to the decoder via FileData. Existing v1.8 library copies are recovered read-only where available.

Foreign-game sound programs now use an engine-readable, distinct cache path. The active game is not switched and its audio banks are not overwritten. File-picking uses native engine import entry points rather than the restricted mod `io.open`/system shim.

Long names scroll on **one line**. Settings and appearance-row navigation are **one tap per position**; holding a direction no longer races through menu options. Colour-chart adjustment remains continuous. Sprite mappings and automatic cycling are unchanged.

## Testing notice

The workflow gates publication on native sandbox/storage/menu/audio tests and real LÖVE decoding/streaming tests of generated WAV, MP3, Ogg and FLAC files using null audio output. The user-supplied six-ROM local check compares short PCM output across all current/selected-game pairings. These are **not physical-device, complete-song listening or exhaustive companion-mod tests**.

Back up/export progress before testing. This update has no new progress-save writer or ROM patch, but a crash can lose unsaved progress. Imported music remains local; original source files are never removed. Please include the engine version, platform, source game/format and exact error when reporting a problem.
