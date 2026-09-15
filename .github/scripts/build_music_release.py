#!/usr/bin/env python3
"""Build source-only Bicycle Plus v1.8.0; exclude all music/ROM/test assets."""
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
ROOT = Path(__file__).resolve().parents[2]
VERSION = '1.8.0'
RUNTIME = {'automount.lua', 'colour_controls.lua', 'hardware_colours.lua', 'main.lua', 'colour_ui.lua', 'bike_parts.lua', 'music_menu.lua', 'colour_picker.lua', 'song_library.lua', 'audio.lua', 'colour_values.lua', 'audio_menu.lua', 'colours.lua'}
UNCHANGED = {'automount.lua': 'e034fb67a43fdcae21af3e47e63b2db4a2087f2d', 'bike_parts.lua': 'c60d47f77f638c6118edca07c733d8257beb06c3', 'colour_controls.lua': '37fc9962a1ae8420908779395f65ba2f4917f91b', 'colour_picker.lua': 'b461520a865ab4d1804f010070094eae392558e5', 'colour_ui.lua': 'ac6b77a1c6b54a2db5a535a70682e5dda3b5f7ae', 'colour_values.lua': 'd6313d8b6f57d409d63964d78fca4f88c55dd8b7', 'colours.lua': 'eafa7478d0531a3ca12f204ff9799401eb78ff62', 'hardware_colours.lua': 'a6cec9563ffd3e639e7991f8cb2dcbd21f93f9df'}
DOCS = {'README.md','LICENSE','CHANGELOG.md','COMPATIBILITY.md',
        'VERIFICATION.md','RELEASE_NOTES_v1.8.0.md','docs/RGB_EDITOR.md','docs/CUSTOM_MUSIC.md'}
def sha(b): return hashlib.sha256(b).hexdigest()
def main():
    files={n:(ROOT/n).read_bytes() for n in sorted(RUNTIME | DOCS | {'manifest.json'})}
    manifest=json.loads(files['manifest.json'])
    assert (manifest['id'],manifest['version'],manifest['entry'],manifest['api']) == ('bicycle_plus',VERSION,'main.lua',2)
    assert manifest['game_version']=='>=0.2.59' and manifest['github']=='moocd123/gen1recomp-bicycle-plus'
    assert set(manifest['games'])=={'red','blue','yellow','gold','silver','crystal'}
    hashes=json.loads((ROOT/'verification/v1.8.0/runtime-sha256.json').read_text())
    assert set(hashes)==RUNTIME
    for n in RUNTIME: assert sha(files[n])==hashes[n], f'Unreviewed source: {n}'
    for n,expected in UNCHANGED.items():
        b=files[n]
        assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==expected,n
    pack={'modkit':'1.0.0','packed_at':'2026-09-15T00:00:00Z','id':'bicycle_plus',
          'version':VERSION,'api':2,'engine_range':manifest['game_version'],
          'files':[{'path':n,'bytes':len(b),'sha256':sha(b)} for n,b in sorted(files.items())]}
    files['.modkit/pack.json']=(json.dumps(pack,indent=2)+'\n').encode()
    dist=ROOT/'dist';dist.mkdir(exist_ok=True)
    path=dist/f'bicycle_plus-{VERSION}.zip'
    with ZipFile(path,'w') as z:
        for n,b in sorted(files.items()):
            zi=ZipInfo(n,(2026,9,15,0,0,0));zi.create_system=3;zi.external_attr=0o100644<<16
            zi.compress_type=ZIP_DEFLATED;z.writestr(zi,b,compresslevel=9)
    with ZipFile(path) as z:
        assert not z.testzip() and set(z.namelist())==set(files)
        for n,b in files.items(): assert z.read(n)==b,n
    checksum=f'{sha(path.read_bytes())}  {path.name}\n'
    (dist/'SHA256SUMS.txt').write_text(checksum,encoding='ascii')
    print('PASS: 13 runtime hashes, 8 unchanged baseline files, update manifest and source-only ZIP round trip.')
    print(checksum,end='')
if __name__=='__main__': main()
