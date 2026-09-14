# Bicycle Plus v1.4.1 verification

## Scope of this release

The engine requirement changes from `=0.2.59` to `=0.2.59 || =0.2.60`, and the mod version becomes `1.4.1`. Public documentation and packaging metadata are updated. All six production Lua files remain byte-for-byte identical to the public v1.4.0 repository source and the supplied v1.4.0 package.

**Full gameplay in a v0.2.60 executable has not been verified.** This is a version-restriction hotfix, not a claim that a full engine port or complete companion-mod retest has been performed.

## Prepared hotfix checks

The earlier v1.4.1 preparation used the supplied v0.2.59 Windows package's Lua runtime modules under `texlua` (Lua 5.3). Its actual `Manifest`, `Semver` and `LauncherMods.deriveList` implementations were exercised with `Version.engine` supplied as a test input.

The old manifest reports `Needs engine =0.2.59 (have 0.2.60)`. The new manifest reports `Ready` for both declared versions across Red, Blue, Yellow, Gold, Silver and Crystal. Unreviewed versions remain excluded. This checks the version gate; it is not execution of a v0.2.60 engine.

Five previously prepared headless regression suites also passed, covering bicycle-part masks, automatic mounting, colour/preview safety, settings and menu integration, and audio-menu controls. These use engine modules and test doubles, not physical graphics or sound devices. Their recorded results and the version-gate reproduction script are in [verification/v1.4.1](verification/v1.4.1).

## Publication checks

Before publishing, the local six Lua files were compared with the current public repository's Git blob IDs. All six matched. The scoped release builder in [.github/scripts/build_release.py](.github/scripts/build_release.py) additionally checks their SHA-256 values against the reviewed v1.4.0 baseline.

The builder validates the exact mod ID, version, engine declaration, API, entry point and six game targets. It includes only an explicit allowlist of source/documentation files, creates per-file hashes in `.modkit/pack.json`, and checks the ZIP's contents and CRC integrity. A separate `SHA256SUMS.txt` covers the installable asset. The publishing workflow downloads the published ZIP again and compares it with the build.

These are source/packaging checks, not a replacement for gameplay testing. See the repository's [Actions runs](https://github.com/moocd123/gen1recomp-bicycle-plus/actions) for the actual publication outcome.

## Not newly verified

- Full gameplay in Gen1ReComp++ v0.2.60.
- Hardware graphics rendering or audio playback on v0.2.60.
- Every feature of every companion mod on the new engine.
- Every physical device and operating system.

Historical v0.2.59 checks are not relabelled as new v0.2.60 verification. The package contains no ROMs, game executables, imported ROM caches, extracted sprite sheets or recorded soundtrack.

## Upstream reference

- [Gen1ReComp++ v0.2.60 release](https://github.com/bryanthaboi/gen1recomp/releases/tag/v0.2.60)
