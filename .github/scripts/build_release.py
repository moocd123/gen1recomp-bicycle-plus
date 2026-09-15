#!/usr/bin/env python3
"""Build the reviewed v1.8.0 source-only mod; never package personal audio/ROMs."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
VERSION = '1.8.0'
RUNTIME = {'main.lua','audio.lua','audio_menu.lua','automount.lua','bike_parts.lua',
           'colours.lua','hardware_colours.lua','colour_controls.lua','colour_picker.lua',
           'colour_ui.lua','colour_values.lua','bike_songs.lua','song_import.lua','song_menu.lua'}
DOCS = {'README.md','LICENSE','CHANGELOG.md','COMPATIBILITY.md','VERIFICATION.md',
        'RELEASE_NOTES_v1.8.0.md','docs/RGB_EDITOR.md','docs/CUSTOM_MUSIC.md'}
BASELINE = {
 'automount.lua':'56cd15b7e830eb50551245978976b533114aebdc72218ded28c35f268d6d019c',
 'bike_parts.lua':'33af78cc7d719755096cb49057d9d8b262ddecbce71df98cd45105b0aca16b19',
 'colour_controls.lua':'dadf554a0f725598cf730299bbf6b2fc33313ee22992b2105eeb1834a9864924',
 'colour_picker.lua':'94eca5cc6b5506f82f7318d4ae7bcb5f16331895a4d4d994ad89f5eb76510ab4',
 'colour_ui.lua':'930dbeb7f9eca2fd82d4e81b636c56afd8be2a5aed4d35f7feec1f390cabc5ad',
 'colour_values.lua':'9a6121b6c4659a5e7640ce47a6ff0d7c876cd2f2fa5d3affb82e1d25eda42e7e',
 'colours.lua':'1dd05758b8c92cb4b22ac01b174251cd6ee3d286cbfa5777aa6ebc6da3b844e6',
 'hardware_colours.lua':'61f9f04e20aee2f9cd094bb76d038db005f0d2ecb3b7b905bb2a948eb5fe45f0',
}
def digest(b): return hashlib.sha256(b).hexdigest()
def main():
    files = {n:(ROOT/n).read_bytes() for n in sorted(RUNTIME|DOCS|{'manifest.json'})}
    m = json.loads(files['manifest.json'])
    assert (m['id'],m['version'],m['api'],m['entry']) == ('bicycle_plus',VERSION,2,'main.lua')
    assert m['github'] == 'moocd123/gen1recomp-bicycle-plus' and m['game_version'] == '>=0.2.59'
    assert set(m['games']) == {'red','blue','yellow','gold','silver','crystal'}
    expected = json.loads((ROOT/'verification/v1.8.0/runtime-sha256.json').read_text())
    assert set(expected) == RUNTIME
    for n in RUNTIME: assert digest(files[n]) == expected[n], f'Unreviewed runtime bytes: {n}'
    for n,h in BASELINE.items(): assert digest(files[n]) == h, f'Baseline unexpectedly changed: {n}'
    meta = {'modkit':'1.0.0','packed_at':'2026-09-15T00:00:00Z','id':m['id'],'version':VERSION,
            'api':2,'engine_range':m['game_version'],
            'files':[{'path':n,'bytes':len(b),'sha256':digest(b)}for n,b in sorted(files.items())]}
    files['.modkit/pack.json'] = (json.dumps(meta,indent=2)+'\n').encode()
    dist=ROOT/'dist'; dist.mkdir(exist_ok=True)
    path=dist/f'bicycle_plus-{VERSION}.zip'
    with ZipFile(path,'w')as z:
        for n,b in sorted(files.items()):
            info=ZipInfo(n,(2026,9,15,0,0,0)); info.compress_type=ZIP_DEFLATED
            info.create_system=3; info.external_attr=0o100644<<16
            z.writestr(info,b,compresslevel=9)
    with ZipFile(path)as z:
        assert z.testzip()is None and set(z.namelist())==set(files)
        for n,b in files.items(): assert z.read(n)==b,n
    checksum=f'{digest(path.read_bytes())}  {path.name}\n'
    (dist/'SHA256SUMS.txt').write_text(checksum,encoding='ascii')
    print('PASS: 14 runtime hashes, eight unchanged baseline modules, manifest and allowlisted source-only ZIP.')
    print(checksum,end='')
if __name__=='__main__': main()
