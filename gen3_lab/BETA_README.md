# AUTOBIKE+ FireRed Test

This is an isolated test package for the FireRed (Gen 3) port of AUTOBIKE+.
It uses the separate mod id `autobike_plus_firered_beta`; it does not replace
the stable `bicycle_plus` mod or its settings/library.

## Target

- Gen1ReComp++ 0.2.66 or newer compatible FireRed build
- Pokemon FireRed USA/Europe 1.0 imported by the host application
- FireRed only. Ruby, Sapphire, Emerald and LeafGreen are not runtime targets
  of this test package yet.

## Before testing

Back up normal game progress and keep the stable AUTOBIKE+ package installed
separately. This is development software and has not been physically tested on
every supported device.

## Install

Install the ZIP through the normal Gen1ReComp++ mod importer. The ZIP is the
mod package itself; do not unzip it into the stable AUTOBIKE+ directory.
Restart Gen1ReComp++ after installing/enabling it.

## Test areas

Check automatic mount/dismount behavior, all bicycle paint parts and Original
restoration, FireRed-style settings screens, AREA/BICYCLE/BOTH audio routing,
FireRed and imported Gen1/2 song selection, local MP3/OGG/WAV/FLAC importing,
restart/resume, battles/fanfares, and return to normal audio after dismounting.

Automated tests exercise the source logic against the pinned engine, including
simulated native file-picker delivery. They do not replace real-ROM gameplay,
visual inspection, listening, or physical-device file-picker tests.
