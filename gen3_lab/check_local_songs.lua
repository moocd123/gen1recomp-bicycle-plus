local Local=dofile('gen3_lab/local_songs.lua')
local store={};local cache={}
function cache:read(p)return store[p]end
function cache:write(p,b)store[p]=b;return true end
function cache:delete(p)store[p]=nil;return true end
function cache:info(p)local b=store[p];return b and{type='file',size=#b}or nil end
local registry={};local serial=0
local function clone(t)local o={};for k,v in pairs(t or{})do o[k]=type(v)=='table'and clone(v)or v end;return o end
local Json={}
function Json.encode(t)serial=serial+1;local k='J'..serial;registry[k]=clone(t);return k end
function Json.decode(s)assert(registry[s],'bad json token');return clone(registry[s])end
local Runtime={safeMode=false}
local released=0
local function sourceFromBytes(bytes,name)
 assert(type(bytes)=='string'and#bytes>0 and type(name)=='string')
 return{getDuration=function()return 12.5 end,release=function()released=released+1 end,
  play=function()end,setLooping=function()end,setVolume=function()end,setFilter=function()end}
end
local hashes={}
local function hash(bytes)
 hashes[bytes]=hashes[bytes]or(string.rep(('%x'):format((#bytes%15)+1),64))
 return hashes[bytes]
end
local mod={id='autobike_plus_firered_beta',cache=cache,exports={}}
local api=Local.init(mod,{Runtime=Runtime,Json=Json,sourceFromBytes=sourceFromBytes,hash=hash})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local bytes='ID3'..string.rep('A',29)
local row,msg=api.importBytes(bytes,'My_Bike Song.mp3')
ck(row and msg=='IMPORTED','valid MP3 fixture not imported')
ck(Local.valid(row.id)and row.name=='My Bike Song','id/name normalization failed')
ck(#api.files()==1 and api.files()[1].missing==false,'indexed file missing')
ck(store['music/local/tracks/'..row.id:sub(6)..'.mp3']==bytes,'copy not kept in isolated local cache')
for path in pairs(store)do ck(path:sub(1,12)=='music/local/','local library escaped beta music/local namespace')end
local selected,err=api.resolve(row.id);ck(selected and selected.kind=='file'and not err,'local resolve failed')
local src;src,err=selected.openSource();ck(src and not err,'local source decode failed')
if src and src.release then src:release()end
local duplicate,why=api.importBytes(bytes,'Other Name.mp3');ck(duplicate and duplicate.id==row.id and why=='ALREADY IMPORTED','duplicate import handling failed')
ck(#api.files()==1,'duplicate added a second row')
ck(api.rename(row.id,'Road Theme.ogg')==true and api.describe(row.id)=='ROAD THEME','rename failed')
local path='music/local/tracks/'..row.id:sub(6)..'.mp3';store[path]=bytes..'X'
local bad,badErr=api.openSource(row.id);ck(not bad and badErr:find('damaged',1,true),'integrity check did not reject changed payload')
store[path]=bytes
ck(api.remove(row.id)==true and#api.files()==0 and store[path]==nil,'remove did not clear index/copy')
local invalid,invalidErr=api.importBytes('not audio bytes at all','thing.txt');ck(not invalid and invalidErr:find('MP3',1,true),'invalid format accepted')
Runtime.safeMode=true;local safe,safeErr=api.importBytes(bytes,'again.mp3');ck(not safe and safeErr:find('Safe mode',1,true),'safe mode did not block import')
ck(mod.exports.gen3LocalSongs==api,'diagnostic export missing')
ck(released>=2,'decoder validation/source lifecycle was not exercised')
print('PASS '..n..' isolated FireRed local-audio library assertions.')
