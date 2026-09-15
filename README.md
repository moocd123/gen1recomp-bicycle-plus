# AUTOBIKE+

Formerly **Bicycle Plus**. The displayed name changes; the internal `bicycle_plus` ID, repository, update source and saved preferences remain compatible.

**v1.9.0 — audio/import repair and simplified menus.**

[Latest release](https://github.com/moocd123/gen1recomp-bicycle-plus/releases/latest) · [Issues](https://github.com/moocd123/gen1recomp-bicycle-plus/issues)

## Updating

Use **MODS → Check for updates → Update All** from Bicycle Plus v1.4.2 or newer. Confirm **AUTOBIKE+ 1.9.0**, then **fully close and reopen the app** to clear any old audio-menu hooks.

New/manual installs use **bicycle_plus-1.9.0.zip**, left zipped. Import it through MODS and enable the games you play. The filename retains the old ID for the updater. Do not import GitHub's Source code ZIP. v1.4.0/v1.4.1 users need one manual replacement to add the update source. Do not delete saves or app data.

Back up your progress before testing. Automated checks do not guarantee every device, native file dialog or mod combination. No ROMs or soundtrack files are included.

## One settings menu

Open **OPTIONS → AUTOBIKE+**:

1. **AUTO BIKE** — toggle automatic mounting on entry to an eligible area while carrying a Bicycle. Deliberate dismounting is remembered for the visit.
2. **SFX FILTER** — normal/off-bike sound-effect filter.
3. **BIKE APPEARANCE** — the existing six-part Original/Custom colour editor and confirmed Reset Colours.
4. **BIKE AUDIO** — cycling settings and the single Bike Song entry.
5. **LANGUAGE** — UK/US spelling.

Menus use **Up/Down** to select, **Left/Right** to change values and **A** to activate. **B/Start** returns. Option navigation advances once per press, not repeatedly while held. Mouse/touch selection is also available. The colour chart itself still supports continuous adjustment and dragging.

The game's original **Audio menu is not modified**. Its **Music volume, SFX volume and Music filter** keep their native labels and positions (including any other native edition-specific controls). Music settings govern the normal/area track, not the separate cycling-music track. The mod's off-bike SFX filter lives only in AUTOBIKE+.

## Bike audio

The private **BIKE AUDIO** page has, in order:

- **AREA VOLUME / AREA FILTER** — the location's music while cycling.
- **SFX VOLUME / SFX FILTER** — sound effects while cycling.
- **CYCLING MUSIC VOLUME / CYCLING MUSIC FILTER** — the selected bicycle song.
- **BIKE SONG** — choose or import a song.
- **ON MOUNT: RESTART / RESUME** — restart or continue between rides in the current session.

Volumes are OFF–7. Filters are OFF/1X/2X/3X. Area/SFX cycling settings also offer SAME to follow their normal counterparts. Dismounting restores normal settings.

There is no separate AREA/BICYCLE/BOTH switch. For bicycle-only music, set cycling **AREA VOLUME to OFF**. For area-only music, set **CYCLING MUSIC VOLUME to OFF**. Set both above OFF to mix them. Normal Music volume remains independent, so turning cycling area music off does not silence walking music. Older mix modes are converted into equivalent cycling volumes once; normal engine settings are not rewritten.

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

WHEEL, STRIPE, CENTRE, EDGE, DETAILS and HANDLEBARS keep the existing pixel mappings and animated preview. Original preserves the artwork; Custom opens the rainbow/brightness picker with exact RGB and hex entry. Apply saves the draft; Cancel discards it. Reset Colours only resets the six paint settings. Trainer Skins integration and remembered custom colours are retained. Menu selection is now tap-only.

## Compatibility and verification

Targets all six games, engine `>=0.2.59`, mod API 2. An open engine range is not a promise against future breaking changes. The mod is portable Lua; native file-picker and codec availability still depend on the host build.

[VERIFICATION.md](VERIFICATION.md) distinguishes sandbox, software-boundary, real decoder and local-ROM checks from physical-device gameplay testing. This release specifically tests through the native mod sandbox/compat layer, which previous direct-module tests did not cover.

Source is [MIT licensed](LICENSE). Pokémon game content belongs to its respective owners. Unofficial fan mod, not affiliated with Nintendo, Creatures Inc. or GAME FREAK. [Gen1ReComp++](https://github.com/bryanthaboi/gen1recomp).
