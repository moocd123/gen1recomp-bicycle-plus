# Custom bicycle music — v1.8.0

## Architecture and scope

The new `song_library.lua` keeps local imports and enumerates only the six supported Pokémon soundtrack registries. `music_menu.lua` adds a native screen-stack song browser. `audio.lua` extends the existing independent layer rather than replacing the engine's global area soundtrack. Default `bike_song=original` preserves the existing theme. The new `bike_song_resume` default is false (restart).

Songs can be selected from the active game's modded registry or another already-imported Red/Blue/Yellow/Gold/Silver/Crystal cache. The latter reads only `data/generated/audio.lua` and its declared sound-program banks, validates the generated data-only syntax, and uses edition/content-specific program-cache paths. It never changes GameVersion or mounts another game over the active one. Copying these ROM-derived programs is a local operation; none are bundled in the mod.

## File import by capability, not an Android assumption

| Build | System picker path | Fallback |
| --- | --- | --- |
| Windows desktop | Engine FilePicker / OpenFileDialog | Inbox browser, desktop drag-and-drop |
| macOS | Engine FilePicker / macOS choose-file dialog | Inbox browser, desktop drag-and-drop |
| Linux / Linux handheld | Engine FilePicker / Zenity then KDialog | Inbox browser, desktop drag-and-drop |
| Android / iOS | Advertised `pickFileKinds` + `required_import` bridge | Inbox browser if absent/refused |
| NX, UWP and other builds | Uses that bridge only if advertised by the host | In-app inbox browser |

These are implemented capability routes, not claims that each physical device has been tested. The Lua mod cannot create a missing native bridge, install file managers, grant OS permissions or access storage the host does not expose. On picker-less builds, copy supported files into the displayed inbox using that platform's supported storage-transfer method. A controller-accessible fallback is always present; filling its inbox still depends on the platform permitting file transfer. Browsing stays inside the inbox and subfolders; `..`, absolute paths and invalid separators are rejected.

Native mobile picking stages to `mods/bicycle_plus/baseroms/bicycle_plus_audio_pick.bin`, an accepted private required-import destination. Only the matching completion/error marker is consumed. A selected file is decoded, hash-verified and copied to durable library storage before being used; the temporary stage is removed. No ROM/save/mod import staging filename is reused. The system may copy a file before Lua learns its size; the 64 MiB cap is enforced before decoding/library acceptance.

Desktop pickers are supplied by the engine. Drag-and-drop is chained and active only while a music screen is visible. Other file types and screens keep their prior handler. The callback becomes inert/restores its predecessor on teardown. Files are opened before reading and closed after import; original source files are never deleted.

## Storage

All permanent data is below `mod_data/bicycle_plus/music` in LÖVE's save root:

- `tracks/<sha256>.<extension>`: verified copied audio.
- `index-a.json` / `index-b.json`: alternating validated catalogue snapshots so an interrupted write retains the older usable slot.
- `inbox/`: user-supplied files/subfolders for the portable browser.
- `cache/`: namespaced foreign-game sound programs; local ROM-derived cache only.
- `awaiting.txt`: pending native-pick state, allowing a completed selection to be consumed after an activity restart.

The path is discovered with `love.filesystem.getSaveDirectory`, not a fixed Windows/Android pathname. It is outside the installed mod directory. Mod updates retain it; clearing app data can remove it. The app's portable cache mode does not relocate this library automatically. Back up this directory separately when migrating installations.

MP3, Ogg Vorbis, WAV and FLAC files are accepted only if the running LÖVE decoder can open them. File size is limited to 64 MiB and the imported catalogue to 128 entries. Exact file-content duplicates reuse the existing item. Local files are streamed for playback, not all decoded into memory at once; importing does read a bounded file into memory for validation and hashing. No audio upload, URL streaming, playlist/shuffle or automatic loudness normalisation is included.

Mobile imports may receive a generated name because the native bridge exposes a staged destination rather than the original filename. Use RENAME in Song Options to give it a readable label.

## Playback

Selected music uses the existing bicycle gain/filter and the Area/Bicycle/Both mode. One-shot game cues loop after their final queued samples drain. Original music definitions keep their own intro/loop behavior. Resume retains the paused source/sequence between rides in the same session; restarting the game resets the position. A selected track can coexist with a different area song, including a soundtrack from another imported edition.

Preview is opt-in, temporarily quiets the native track and stops on leaving the preview screen. It does not change the chosen song. Bike volume OFF makes preview silent, intentionally matching the bicycle bus setting. Normal game music resumes after preview/dismount. Missing or decoder-failing custom choices fall back to the original bicycle theme; other unrecoverable audio failures leave native area audio available rather than crashing.

## Source references

- Gen1ReComp++ v0.2.60 `src/core/FilePicker.lua`, `src/core/ChipSynth.lua`, `src/core/Music.lua`, `src/import/CacheFs.lua`.
- Android `mobile/android/love/src/jni/love/src/modules/system/System.cpp` and `GameActivity.java`.
- iOS `mobile/ios/native/GRPickerBridge.swift`.
- LÖVE documentation: `love.filedropped`, `love.filesystem.getSaveDirectory`, `love.audio.newSource`.

The test report distinguishes actual synthesised samples from simulated audio-device/dialog/UI boundaries.
