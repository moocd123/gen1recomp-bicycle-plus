# AUTOBIKE+ v1.9.1 — Quick music selector restored

**Use MODS → Check for updates → Update All, then close and reopen the app.** Existing installations from v1.4.2 onward can update normally. The mod ID and repository have not changed.

## ON BIKE: AREA / BICYCLE / BOTH

The first row under **OPTIONS → AUTOBIKE+ → BIKE AUDIO** is now **ON BIKE**. Left/Right or A changes the mode.

- **AREA:** only the location's track while cycling.
- **BICYCLE:** only your selected bicycle song while cycling.
- **BOTH:** both tracks at their saved volumes and filters.

**This switches which tracks play, not their settings.** Volumes, filters, SAME inheritance, the chosen song and restart/resume preference are untouched. Dismounting returns to the normal off-bike settings. OFF is still respected: selecting a muted channel does not secretly increase its volume.

Example: save area volume 2 with a filter and bicycle volume 5 without one. Switching to BICYCLE hides the area track. Returning to BOTH restores the same mix without rebuilding it.

## Existing preferences

Direct upgrades from earlier versions preserve their old music-mode selection without zeroing a slider. For users who ran v1.9.0, its migration may already have saved AREA VOLUME or CYCLING MUSIC VOLUME as OFF. That version did not keep the previous level, so it cannot be reliably recovered. This patch preserves the current values; set an affected channel to your preferred level once, and mode switching will leave it alone thereafter.

Only main.lua and audio_menu.lua change at runtime. The native Audio menu remains unmodified; the AUTOBIKE+ layout, repaired imports, other-game playback, artwork and automatic cycling are retained.

## Checks and limits

Regression checks exercise the native sandbox, menus, options storage and music hooks against all six game contexts, with playback/graphics/input simulated. The checks cover repeated mode changes, migration, all volume combinations, filters, SAME, off-bike restoration and battles. They do not constitute a new physical-device or complete gameplay test. Back up progress when testing a mod update.

Manual installation uses **bicycle_plus-1.9.1.zip**, not GitHub's automatic Source code ZIP.
