# AUTOBIKE+ Gen 3 laboratory — development components, NOT an installable mod

The public AUTOBIKE+ 1.9.3 runtime, manifest, settings namespace, release assets and publishing workflows are intentionally unchanged. This branch has no release job; workflow permissions are read-only.

## Target

Gen1ReComp++ v0.2.66, d70ef7c40e4166b82ed8da692423f010f4406e1b. The game registry currently enables FireRed only amongst Gen 3 games, and accepts original USA 1.0 (SHA-1 41cb23d8dccc8ebd7c649cd8fbb58eeace6e2fdc). The supplied original FireRed matches. FireRed Rev 1, LeafGreen, Ruby and Sapphire are reference assets, not additional runtime targets. The user subsequently supplied Emerald in the interactive project, but scheduled CI cannot access or redistribute those ROM uploads; Emerald is future reference rather than a FireRed runtime target.

## Latest verified checkpoint

- `b5a2eb1f5e58853a1cb90935ceb4bc31e7493f62` completed continuous mouse/touch drag capture for the modal picker. GitHub Actions run `35492727489` completed successfully against the pinned engine, including unchanged Gen1/2 regression suites and all FireRed component checks.
- `af43f2a3976bdedebd6ac0ce882ef45804bd8486` added a live FireRed bicycle preview to BIKE APPEARANCE. The preview uses the same verified private shade-preserving texture as gameplay, works while the player is off the bike, animates native standard bike frames/facings (including mirrored right-facing frames), and reserves a separate menu column so labels/values remain clipped rather than overlapping it. Its first run (`35492988390`) exposed a test-visible success-state bug in preview error bookkeeping.
- `03777214ceb14d9eb4cf5c1d2a32a74cba2003e9` split the FireRed lab checks into named CI steps so future failures identify the exact component without relying on unavailable raw Actions logs. Run `35493067687` correctly isolated the preview issue to the native-menu step while the stable regressions and mount checks stayed green.
- `2b1e7ca0e6415419b7788c98753aa1e982d9edd7` fixed the preview success-state logic. GitHub Actions run `35493141159` completed successfully: stable Gen1/2 checks, mount model/adapter, native menus, shade transform, isolated settings, lifecycle integration, player paint/preview, colour picker, pointer bridge and beta manifest gate all passed.
- `98e961177ae2a1d717c3b3eaf2371114bbfb3e7d` added the independent FireRed M4A cycling layer and its routing tests. It renders the native cycling role through a private QueueableSource instead of taking ownership of Game3's singleton BGM worker; tests cover BICYCLE/BOTH area routing, separate bike gain/filter, invalid-song fail-open, native fanfare safety, restart/resume and SFX-filter ownership. GitHub Actions run `35494391010` completed successfully after an earlier syntax-check failure exposed and corrected a missing token separator.
- `561f66c07624123e0186197fb58a0f624fb52eb3` wired that independent layer into the isolated beta entry. GitHub Actions run `35494442028` completed successfully: unchanged Gen1/2 regressions plus every named FireRed check, including the new independent cycling-audio test, passed against the pinned engine.

These tests are code/integration checks with generated fixtures. They do not claim ROM-dependent in-motion mask review, physical touch-device testing, real-device file-picker testing, or listening tests.

## Development components

- mount.lua: pure state machine; native Bicycle action, owned item, safe/idle gating, manual dismount suppression and per-area decisions. No persistence calls.
- native_mount.lua: FireRed Bag/player/ItemUse adapter with chained/restorable wrappers.
- parts.lua: conservative material masks for the two original 32x32 FireRed player-bike sprites and nine standard frames. Whole-sheet SHA-256 identity gates reject unknown art. Working labels Frame, Tyres, Rims, Spokes, Handlebars do not alter Gen1/2's existing labels.
- shading.lua: shade-preserving paint transform with non-collapsing black/white endpoints and exact Original bypass. RGB is a reference paint colour, not the value of every shaded output pixel.
- native_menu.lua: 240x160 menu scaffold using native font/windows/frame preference, tap-only navigation, clipped text and an optional dedicated animated-preview column.
- settings.lua: separate FireRed-beta options namespace, first-run Auto Bike ON, one-time native Music-volume copy (including zero), inherited cycling profiles, restart/resume, validated RGB hex storage, and per-part remembered custom colours. It never migrates from or writes the stable bicycle_plus bucket.
- colour_picker.lua: native 240x160 HSV/value picker with exact RGB/hex fields, controller keypad, raw keyboard editing/paste, Original/apply/cancel, remembered custom values and deliberate held-repeat only while adjusting colour. It is wired from every FireRed appearance part.
- pointer_bridge.lua: FireRed-v0.2.66 compatibility bridge for modal mouse/touch press, move and release capture. It translates display-fit coordinates, keeps captured drags isolated across viewport boundaries, ignores synthetic touch mouse events and restores all wrapped Game3 methods on disposal.
- integration.lua + beta_main.lua: FireRed generation gate and lifecycle wiring attach native auto-mount, add an AUTOBIKE+ row to the native Gen 3 OPTION screen, expose Gen 3-styled top/audio/appearance pages, wire the colour picker and animated appearance preview, provide paint-only reset, attach the independent cycling-audio layer, and restore direct engine wrappers on disposal. beta_manifest.json uses the distinct autobike_plus_firered_beta id and has no GitHub updater field.
- player_paint.lua: wraps the native FireRed overworld draw only for a call matching the live player's bike graphics, position and facing. It verifies the canonical extracted source, builds a private shade-preserving image and draws that copy; shared OwSprites images are never mutated, non-player calls fall through, all-Original uses the exact vanilla path, and the same renderer exposes an off-bike animated menu preview.
- audio_layer.lua: FireRed-only independent M4A renderer. It starts the ROM-derived cycling role in a private sequencer/QueueableSource, leaves the native Game3 worker in charge of area/battle/fanfare music, implements AREA/BICYCLE/BOTH routing, cycling area/SFX/bike volume/filter profiles, restart/resume, fanfare suspension and fail-open restoration if an overlay cannot start. It currently resolves Original and FireRed numeric song keys; broader song browsing/import is the next audio milestone.

## Tests and limits

The unchanged v1.9.3 import, options/reset, region, first-ride and six-edition routing suites run against the pinned v0.2.66 engine on every lab commit. Graphics/devices/audio sources are simulated in those suites; this is not full gameplay or all companion mods.

Private local art tests use both canonical rider sheets extracted from the supplied ROM: Original, single-part paint, black/white/saturated colours, alpha and unchanged non-target pixels across nine frames each. The repository includes no ROMs, ripped sprites, font data or user audio. Local comparison images are diagnostic outputs, not game screenshots.

Repository tests cover model rules, native Bag/ItemUse, native UI Stack, isolated settings, lifecycle/menu integration, native colour-picker state/input, FireRed display-coordinate pointer press/move/release capture, player-only/private-texture paint interception, native-frame animated preview using generated RGBA bytes, and independent cycling-audio routing using generated queue/source fixtures. Refer to Actions for actual pass/fail outcomes. A synthetic renderer test proves selection and source isolation, not the anatomical correctness of every real-art mask; that still requires visual review in motion. The audio test proves sequencer/routing ownership and restoration, not audible quality on a physical device.

## Still required before a playable beta

Implement the FireRed/current-game song catalogue and menu; adapt supported Gen1/2 imported-game songs to the Gen3 overlay without stealing native audio; add imported MP3/OGG/WAV/FLAC playback and platform chooser/decoder integration; add beta staging/ZIP validation; then perform full-gameplay, ROM-dependent visual review, listening tests and physical-device tests. The independent native FireRed cycling path itself is now wired, so the remaining audio work is selection/import breadth and real playback validation rather than sharing Game3's singleton BGM worker.

A temporary FireRed-only testing package with a separate ID remains the initial deliverable. A single public AUTOBIKE+ with isolated generation adapters remains the longer-term design. No new public tag or Update All release is created by this branch.
