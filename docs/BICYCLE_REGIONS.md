# Bicycle colour regions — v1.6.0

These are exact source-coordinate masks used by the mod, not official anatomical labels supplied with the games. The small side grip/stem outline can visually serve both the hand and bicycle. Keep DETAILS on Original when retaining that original shared outline is preferred. We do not treat the entire dark area between the wheels as a bicycle chassis: it contains the moving rider's leg and shoe.

Coordinates are zero-based within each native 16×16 frame. Source frame order is front, rear, left, then their moving poses. Right-facing poses use the engine's normal horizontal mirror.

| Control | Visible region |
| --- | --- |
| WHEEL | The original main coloured wheel pixels. |
| STRIPE | Existing contrasting rotation marks on Gen 2-style wheels; an explicit selection can decorate existing Gen 1 wheel pixels. Original adds no stripe to the original Gen 1 art. |
| CENTRE | The six-pixel centre of each side-view wheel, where exposed. |
| EDGE | The exposed wheel outlines, including the dark vertical borders of the narrow front/rear wheel. |
| DETAILS | The remaining single black side stem/grip-adjacent pixel underneath the projecting bar end. It is a visual detail, not a full frame or a claim that every shared outline is exclusively bicycle. |
| HANDLEBARS | The exposed front crossbar and two projecting side-view pixels. No back-view bar is invented. |

## Mappings

Gen 2-style front handlebars: x=4…11, y=10…11 in frames 1 and 4. Side projecting end: (2,10),(3,10) in frames 3 and 6; retained detail: (3,11). The source-black and alpha tests preserve the coloured foreground cutouts in Dawn and Hilda rather than painting over them. Their bar masks expose four fewer pixels across the two front frames.

Gen 1's front bar is a row higher: x=4…11, y=9…10. Its moving frame shifts one pixel left. Gen 1's standing side bar/detail are one pixel right of the Gen 2 side locations, then shift left in the moving frame. The current sprite selects its mapping; a Trainer Skins bicycle in Pokémon Red uses its Gen 2-shaped mapping rather than Red's original one.

The vertical wheel borders previously assigned to DETAILS are now EDGE. Shared pedal/shoe boundaries at the rear wheel's inward edge are excluded from recolouring. Non-black foreground pixels never become black-outline paint merely because their screen palette is dark: classification uses the untouched source sheet.

## Verification and limits

Tests use the actual Red, Chris and Kris source sheets and the supplied Trainer Skins 0.2.0 archive. Publication checks additionally obtain the earlier 0.1.0 archive. Tests compare every resulting pixel, confirm hand-region exclusions, preserve alpha and non-selected regions, and restore the exact source-resolved image when all controls are Original. True-colour and Trainer Skins-style luminance-quantised cases are separate checks.

This establishes what the implementation recolours. It cannot recover an artist's unrecorded intent for every shared outline, or establish compatibility with arbitrary future replacement artwork. Unknown sprite families retain their original artwork. No original game or trainer artwork is distributed in this mod's ZIP.

Reference source blobs (test fixtures only):
- `pret/pokered`, `gfx/sprites/red_bike.png`, Git blob `ed117d0b11c3d3fd9a75a9afac64eff1bd8cc3d4`.
- `pret/pokecrystal`, `gfx/sprites/chris_bike.png`, Git blob `0d18d11a6b93f1de5af558206d228106d3067291`.
- `pret/pokecrystal`, `gfx/sprites/kris_bike.png`, Git blob `161ce5722d19efb305928f418b83b36897200edb`.
- `DarkwarePX/Trainer-Skins`, release `V0.2.0`, archive SHA-256 `9295d0f2749d9e5519257fdb6609f781af3b8482cfc91e28fcd2a0437cd5ce36` (matches the supplied ZIP).
