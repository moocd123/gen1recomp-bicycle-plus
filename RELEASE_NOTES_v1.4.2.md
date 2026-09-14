# Bicycle Plus v1.4.2 — In-app updates and future engine versions

This release adds **native Check for updates / Update All support** and removes the upper engine-version limit.

## What changed

- The manifest now tells the launcher to check **`moocd123/gen1recomp-bicycle-plus`** for new releases.
- The installable asset is **`bicycle_plus-1.4.2.zip`**, matching the launcher's preferred update naming.
- The engine requirement is now **`>=0.2.59`**, rather than a list of two specific engine versions. The minimum version and mod API 2 requirement remain.
- **All six runtime Lua files are unchanged.** Automatic cycling, manual dismount memory, bicycle colours, Trainer Skins handling, audio profiles and saved-setting keys are unchanged.

## Install this update once

Download **`bicycle_plus-1.4.2.zip`** below and leave it zipped. For v1.4.0/v1.4.1 installations, return to the launcher's MODS tab, delete only the old Bicycle Plus entry, import this ZIP, enable your editions, and fully close/reopen the app. Do not delete your saves or app data.

**One manual install is necessary:** older packages do not contain the GitHub repository field, so the app does not know where to look for this update. After installing this version, use **Update All** for subsequently published releases. It is a user-triggered check, not a background updater.

Use the attached mod ZIP, **not GitHub's automatic Source code ZIP**. `SHA256SUMS.txt` is optional.

## Compatibility and checks

New engine numbers alone no longer block the mod. **That is not a guarantee that every future engine will work:** breaking changes to rendering, audio, menus, movement or the mod API may still require fixes.

Native Lua checks cover range validation, six-game launcher eligibility, the required API check, GitHub update discovery, release ZIP selection, version comparison and Update All queueing. UI, network and install boundaries are simulated in those headless tests. Full v0.2.60 gameplay and every physical platform are not newly verified. The publishing workflow checks the exact source hashes, package contents and downloaded release bytes.

[Verification](https://github.com/moocd123/gen1recomp-bicycle-plus/blob/v1.4.2/VERIFICATION.md) · [Report an issue](https://github.com/moocd123/gen1recomp-bicycle-plus/issues)
