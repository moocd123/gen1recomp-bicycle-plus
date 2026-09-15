local T=dofile('verification/v1.8.0/test_support.lua').init(assert(arg[1]))
local L=dofile('song_library.lua');local lib=L.init({})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
for _,id in ipairs({'original','game:red:Music_PalletTown','game:crystal:Music_Bicycle','file:'..string.rep('a',64)})do ck(L.valid(id),'valid ID')end
for _,id in ipairs({'../save.lua','file:AAA','game:green:Music_Test','game:red:../../secret','file:'..string.rep('a',65)})do ck(not L.valid(id),'invalid ID')end
local wav='RIFF1234WAVE'..string.rep('tone',200)
local row,err=lib.importBytes(wav,'My Song.wav');ck(row,err);ck(row.name=='My Song','filename label')
ck(#lib.files()==1,'first import');ck(lib.resolve(row.id,{}).def.file==row.path,'resolve path')
ck(lib.importBytes(wav,'Second Name.wav').id==row.id and #lib.files()==1,'deduplicated import')
local other=assert(lib.importBytes('ID3'..string.rep('music',300),'second.mp3'));ck(#lib.files()==2,'second import')
ck(lib.rename(row.id,'RENAME SUCCESS'),'rename');ck(lib.describe(row.id)=='RENAME SUCCESS','rename description')
local before=T.files[row.path]
ck(not lib.importBytes('CORRUPT FILE DATA','x.mp3'),'invalid decode rejected')
ck(T.files[row.path]==before and #lib.files()==2,'bad input did not damage library')
ck(not lib.importBytes('not audio data here','x.bin'),'invalid extension/magic rejected')
ck(not lib.importBytes('ID3'..string.rep('x',L.MAX_BYTES),'x.mp3'),'size bounded')
local relaunch=L.init({});ck(#relaunch.files()==2 and relaunch.describe(row.id)=='RENAME SUCCESS','library survives new instance')
-- An interrupted latest index write must leave the previous valid slot available.
T.files[L.ROOT..'/index-a.json']='{bad';local repaired=L.init({});ck(#repaired.files()>=1,'index fallback')
T.Runtime.safeMode=true;ck(not lib.rename(row.id,'NO') and not lib.remove(row.id) and not lib.importBytes(wav,'no.wav'),'safe mode writes denied');T.Runtime.safeMode=false
ck(lib.remove(other.id),'remove');ck(T.files[other.path]==nil,'only library copy removed')
T.files[row.path]=nil;ck(not lib.resolve(row.id,{}),'missing file fallback');ck(lib.importBytes(wav,'repair.wav'),'reimport repairs missing copy')
-- Native mobile import uses its own basename and never claims ROM/save paths.
local calls={}
love.system.pickFileKinds=function()return'rom,mod,sav,required_import'end
love.system.pickFile=function(k,p)calls={k,p};return true end
ck(lib.chooseFile()=='pending','picker starts');ck(calls[1]=='required_import'and calls[2]==L.PENDING,'private native destination')
T.files[L.PENDING]='ID3'..string.rep('new',200)
T.files['pick_complete.flag']='v1\n'..L.PENDING..'\n'..string.rep('a',32)..'\n603\n'
local imported=lib.poll();ck(imported and not lib.pending,'picker completed');ck(not T.files[L.PENDING],'own staging consumed')
ck(lib.chooseFile()=='pending','second picker');T.files['pick_error.flag']='cancelled:'..L.PENDING
local result,message=lib.poll();ck(not result and message=='IMPORT CANCELLED','cancel handled');ck(T.files['pick_error.flag']==nil,'own error consumed')
ck(lib.chooseFile()=='pending','third picker');T.files['pick_error.flag']='picked_rom.gb'
lib.poll();ck(lib.pending and T.files['pick_error.flag']=='picked_rom.gb','unrelated bridge flag preserved')
lib.cancelPick()
-- Current metadata remains the live modded registry; foreign programs get unique keys.
local V=require('src.core.GameVersion');V.set('red')
local g={data={audio={songs={Music_Example={bank=2,address=16384}},programFile='assets/generated/audio/programs.bin'}}}
ck(lib.gameData('red',g)==g.data,'active data not replaced');ck(lib.gameSongs('red',g)[1].id=='game:red:Music_Example','current songs')
local Writer=require('src.import.LuaWriter')
T.files['blue/data/generated/audio.lua']=Writer.encode({songs={Music_Blue={bank=2,address=16384}},bankOrder={2},programFile='assets/generated/audio/programs.bin'})
T.files['blue/assets/generated/audio/programs.bin']=string.rep('\0',16384)
local foreign=assert(lib.gameData('blue',g));ck(foreign.audio.programFile~=g.data.audio.programFile,'distinct program cache key');ck(V.get()=='red','active edition not changed')
ck(lib.gameSongs('blue',g)[1].name=='BLUE','song labels');ck(lib.resolve('game:blue:Music_Blue',g).data==foreign,'foreign resolution')
ck(not lib.gameData('crystal',g),'missing imported game not loaded')
T.files['gold/data/generated/audio.lua']='return (function() while true do end end)()';ck(not lib.gameData('gold',g),'executable metadata rejected')
T.files['silver/data/generated/audio.lua']=Writer.encode({songs={},bankOrder={2},programFile='../../save.lua'});ck(not lib.gameData('silver',g),'program traversal rejected')
print(('PASS %d music-library checks: import/dedup/storage/validation/mobile contract/foreign cache isolation.'):format(n))
