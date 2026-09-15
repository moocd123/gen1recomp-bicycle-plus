#!/usr/bin/env python3
"""Build the reviewed source-only AUTOBIKE+ v1.9.3 package."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
VERSION = '1.9.3'
sha = lambda b: hashlib.sha256(b).hexdigest()

def main():
    h = json.loads((ROOT/'verification/v1.9.3/runtime-sha256.json').read_text())
    runtime = h['runtime']
    assert len(runtime) == 15 and len(h['unchanged_from_v1_9_2']) == 10
    assert all(Path(n).name == n and n.endswith('.lua') for n in runtime)
    docs = ['README.md', 'LICENSE', 'CHANGELOG.md', 'COMPATIBILITY.md',
            'VERIFICATION.md', 'RELEASE_NOTES_v1.9.3.md', 'docs/CUSTOM_MUSIC.md']
    files = {n: (ROOT/n).read_bytes() for n in list(runtime)+docs+['manifest.json']}
    for n, d in runtime.items():
        assert sha(files[n]) == d, 'Unreviewed runtime: '+n
    for n, d in h['unchanged_from_v1_9_2'].items():
        assert sha(files[n]) == d, 'Baseline mismatch: '+n
    restored_renderer = files['colours.lua'].replace(
        b'-- Bicycle Plus: independent wheel, stripe, centre, edge and combined handlebar colours.',
        b'-- Bicycle Plus: independent wheel, stripe, centre, edge, detail and handlebar colours.', 1).replace(
        b'frame="bike_handlebars_colour", handlebars="bike_handlebars_colour"',
        b'frame="bike_frame_colour", handlebars="bike_handlebars_colour"', 1)
    assert sha(restored_renderer) == '1dd05758b8c92cb4b22ac01b174251cd6ee3d286cbfa5777aa6ebc6da3b844e6'
    m = json.loads(files['manifest.json'])
    assert (m['id'], m['name'], m['version'], m['api'], m['entry']) == ('bicycle_plus', 'AUTOBIKE+', VERSION, 2, 'main.lua')
    assert m['game_version'] == '>=0.2.59' and m['github'] == 'moocd123/gen1recomp-bicycle-plus'
    assert set(m['games']) == {'red','blue','yellow','gold','silver','crystal'}
    assert m['permissions'] == ['engine_internals']
    meta = {'modkit':'1.0.0','packed_at':'2026-09-15T00:00:00Z','id':m['id'],
            'version':VERSION,'api':2,'engine_range':m['game_version'],
            'files':[{'path':n,'bytes':len(b),'sha256':sha(b)} for n,b in sorted(files.items())]}
    files['.modkit/pack.json'] = (json.dumps(meta, indent=2)+'\n').encode()
    out = ROOT/'dist'; out.mkdir(exist_ok=True)
    archive = out/f'bicycle_plus-{VERSION}.zip'
    with ZipFile(archive,'w') as z:
        for name, data in sorted(files.items()):
            info = ZipInfo(name, (2026,9,15,0,0,0)); info.compress_type = ZIP_DEFLATED
            info.create_system = 3; info.external_attr = 0o100644 << 16
            z.writestr(info, data, compresslevel=9)
    with ZipFile(archive) as z:
        assert z.testzip() is None and set(z.namelist()) == set(files)
        for name, data in files.items(): assert z.read(name) == data
    checksum = f'{sha(archive.read_bytes())}  {archive.name}\n'
    (out/'SHA256SUMS.txt').write_text(checksum)
    print('PASS 15 runtime hashes, ten unchanged modules, exact renderer boundary, manifest and ZIP integrity.')
    print(checksum, end='')

if __name__ == '__main__':
    main()
