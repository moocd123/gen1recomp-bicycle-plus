# Repeating v1.8.0 tests

Run from the repository root with a compatible Gen1ReComp++ source folder:

```sh
for suite in check_library check_file_pickers check_menu check_native_audio_menu check_updater; do
  lua5.3 verification/v1.8.0/$suite.lua /path/to/engine || exit 1
done
for game in red blue yellow gold silver crystal; do
  lua5.3 verification/v1.8.0/check_audio.lua /path/to/engine "$game" || exit 1
done
python3 .github/scripts/build_release.py
```

`texlua` can replace `lua5.3`. The test hash helper uses sha2 when available or OpenSSL otherwise. The installer contains neither that helper nor any shell test code. OS dialogs, filesystem and playback Sources are test doubles. Production uses LÖVE/native objects, not these mocks.

Optional, local-only, with your own six ROMs (filenames in the script):

```sh
texlua verification/v1.8.0/check_rom_audio.lua /path/to/engine /path/to/your/roms
```

This invokes native extraction and synthesis but keeps the output in memory; it does not upload or package ROM/audio data. Recorded counts concern short sample windows, not every song through its entire loop.
