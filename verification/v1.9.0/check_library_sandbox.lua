local T=dofile('verification/v1.9.0/support.lua').init(assert(arg[1]))
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local mod=T.mod({save={options={}}})
local L=T.load(mod,'song_library');local library=L.init(mod)
local bytes='RIFF0000WAVE'..string.rep('audiodata',100)
local protected={'save.lua','save_blue.lua','options.lua','picked_rom.gb','picked_save.sav','mods/other/code.lua'}
for _,p in ipairs(protected)do T.files[p]='DO NOT CHANGE'end
-- Reproduce the real v1.8 mismatch: compat writes are NOT native audio paths.
local old='mod_data/bicycle_plus/music/example.wav'
mod.env.love.filesystem.write(old,bytes)
ck(not T.files[old],'compat alias unexpectedly exists in native filesystem')
ck(T.files['mod_compat/bicycle_plus/'..old]==bytes,'legacy overlay not reproduced')
ck(not pcall(love.audio.newSource,old,'stream'),'old decoder path should fail')
local row=assert(library.importBytes(bytes,'A very long imported file name for a scrolling single line.wav'))
ck(T.files[row.path]==bytes,'scoped cache not at native path')
local source=assert(library.resolve(row.id,{})).openSource()
ck(source and source.dataBytes==bytes,'sandbox local playback cannot read its stored bytes')
-- Portable providers may report existence/type but omit a size field.
local nativeInfo=mod.cache.info
mod.cache.info=function(self,path)local i=nativeInfo(self,path);if i then i.size=nil end;return i end
ck(assert(library.openSource(row.id)).dataBytes==bytes,'cache without stat size failed')
mod.cache.info=nativeInfo
local reloaded=L.init(mod);ck(#reloaded.files()==1,'library persistence')
ck(assert(reloaded.openSource(row.id)).dataBytes==bytes,'cold library playback')
assert(reloaded.rename(row.id,'RENAMED'));ck(reloaded.files()[1].name=='RENAMED','rename failed')
local duplicate=assert(reloaded.importBytes(bytes,'other.wav'));ck(duplicate.id==row.id and #reloaded.files()==1,'duplicates not merged')
-- Legacy v1.8 index/track migration is read-only and uses the same IDs.
local legacyBytes='RIFF0000WAVE'..string.rep('older',80);local digest=L.hash(legacyBytes)
local id='file:'..digest
local Json=require('src.link.Json')
mod.env.love.filesystem.write('mod_data/bicycle_plus/music/tracks/'..digest..'.wav',legacyBytes)
mod.env.love.filesystem.write('mod_data/bicycle_plus/music/index-a.json',Json.encode({format=1,seq=99,tracks={{id=id,ext='wav',name='OLDER SONG'}}}))
T.files['mod_cache/bicycle_plus/music/index-a.json']=nil;T.files['mod_cache/bicycle_plus/music/index-b.json']=nil
local older=L.init(mod);ck(assert(older.openSource(id)).dataBytes==legacyBytes,'legacy import unrecoverable')
assert(older.rename(id,'RECOVERED'));ck(T.files['mod_cache/bicycle_plus/music/index-b.json']~=nil,'index did not migrate')
assert(older.remove(id));ck(#older.files()==0,'remove failed')
ck(mod.env.love.filesystem.read('mod_data/bicycle_plus/music/tracks/'..digest..'.wav')==legacyBytes,'legacy source removed during migration')
-- Foreign sound programs go into a REAL scoped cache, never a compat alias.
local meta='return { programFile="assets/generated/audio/programs.bin",bankOrder={1},songs={Music_Bicycle={bank=1,address=16384}} }'
T.files['gold/data/generated/audio.lua']=meta
T.files['gold/assets/generated/audio/programs.bin']=string.rep('A',16384)
local foreign=assert(library.gameData('gold',{data={audio={}}}))
ck(T.files[foreign.audio.programFile]==string.rep('A',16384),'native synth cannot see foreign bank copy')
local synth=require('src.core.ChipSynth');synth.invalidateBanks()
ck(synth._loadBanksForTest(foreign)[1]==string.rep('A',16384),'real synth read differs from cache bytes')
ck(require('src.core.GameVersion').get()=='red','foreign audio switched active edition')
for _,p in ipairs(protected)do ck(T.files[p]=='DO NOT CHANGE','protected file mutated: '..p)end
T.Runtime.safeMode=true;ck(not library.importBytes(bytes,'no.wav'),'safe-mode write');ck(not library.remove(row.id),'safe-mode removal')
print(('PASS %d sandbox/compat/cache/playback-path/library/storage-isolation checks.'):format(n))
