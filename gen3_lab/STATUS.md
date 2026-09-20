# AUTOBIKE+ Gen 3 laboratory — development components, NOT an installable mod

The public AUTOBIKE+ 1.9.3 runtime, manifest, settings namespace, release assets and publishing workflows are intentionally unchanged. This branch has no release job; workflow permissions are read-only.

## Target

Gen1ReComp++ v0.2.66, d70ef7c40e4166b82ed8da692423f010f4406e1b. The game registry currently enables FireRed only amongst Gen 3 games, and accepts original USA 1.0 (SHA-1 41cb23d8dccc8ebd7c649cd8fbb58eeace6e2fdc). The supplied original FireRed matches. FireRed Rev 1, LeafGreen, Ruby and Sapphire are reference assets, not additional runtime targets. The user subsequently supplied Emerald in the interactive project, but scheduled CI cannot access or redistribute those ROM uploads; Emerald is future reference rather than a FireRed runtime target.

## Development components

- mount.lua: pure state machine; native Bicycle action, owned item, safe/idle gating, manual dismount suppression and per-area decisions. No persistence calls.
- native_mount.lua: FireRed Bag/player/ItemUse adapter with chained/restorable wrappers.
- parts.lua: conservative material masks for the two original 32x32 FireRed player-bike sprites and nine standard frames. Whole-sheet SHA-256 identity gates reject unknown art. Working labels Frame, Tyres, Rims, Spokes, Handlebars do not alter Gen1/2's existing labels.
- shading.lua: shade-preserving paint transform with non-collapsing black/white endpoints and exact Original bypass. RGB is a reference paint colour, not the value of every shaded output pixel.
- native_menu.lua: 240x160 menu scaffold using native font/windows/frame preference, tap-only navigation and clipped text.
- settings.lua: separate FireRed-beta options namespace, first-run Auto Bike ON, one-time native Music-volume copy (including zero), inherited cycling profiles, restart/resume and validated RGB hex storage. It never migrates from or writes the stable bicycle_plus bucket.
- integration.lua + beta_main.lua: FireRed generation gate and lifecycle wiring attach native auto-mount, add an AUTOBIKE+ row to the native Gen 3 OPTION screen, expose Gen 3-styled top/audio/appearance pages and restore direct engine wrappers on disposal. beta_manifest.json uses the distinct autobike_plus_firered_beta id and has no GitHub updater field.
- player_paint.lua: wraps the native FireRed overworld draw only for a call matching the live player's bike graphics, position and facing. It verifies the canonical extracted source, builds a private shade-preserving image and draws that copy; shared OwSprites images are never mutated, non-player calls fall through, and all-Original uses the exact vanilla path.

## Tests and limits

The unchanged v1.9.3 import, options/reset, region, first-ride and six-edition routing suites run against the pinned v0.2.66 engine on every lab commit. Graphics/devices/audio sources are simulated in those suites; this is not full gameplay or all companion mods.

Private local art tests use both canonical rider sheets extracted from the supplied ROM: Original, single-part paint, black/white/saturated colours, alpha and unchanged non-target pixels across nine frames each. The repository includes no ROMs, ripped sprites, font data or user audio. Local comparison images are diagnostic outputs, not game screenshots.

Repository tests cover model rules, native Bag/ItemUse, native UI Stack, isolated settings, lifecycle/menu integration and player-only/private-texture paint interception using generated RGBA bytes. Refer to Actions for actual pass/fail outcomes. A synthetic renderer test proves selection and source isolation, not the anatomical correctness of every real-art mask; that still requires visual review in motion.

## Still required before a playable beta

Complete native appearance/colour-picker and pointer/keyboard/controller editing; independent M4A sequencing and audio mixing; current/other-game/imported-file song selection and profiles; platform chooser/decoder integration; beta staging/ZIP validation; full-gameplay and physical-device tests. Reusing the singleton Gen3 audio worker would steal native music, so the Gen1/2 audio implementation cannot simply be enabled for FireRed.

A temporary FireRed-only testing package with a separate ID remains the initial deliverable. A single public AUTOBIKE+ with isolated generation adapters remains the longer-term design. No new public tag or Update All release is created by this branch.
