# Bicycle Plus v1.4.2 verification

## Scope

This is a metadata and release-packaging update. The manifest now declares `github: moocd123/gen1recomp-bicycle-plus` and the engine range `>=0.2.59`. API 2, all six game targets, permissions, the mod ID and every runtime Lua file are unchanged.

**An open engine range is not proof of compatibility with future engines.** Full gameplay in a v0.2.60-or-later executable and every physical device were not newly tested for this update.

## Native launcher/updater checks

The supplied v0.2.59 Windows package's native Lua modules were loaded under `texlua` (Lua 5.3). The new script exercises `Manifest`, `Semver`, `LauncherMods.deriveList`, `ModUpdate` and the actual `RomImporter` Update All state machine. Only network transport, UI callbacks, preferences persistence and the final filesystem-install boundary are simulated. No live third-party release or game installation is altered by the test.

**125 assertions passed**, covering:

- The `>=0.2.59` range accepts the minimum and later synthetic version inputs across all six launcher game selections.
- Older versions still fail the minimum, and an engine providing only API 1 still rejects this API 2 mod.
- The GitHub field survives manifest validation and reaches the launcher row.
- GitHub release parsing prefers `bicycle_plus-<version>.zip` over an unrelated ZIP and recognises a newer version without downgrading or reinstalling the current version.
- The native Update All path requests the right repository, bypasses stale cache, queues this mod and reaches the simulated install boundary with the correct asset.
- An older package with no GitHub field makes no update request: one manual installation is necessary to add that field.
- Current-version and offline cases do not schedule an inappropriate installation.

The hypothetical **v1.4.3** release in the test is only a fixture demonstrating an update from v1.4.2. It was **not published**. Synthetic future engine numbers test range matching only; they are not executions of future software.

## Source identity

These supplied v0.2.59 files have the same Git blob IDs as the official **v0.2.60 tag** inspected through GitHub:

| Native engine file | Git blob SHA-1 |
| --- | --- |
| `src/mods/Manifest.lua` | `865b9f03e0dbc5ce4c102321873df0b22bfccf6b` |
| `src/mods/ModUpdate.lua` | `d839a0f71c731f53e7e14077e2b2d691918c02a5` |
| `src/import/RomImporter.lua` | `5cd193119ffcf5ff1addfd69a32b6fffbaff01cc` |

This establishes identity of those source modules, not an end-to-end physical-device test.

## Reproduce

From the repository root, with the original engine Lua source available locally:

```sh
texlua verification/v1.4.2/check_updater.lua /path/to/engine
python3 .github/scripts/build_release.py
```

The engine directory must contain `src/` and its normal data/dependencies from the application package. The test does not require a Pokémon ROM. [Recorded output](verification/v1.4.2/recorded-results.txt) and [test source](verification/v1.4.2/check_updater.lua) are included in the repository.

The previous [v1.4.1 verification](https://github.com/moocd123/gen1recomp-bicycle-plus/blob/v1.4.1/VERIFICATION.md) remains historical evidence. It is not relabelled as a new gameplay run.

## Release integrity

The builder checks the exact manifest, required GitHub repository, API, game targets and permissions, then verifies all six runtime SHA-256 hashes against the public v1.4.0 baseline. It packs only an explicit source/documentation/test allowlist, generates per-file integrity records and validates the ZIP. `SHA256SUMS.txt` covers the final asset.

The publishing workflow downloads the published ZIP and checksum, compares both with its build and verifies the checksum. See [Actions](https://github.com/moocd123/gen1recomp-bicycle-plus/actions) for the actual publication result.

The package contains no ROMs, engine executables, imported ROM caches, extracted game assets or soundtrack. GitHub/network availability and future breaking engine changes remain external constraints.
