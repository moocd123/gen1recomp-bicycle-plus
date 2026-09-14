#!/usr/bin/env python3
"""Build the reviewed v1.6.0 source-only release from an explicit allowlist."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import hashlib, json
ROOT=Path(__file__).resolve().parents[2]
HASHES={'audio.lua': '7923276326260941c5af81cdbb704ed282fa99ca4156d63a18e369944835e880', 'audio_menu.lua': 'fbd12b1c7ba818ab140d25ce76f01f52847f92dc20505cd766e5fced53fe5d71', 'automount.lua': '56cd15b7e830eb50551245978976b533114aebdc72218ded28c35f268d6d019c', 'bike_parts.lua': '33af78cc7d719755096cb49057d9d8b262ddecbce71df98cd45105b0aca16b19', 'colour_controls.lua': '30ecf3b2e8f16b678c5f8655e24785e880c7056253f61c4bf12aff88f847e82d', 'colour_picker.lua': '46e6cf13e4781cbe61b0e6ccd2f258f0b732a02fbf72280f38dfa610e3156654', 'colours.lua': '1dd05758b8c92cb4b22ac01b174251cd6ee3d286cbfa5777aa6ebc6da3b844e6', 'hardware_colours.lua': '61f9f04e20aee2f9cd094bb76d038db005f0d2ecb3b7b905bb2a948eb5fe45f0', 'main.lua': 'fe28ccae165664b170729a94c6b5248e5401ce308c15d3897032635c14946192'}

def sha(b): return hashlib.sha256(b).hexdigest()
def main():
    m=json.loads((ROOT/'manifest.json').read_text())
    assert (m['id'],m['version'],m['game_version'],m['api'],m['entry'],m['github']) == ('bicycle_plus','1.6.0','>=0.2.59',2,'main.lua','moocd123/gen1recomp-bicycle-plus')
    assert m['permissions']==['engine_internals'] and m['affects_link'] is False
    assert set(m['games'])=={'red','blue','yellow','gold','silver','crystal'}
    names=sorted([*HASHES,'manifest.json','LICENSE','README.md','CHANGELOG.md','COMPATIBILITY.md','VERIFICATION.md','RELEASE_NOTES_v1.6.0.md','docs/HARDWARE_COLOURS.md','docs/BICYCLE_REGIONS.md'])
    files={n:(ROOT/n).read_bytes() for n in names}
    for n,h in HASHES.items(): assert sha(files[n])==h, f'Unreviewed runtime file: {n}'
    meta={'modkit':'1.0.0','packed_at':'2026-09-14T00:00:00Z','id':m['id'],'version':m['version'],'api':m['api'],'engine_range':m['game_version'],'files':[{'path':n,'bytes':len(b),'sha256':sha(b)} for n,b in sorted(files.items())]}
    files['.modkit/pack.json']=(json.dumps(meta,indent=2)+'\n').encode()
    dist=ROOT/'dist';dist.mkdir(exist_ok=True);out=dist/'bicycle_plus-1.6.0.zip'
    with ZipFile(out,'w') as z:
        for n,b in sorted(files.items()):
            info=ZipInfo(n,(2026,9,14,0,0,0));info.compress_type=ZIP_DEFLATED;info.create_system=3;info.external_attr=0o100644<<16
            z.writestr(info,b,compresslevel=9)
    with ZipFile(out) as z:
        assert z.testzip() is None and set(z.namelist())==set(files)
        for n,b in files.items(): assert z.read(n)==b
    sums=f'{sha(out.read_bytes())}  {out.name}\n'
    (dist/'SHA256SUMS.txt').write_text(sums,encoding='ascii')
    print('PASS: exact manifest, nine reviewed modules, source-only allowlist, per-file hashes and ZIP integrity.');print(sums,end='')
if __name__=='__main__':main()
