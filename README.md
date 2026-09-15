# AUTOBIKE+

Formerly **Bicycle Plus**. The displayed name changes; the internal `bicycle_plus` ID, repository, update source and saved preferences remain compatible.

**v1.9.3 — mobile import completion and combined handlebars.**

[Latest release](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/latest) · [Issues](https://github.com/moocd123/gen1recomp-bicycle-plus/issues)

## Updating

Use **MODS → Check for updates → Update All** from Bicycle Plus v1.4.2 or newer. Confirm **AUTOBIKE+ 1.9.3**, then **fully close and reopen the app** to clear any old audio-menu hooks.

New/manual installs use **bicycle_plus-1.9.3.zip**, left zipped. Import it through MODS and enable the games you play. The filename retains the old ID for the updater. Do not import GitHub's Source code ZIP. v1.4.0/v1.4.1 users need one manual replacement to add the update source. Do not delete saves or app data.

Back up your progress before testing. Automated checks do not guarantee every device, native file dialog or mod combination. No ROMs or soundtrack files are included.

## First-install defaults

With no saved AUTOBIKE+ preferences, **AUTO BIKE is ON**, **ON BIKE is BICYCLE**, and **BIKE SONG is the original bicycle theme**. A missing bicycle-volume setting is initialised from the game's current **Music volume**, including OFF. This is copied once when the game and its options are ready, then saved as the independent cycling volume. If Music volume is absent, the native default of 7 is used.

A saved bike volume always wins, including zero. Updates and reinstalls with retained preferences do not reset previously chosen AREA/BICYCLE/BOTH, auto-bike OFF, filters, colours, imported songs or resume behaviour. Reinstalling after deleting all app settings cannot recover preferences that no longer exist.

Example: a new user with Music volume 3 starts with bicycle volume 3. Changing normal Music to 6 later does not change that saved bicycle volume. They can choose AREA or BOTH and adjust volumes/filters at any time; mode changes leave the mix alone.

## One settings menu

Open **OPTIONS → AUTOBIKE+**:

1. **AUTO BIKE** — toggle automatic mounting on entry to an eligible area while carrying a Bicycle. Deliberate dismounting is remembered for the visit.
2. **SFX FILTER** — normal/off-bike sound-effect filter.
3. **BIKE APPEARANCE** — the existing five-part Original/Custom colour editor and confirmed Reset Colours.
4. **BIKE AUDIO** — cycling settings and the single Bike Song entry.
5. **LANGUAGE** — UK/US spelling.

Menus use **Up/Down** to select, **Left/Right** to change values and **A** to activate. **B/Start** returns. Option navigation advances once per press, not repeatedly while held. Mouse/touch selection is also available. The colour chart itself still supports continuous adjustment and dragging.

The game's original **Audio menu is not modified**. Its **Music volume, SFX volume and Music filter** keep their native labels and positions (including any other native edition-specific controls). Music settings govern the normal/area track, not the separate cycling-music track. The mod's off-bike SFX filter lives only in AUTOBIKE+.

## Bike audio

The private **BIKE AUDIO** page has, in order:

- **ON BIKE: AREA / BICYCLE / BOTH** — choose which tracks play without changing any saved volume, filter or song.
- **AREA VOLUME / AREA FILTER** — the location's music while cycling.
- **SFX VOLUME / SFX FILTER** — sound effects while cycling.
- **CYCLING MUSIC VOLUME / CYCLING MUSIC FILTER** — the selected bicycle song.
- **BIKE SONG** — choose or import a song.
- **ON MOUNT: RESTART / RESUME** — restart or continue between rides in the current session.

Volumes are OFF–7. Filters are OFF/1X/2X/3X. Area/SFX cycling settings also offer SAME to follow their normal counterparts. Dismounting restores normal settings.

**ON BIKE** is an independent routing switch. **AREA** plays only the location track; **BICYCLE** plays only your selected bicycle song; **BOTH** mixes them using your saved gains and filters. Suppressing a track does not turn its saved slider to zero. Dismounting still restores normal Music/SFX settings, regardless of the routing choice. A track whose saved volume is OFF remains silent even when selected.

Direct upgrades from v1.8.0 or earlier retain their old AREA/BICYCLE/BOTH choice and saved mix. **v1.9.0 already converted modes to zero volumes and did not store the previous gains.** Those values cannot be reliably reconstructed. This update leaves them alone: adjust an affected OFF slider once to your preferred level, then switch modes without changing it again. No normal Music/SFX preferences are overwritten.

## Bike song and importing

The only route is **AUTOBIKE+ → BIKE AUDIO → BIKE SONG**:

- Original Bicycle Theme
- Current Game Songs
- Other Imported Games
- Imported Songs
- **Import Song**

**A on Import Song opens the file picker directly.** A successful import is selected for cycling immediately. Previously imported songs remain in Imported Songs. Song details offer Preview, Use for Cycling, and (for local copies) Rename and confirmed Remove Local Copy. Long titles/filenames scroll horizontally on one line; they do not wrap.

Supported formats: **MP3, Ogg Vorbis, WAV and FLAC**, subject to the decoder shipped by your host. Limit: 64 MiB per file and 128 imports. This imports a local copy; it does not upload to a server. M4A/AAC/DRM and streaming URLs are not supported.

Windows, macOS and Linux use the host engine's desktop picker. Mobile builds with the required-import bridge use the host document picker and a unique mod-confined staging file. On a build without a usable native dialog, the same Import action opens a file browser for host-visible storage instead. OS permissions still apply; a Lua mod cannot add a missing native bridge. Desktop file-drop import is accepted only while a song screen is open.

The repaired library uses the engine's scoped **mod cache**, outside the replaceable mod folder. Existing v1.8 library records/copies are read from the previous storage location when present, retaining their song IDs. New audio is passed to the decoder as validated FileData bytes; the decoder is no longer asked to open an alias that only the mod sandbox can see. Removing a song deletes only the new library copy, never the user's original chosen file. Legacy migration sources are not deleted.

Other-game songs are from **already-imported Red, Blue, Yellow, Gold, Silver and Crystal**, not arbitrary other systems' ROMs. Each foreign sound-program bank is stored under a distinct engine-readable cache path; the active game and its soundtrack bank remain unchanged.

On native bridges that do not return the source filename, an imported song receives a generated name and can be renamed. The original file is untouched. Resume position is not preserved across closing the app.

## Appearance

WHEEL, STRIPE, CENTRE, EDGE and HANDLEBARS keep the existing pixel mappings and animated preview. Original preserves the artwork; Custom opens the rainbow/brightness picker with exact RGB and hex entry. Apply saves the draft; Cancel discards it. Reset Colours only resets the five paint settings. Trainer Skins integration and remembered custom colours are retained. Menu selection is now tap-only.

## Compatibility and verification

Targets all six games, engine `>=0.2.59`, mod API 2. An open engine range is not a promise against future breaking changes. The mod is portable Lua; native file-picker and codec availability still depend on the host build.

[VERIFICATION.md](VERIFICATION.md) distinguishes sandbox, software-boundary, real decoder and local-ROM checks from physical-device gameplay testing. This release specifically tests through the native mod sandbox/compat layer, which previous direct-module tests did not cover.

Source is [MIT licensed](LICENSE). Pokémon game content belongs to its respective owners. Unofficial fan mod, not affiliated with Nintendo, Creatures Inc. or GAME FREAK. [Gen1ReComp++](https://github.com/bryanthaboi/gen1recomp).

## v1.9.3 repair notes

**Import Song** still opens the file picker directly. Mobile completion now supports both the current per-request destination and the older `picked_required_import.bin` delivery. The latter does not supply the completion marker the old mod waited for. A returned final file whose marker is missing is also checked. Partial files are not decoded; markerless data must be stable across polls before validation.

A pending import from the previous version can be recovered on reopening the game. When a native picker returns with no selection or callback, **Import Song** can retry rather than permanently reporting that the previous request must finish. A timeout also releases a silent wait. Error messages remain visible in the existing single-line status row. Other importers' staged files and unrelated markers are not consumed.

There are now five appearance controls. **HANDLEBARS includes the former DETAILS pixel(s)** as well as the existing bar region, using the same source masks. No additional hand/clothing pixels are painted. Your saved custom handlebar colour takes precedence; if that was Original and Details had a custom colour, the merged control starts with the Details colour. Otherwise it remains Original. The two older independent colours cannot both be displayed on one combined control. Historical values are retained for rollback, not exposed as another menu option.

Current/other-game song playback, the original Audio menu, routing, all filters/volumes, auto-bike behaviour and first-install defaults are unchanged. Physical phone picker testing is still needed; see VERIFICATION.md for the exact test boundary.
