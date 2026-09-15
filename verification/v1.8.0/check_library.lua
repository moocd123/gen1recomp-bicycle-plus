local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
local T=dofile('verification/v1.8.0/support.lua');local R=T.install();local m=T.mod()
local Songs=dofile('bike_songs.lua');local L=Songs.init(m,{})
for _,bad in ipairs({'../../x','file:xx','game:evil:A','game:red:../x','file:'..string.rep('f',65)})do T.check(not Songs.canonical(bad),'unsafe song ID')end
local wav='RIFFxxxxWAVE'..string.rep('x',90)
local id=assert(L.importBytes(wav,'Example song.wav'));T.check(id:match('^file:'),'import did not register')
T.eq(#L.myAudio(),1);T.eq(L.title(id),'EXAMPLE SONG')
T.eq(L.importBytes(wav,'different.wav'),id,'duplicate not detected');T.eq(#L.myAudio(),1)
T.check(not L.importBytes('not audio','bad'),'bad magic accepted')
T.check(not L.importBytes('RIFFxxxxWAVEBADxx','bad'),'bad codec accepted')
T.check(not L.importBytes('RIFFxxxxWAVE'..string.rep('x',Songs.MAX_BYTES),'huge'),'large input accepted')
T.check(L.rename(id,'New name'));T.eq(L.title(id),'NEW NAME')
local data=L.resolve({},id);T.check(data.def.file.bytes==wav,'stored file bytes changed')
local L2=Songs.init(m,{});T.eq(L2.title(id),'NEW NAME','library lost across sessions')
-- Library is installation-scoped and independent from mod-code replacement.
T.files['mods/bicycle_plus/main.lua']='new version';T.eq(L2.resolve({},id).def.file.bytes,wav)
local GV=require('src.core.GameVersion');GV.set('red')
local game={data={audio={songs={Music_PalletTown={file='area.ogg'},Music_BikeRiding={file='bike.ogg'}}}}}
local list=L.gameList(game,'current');T.eq(#list,2);T.check(list[1].id:match('^game:red:'),'current choice not pinned to game')
local before=GV.get();local donor={generation=2,songs={Music_TitleScreen={bank=7,address=16400}},programFile='assets/generated/audio/programs.bin',bankOrder={7},waveBanks={},drumkits={}}
m.datasets={open=function(_,v)
 if v~='gold'then return nil,'not imported'end
 return{content={audio={get=function(_,k)return donor[k]end}},assets={info=function()return{size=16384}end,path=function(_,p)return'gold/'..p end}}
end}
local tracks=L.gameList(game,'gold');T.eq(#tracks,1)
local g=assert(L.resolve(game,'game:gold:Music_TitleScreen'));T.eq(g.data.audio.programFile,'gold/assets/generated/audio/programs.bin')
T.eq(GV.get(),before,'cross-game browse changed active game')
T.check(not L.resolve(game,'game:blue:Music_PalletTown'),'unimported donor allowed')
T.check(not L.resolve(game,'game:red:Music_Absent'),'missing label accepted')
R.safeMode=true;T.check(not L.importBytes(wav..'x','next'),'safe-mode import');T.check(not L.rename(id,'bad'),'safe-mode rename');R.safeMode=false
T.check(L.remove(id));T.eq(#L.myAudio(),0);T.check(not L.resolve(game,id),'removed file still resolves')
T.check(T.files['mod_cache/bicycle_plus/music/'..id:sub(6)..'.wav']==nil,'library copy not removed')
T.files['mod_cache/bicycle_plus/music/library.json']='broken';T.files['mod_cache/bicycle_plus/music/library.bak']='broken'
local L3=Songs.init(m,{});T.check(not L3.importBytes(wav,'should fail'),'corrupt metadata overwritten')
print(('PASS %d library/path/duplicate/metadata/donor/session assertions (codec and filesystem doubles).'):format(T.count))
