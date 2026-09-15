# AUTOBIKE+ v1.9.2 — First-install defaults

**Use MODS → Check for updates → Update All**, then relaunch the game. Existing v1.4.2+ installations keep the same mod ID and update source. The installer remains `bicycle_plus-1.9.2.zip`.

## New users can install and ride

- **AUTO BIKE: ON** by default.
- **ON BIKE: BICYCLE** by default, rather than mixing both tracks.
- **BIKE SONG: Original Bicycle Theme** remains the default.
- **CYCLING MUSIC VOLUME** starts at the game's current **Music volume** only when no bicycle volume is already saved. OFF is preserved. With no native Music setting, the native default of 7 is used.

The initial volume is copied once, not permanently linked. For example, normal Music 3 gives a new bicycle volume of 3; changing normal Music later will not overwrite the independent bicycle setting.

## Existing users keep their preferences

A previously saved bike volume wins, including OFF. Existing auto-bike OFF, AREA/BICYCLE/BOTH, volume/filter choices, songs, resume behaviour and colours are retained. The default changes are not a reset of everybody's setup. Reinstalling also retains preferences when the host still has them; deleted app data cannot be recovered.

The quick **AREA / BICYCLE / BOTH** selector remains available and still changes only which tracks are heard. Dismounting restores normal off-bike audio. No customisation options have been removed.

Only `main.lua` changes at runtime. The other 14 runtime modules, including playback, importing, colour customisation and movement, are unchanged from v1.9.1.

## Checks and limits

Automated checks cover first-install volumes 0–7, stored volumes 0–7, all music modes, separate saved/live stores, prior-version settings, delayed game-option availability, safe-mode deferral, reinstalls and off-bike restoration. They use the native Loader option API, sandbox, screens and Music module with simulated disk/graphics/device boundaries. This is not a new physical-device or full gameplay test.

Back up progress before testing a mod update. This patch adds no progress-save writer or save-format migration. Manual installations use the attached mod ZIP, not GitHub's Source code ZIP.
