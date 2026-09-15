#!/usr/bin/env python3
"""Reproducible source-only Bicycle Plus v1.7.0 package; never include test art."""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
VERSION = '1.7.0'
RUNTIME = {'main.lua', 'audio.lua', 'audio_menu.lua', 'automount.lua',
           'bike_parts.lua', 'colours.lua', 'hardware_colours.lua',
           'colour_controls.lua', 'colour_picker.lua', 'colour_ui.lua', 'colour_values.lua'}
DOCS = {'README.md', 'LICENSE', 'CHANGELOG.md', 'COMPATIBILITY.md',
        'VERIFICATION.md', 'RELEASE_NOTES_v1.7.0.md', 'docs/RGB_EDITOR.md'}
UNCHANGED = {
    'audio.lua': '22d09b68031f1512e78591d9d98bce72d76eefaf',
    'audio_menu.lua': 'cf0a4a3ebc492e1ed4edcbc168c9808179f75d5a',
    'automount.lua': 'e034fb67a43fdcae21af3e47e63b2db4a2087f2d',
    'bike_parts.lua': 'c60d47f77f638c6118edca07c733d8257beb06c3',
    'colours.lua': 'eafa7478d0531a3ca12f204ff9799401eb78ff62',
    'hardware_colours.lua': 'a6cec9563ffd3e639e7991f8cb2dcbd21f93f9df',
}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def main():
    files = {name: (ROOT / name).read_bytes() for name in sorted(RUNTIME | DOCS | {'manifest.json'})}
    manifest = json.loads(files['manifest.json'])
    assert (manifest['id'], manifest['version'], manifest['api'], manifest['entry']) == ('bicycle_plus', VERSION, 2, 'main.lua')
    assert manifest['game_version'] == '>=0.2.59'
    assert manifest['github'] == 'moocd123/gen1recomp-bicycle-plus'
    assert set(manifest['games']) == {'red', 'blue', 'yellow', 'gold', 'silver', 'crystal'}
    hashes = json.loads((ROOT / 'verification/v1.7.0/runtime-sha256.json').read_text())
    assert set(hashes) == RUNTIME
    for name in RUNTIME:
        assert sha256(files[name]) == hashes[name], f'Unreviewed runtime bytes: {name}'
    for name, expected in UNCHANGED.items():
        data = files[name]
        assert hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest() == expected, name
    metadata = {'modkit': '1.0.0', 'packed_at': '2026-09-15T00:00:00Z',
                'id': manifest['id'], 'version': VERSION, 'api': 2,
                'engine_range': manifest['game_version'],
                'files': [{'path': n, 'bytes': len(d), 'sha256': sha256(d)} for n, d in sorted(files.items())]}
    files['.modkit/pack.json'] = (json.dumps(metadata, indent=2) + '\n').encode()
    dist = ROOT / 'dist'
    dist.mkdir(exist_ok=True)
    archive = dist / f'bicycle_plus-{VERSION}.zip'
    with ZipFile(archive, 'w') as z:
        for name, data in sorted(files.items()):
            info = ZipInfo(name, date_time=(2026, 9, 15, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            z.writestr(info, data, compresslevel=9)
    with ZipFile(archive) as z:
        assert z.testzip() is None and set(z.namelist()) == set(files)
        for name, data in files.items():
            assert z.read(name) == data, name
    checksum = f'{sha256(archive.read_bytes())}  {archive.name}\n'
    (dist / 'SHA256SUMS.txt').write_text(checksum, encoding='ascii')
    print('PASS: 11 runtime hashes, six unchanged baseline modules, manifest and source-only ZIP integrity.')
    print(checksum, end='')


if __name__ == '__main__':
    main()
