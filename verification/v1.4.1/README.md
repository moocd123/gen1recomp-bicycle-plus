# v1.4.1 headless check evidence

These are the recorded results from preparation of the v1.4.1 hotfix, not new v0.2.60 gameplay runs.

Run the version-gate reproduction from the repository root with the supplied v0.2.59 runtime extracted:

```sh
texlua verification/v1.4.1/check_version_gate.lua /path/to/extracted/runtime
```

The runtime path must contain `src/`. The script does not edit the engine on disk; it varies `Version.engine` in its own Lua process. It uses the included original manifest as a rejection fixture and the repository manifest as the candidate. No save directory is opened.

`recorded-results.txt` contains the retained output from the prepared headless suites and version check. The earlier regression scripts require the original source/test archive and are not bundled here. They used test doubles, not hardware graphics/audio.

See [VERIFICATION.md](../../VERIFICATION.md) at the repository root for scope and publication checks.
