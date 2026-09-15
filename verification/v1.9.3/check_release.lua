-- Actual Sandbox/LegacyCompat, scoped cache, native import reader and Library.
-- The OS picker, filesystem and decoder in this suite are software doubles.
local T=dofile('verification/v1.9.0/support.lua').init(assert(arg[1]))
local Runtime=T.Runtime;local Cache=T.Cache;local Json=require('src.link.Json')
local Platform=require('src.core.Platform')
local n=0;local function check(v,m)assert(v,m);n=n+1 end
local legacy='picked_required_import.bin'
local data='RIFF0000WAVE'..string.rep('audio',100)
local md5=string.rep('a',32)
local baseHash=love.data.hash
love.data.hash=function(alg,bytes)
 if alg=='md5' then return string.rep(string.char(0xaa),16) end
 return baseHash(alg,bytes)
end
local protected={'save.lua','options.lua','picked_rom.gb','picked_save.sav','picked_mod.zip','mods/other/baseroms/keep.bin','original-audio.mp3'}
local function setup(osname,existing)
 for k in pairs(T.files)do T.files[k]=nil end
 for _,p in ipairs(protected)do T.files[p]='KEEP:'..p end
 Runtime.safeMode=false;Runtime.install(require('src.mods.Events').new(),require('src.mods.Hooks').new())
 local path
 love.system={getOS=function()return osname end,pickFileKinds=function()return'required_import,rom,mod,sav'end,
  pickFile=function(kind,dest)check(kind=='required_import','must never request ROM picker');path=dest;return true end}
 Platform._resetForTests()
 local mod=T.mod({data={}})
 local L=T.load(mod,'song_library').init(mod)
 if existing then mod.cache:write('music/picker.json',Json.encode(existing)) end
 local P=T.load(mod,'import_picker').init(mod,L);L.attachPicker(P)
 return mod,L,P,function()return path end
end
local function marker(path,bytes,checksum)
 return 'v1\n'..path..'\n'..(checksum or md5)..'\n'..#bytes..'\n'
end
local function preserve()
 for _,p in ipairs(protected)do check(T.files[p]=='KEEP:'..p,'protected file changed: '..p)end
end
for _,osname in ipairs({'Android','iOS'})do
 for _,delivery in ipairs({'direct','direct-no-marker','legacy'})do
  local mod,L,P,path=setup(osname);check(P.choose()=='pending','picker did not start')
  local dest=delivery=='legacy'and legacy or path()
  T.files[dest]=data
  if delivery=='direct'then T.files['pick_complete.flag']=marker(dest,data)end
  local row,err=P.poll(.3)
  if delivery~='direct'then check(not row and L.pending,'markerless copy must stabilise');row,err=P.poll(.3)end
  check(row,'import failed: '..tostring(err));check(not P.request and not L.pending,'pending not cleared')
  check(#L.files()==1,'song missing');check(L.openSource(row.id)~=nil,'saved song cannot open')
  check(not T.files[dest],'staging not cleaned')
  local nextL=T.load(mod,'song_library').init(mod);check(#nextL.files()==1,'library not persistent')
  preserve()
 end
 local mod,L,P,path=setup(osname);P.choose();T.files[path()..'.part']=data
 for i=1,3 do check(not P.poll(.4),'partial decoded')end
 T.files[path()]=data;check(not P.poll(.3),'part + final decoded')
 T.files[path()..'.part']=nil;P.poll(.3);T.files[path()]=data..'X';check(not P.poll(.3),'changing file imported')
 check(P.poll(.3),'stable file did not import');preserve()
 -- Checksum/count failure must not publish a song or leave pending true.
 for _,bad in ipairs({'digest','count','decoder'})do
  mod,L,P,path=setup(osname);P.choose();T.files[path()]=bad=='decoder'and(data..'CORRUPT')or data
  T.files['pick_complete.flag']=marker(path(),T.files[path()],bad=='digest'and string.rep('b',32)or nil)
  if bad=='count'then T.files['pick_complete.flag']=marker(path(),data..'X')end
  local row,err=P.poll(.3);check(not row and type(err)=='string','invalid import accepted: '..bad)
  check(not L.pending and #L.files()==0,'failure did not clear request');preserve()
 end
 -- Retry, timeout, stale signals, recovery of v1.9.2 persisted pending state.
 mod,L,P,path=setup(osname);P.choose();local prior=path();P.poll(1.1);P.choose();check(path()~=prior,'no-callback retry stuck')
 T.files['pick_complete.flag']='v1\nmods/other/baseroms/keep.bin\n'..md5..'\n10\n'
 T.files['pick_error.flag']='cancelled:mods/other/baseroms/keep.bin'
 local otherError=T.files['pick_error.flag'];local otherMarker=T.files['pick_complete.flag']
 T.files[path()]=data;P.poll(.3);check(P.poll(.3),'unrelated marker blocked complete file')
 check(T.files['pick_error.flag']==otherError and T.files['pick_complete.flag']==otherMarker,'unrelated marker removed');preserve()
 mod,L,P,path=setup(osname);P.choose();T.files['pick_error.flag']='cancelled:'..path()
 local row,err=P.poll(.2);check(not row and err=='IMPORT CANCELLED'and not L.pending,'cancel flag failed')
 P.choose();for i=1,121 do row,err=P.poll(1)end
 check(not L.pending and err and err:find('NO FILE RETURNED'),'silent picker timeout failed');preserve()
 mod,L,P=setup(osname,{file='autobike_audio_100_1_123456.bin'})
 T.files[legacy]=data;P.poll(.3);check(P.poll(.3),'old pending record not recovered');preserve()
 mod,L,P,path=setup(osname);T.files[legacy]='UNRELATED STAGED DEPENDENCY'
 check(not P.choose() and T.files[legacy]=='UNRELATED STAGED DEPENDENCY','preexisting legacy stage consumed')
 T.files[legacy]=nil;Runtime.safeMode=true;check(not P.choose(),'safe-mode picker opened');check(not P.poll(.5),'safe-mode import')
 Runtime.safeMode=false;preserve()
end
-- Desktop file dialogs remain the actual engine implementation; only the
-- external dialog process is simulated. The selected local file is read.
package.loaded['src.core.FilePicker']=nil
local FilePicker=require('src.core.FilePicker');local Host=require('src.core.HostShell')
local hostPath=os.tmpname()..'.wav';local f=assert(io.open(hostPath,'wb'));f:write(data);f:close()
Host.popen=function()return{read=function()return hostPath end}end
Host.pclose=function()end;Host.pumpHostEvents=function()end
for _,osname in ipairs({'Windows','OS X','Linux'})do
 local mod,L,P=setup(osname)
 love.system={getOS=function()return osname end};Platform._resetForTests()
 local row,err=P.choose();check(type(row)=='table','desktop import: '..tostring(err))
 check(L.openSource(row.id)~=nil,'desktop result did not reopen');preserve()
end
os.remove(hostPath)
for _,osname in ipairs({'NX','UWP','Unknown'})do
 local mod,L,P=setup(osname)
 love.system={getOS=function()return osname end};Platform._resetForTests()
 check(P.choose()=='browser','picker-less fallback lost')
end
local mod,L,P=setup('Android');local forbidden=false
love.system={getOS=function()return'Android'end,pickFile=function()forbidden=true;return true end}
Platform._resetForTests();check(not P.choose()and not forbidden,'unsafe ROM fallback allowed')
print(('PASS %d completion/retry/recovery/storage/desktop routing checks with native sandbox/import reader. OS dialogs/delivery and decoder are simulated.'):format(n))
