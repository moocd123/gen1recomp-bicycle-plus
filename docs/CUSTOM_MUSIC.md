# AUTOBIKE+ custom music

The only menu route is **OPTIONS → AUTOBIKE+ → BIKE AUDIO → BIKE SONG**. Select Original, Current Game Songs, Other Imported Games, Imported Songs or Import Song. **Import Song immediately opens the host's file picker** (or a browser when a native picker is unavailable), and a successful import becomes the cycling selection. There are no separate help or inbox menu entries.

MP3, Ogg Vorbis, WAV and FLAC are accepted when the host decoder can read them, up to 64 MiB and 128 imports. Invalid files report a short error; any long title/error scrolls on one line. Local copies can be previewed, selected, renamed or removed with confirmation. Original user-selected files are not deleted. Some native bridges omit the filename; those imports have generated names that can be renamed.

The cycling track has its own volume and filter. **BIKE AUDIO → ON BIKE: AREA / BICYCLE / BOTH** selects the audible tracks without changing those preferences. Both uses the saved area/bicycle gains; OFF still means a channel is silent. Dismounting restores normal/off-bike Music and SFX from the game's unmodified Audio menu. SAME inherits normal settings. ON MOUNT controls restart/resume within the current session.

The selector changes neither the chosen song nor resume behaviour. A stored OFF value from v1.9.0 is retained rather than guessed; raise it once to the desired level if that channel should be heard.

Other-game soundtracks require those supported Pokémon editions already imported in Gen1ReComp++. The app's read-only audio metadata and program banks are used without launching/switching games. It does not extract soundtracks from arbitrary other games.

New library storage is **mod_cache/bicycle_plus/music**, outside the replaced mod package. Historical v1.8 storage under **mod_data/bicycle_plus/music** may actually reside in the engine's private compatibility overlay; the update checks both old representations when recovering data. Existing song IDs are retained. Do not manually delete old data while verifying the migration.

Windows/macOS/Linux use the engine's desktop picker and bounded external-file reader. Current Android/iOS required-import bridges stage into a unique own-mod temporary path. Only matching completions are consumed. Late cancelled results are ignored/cleaned rather than assigned to a new request. The fallback browser only sees host-permitted storage; native OS capability cannot be invented by a Lua mod.

Up/Down selects, A activates, B/Start returns; lists allow Left/Right page jumps. These are press-edge actions, not held-repeat scrolling. Mouse/touch also works. Song names bounce-scroll horizontally rather than wrap. The rename screen retains its on-screen keypad and keyboard entry.

## Mobile return handling (v1.9.3)

After you select a file, AUTOBIKE+ accepts the app's direct per-request delivery or its older required-import staging file. It validates a completed/stable file before adding it to Imported Songs, selects a successful import, and clears the pending status. No extra import submenu is required.

When returning without a result, press **IMPORT SONG** again to retry. That no longer leaves the menu permanently locked behind “finish or cancel the current import.” A silent request also expires after active waiting. A native error or undecodable file is reported rather than silently accepted. If the engine has an unrelated dependency import waiting, finish that in the launcher before starting another picker.

Restart the app after updating so the new pending-file handler replaces the old one. A persisted AUTOBIKE+ request and its returned file can be recovered when the mod starts again. Existing local songs and other-game soundtracks are not changed by this repair.
