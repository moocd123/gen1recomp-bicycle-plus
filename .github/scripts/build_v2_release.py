#!/usr/bin/env python3
"""Build the public ZIP from the reviewed runtime allowlist; no private fixtures."""
from pathlib import Path
from zipfile import ZipFile,ZipInfo,ZIP_DEFLATED
import json,hashlib,sys
root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[2]
def sha(b):return hashlib.sha256(b).hexdigest()
h=json.loads((root/'verification/v2.0.0/runtime-sha256.json').read_text())
files={name:(root/name).read_bytes()for name in h['runtime']}
assert len(files)==37
for n,d in h['runtime'].items():assert sha(files[n])==d,'Runtime mismatch: '+n
for n,d in h['unchanged_from_approved_test3'].items():assert sha(files[n])==d,'Changed approved gameplay: '+n
assert len(h['unchanged_from_approved_test3'])==35
for n in ['manifest.json','LICENSE','README.md','CHANGELOG.md','COMPATIBILITY.md','VERIFICATION.md','RELEASE_NOTES_v2.0.0.md']:
 files[n]=(root/n).read_bytes()
m=json.loads(files['manifest.json']);assert (m['id'],m['name'],m['version'])==('bicycle_plus','AUTOBIKE+','2.0.0')
assert m['github']=='moocd123/gen1recomp-bicycle-plus'and m['api']==2 and m['game_version']=='>=0.3.36'
assert m['games']==['red','blue','yellow','gold','silver','crystal','firered','leafgreen']
assert m['permissions']==['engine_internals','compute']
assert m['conflicts']==['autobike_plus_test','autobike_plus_firered_beta']
for n in files:
 assert not Path(n).is_absolute()and '..'not in Path(n).parts
 assert Path(n).suffix in ('.lua','.json','.md') or n=='LICENSE'
pack={'modkit':'1.0.0','packed_at':'2026-09-30T00:00:00Z','id':m['id'],'version':m['version'],'api':2,'engine_range':m['game_version'],
 'files':[{'path':n,'bytes':len(b),'sha256':sha(b)}for n,b in sorted(files.items())]}
files['.modkit/pack.json']=(json.dumps(pack,indent=2)+'\n').encode()
out=root/'dist';out.mkdir(exist_ok=True);zpath=out/'bicycle_plus-2.0.0.zip'
with ZipFile(zpath,'w')as z:
 for n,b in sorted(files.items()):
  i=ZipInfo(n,(2026,9,30,0,0,0));i.compress_type=ZIP_DEFLATED;i.create_system=3;i.external_attr=0o100644<<16;z.writestr(i,b,compresslevel=9)
with ZipFile(zpath)as z:
 assert z.testzip()is None and set(z.namelist())==set(files)
 for n,b in files.items():assert z.read(n)==b
checksum=f'{sha(zpath.read_bytes())}  {zpath.name}\n';(out/'SHA256SUMS.txt').write_text(checksum)
print(f'PASS public package: {len(files)} entries, 35 unchanged approved modules, source-only archive')
print(checksum,end='')
