# Bicycle Plus v1.8.0 — Custom cycling songs

> **Testing notice:** Custom-song playback and file importing have passed automated checks but have not yet had in-depth real-device testing. **Export/back up your progress save before updating, and save your game before trying imports.** A crash can still lose unsaved progress. Custom music is opt-in: the new song setting defaults to **Original**.

**On v1.4.2 or newer, use MODS → Check for updates → Update All.** The mod ID and GitHub source remain unchanged.

## Features

- Choose a cycling song from your current game's soundtrack.
- Choose tracks from other Red, Blue, Yellow, Gold, Silver or Crystal games already imported in the launcher, without switching the active game.
- Import your own MP3, Ogg Vorbis, WAV or FLAC files (64 MiB per file, up to 128 imports).
- Native file-picking routes for Windows, macOS, Linux and supported mobile bridges; an in-app inbox/subfolder browser on every build as a fallback. Desktop file-drop import works while a music menu is open.
- Preview before selection, rename imports, or remove a local copy with confirmation. Original source files are not deleted.
- Restart/resume between rides during the current session.
- Keep the existing area/bicycle/both modes, independent volumes/filters, audio profiles and original-theme option.
- Store imported music outside the installed mod folder so mod replacement does not remove the library.

## Use

Open **OPTIONS → AUDIO → BIKE SONG**, **BICYCLE + → AUDIO → BIKE SONG**, or **AUDIO → CYCLING → BIKE SONG**.

Choose ORIGINAL, CURRENT GAME SONGS, OTHER IMPORTED GAMES, MY AUDIO FILES or IMPORT AUDIO FILE. A song's options include PREVIEW and USE FOR CYCLING. The selected song replaces only the bicycle layer; AREA mode still suppresses bicycle music. Preview uses BIKE VOL and BIKE FILTER.

Up/Down selects a row, Left/Right moves a page, A activates, B/Start returns. Mouse/touch selection and a rename keypad are included. BROWSE MUSIC INBOX and FILE IMPORT HELP are available even without a system dialog.

For picker-less platforms, copy audio into the displayed inbox using the platform's supported file-transfer method, then select it in the in-app browser. This does not bypass OS permissions or provide a native picker where the host has none. See docs/CUSTOM_MUSIC.md.

The chosen file stays local; this is not an upload to a server. Arbitrary non-Pokémon ROM soundtracks, streaming links, M4A/AAC/DRM downloads, playlists and saved resume positions across app restarts are not included.

## Verification limits

Native music/menu modules, library state and platform routing were tested with simulated graphics, file-picker and audio-device boundaries. Local tests also extracted audio from the six supplied ROMs, started 425 registered tracks, and compared PCM across 36 current/selected edition pairings. Those are short synthesis checks, not listening tests of every full song or physical-device gameplay tests.

The colour editor, bicycle masks and automatic cycling are unchanged. Back up your save before testing, as with any new mod release.

Manual installation uses **bicycle_plus-1.8.0.zip**, not GitHub's Source code ZIP.
