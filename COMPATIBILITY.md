# Compatibility — AUTOBIKE+ v2.0.0

Requires mod API 2 and Gen1ReComp++ >=0.3.36. Targets Red/Blue/Yellow/Gold/Silver/Crystal/FireRed/LeafGreen. Permissions: engine_internals and compute; local GBA synthesis uses the latter. No remote AI or telemetry feature is added.

Do not enable the public package together with autobike_plus_test or autobike_plus_firered_beta; the manifest declares these conflicts. Existing public ID bicycle_plus is retained for automatic updates.

Test 3 companion coverage: actual Gen 1 Auto Field Moves 1.1.5, Running Shoes 1.1.2 and Trainer Skins 0.2.0, including all three in Surf sequences. Other installed mods were not fully tested as the owner's entire latest stack. Generic hooks do not constitute a compatibility guarantee.

All gameplay/rendering/audio/profile modules are carried from approved Test 3; a public-upgrade module and entry integration add one-time adoption of local test data. Reads from the old test namespace are limited to its profile/music/soundtrack cache. Writes stay in the public mod cache and options-only persistence. Neither test originals nor user-selected media are deleted. Failed migration writes are reported, not silently advertised as successful.

The v0.3.36 engine can intermittently hang while exiting after FireRed/LeafGreen switching. It was reproduced with all mods disabled. No native teardown workaround is introduced here. Restart between GBA games for conservative testing, save first, and do not force-close during writes.

Physical OS pickers, speaker/listening tests, all trainer replacements, all locations and all possible mod combinations remain outside automated guarantees. Later host/mod versions may require updates.
