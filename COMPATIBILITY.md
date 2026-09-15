# AUTOBIKE+ v1.9.0 compatibility

The displayed name changes from Bicycle Plus to AUTOBIKE+. `id=bicycle_plus`, the GitHub update source, six editions, `api=2` and `game_version=>=0.2.59` remain intact. The repository is deliberately not renamed so existing installations continue to receive releases.

The native Audio menu is no longer wrapped. The music/profile implementation still makes normal Music controls apply to area/normal music and uses a separate cycling gain. Off-bike SFX filtering is configured in AUTOBIKE+, not native Audio. Historical mix modes are translated to cycling-volume choices once; colours and normal engine volume/filter preferences are retained.

ImportAccess's supported cache API replaces writable compatibility aliases. Old library indices and tracks are read as fallback sources without deleting them. Decoder Sources take FileData constructed from validated owned bytes. Other-game program caches have distinct real paths, and the active game selection is not changed.

The native file dialog is delegated to engine FilePicker/RomImporter entry points with a size-limited local receiving proxy. Desktop selected paths are read by the engine, not by restricted mod io. Native mobile requests use unique own-mod baseroms staging destinations; only matching completions/errors are consumed. Obsolete ROM-picker fallback is rejected. Cancellation does not block a new import, and late cancelled completions are discarded. The generic Import action can fall back to an engine-backed file browser; no missing OS permissions are bypassed.

Colour geometry, hand/handlebar masks, trainer rendering and automatic mounting are unchanged. Appearance option navigation uses press edges; chart movement still repeats. Existing companion checks are historical evidence, not a new certification of every enabled-mod combination.

See VERIFICATION.md. Real Linux LÖVE decoder tests use null output; OS dialogs on other platforms and physical gameplay remain device-test items. Future engine changes can require fixes despite the open version declaration.
