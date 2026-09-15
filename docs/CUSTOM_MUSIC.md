# AUTOBIKE+ custom music

The only menu route is **OPTIONS → AUTOBIKE+ → BIKE AUDIO → BIKE SONG**. Select Original, Current Game Songs, Other Imported Games, Imported Songs or Import Song. **Import Song immediately opens the host's file picker** (or a browser when a native picker is unavailable), and a successful import becomes the cycling selection. There are no separate help or inbox menu entries.

MP3, Ogg Vorbis, WAV and FLAC are accepted when the host decoder can read them, up to 64 MiB and 128 imports. Invalid files report a short error; any long title/error scrolls on one line. Local copies can be previewed, selected, renamed or removed with confirmation. Original user-selected files are not deleted. Some native bridges omit the filename; those imports have generated names that can be renamed.

The cycling track has its own volume and filter. OFF on cycling AREA VOLUME gives bike-only music; OFF on CYCLING MUSIC VOLUME gives area-only. Both above OFF gives a mix. Normal/off-bike Music and SFX remain in the game's unmodified Audio menu. SAME inherits normal settings. ON MOUNT controls restart/resume within the current session.

Other-game soundtracks require those supported Pokémon editions already imported in Gen1ReComp++. The app's read-only audio metadata and program banks are used without launching/switching games. It does not extract soundtracks from arbitrary other games.

New library storage is **mod_cache/bicycle_plus/music**, outside the replaced mod package. Historical v1.8 storage under **mod_data/bicycle_plus/music** may actually reside in the engine's private compatibility overlay; the update checks both old representations when recovering data. Existing song IDs are retained. Do not manually delete old data while verifying the migration.

Windows/macOS/Linux use the engine's desktop picker and bounded external-file reader. Current Android/iOS required-import bridges stage into a unique own-mod temporary path. Only matching completions are consumed. Late cancelled results are ignored/cleaned rather than assigned to a new request. The fallback browser only sees host-permitted storage; native OS capability cannot be invented by a Lua mod.

Up/Down selects, A activates, B/Start returns; lists allow Left/Right page jumps. These are press-edge actions, not held-repeat scrolling. Mouse/touch also works. Song names bounce-scroll horizontally rather than wrap. The rename screen retains its on-screen keypad and keyboard entry.
