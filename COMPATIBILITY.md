# Bicycle Plus v1.7.0 compatibility

The mod retains Red, Blue, Yellow, Gold, Silver and Crystal targeting, mod API 2 and the `>=0.2.59` engine declaration. No upper engine limit is imposed; future breaking changes may still require a fix.

`audio.lua`, `audio_menu.lua`, `automount.lua`, `bike_parts.lua`, `colours.lua` and `hardware_colours.lua` are byte-for-byte unchanged from the published v1.6.0. The new editor passes validated RGB values into the same renderer. It does not replace trainer artwork, change movement speed or alter audio profiles.

The six visible regions remain conservative Gen 1 / Gen 2-style pixel mappings chosen from the active artwork. Shared outlines are not official anatomical labels. Trainer Skins 0.1.0/0.2.0 palette-lifecycle handling is retained, as are safeguards for Wilds of Kanto and unrelated renderer chains. Unknown artwork can require a separate mapping review.

Existing aliases and RGB555 IDs retain their old colour values. New `rgb:RRGGBB` values are exact 24-bit colours. Reset restores the six main colour keys to Original; remembered custom values, trainer/rival selections, audio, language and automatic cycling are not erased.

Pointer and keyboard input use the native hooks. Virtual controls take priority before the picker. Pointer mapping supports the standard game viewport/letterbox; third-party output transforms can require additional integration. A compact Lua-drawn alphabet and solid markers avoid reliance on missing menu glyphs.

Automated checks use engine modules with software graphics/input boundaries. Actual sprite PNGs can be used in the renderer test without including them in the release. These checks do not certify every companion feature, every physical device or complete gameplay on v0.2.60. See [VERIFICATION.md](VERIFICATION.md).

The [v1.6.0 compatibility record](https://github.com/moocd123/gen1recomp-bicycle-plus/blob/v1.6.0/COMPATIBILITY.md) remains available as historical evidence; it is not a new full-stack retest for this release.
