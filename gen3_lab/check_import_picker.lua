local T=dofile('verification/v1.9.0/support.lua').init(assert(arg[1]))
package.loaded['src.core.FilePicker']=nil
local Platform=require('src.core.Platform')
local Host=require('src.core.HostShell')
local game={save={options={}}}
local mod=T.mod(game)
-- Rebind the harness itself to the isolated beta identity. T.mod() creates a
-- stable-mod sandbox, so mutating only mod.id/path would test the wrong scope.
mod.id='autobike_plus_firered_beta';mod.path='mods/autobike_plus_firered_beta'
mod.manifest={id=mod.id,path=mod.path,optional_imports={}}
local compat=require('src.mods.LegacyCompat').new({modId=mod.id,modPath=mod.path,fs=T.fs,game=function()return game end})
mod.env=require('src.mods.Sandbox').envFor({modId=mod.id,permissions={engine_internals=true},compat=compat})
local _,cache=require('src.mods.ImportAccess').new(mod.manifest,T.fs);mod.cache=cache
local function fakeHash(bytes)
 local n=0;for i=1,#bytes do n=(n+bytes:byte(i)*i)%256 end
 return string.rep(('%02x'):format(n),32)
end
local Local=T.load(mod,'gen3_lab/local_songs');local library=Local.init(mod,{hash=fakeHash})
local Pick=T.load(mod,'import_picker');local picker=Pick.init(mod,library)
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local bytes='RIFF0000WAVE'..string.rep('selected-audio',90)
local path=os.tmpname()..'.wav';local f=assert(io.open(path,'wb'));f:write(bytes);f:close()
local command
Host.popen=function(c)command=c;return{read=function()return path end}end
Host.pclose=function()end;Host.pumpHostEvents=function()end
love.system={getOS=function()return'Windows'end};Platform._resetForTests()
local row,err=picker.choose();ck(row and type(row)=='table','desktop picker failed '..tostring(err))
ck(command and command:find('OpenFileDialog',1,true),'desktop route did not use native chooser')
ck(assert(library.openSource(row.id)).dataBytes==bytes,'desktop selected bytes changed')
os.remove(path)
local destination
love.system={getOS=function()return'Android'end,pickFileKinds=function()return'rom,mod,sav,required_import'end,
 pickFile=function(kind,dest)ck(kind=='required_import','wrong Android picker kind');destination=dest;return true end}
Platform._resetForTests()
local result;result,err=picker.choose();ck(result=='pending','Android picker did not become pending: '..tostring(err))
ck(destination and destination:match('^mods/autobike_plus_firered_beta/baseroms/autobike_audio_'),'beta picker escaped isolated staging path')
local mobileBytes=bytes..'mobile';T.files[destination]=mobileBytes
local first=picker.poll(0.1);ck(first==nil,'markerless native result should settle before import')
local mobile;mobile,err=picker.poll(0.3);ck(type(mobile)=='table','Android pending result failed '..tostring(err))
ck(not library.pending and not T.files[destination],'native staging cleanup failed')
ck(assert(library.openSource(mobile.id)).dataBytes==mobileBytes,'mobile selected bytes changed')
for _,osName in ipairs({'NX','UWP','Unknown'})do
 love.system={getOS=function()return osName end};Platform._resetForTests()
 ck(picker.choose()=='browser','picker-less build must use in-app browser')
end
print(('PASS %d FireRed beta desktop/native picker isolation, pending polling and browser fallback assertions; OS dialogs are simulated.'):format(n))
