local Legacy=dofile('gen3_lab/legacy_songs.lua')
local function ck(v,m)assert(v,m)end
local files={}
local modCache={}
function modCache:read(path)return files[path]end
function modCache:write(path,bytes)files[path]=bytes;return true end
local programs=string.rep('P',16384)
local metadata='fixture-audio'
local Cache={}
function Cache.existsAt(path)return path=='red/data/generated/audio.lua'end
function Cache.readAt(path)
 if path=='red/data/generated/audio.lua'then return metadata end
 if path=='red/assets/generated/audio/programs.bin'then return programs end
end
local Version={cachePrefix=function(edition)return edition..'/'end}
local decodeCalls=0
local function decode(bytes)
 decodeCalls=decodeCalls+1;ck(bytes==metadata,'unexpected metadata bytes')
 return{programFile='assets/generated/audio/programs.bin',bankOrder={1},songs={
  Music_Bicycle={chip=true},Music_Route1={bank=1,address=1234},Music_Nothing={chip=true},
 }}
end
local function hash(bytes)return'h'..#bytes..'-'..bytes:sub(1,1)end
local mod={id='autobike_plus_firered_beta',cache=modCache,exports={}}
local api=Legacy.init(mod,{Cache=Cache,Version=Version,decode=decode,hash=hash})
local editions=api.editions();ck(#editions==6 and editions[1].id=='red'and editions[1].available,'Red import not detected')
ck(editions[2].id=='blue'and not editions[2].available,'Unavailable edition misreported')
local songs,err=api.gameSongs('red');ck(songs and not err and #songs==2,'Playable legacy songs not enumerated')
ck(songs[1].name=='BICYCLE'and songs[2].name=='ROUTE1','Legacy song labels/order incorrect')
local chosen=assert(api.resolve('game:red:Music_Route1'))
ck(chosen.kind=='chip'and chosen.edition=='red'and chosen.label=='Music_Route1','Legacy selection did not resolve')
ck(chosen.data.audio.programFile=='mod_cache/autobike_plus_firered_beta/music/cache/red-h16384-P.bin','Program path is not beta-isolated')
ck(files['music/cache/red-h16384-P.bin']==programs,'Program cache was not copied to beta storage')
ck(api.describe('game:red:Music_Route1')=='RED: ROUTE1','Legacy description incorrect')
local again=assert(api.resolve('game:red:Music_Bicycle'));ck(decodeCalls==1,'Edition cache should be reused')
ck(again.data==chosen.data,'Resolved songs should share immutable edition data')
local missing,msg=api.resolve('game:emerald:Music_Route1');ck(not missing and msg,'Unsupported edition must fail closed')
ck(mod.exports.gen3LegacySongs==api,'Diagnostic export missing')
print('PASS isolated imported Gen1/2 song source bridge')
