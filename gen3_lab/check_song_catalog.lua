local Catalog=dofile('gen3_lab/song_catalog.lua')
local seen={[264]='bgm',[282]='bgm',[300]='bgm',[340]='bgm',[268]='fanfare',[299]='se'}
local Audio={songInfo=function(id)local k=seen[id];return k and{kind=k}or nil end}
local rows=Catalog.available(Audio)
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
ck(#rows==4,'catalog did not filter runtime song kinds')
ck(rows[1].id==264 and rows[2].id==282 and rows[3].id==300 and rows[4].id==340,'catalog order is not deterministic')
ck(rows[2].name=='Bicycle'and rows[3].name=='Pallet Town','friendly FireRed names missing')
ck(Catalog.key(282)=='firered:282'and Catalog.id('firered:282')==282 and Catalog.id('fr:300')==300,'song key conversion failed')
ck(Catalog.key(999)==nil and Catalog.id('game:red:Music_BikeRiding')==nil,'catalog accepted unsupported key')
ck(Catalog.describe('original')=='ORIGINAL BICYCLE'and Catalog.describe('firered:340')=='Mewtwo Battle','song description failed')
ck(Catalog.describe('firered:999')=='MISSING SONG','missing song description unsafe')
print('PASS '..n..' FireRed current-song catalogue assertions.')
