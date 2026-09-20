# AUTOBIKE+ FireRed test-build continuation

## User authorisation and deliverable

The user requested continued background implementation until a feature-complete, installable FireRed testing ZIP can be delivered. This authorises incremental development and testing on `gen3-lab`, not publication to the stable release or changes to unrelated repositories. This document is a handoff for scheduled work; it is not evidence that a coding run or test has executed.

The deliverable is a working test package, not another audit or a sprite preview. Do not describe partial components as a complete mod. No universal bug-free guarantee is possible; state what actually ran and any remaining device tests.

## Boundaries

- Work only on `gen3-lab` in `moocd123/gen1recomp-bicycle-plus`. Read its current head before each change; never force-push or overwrite another contributor's work.
- Keep main, v1.9.3, all existing public tags/releases, stable updater identity and the Gen1/2 runtime files unchanged. Do not run or edit a publishing workflow to make a regular release.
- Build the beta from its own staging directory with a distinct FireRed-only mod ID and separate options/cache/library keys. Use an Actions artifact for delivery, not a latest release or Update All rollout. Keep CI permissions read-only.
- Do not upload ROMs, extracted artwork/fonts, existing saves, personal audio, tokens or credentials. Runtime game assets must come from the user's host import. Use generated tones and procedural fixtures in public tests.
- No new subscription, paid AI endpoint or secret is authorised. Stop and ask if additional permissions, a hosted coding environment or another paid service is required.

## Source checkpoint

At handoff, the inspected lab head was `1cc88d4d1d7362e544d261939bd646c12e8d30b9`. See `gen3_lab/STATUS.md`, the source files beside it and `.github/workflows/gen3-lab.yml` for current implementation/test coverage. The pinned engine is `bryanthaboi/gen1recomp` v0.2.66, commit `d70ef7c40e4166b82ed8da692423f010f4406e1b`. Recheck current releases, but do not continually change the integration target without a concrete need.

The user has now also uploaded Emerald in the interactive conversation. Earlier notes saying Emerald was not supplied are outdated. Scheduled ChatGPT runs cannot access those project uploads: do not claim to inspect them during a scheduled run or upload them to GitHub as a workaround. The supported initial runtime target remains FireRed USA 1.0; other GBA games are reference/future work only.

## Required functionality

Preserve the established AUTOBIKE+ experience: owned-bike auto-mount on eligible new areas; intentional-dismount suppression until a new area or manual mount; safe native restrictions and no mounting while scripts/battles/transitions/Surf own control. Auto Bike is ON only when the setting is absent; saved ON/OFF remains intact.

Integrate player-only shade-preserving recolouring for both FireRed riders, every standard frame and facing, with native animated previews. Preserve rider pixels, alpha, source geometry, highlights/shadows and exact Original restoration. Unknown replacement artwork must fail safely rather than paint guessed regions. Keep RGB/hex entry, controller/mouse/touch/keyboard input, remembered custom values, cancel/apply and paint-only reset.

Use Gen3-native 240x160 menus: AUTO BIKE first, off-bike SFX FILTER, BIKE APPEARANCE, BIKE AUDIO and language. Keep the native Audio menu unchanged. Retain AREA/BICYCLE/BOTH without modifying stored volume/filter settings, separate cycling area/SFX/bicycle volume/filter controls, one BIKE SONG route, and restart/resume. New bike volume copies native Music once if absent, respecting zero.

Implement an independent Gen3 cycling-audio backend, not reuse the singleton native area music worker. Include original/current FireRed songs, the supported Gen1/2 imported-game soundtracks and local audio imports with platform-native selection/fallback. Preserve battles, cries, fanfares, pauses, focus and normal audio restoration. Long song names stay on one scrolling line. Settings navigation uses press edges, not hold-repeat; continuous colour adjustment is allowed.

## Execution, validation and durable state

Each run must inspect the checkpoint and make a concrete code/test/build improvement rather than merely poll readiness. Integrate the separate entry/lifecycle and native menus, then renderer/picker and audio/song backend, using small reviewable changes. Preserve tests and test intent; never delete or weaken checks just to get green results. Run available local tests or branch-scoped CI and read the actual results. Record exact commits, commands and outcomes in a concise durable checkpoint for the next run. Do not launch overlapping CI runs or duplicate unfinished work.

Before marking ready: all requested features must be connected, automated regression/integration tests must pass against pinned engine modules, stable runtime hashes must remain unchanged, generated audio must exercise real decoding where available, and the ZIP must contain only the intended beta source/documents with valid manifest and checksums. Confirm the downloadable artifact exists and matches the tested commit. Distinguish simulated callbacks from physical pickers and real codecs from listening tests.

If coding/commit/test tools are unavailable, an approval is needed, or required ROM-dependent verification cannot be completed in the scheduled environment, report the exact blocker and pause the scheduled task instead of silently polling or saying development is continuing. Do not fabricate test results or file links.

Notify the user only on a verified installable candidate or a concrete blocker requiring their action. At delivery provide the artifact link, concise install/test instructions, passed checks, limitations and backup advice, then disable the scheduled task. Do not post to Discord or release to existing users.
