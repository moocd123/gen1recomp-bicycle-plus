# AUTOBIKE+ Gen 3 laboratory — development components, NOT an installable mod

The public AUTOBIKE+ 1.9.3 runtime, manifest, settings namespace, release assets and publishing workflows are intentionally unchanged. This branch has no release job; workflow permissions are read-only.

## Target

Gen1ReComp++ v0.2.66, d70ef7c40e4166b82ed8da692423f010f4406e1b. The game registry currently enables FireRed only amongst Gen 3 games, and accepts original USA 1.0 (SHA-1 41cb23d8dccc8ebd7c649cd8fbb58eeace6e2fdc). The supplied original FireRed matches. FireRed Rev 1, LeafGreen, Ruby and Sapphire are reference assets, not additional runtime targets. No Emerald ROM was supplied.

## Development components

- mount.lua: pure state machine; native Bicycle action, owned item, safe/idle gating, manual dismount suppression and per-area decisions. No persistence calls.
- native_mount.lua: FireRed Bag/player/ItemUse adapter with chained/restorable wrappers; not called by the production entry.
- parts.lua: conservative material masks for the two original 32x32 FireRed player-bike sprites and nine standard frames. Whole-sheet SHA-256 identity gates reject unknown art. Working labels Frame, Tyres, Rims, Spokes, Handlebars do not alter Gen1/2's existing labels.
- shading.lua: shade-preserving paint transform with non-collapsing black/white endpoints and exact Original bypass. RGB is a reference paint colour, not the value of every shaded output pixel.
- native_menu.lua: 240x160 menu scaffold using native font/windows/frame preference, tap-only navigation and clipped text. Not yet integrated into the mod's production screens.

## Tests and limits

The unchanged v1.9.3 import, options/reset, region, first-ride and six-edition routing suites passed against v0.2.66 on the initial lab run. Graphics/devices/audio sources are simulated in those suites; this is not full gameplay or all companion mods.

Private local art tests use both canonical rider sheets extracted from the supplied ROM: Original, single-part paint, black/white/saturated colours, alpha and unchanged non-target pixels across nine frames each. The repository includes no ROMs, ripped sprites, font data or user audio. Local comparison images are diagnostic outputs, not game screenshots.

New component tests cover model rules, the native Bag/ItemUse adapter and native UI Stack with simulated device/field/window boundaries. Refer to Actions for actual pass/fail outcomes. Obeying a mask does not prove all ambiguous pixels were classified anatomically correctly; the animation still requires human review.

## Still required before a playable beta

Generation dispatch/lifecycle integration; player-only texture interception without NPC/shared-palette changes; complete native appearance/colour-picker and pointer/keyboard/controller UI; independent M4A sequencing and audio mixing; all current/other-game/imported-file song selection and profiles; chooser/decoder and full-gameplay tests. Reusing the singleton Gen3 audio worker would steal native music, so the Gen1/2 audio implementation cannot simply be enabled for FireRed.

A temporary FireRed-only testing package with a separate ID is preferable initially. A single public AUTOBIKE+ with isolated generation adapters remains the longer-term design. No new public tag or Update All release is created by this branch.
