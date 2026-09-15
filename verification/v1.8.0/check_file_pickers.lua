-- Platform adapters use the actual engine FilePicker; dialogs/devices are mocked.
local engine=assert(arg[1]);local T=dofile('verification/v1.8.0/test_support.lua').init(engine)
local L=dofile('song_library.lua');local lib=L.init({})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local nativeFile=engine..'/src/core/FilePicker.lua'
local calls={};local osName='Windows';local outputs={};local commands={}
love.system.getOS=function()return osName end
package.loaded['src.core.Platform']={canSpawnProcess=function()return osName=='Windows'or osName=='OS X'or osName=='Linux'end}
package.loaded['src.core.HostShell']={popen=function(command)
 commands[#commands+1]=command
 local text=table.remove(outputs,1)
 if not text then return nil end
 return {read=function()return text end}
end,pclose=function()end,pumpHostEvents=function()end}
local function picker()package.loaded['src.core.FilePicker']=assert(loadfile(nativeFile))()end
local oldPath=lib.importPath
lib.importPath=function(p)calls[#calls+1]=p;return {id='file:'..string.rep('1',64),name=p}end
for _,spec in ipairs({{'Windows','System.Windows.Forms.OpenFileDialog','C:\\Temp\\Music Test.mp3'},
 {'OS X','osascript','/Users/test/Music/song.ogg'}, {'Linux','zenity','/home/test/Music/test.flac'}}) do
 osName=spec[1];picker();commands={};outputs={spec[3]..'\n'}
 local r=lib.chooseFile();ck(type(r)=='table'and r.name==spec[3],osName..' selected path')
 ck(commands[1]:find(spec[2],1,true),osName..' native platform adapter')
 ck(commands[1]:find('mp3',1,true)and commands[1]:find('wav',1,true)and commands[1]:find('flac',1,true),'audio filter types')
end
osName='Linux';picker();commands={};outputs={'','/home/test/second.ogg\n'}
ck(lib.chooseFile().name=='/home/test/second.ogg'and commands[2]:find('kdialog',1,true),'Linux fallback dialog')
for _,os in ipairs({'Windows','OS X','Linux','NX','UWP','Unknown','iOS','Android'})do
 osName=os;picker();commands={};outputs={};love.system.pickFileKinds=nil;love.system.pickFile=nil
 ck(lib.chooseFile()=='browser','portable browser fallback '..os)
 if os~='Windows'and os~='OS X'and os~='Linux'then ck(#commands==0,'shell invoked on non-desktop')end
end
lib.importPath=oldPath
for _,os in ipairs({'Android','iOS','UWP'})do
 osName=os;picker();local selected
 love.system.pickFileKinds=function()return'rom,mod,sav,required_import'end
 love.system.pickFile=function(k,path)selected={k,path};return true end
 ck(lib.chooseFile()=='pending','native picker branch '..os)
 ck(selected[1]=='required_import'and selected[2]==L.PENDING,'wrong native destination '..os)
 T.files[L.PENDING]='RIFF1234WAVE'..string.rep(os,40)
 T.files['pick_complete.flag']='v1\n'..L.PENDING..'\nmd5\n'..#T.files[L.PENDING]..'\n'
 local row=lib.poll();ck(row~=nil,'native import completion '..os)
 ck(row.path:find(L.ROOT..'/tracks/',1,true)==1,'audio stored in install directory')
 ck(T.files['picked_rom.gb']==nil and T.files['picked_save.sav']==nil and T.files['picked_mod.zip']==nil,'standard staging affected')
end
osName='Android';picker();local attempted=false
love.system.pickFileKinds=function()return'rom,mod,sav'end
love.system.pickFile=function()attempted=true;return true end
ck(lib.chooseFile()=='browser'and not attempted,'unsupported bridge called blindly')
love.system.pickFileKinds=function()error('no function')end
ck(lib.chooseFile()=='browser','throwing bridge not handled')
love.system.pickFileKinds=function()return'required_import'end
love.system.pickFile=function()return false end
ck(lib.chooseFile()=='browser','refused native picker not handled')
-- Browser is bounded to the dedicated inbox, preserves filename case/subfolders.
local root=L.ROOT..'/inbox';T.dirs[root..'/Album']=true
T.files[root..'/Album/MySong.WAV']='RIFF1234WAVE'..string.rep('wave',90)
T.files[root..'/z.ogg']='OggS'..string.rep('ogg',90)
T.files[root..'/private.txt']='ignored'
local rows=lib.inbox();ck(#rows==2 and rows[1].directory and rows[1].name=='Album','browser folders first')
rows=lib.inbox('Album');ck(#rows==1 and rows[1].relative=='Album/MySong.WAV','nested audio file')
ck(lib.importInbox('Album/MySong.WAV'),'nested file import')
for _,p in ipairs({'../save.lua','Album/../../save.lua','/secret.wav','a\\b.wav','a//b.wav','a/./b.wav','a:/b.wav','a\0b.wav'})do
 ck(not lib.importInbox(p),'inbox traversal accepted: '..p)
end
local clipboard,uri
love.system.setClipboardText=function(text)clipboard=text end
love.system.openURL=function(url)uri=url;return true end
ck(lib.copyInboxPath()and clipboard:find(root,1,true),'runtime path copy')
ck(lib.openInboxFolder()and uri:find('file:///',1,true)==1,'runtime folder opener')
T.Runtime.safeMode=true;ck(not lib.openInboxFolder(),'safe mode directory write');T.Runtime.safeMode=false
-- Imported originals and old source files are never deleted by an update/delete.
local sample='RIFF1234WAVE'..string.rep('disk',45);T.files['dropped.wav']=sample
local row=lib.importFile(T.fs.newFile('dropped.wav'));ck(row~=nil,'dropped file was not opened')
ck(T.files['dropped.wav']==sample,'source file changed')
local bad={getSize=function()return 12 end,isOpen=function()return false end,open=function()return false end,
 read=function()error('should never read')end,getFilename=function()return'bad.wav'end}
ck(not lib.importFile(bad),'failed file-open accepted')
print(('PASS %d cross-platform file-picker/browser checks; actual desktop adapters, simulated OS/native-dialog/filesystem boundaries.'):format(n))
