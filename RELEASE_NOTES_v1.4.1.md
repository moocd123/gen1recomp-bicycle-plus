# Bicycle Plus v1.4.1 — Engine-version compatibility hotfix

This update addresses the **Incompatible** warning caused by v1.4.0 requiring exactly Gen1ReComp++ v0.2.59.

The manifest now permits **v0.2.59 or v0.2.60**. All six production Lua files remain unchanged: automatic cycling, deliberate dismount memory, five-part bicycle colours, Trainer Skins handling, and normal/cycling audio profiles have not been rewritten. The mod ID and saved-setting keys stay the same.

## Download and install

Download **Bicycle_Plus-1.4.1-Gen1ReComp-0.2.60.zip** from the assets below and **leave it zipped**. The filename mentions v0.2.60, but the package also permits v0.2.59.

To update, return to the launcher's **MODS** tab, delete only the old **Bicycle Plus** entry, import the new ZIP, enable your editions, then fully close and reopen the application. The supplied launcher's Delete action retains the mod-options table. Do not delete your saves or the whole mods folder.

**Do not import GitHub's automatic Source code ZIP.** `SHA256SUMS.txt` is optional and lets you verify the installable download.

## Verification limits

The engine-version rejection was reproduced using the supplied v0.2.59 launcher's actual version-check logic with v0.2.60 supplied as a test input. The corrected declaration passed that check. The prepared hotfix also passed the recorded headless regression checks.

**This is a targeted version-restriction fix, not a fully gameplay-tested v0.2.60 port.** Graphics, audio devices and the complete companion-mod stack on v0.2.60 have not been newly verified. Feedback is welcome, including your engine version, game edition, platform and enabled mods.

The release builder checks the manifest, verifies that all six Lua hashes match v1.4.0, and validates the generated ZIP. No ROMs, game executables or extracted game assets are included.

[Verification details](https://github.com/moocd123/gen1recomp-bicycle-plus/blob/v1.4.1/VERIFICATION.md) · [Report an issue](https://github.com/moocd123/gen1recomp-bicycle-plus/issues)
