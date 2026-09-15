# Bicycle Plus v1.8.0 — Custom cycling songs

**On v1.4.2 or newer? Use MODS → Check for updates → Update All**, then relaunch your game. The mod ID and GitHub source are unchanged.

## Choose your cycling soundtrack

Open **OPTION/OPTIONS → BICYCLE + → AUDIO → BIKE SONG** (also in **AUDIO → CYCLING**).

- **ORIGINAL BICYCLE** restores the current game's normal bicycle theme.
- **THIS GAME SOUNDTRACK** lists the current game's registered songs.
- **OTHER IMPORTED GAMES** offers Red, Blue, Yellow, Gold, Silver and Crystal when their valid imports are available. It reads those imports without switching the running game.
- **MY AUDIO FILES** lists your imported MP3, Ogg Vorbis and WAV files.
- **IMPORT AUDIO FILE** opens the available system picker. Windows/macOS/Linux use desktop dialogs; Android/iOS use the engine's native document bridge where supported.
- **AUDIO INBOX** is an in-game file selector for builds with no usable dialog, including console-style builds. Copy audio to `mods/bicycle_plus/baseroms/audio_inbox/` in the app's game-data folder, then select a file in this list.
- **ON MOUNT: RESTART / RESUME** chooses whether a custom song starts again or continues after dismounting. Resume is session-local, not a saved playback position across application restarts.

Songs can be previewed without changing the selection. In a list, **Up/Down** selects, **Left/Right** changes page, **Select** previews/stops, **A** opens the selected song's actions, and **B** returns. Select **USE FOR CYCLING** to save the choice. Personal audio has rename and confirmed removal actions; removal deletes only the library copy, never the originally chosen device file.

The selected song replaces only the bicycle layer. **BICYCLE / AREA / BOTH**, the independent volumes/filters and normal/cycling SFX settings retain their roles. Preview also uses BIKE VOL/BIKE FILTER; raise BIKE VOL above OFF to hear it. Different recordings can be mastered louder or quieter despite using the same volume setting.

## Files and safeguards

Imports remain local; nothing is uploaded. The library is stored in `mod_cache/bicycle_plus/music/`, outside the mod code directory, so ordinary Update All replacements do not erase it. Clearing app data or manually deleting that cache still removes the library. Keep your own copies of important files.

Limit: **64 MiB per file, 128 library entries**. Identical file contents are not imported twice. Files are checked for supported signatures and decodable samples before use. Unsupported/corrupt selections fall back to the original bicycle theme where possible, without muting the area just because the replacement failed. Some native pickers do not return the original filename; use RENAME for a friendlier title.

The colour editor, bicycle region masks and automatic-cycling controller are unchanged. No ROMs, soundtrack recordings or test-tone files are included in the release.

**Testing scope:** automated checks cover native Music/hooks, profiles, library persistence, source selection, sandbox loading and platform-picker routing. Actual game audio programs from the six supplied ROMs were exercised through the native synthesiser locally; no ROMs are published. OS dialogs, controller/touch drivers and full physical-device gameplay have not been tested on every platform. Native dialog availability depends on the host build; the inbox is the fallback, not a claim that all platforms ship an OS picker.

Manual/new users: import **bicycle_plus-1.8.0.zip**, leaving it zipped. Do not import GitHub's Source code ZIP. v1.4.0/v1.4.1 installations need one manual update to acquire the update source.
