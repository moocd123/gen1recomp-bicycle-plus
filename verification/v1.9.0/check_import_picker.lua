local T=dofile('verification/v1.9.0/support.lua').init(assert(arg[1]))
package.loaded['src.core.FilePicker']=nil
local Platform=require('src.core.Platform')
local FilePicker=require('src.core.FilePicker')
local Host=require('src.core.HostShell')
local mod=T.mod({save={options={}}})
local L=T.load(mod,'song_library');local library=L.init(mod)
local Pick=T.load(mod,'import_picker');local picker=Pick.init(mod,library);library.attachPicker(picker)
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local bytes='RIFF0000WAVE'..string.rep('selected-audio',90)
local path=os.tmpname()..'.wav';local f=assert(io.open(path,'wb'));f:write(bytes);f:close()
local command
Host.popen=function(c)command=c;return{read=function()return path end}end
Host.pclose=function()end;Host.pumpHostEvents=function()end
for _,osName in ipairs({'Windows','OS X','Linux'})do
 love.system={getOS=function()return osName end};Platform._resetForTests()
 local row,err=picker.choose();ck(row and type(row)=='table','native desktop reader failed '..osName..' '..tostring(err))
 ck(assert(library.openSource(row.id)).dataBytes==bytes,'selected file bytes changed')
 ck(command and (osName~='Windows' or command:find('OpenFileDialog',1,true)),'Windows native route')
end
os.remove(path)
for _,osName in ipairs({'Android','iOS'})do
 local calledKind,destination
 love.system={getOS=function()return osName end,pickFileKinds=function()return'rom,mod,sav,required_import'end,
   pickFile=function(k,d)calledKind=k;destination=d;return true end}
 Platform._resetForTests()
 ck(mod.env.love.system.pickFile==nil,'test must run with the native bridge hidden by sandbox')
 local result,err=picker.choose();ck(result=='pending','mobile choice failed '..tostring(err))
 ck(calledKind=='required_import'and destination:match('^mods/bicycle_plus/baseroms/autobike_audio_'),'unsafe native staging target')
 T.files[destination]=bytes;T.files['pick_complete.flag']='v1\n'..destination..'\n'..string.rep('0',32)..'\n'..#bytes..'\n'
 local row;row,err=picker.poll();ck(type(row)=='table','native completion failed '..tostring(err))
 ck(not library.pending and not T.files[destination],'staging cleanup failed')
 ck(assert(library.openSource(row.id)).dataBytes==bytes,'mobile data playback failed')
 -- Cancellation is not a ROM pick and does not touch unrelated picker flags.
 ck(picker.choose()=='pending','second mobile choice')
 T.files['pick_error.flag']='cancelled:'..destination
 local cancelled,why=picker.poll();ck(not cancelled and why=='IMPORT CANCELLED','native cancel not recognised')
end
-- Silent OS cancellation must not permanently lock the import action.
local dest
love.system={getOS=function()return'iOS'end,pickFileKinds=function()return'required_import'end,
 pickFile=function(_,d)dest=d;return true end}
Platform._resetForTests()
ck(picker.choose()=='pending','silent cancellation start')
local cancelledPath=dest;picker.cancel();ck(not picker.request and not library.pending,'cancel did not release foreground request')
ck(picker.choose()=='pending'and dest~=cancelledPath,'new import after silent cancellation blocked')
local freshPath=dest
T.files[cancelledPath]=bytes;T.files['pick_complete.flag']='v1\n'..cancelledPath..'\n0\n'..#bytes..'\n'
picker.poll();ck(not T.files[cancelledPath]and picker.request,'late cancelled callback consumed new request')
T.files[freshPath]=bytes;T.files['pick_complete.flag']='v1\n'..freshPath..'\n0\n'..#bytes..'\n'
ck(type(picker.poll())=='table','fresh callback after cancellation failed')
local nativeCalls=0
love.system={getOS=function()return'Android'end,pickFile=function()nativeCalls=nativeCalls+1;return true end}
Platform._resetForTests()
local r,e=picker.choose();ck(not r and nativeCalls==0,'legacy bridge fallback must not overwrite picked_rom.gb')
ck(tostring(e):find('newer native',1,true)~=nil,'missing capability error absent')
for _,osName in ipairs({'NX','UWP','Unknown'})do
 love.system={getOS=function()return osName end};Platform._resetForTests()
 ck(picker.choose()=='browser','picker-less build must open file browser directly')
end
print(('PASS %d actual engine desktop/native routing, sandbox separation, safe staging and fallback checks; OS dialogs are simulated.'):format(n))
