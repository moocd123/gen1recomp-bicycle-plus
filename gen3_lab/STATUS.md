# AUTOBIKE+ FireRed beta — isolated Gen 3 test build

The public AUTOBIKE+ v1.9.3 runtime, manifest, settings namespace, tags/releases and publishing workflow remain unchanged. Development is isolated on `gen3-lab`; the beta has its own `autobike_plus_firered_beta` id and no stable updater field.

## Runtime target

The current test target is Gen1ReComp++ v0.2.66, pinned at `d70ef7c40e4166b82ed8da692423f010f4406e1b`, with FireRed USA/Europe 1.0. LeafGreen, Ruby, Sapphire and Emerald are reference/future targets only because the pinned host runtime exposes FireRed as the Gen 3 game target. Scheduled CI cannot access or redistribute the user's ROM uploads.

## Verified implementation

Implementation commit `8790eeca9a25f3ec6728475bddaeab81dcf1c3b8` passed GitHub Actions run `35506820813`. The run also rebuilt and validated an installable FireRed-only beta artifact. See `RUN_CHECKPOINT.md` for exact run/artifact metadata.

Implemented test-build features:

- Native Bicycle auto-mount when owned/eligible, manual-dismount suppression until area change or manual remount, and safe native control gating.
- FireRed-native 240x160 settings/audio/appearance/song pages with edge-triggered menu navigation and mouse/touch support.
- Both FireRed player-bike sheets handled through identity-gated, player-only private textures; shared native sprite art is never mutated.
- Five paint groups (Frame, Tyres, Rims, Spokes, Handlebars), shade-preserving recolour, exact Original bypass, black/white handling, remembered custom colours, HSV/RGB/hex editing, keyboard/controller/mouse/touch input, animated native appearance preview and paint-only reset.
- Independent cycling audio that does not take ownership of Game3's native area/battle/fanfare BGM worker.
- AREA/BICYCLE/BOTH, riding area/SFX/bicycle volumes and filters, restart/resume, fanfare suspension and fail-open native-audio restoration.
- Original/current FireRed soundtrack selection and preview, imported supported Gen1/2 soundtrack bridge, isolated local MP3/OGG/WAV/FLAC library, platform-aware import picker/browser fallback, rename/remove, and local playback.
- Separate FireRed beta options/library storage so testing cannot migrate or overwrite stable AUTOBIKE+ Gen1/2 settings.
- Source-only beta staging with manifest/modkit/checksum validation and no embedded ROM, sprite, font or audio assets.

## Automated verification scope

The branch runs unchanged stable v1.9.3 checks against the pinned engine plus named FireRed tests for mount behavior, native adapters/UI, song catalogues/imports, shading/settings, independent audio, lifecycle integration, paint/preview, colour picker/pointer bridge, manifest and ZIP staging. Run `35506820813` passed all of them.

These tests use generated/simulated fixtures where hardware, ROM art, native pickers or audio output are involved. They prove code paths, ownership/restoration rules, package isolation and generated-source behavior; they do not prove audible quality or anatomical correctness of every recolour mask in every real animation frame.

## Required before public release

The isolated ZIP is ready for hands-on FireRed testing, but a public AUTOBIKE+ release should wait for real-ROM in-motion visual review of both trainers/all bicycle frames, physical-device native file-picker/touch testing, and listening checks across cycling, battles, fanfares, pauses and dismount restoration. Defects found in those checks stay on `gen3-lab` until resolved. Gen1/2 remains the stable public implementation throughout this beta phase.
