#!/usr/bin/env python3
"""Allowlisted, reproducible AUTOBIKE+ package; old ID retained for Update All."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import hashlib
import json
ROOT=Path(__file__).resolve().parents[2]
VERSION='1.9.2'
def sha(data): return hashlib.sha256(data).hexdigest()
def main():
    manifest=json.loads((ROOT/'manifest.json').read_text())
    assert (manifest['id'],manifest['name'],manifest['version'],manifest['api'],manifest['entry'])==('bicycle_plus','AUTOBIKE+',VERSION,2,'main.lua')
    assert manifest['game_version']=='>=0.2.59' and manifest['github']=='moocd123/gen1recomp-bicycle-plus'
    assert set(manifest['games'])=={'red','blue','yellow','gold','silver','crystal'}
    hashes=json.loads((ROOT/'verification/v1.9.2/runtime-sha256.json').read_text())
    runtime=hashes['runtime']; assert len(runtime)==15
    docs=['README.md','LICENSE','CHANGELOG.md','COMPATIBILITY.md','VERIFICATION.md','RELEASE_NOTES_v1.9.2.md','docs/CUSTOM_MUSIC.md']
    files={name:(ROOT/name).read_bytes() for name in sorted(set(runtime)|set(docs)|{'manifest.json'})}
    for name,digest in runtime.items(): assert sha(files[name])==digest, name
    for name,digest in hashes['unchanged_from_v1_9_1'].items(): assert sha(files[name])==digest, name
    metadata={'modkit':'1.0.0','packed_at':'2026-09-15T00:00:00Z','id':'bicycle_plus','version':VERSION,'api':2,'engine_range':manifest['game_version'],
              'files':[{'path':n,'bytes':len(d),'sha256':sha(d)} for n,d in sorted(files.items())]}
    files['.modkit/pack.json']=(json.dumps(metadata,indent=2)+'\n').encode()
    dist=ROOT/'dist';dist.mkdir(exist_ok=True);archive=dist/f'bicycle_plus-{VERSION}.zip'
    with ZipFile(archive,'w') as z:
        for name,data in sorted(files.items()):
            info=ZipInfo(name,date_time=(2026,9,15,0,0,0));info.compress_type=ZIP_DEFLATED;info.create_system=3;info.external_attr=0o100644<<16
            z.writestr(info,data,compresslevel=9)
    with ZipFile(archive) as z:
        assert z.testzip() is None and set(z.namelist())==set(files)
        for name,data in files.items(): assert z.read(name)==data,name
    checksum=f'{sha(archive.read_bytes())}  {archive.name}\n';(dist/'SHA256SUMS.txt').write_text(checksum)
    print('PASS exact manifest, 15 runtime hashes, unchanged modules and source-only ZIP roundtrip.');print(checksum,end='')
if __name__=='__main__':main()
