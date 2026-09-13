# Bicycle Plus 1.4.0 verification

Target: **Gen1ReComp++ v0.2.59**.

Bicycle Plus v1.4.0 is the **first public release**. Development builds used earlier internal version numbers while the feature set was being tested; those builds were not public releases.

## What was verified

- Automatic mounting and deliberate-dismount behaviour across Red, Blue, Yellow, Gold, Silver and Crystal.
- Native bicycle eligibility and transitions.
- Independent normal/cycling area-music, bicycle-music and SFX controls.
- Bicycle, Area and Both cycling-music modes.
- Volume/filter changes and restoration after dismounting.
- Five separate bicycle colour regions: WHEEL, STRIPE, CENTRE, EDGE and DETAILS.
- Original sprite dimensions and animation retained.
- Animated stripe movement retained where the source artwork contains it.
- Trainer pixels preserved while bicycle pixels are recoloured.
- Trainer Skins 0.1.0 and 0.2.0 compatibility paths.
- Native and Trainer Skins bicycle artwork across both generations.
- Menu navigation, English UK/US labels and preview rendering.
- ZIP packaging through the Gen1ReComp++ mod importer.

## Platform note

The mod contains portable Lua and no platform-specific native code. It is intended to work wherever Gen1ReComp++ v0.2.59 supports its normal mod system. Development verification exercises the shared game/mod code; this should not be interpreted as physical testing of every device or operating system.

## Limits

Tests do not certify every unrelated feature of every companion mod, every future mod update, every possible replacement bicycle sprite or every physical platform.

The installable ZIP contains no ROMs, imported game data, copyrighted sprite sheets, soundtrack recordings or game executable.
