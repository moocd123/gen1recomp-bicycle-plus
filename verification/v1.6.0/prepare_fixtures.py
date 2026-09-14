"""Download pinned art only for tests. It is never committed or packed into the mod."""
from pathlib import Path
from PIL import Image
import argparse, base64, hashlib, io, json, re, urllib.request, zipfile
NATIVE={
 'red':('pret/pokered','ed117d0b11c3d3fd9a75a9afac64eff1bd8cc3d4'),
 'chris':('pret/pokecrystal','0d18d11a6b93f1de5af558206d228106d3067291'),
 'kris':('pret/pokecrystal','161ce5722d19efb305928f418b83b36897200edb')}
TRAINERS={
 '010':('v0.1.0','3099586e1159e77002c75887d776ced11e4807abe54fb629b565ab2ff0334232'),
 '020':('V0.2.0','9295d0f2749d9e5519257fdb6609f781af3b8482cfc91e28fcd2a0437cd5ce36')}
SKINS={'Brendan','Dawn','Dawn P','Green Ad','Hilbert','Hilda','Leaf','Lyra','May','Michael','Nate','Rosa','Wes'}
def get(url):
 req=urllib.request.Request(url,headers={'User-Agent':'BicyclePlus-Verification'})
 with urllib.request.urlopen(req,timeout=45) as f:return f.read()
def fixture(name,data,kind,skin=None,quantized=False):
 with Image.open(io.BytesIO(data)) as im:
  im=im.convert('RGBA');assert im.size==(16,96)
  pixels=bytearray(im.tobytes())
 if quantized:
  for i in range(0,len(pixels),4):
   if not pixels[i+3]:continue
   lum=(pixels[i]*.2126+pixels[i+1]*.7152+pixels[i+2]*.0722)/255
   shade=170 if lum>=.60 else 85 if lum>=.17 else 0
   pixels[i:i+3]=bytes([shade]*3)
 return '{name=%s,kind=%s,skin=%s,trueColor=%s,rgba=%s}'%(
  json.dumps(name),json.dumps(kind),json.dumps(skin) if skin else 'nil',
  'true' if skin and not quantized else 'false',json.dumps(pixels.hex()))
def main():
 ap=argparse.ArgumentParser();ap.add_argument('out');ap.add_argument('--native-dir');ap.add_argument('--trainer-zip');a=ap.parse_args()
 rows=[]
 for name,(repo,sha) in NATIVE.items():
  if a.native_dir:data=(Path(a.native_dir)/(name+'_bike.png')).read_bytes()
  else:data=base64.b64decode(json.loads(get(f'https://api.github.com/repos/{repo}/git/blobs/{sha}'))['content'])
  assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()==sha
  rows.append(fixture(name,data,'red' if name=='red' else 'gen2'))
 versions={'020':TRAINERS['020']} if a.trainer_zip else TRAINERS
 for ver,(tag,digest) in versions.items():
  data=Path(a.trainer_zip).read_bytes() if a.trainer_zip else get(f'https://github.com/DarkwarePX/Trainer-Skins/releases/download/{tag}/trainer_skins-{ "0.1.0" if ver=="010" else "0.2.0"}.zip')
  assert hashlib.sha256(data).hexdigest()==digest,'companion archive changed'
  with zipfile.ZipFile(io.BytesIO(data)) as z:
   names={Path(n).parent.name:n for n in z.namelist() if n.endswith('/bike.png')}
   assert set(names)==SKINS,'unexpected trainer artwork set'
   for skin,n in sorted(names.items()):
    for quant in [False,True]:
     rows.append(fixture(f'{ver}/{skin}/'+('palette' if quant else 'true'),z.read(n),'gen2',skin,quant))
   if ver=='020':
    source=z.read(next(n for n in z.namelist() if n.endswith('/main.lua'))).decode()
    block=source[source.index('local SKIN_COLOR_PALETTES ='):source.index('local SKIN_COLOR_PALETTES =')+2500]
    accents=re.findall(r'(\w+)\s*=\s*\{\s*\{[^}]+\},\s*\{[^}]+\},\s*\{\s*(\d+),\s*(\d+),\s*(\d+)\s*\}',block)
    assert len(accents)==10,'expected ten named palettes in actual 0.2.0 code'
    out=Path(a.out);out.parent.mkdir(parents=True,exist_ok=True)
    (out.parent/'trainer_accents.lua').write_text('return {\n'+',\n'.join('{%s,{%s,%s,%s}}'%(json.dumps(n.upper()),r,g,b) for n,r,g,b in accents)+'\n}\n')
 Path(a.out).write_text('return {\n'+',\n'.join(rows)+'\n}\n')
 print('Prepared',len(rows),'source/quantised fixture cases; original art remains outside release.')
if __name__=='__main__':main()
