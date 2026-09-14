#!/usr/bin/env python3
"""Build the reviewed v1.4.2 update from a strict allowlist; never package game data."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
DIST = ROOT / 'dist'
VERSION = '1.4.2'
REPOSITORY = 'moocd123/gen1recomp-bicycle-plus'
LUA_HASHES = {
    'audio.lua': '7923276326260941c5af81cdbb704ed282fa99ca4156d63a18e369944835e880',
    'audio_menu.lua': 'fbd12b1c7ba818ab140d25ce76f01f52847f92dc20505cd766e5fced53fe5d71',
    'automount.lua': '56cd15b7e830eb50551245978976b533114aebdc72218ded28c35f268d6d019c',
    'bike_parts.lua': '9f6f88975ed71bd5409800c78c91a975375790911f0f26af7b9c39023321fb87',
    'colours.lua': '3913d67b0c95c4744e9b7cdd922d2596ac8d272b001bd38dc2ea2038a28cb1d4',
    'main.lua': 'f349fcd0da72767bd558cbed83a5f4d53acd7c30c8ec9e48db8e5ce5d289c0d6',
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    manifest = json.loads((ROOT / 'manifest.json').read_text(encoding='utf-8'))
    expected = ('bicycle_plus', VERSION, '>=0.2.59', REPOSITORY)
    actual = tuple(manifest.get(k) for k in ('id', 'version', 'game_version', 'github'))
    if actual != expected:
        raise SystemExit('This builder requires the reviewed v1.4.2 range and GitHub update source.')
    if manifest.get('entry') != 'main.lua' or manifest.get('api') != 2:
        raise SystemExit('Unexpected entry point or required API.')
    if set(manifest.get('games', [])) != {'red', 'blue', 'yellow', 'gold', 'silver', 'crystal'}:
        raise SystemExit('Unexpected game targeting.')
    if manifest.get('permissions') != ['engine_internals']:
        raise SystemExit('Unexpected permissions; launcher-owned updates need no new mod permission.')
    if manifest.get('optional_dependencies') != ['trainer_skins'] or manifest.get('affects_link') is not False:
        raise SystemExit('Unexpected companion dependency or link declaration.')
    names = sorted([*LUA_HASHES, 'manifest.json', 'README.md', 'LICENSE',
                    'CHANGELOG.md', 'COMPATIBILITY.md', 'VERIFICATION.md',
                    'RELEASE_NOTES_v1.4.2.md', 'verification/v1.4.2/check_updater.lua',
                    'verification/v1.4.2/recorded-results.txt'])
    files = {name: (ROOT / name).read_bytes() for name in names}
    for name, expected_hash in LUA_HASHES.items():
        if digest(files[name]) != expected_hash:
            raise SystemExit(f'{name} differs from the reviewed public v1.4.0 code.')
    metadata = {
        'modkit': '1.0.0', 'packed_at': '2026-09-14T00:00:00Z',
        'id': manifest['id'], 'version': VERSION, 'api': manifest['api'],
        'engine_range': manifest['game_version'],
        'files': [{'path': name, 'bytes': len(data), 'sha256': digest(data)}
                  for name, data in sorted(files.items())],
    }
    files['.modkit/pack.json'] = (json.dumps(metadata, indent=2) + '\n').encode('utf-8')
    DIST.mkdir(exist_ok=True)
    archive = DIST / f'bicycle_plus-{VERSION}.zip'
    with ZipFile(archive, 'w') as z:
        for name, data in sorted(files.items()):
            info = ZipInfo(name, date_time=(2026, 9, 14, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            z.writestr(info, data, compresslevel=9)
    with ZipFile(archive) as z:
        if z.testzip() is not None or set(z.namelist()) != set(files):
            raise SystemExit('ZIP verification failed.')
        for name, data in files.items():
            if z.read(name) != data:
                raise SystemExit(f'ZIP round-trip failed: {name}')
    checksum = f'{digest(archive.read_bytes())}  {archive.name}\n'
    (DIST / 'SHA256SUMS.txt').write_text(checksum, encoding='ascii')
    print('PASS: manifest/update source, six unchanged runtime files, allowlisted packaging and ZIP integrity.')
    print('Packaging checks do not certify future engine gameplay compatibility.')
    print(checksum, end='')


if __name__ == '__main__':
    main()
