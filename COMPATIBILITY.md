# AUTOBIKE+ v1.9.3 compatibility

The same mod ID `bicycle_plus`, API 2, six-game targets, `>=0.2.59` minimum and GitHub update source are retained. Future breaking engine changes can still require fixes.

Five runtime modules change: `import_picker.lua`, `song_library.lua` (poll dt forwarding), `main.lua` (poll dt and handlebar migration), `colours.lua` (map both existing groups to one paint key) and `colour_controls.lua` (one fewer visible row). The other ten runtime files, including playback, foreign-game audio handling, colour picker, part masks and automatic cycling, are byte-for-byte unchanged from v1.9.2.

## Native mobile importing

Both current per-request completion and older shared required-import staging are supported. Current direct deliveries have a destination, byte count and MD5 marker. Old bridges can return a staged file without any completion marker. The new poller waits for stable markerless data and uses the native bounded reader; `.part` files are not consumed. A previous pending record can recover returned data, and pressing Import Song can retry a request with no callback.

Only the current request's private staging or its owned required-import slot is cleaned. Pre-existing unrelated legacy staging prevents a new request from starting. Other imports' completion markers and ROM/save/mod staging are left alone. A timeout clears a silent wait. This does not bypass OS permissions, add a new picker to a host without one, or repair an unreadable file-provider URI.

Desktop file-picking and file-backed/foreign-game playback code retain their prior implementations. All platform-native dialog behaviour still needs device confirmation; simulated callbacks do not prove that every phone's file provider returns a file correctly.

## Appearance

The old DETAILS group and HANDLEBARS group use one HANDLEBARS value. This is the union of existing conservative pixel mappings, not an expansion into uncertain rider outlines. Gen 1/Gen 2 detection, Trainer Skins treatment, frame timing and native sprite geometry are unchanged.

A previously custom handlebar value wins. If handlebars were Original and Details was custom, Details supplies the combined value. If neither was custom, Original is retained. Existing WHEEL, STRIPE, CENTRE, EDGE and their remembered values are unchanged. The two old independent paints cannot both be retained visually with one control; the obsolete value remains stored as history for rollback. Reset restores all visible paint and also clears the obsolete Details paint key.

No progress-save writer, save-format conversion, ROM patch, new permission or active-game switch is added. Defaults, auto-bike ON/OFF, routing, song selection, filters, volumes, native Audio and resume remain as saved. Back up progress before testing any mod update.
