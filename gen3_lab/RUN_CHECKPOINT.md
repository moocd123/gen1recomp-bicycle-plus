# Scheduled development checkpoint

Verified implementation commit: `037d3730d75f3e2bcc89f550e1688323eeef1a5e` (`Lazy-load serializer in Gen1 and Gen2 song bridge`).

This milestone adds an isolated, read-only bridge for already-imported Red/Blue/Yellow/Gold/Silver/Crystal audio caches; a Gen 3-native OTHER IMPORTED GAMES browser; and private Gen 1/2 ChipSynth playback on the FireRed cycling audio bus. It preserves AREA/BICYCLE/BOTH routing, filters, volume, fanfare safety and restart/resume. Copied sound-program banks use the beta mod's own cache namespace, so the stable `bicycle_plus` library/settings are not touched. The stable Gen 1/2 runtime, manifest and publishing workflow remain unchanged.

Verification: Gen 3 lab Actions run `35500653212` completed successfully on commit `037d3730d75f3e2bcc89f550e1688323eeef1a5e`. Stable v1.9.3 regression checks passed for all six Gen 1/2 editions; FireRed mount, native menu, current-song catalogue, imported-song bridge/menu, shade transform, isolated settings, independent M4A/ChipSynth cycling audio, lifecycle integration, player paint/preview, colour picker, pointer bridge and beta manifest gate all passed. These checks use synthetic/simulated audio/world fixtures where appropriate; they are not ROM/device/listening tests.

Remaining milestones before an installable candidate: isolated local MP3/OGG/WAV/FLAC import/library/playback with platform picker routes; complete staged beta ZIP/artifact validation; then ROM-dependent and physical-device/listening checks that cannot be performed by scheduled runs.
