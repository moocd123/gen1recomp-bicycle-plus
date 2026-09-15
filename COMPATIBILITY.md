# Bicycle Plus v1.8.0 compatibility

The mod keeps the same six game targets, API 2 requirement, `>=0.2.59` declaration and GitHub update source. An open version range is not a promise against future breaking engine changes.

The colour editor/renderer, masks and automatic-mount controller are unchanged from v1.7.0. The audio-menu and overlay code now support the selected track. Existing area/bicycle/SFX settings and profile keys remain unchanged. The default song selection is Original, retaining the existing sound unless a different song is selected.

Soundtrack donors are restricted to the six supported editions and engine-validated imported datasets. Current-game modded music records are usable where supported by the existing audio registry. Mods on a different donor edition are not executed merely to read its soundtrack.

File import supports the engine desktop/native-mobile paths and an explicit controller-operated inbox fallback on builds lacking dialogs. This does not claim that every OS/console build has a native document picker. The personal library is installation-scoped, not a Pokémon playthrough or mod-code folder.

Preview, rename/remove and changes to the chosen song are user initiated. File errors attempt the original bicycle theme, and normal scene/battle audio remains responsible for non-cycling moments. Resume keeps state only within the running session.

New headless tests use pinned engine modules with specified software boundaries. Real LÖVE codec checks use generated test tones and a null audio driver in CI; they are not a physical loudspeaker test. Local ROM-based synthesis checks used the six user-supplied ROMs. No new blanket guarantee is made for every feature of every other mod or every hardware platform. See [VERIFICATION.md](VERIFICATION.md).

The [v1.7.0 compatibility record](https://github.com/moocd123/gen1recomp-bicycle-plus/blob/v1.7.0/COMPATIBILITY.md) retains earlier colour/input details.
