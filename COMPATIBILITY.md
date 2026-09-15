# Bicycle Plus v1.8.0 compatibility

Requires Gen1ReComp++ v0.2.59 or newer, mod API 2. Red, Blue, Yellow, Gold, Silver and Crystal remain the six supported editions. New engine version numbers are not blocked, but future breaking changes are not guaranteed compatible.

The colour renderer, part masks, colour editor/value/UI modules and automatic-mount module are unchanged from v1.7.0. Existing settings keys and the native GitHub update source remain. New song settings default to the original theme and restart-on-mount. Historical Trainer Skins and companion-mod checks are not a fresh exhaustive retest of every combination.

Custom music uses a separate source/sequencer, preserving normal music/SFX and existing volume/filter hooks. Imported other-game programs have isolated cache keys to avoid collisions with the active soundtrack. Current-game soundtrack enumeration uses the live audio registry; other-game enumeration uses the imported base cache, not mods active only in that other game.

All-platform import is capability-based: native desktop pickers on Windows/macOS/Linux, advertised native required-import bridge where present, and an in-app music-inbox browser as fallback. Native dialogs are not invented on builds that do not expose them. Desktop drag/drop is limited to visible music screens and chains other handlers. The library is in LÖVE's save root, outside the mod-install directory. Platform storage-transfer/permission rules still apply.

Supported file formats are subject to the actual decoder in each platform build. MP3/Ogg Vorbis/WAV/FLAC files must validate before use. No promise is made for AAC/M4A, DRM files or URL streaming. Imported recordings are not automatically loudness-normalised.

See [CUSTOM_MUSIC.md](docs/CUSTOM_MUSIC.md) and [VERIFICATION.md](VERIFICATION.md) for capabilities, defaults, storage and actual testing limits.
