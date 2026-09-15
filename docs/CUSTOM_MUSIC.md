# Personal cycling music

The song selector is in **BICYCLE + → AUDIO → BIKE SONG** and **AUDIO → CYCLING → BIKE SONG**. Selection does not require riding, but previews should be opened from the overworld rather than battle or a one-shot scene.

## Soundtrack sources

`game:<edition>:<song>` records are pinned to a supported edition, including songs selected through THIS GAME. Current-edition songs use the live audio registry; other editions use the engine's read-only `mod.datasets` views of validated generated imports. Other editions' mods are not launched just to list their soundtrack. Cached program paths include the edition prefix, keeping similarly named sound banks separate. There is no ROM search/download service and no soundtrack distribution.

## Personal file library

MP3, Ogg Vorbis and WAV are checked by signature, decoder sample output and streaming-source creation. A SHA-256 content ID prevents duplicate imports. One compressed selected file is retained for file-backed playback, not a predecoded library of full PCM songs. File size is capped at 64 MiB; the library has at most 128 entries.

The installed code, progress saves, metadata and audio are separate:

- Code is replaced in `mods/bicycle_plus/` by the native updater.
- The chosen song ID remains in the usual Bicycle Plus mod options.
- User audio and `library.json` live in `mod_cache/bicycle_plus/music/` through the engine's installation-scoped cache API.
- A backup metadata file supports recovery from an interrupted metadata write. This is not a substitute for personal backups or a transactional database.

Remove Library Copy asks for confirmation. It never deletes the source file selected in the OS dialog or an inbox original. Reset Colours has no effect on music.

## Cross-platform importing

The adapter probes capabilities rather than treating Android as universal:

| Host capability | Import path |
| --- | --- |
| Windows desktop | Engine FilePicker / Windows OpenFileDialog. |
| macOS desktop | Engine FilePicker / macOS file dialog. |
| Linux desktop, including Linux-based handhelds | Engine FilePicker / Zenity with KDialog fallback where installed. |
| Android and iOS with the current engine document bridge | User-initiated native required-import picker, scoped to Bicycle Plus staging. The completion receipt's path, byte count and digest are checked before audio is accepted. |
| No usable native dialog, including some UWP/Xbox or NX/Switch builds | Copy audio into `mods/bicycle_plus/baseroms/audio_inbox/` using the platform's file-transfer tools; choose AUDIO INBOX and select a file with the controller or pointer. |

The directory is relative to the app's game-data root, not an assumed drive, username or Android storage path. The inbox is a file selector, not an OS-wide directory browser. It does not search unrelated directories. A build that does not allow transferring files into its data storage needs a host-supported import/transfer mechanism; a Lua mod cannot add a missing OS API.

Current native mobile pickers may label files generically because the bridge returns file bytes but no display filename. RENAME provides an on-screen controller/touch keypad or keyboard entry. Native pickers can require an app update if the host bridge is too old.

## Playback

The selected song replaces only the bicycle layer. Original game songs are rendered by an independent ChipSynth instance; personal files are streamed with LÖVE. Area music, bicycle gain/filter, cycling SFX and the original audio profiles remain separate. Missing or undecodable songs attempt Original, and failed playback does not intentionally suppress otherwise available area audio.

Custom songs loop. ON MOUNT / RESTART begins at the start after dismounting; RESUME retains the paused source in the current session. Battles and fanfares take priority, and menu preview is temporary. No playlists, crossfades, streaming-service login, per-song loudness normalisation or saved cross-session playback positions are included.
