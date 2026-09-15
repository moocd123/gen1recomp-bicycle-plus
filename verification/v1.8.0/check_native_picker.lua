local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
package.preload.bit=function()return bit32 end
local T=dofile('verification/v1.8.0/support.lua');T.install()
for k,v in pairs(T.fs())do love.filesystem[k]=v end
package.loaded['src.core.SaveData'].isPortable=function()return false end
package.loaded['src.core.SaveData'].portableBaseDir=function()return false end
local outputs={};local commands={}
package.loaded['src.core.HostShell']={popen=function(cmd)
 commands[#commands+1]=cmd
 return{read=function()return outputs[#commands]or''end}
 end,pclose=function()end,pumpHostEvents=function()end}
local P=require('src.core.Platform');local F=require('src.core.FilePicker');local Import=dofile('song_import.lua')
local m=T.mod();local L={importBytes=function(b,n)return'file:'..string.rep('a',64)end}
for _,osname in ipairs({'Windows','OS X','Linux'})do
 T.os=osname;love.system.pickFile=nil;P._resetForTests();commands={};outputs={'/tmp/music.wav'}
 local value=F.open('Choose bicycle music',{label='Audio',exts={'mp3','ogg','wav'}})
 T.eq(value,'/tmp/music.wav');T.check(commands[1]:find(osname=='Windows'and'OpenFileDialog'or osname=='OS X'and'choose file'or'zenity',1,true),'wrong native desktop command')
 T.check(commands[1]:find('mp3',1,true)and commands[1]:find('wav',1,true),'audio filter lost')
end
-- Linux kdialog fallback is the engine's actual implementation.
commands={};outputs={'','/tmp/fallback.ogg'};T.eq(F.open('Music',{label='Audio',exts={'ogg'}}),'/tmp/fallback.ogg');T.check(commands[2]:find('kdialog',1,true),'missing Linux fallback')
for _,osname in ipairs({'Android','iOS'})do
 T.os=osname;love.system.pickFileKinds=function()return'rom,mod,sav,required_import'end
 local got
 love.system.pickFile=function(kind,path)got={kind,path};return true end
 P._resetForTests()
 local I=Import.init(m,L);local ok,why=I.start();T.check(ok,why)
 T.eq(got[1],'required_import','wrong picker kind');T.eq(got[2],I.staging,'wrong scoped staging destination');T.check(got[2]:match('^mods/bicycle_plus/baseroms/bicycle_personal_audio_%d+_%d+%.bin$'),'unsafe staging name')
 T.check(I.pending,'native request not pending')
 I.cancel()
end
-- Actual chooser's not-available response is handled, rather than calling nil.
T.os='iOS';love.system.pickFile=function()return false end;P._resetForTests()
local I=Import.init(m,L);T.check(not I.start(),'native refusal hidden')
print(('PASS %d actual engine FilePicker/RomImporter adapter checks; native OS dialogs replaced by boundary doubles.'):format(T.count))
