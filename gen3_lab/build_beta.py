#!/usr/bin/env python3
"""Build the isolated source-only AUTOBIKE+ FireRed beta artifact."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import hashlib, json
ROOT=Path(__file__).resolve().parents[1];MANIFEST=ROOT/'gen3_lab'/'beta_manifest.json';OUT=ROOT/'dist'
FILES={
 'main.lua':'gen3_lab/beta_main.lua','settings.lua':'gen3_lab/settings.lua','native_menu.lua':'gen3_lab/native_menu.lua',
 'colour_picker.lua':'gen3_lab/colour_picker.lua','pointer_bridge.lua':'gen3_lab/pointer_bridge.lua','text_entry.lua':'gen3_lab/text_entry.lua',
 'legacy_songs.lua':'gen3_lab/legacy_songs.lua','local_songs.lua':'gen3_lab/local_songs.lua','import_picker.lua':'import_picker.lua',
 'song_menu.lua':'gen3_lab/song_menu.lua','song_catalog.lua':'gen3_lab/song_catalog.lua','mount.lua':'gen3_lab/mount.lua',
 'native_mount.lua':'gen3_lab/native_mount.lua','integration.lua':'gen3_lab/integration.lua','parts.lua':'gen3_lab/parts.lua',
 'shading.lua':'gen3_lab/shading.lua','player_paint.lua':'gen3_lab/player_paint.lua','audio_layer.lua':'gen3_lab/audio_layer.lua',
 'README.md':'gen3_lab/BETA_README.md'}
def sha(b):return hashlib.sha256(b).hexdigest()
def main():
 m=json.loads(MANIFEST.read_text(encoding='utf-8'));assert m['id']=='autobike_plus_firered_beta'and m['entry']=='main.lua'and m['games']==['firered'];assert m['api']==2 and m.get('experimental')is True and'github'not in m and m['game_version']=='>=0.2.66';version=m['version'];assert version=='0.1.0-beta.1'
 payload={'manifest.json':MANIFEST.read_bytes()}
 for dest,source in FILES.items():p=ROOT/source;assert p.is_file(),f'missing staged source: {source}';payload[dest]=p.read_bytes()
 for name in payload:assert not name.lower().endswith(('.gba','.gb','.gbc','.png','.jpg','.ogg','.mp3','.wav','.flac'));assert'..'not in Path(name).parts and not name.startswith('/')
 meta={'modkit':'1.0.0','packed_at':'2026-09-20T00:00:00Z','id':m['id'],'version':version,'api':2,'engine_range':m['game_version'],'files':[{'path':n,'bytes':len(b),'sha256':sha(b)}for n,b in sorted(payload.items())]};payload['.modkit/pack.json']=(json.dumps(meta,indent=2)+'\n').encode()
 OUT.mkdir(exist_ok=True);archive=OUT/f'autobike_plus_firered_beta-{version}.zip'
 with ZipFile(archive,'w')as z:
  for name,data in sorted(payload.items()):info=ZipInfo(name,(2026,9,20,0,0,0));info.compress_type=ZIP_DEFLATED;info.create_system=3;info.external_attr=0o100644<<16;z.writestr(info,data,compresslevel=9)
 with ZipFile(archive)as z:assert z.testzip()is None and set(z.namelist())==set(payload);[(_ for _ in()).throw(AssertionError('ZIP byte mismatch: '+n))for n,d in payload.items()if z.read(n)!=d]
 checksum=f'{sha(archive.read_bytes())}  {archive.name}\n';(OUT/'AUTOBIKE_FIRERED_BETA_SHA256SUMS.txt').write_text(checksum,encoding='utf-8');print(f'PASS isolated FireRed beta ZIP: {len(payload)} files, no embedded game/media assets.');print(checksum,end='')
if __name__=='__main__':main()
