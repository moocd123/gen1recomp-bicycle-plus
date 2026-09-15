local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
package.preload.bit=package.preload.bit or function()return bit32 end
local T=dofile('verification/v1.8.0/support.lua');local R=T.install()
local Platform=require('src.core.Platform');local m=T.mod();local imported={}
local L={importBytes=function(bytes,name)imported[#imported+1]={bytes=bytes,name=name};return'file:'..string.rep('a',64)end}
local actual={}
-- Native/desktop boundary doubles. Routing through the actual adapter is under test.
local stage
package.loaded['src.core.FilePicker']={available=function()return Platform.canSpawnProcess()end,
 open=function(_,kind)actual.filters=kind.exts;return actual.chosenPath end,basename=function(p)return p:match('[^/\\]+$')end}
package.loaded['src.mods.RequiredImports']={path=function(manifest,spec)return manifest.path..'/baseroms/'..spec.file end,
 remove=function(manifest)T.files[manifest.path..'/baseroms/'..manifest.optional_imports[1].file]=nil;return true end}
package.loaded['src.import.RomImporter']={chooseRequiredImport=function(self,modId,importId)
 actual.native={mod=modId,id=importId,mobile=self.mobileFileBridge};actual.nativeCalls=(actual.nativeCalls or 0)+1
 if actual.refuse then self.requiredImportNotice={text='Native file picker unavailable.'}end
 end,_importRequiredSource=function(self,modId,importId,p,confirmed)
 actual.desktop={path=p,confirmed=confirmed};return self:_importRequiredData(modId,importId,'RIFFxxxxWAVEexample')
 end}
local Import=dofile('song_import.lua')
for _,osName in ipairs({'Windows','OS X','Linux','Android','iOS','NX','UWP','Unknown'})do
 T.os=osName;local mobile=osName=='Android'or osName=='iOS'
 love.system.pickFile=mobile and function()return true end or nil
 love.system.pickFileKinds=function()return 'rom,mod,sav,required_import'end
 Platform._resetForTests();actual.chosenPath='C:/Users/Someone/My song.ogg';actual.refuse=false
 local I=Import.init(m,L)
 local ok,err=I.start();stage=I.staging
 if mobile then
  T.check(ok and I.pending and actual.native.mobile,'native picker not selected '..osName)
  local bytes='RIFFxxxxWAVEexample';T.files[stage]=bytes
  local digest=love.data.hash('md5',bytes)
  -- Unrelated flags cannot be consumed by this mod.
  T.files['pick_complete.flag']='v1\nmods/another/baseroms/x.bin\n'..digest..'\n'..#bytes..'\n'
  I.poll(.3);T.check(I.pending and T.files['pick_complete.flag'],'unrelated import consumed')
  T.files['pick_complete.flag']='v1\n'..stage..'\n'..digest..'\n'..#bytes..'\n'
  I.poll(.3);T.check(I.result and not I.pending,'native completion not imported')
  T.check(not T.files[stage]and not T.files['pick_complete.flag'],'staging file leaked')
  I.start();stage=I.staging;I.cancel();T.files[stage]=bytes;T.files['pick_complete.flag']='v1\n'..stage..'\n'..digest..'\n'..#bytes..'\n'
  local n=#imported;I.poll(.3);T.eq(#imported,n,'cancelled request imported')
  I.start();local old=I.staging;I.cancel();I.start();stage=I.staging
  T.check(stage~=old,'staging path reused after cancellation')
  T.files[old]=bytes;T.files['pick_complete.flag']='v1\n'..old..'\n'..digest..'\n'..#bytes..'\n'
  I.poll(.3);T.eq(#imported,n,'abandoned receipt imported into new request')
  T.check(I.pending and not T.files[old],'new request lost or abandoned file retained')
  T.files[stage]=bytes;T.files['pick_complete.flag']='v1\n'..stage..'\n'..digest..'\n'..#bytes..'\n'
  I.poll(.3);T.eq(#imported,n+1,'new request cannot complete')
 elseif osName=='Windows'or osName=='OS X'or osName=='Linux'then
  T.check(ok and I.result and not I.pending,'desktop picker failed '..osName)
  T.check(actual.desktop.confirmed and actual.desktop.path==actual.chosenPath,'desktop size-checked reader bypassed')
  T.eq(actual.filters[1],'mp3');T.eq(imported[#imported].name,'My song.ogg')
  actual.chosenPath=nil;T.check(not I.start(),'desktop cancellation not respected')
 else
  T.check(not ok and I.mode=='inbox','pickerless platform lacks inbox fallback '..osName)
 end
 -- Explicit universal inbox selection stays under our mod and reads no other files.
 T.files['mods/bicycle_plus/baseroms/audio_inbox/song.wav']='RIFFxxxxWAVEexample'
 T.files['mods/bicycle_plus/baseroms/audio_inbox/no.txt']='not audio'
 T.files['mods/another/private.mp3']='not yours'
 local rows=I.inbox();T.eq(#rows,1);T.eq(rows[1].name,'song.wav')
 T.check(I.fromInbox('song.wav'),'inbox import failed '..osName)
 T.check(T.files['mods/bicycle_plus/baseroms/audio_inbox/song.wav'],'original inbox file deleted')
 T.check(not I.fromInbox('../../another/private.mp3'),'directory escape')
 R.safeMode=true;T.check(not I.start()and not I.fromInbox('song.wav'),'safe-mode write');R.safeMode=false
end
-- Native dialog refusal remains visible; file browser still works.
T.os='iOS';love.system.pickFile=function()end;Platform._resetForTests();actual.refuse=true
local I=Import.init(m,L);T.check(not I.start(),'failed native picker reported success');T.check(I.fromInbox('song.wav'),'fallback after native picker refusal')
-- Unsupported exported native functions must not route audio into ROM staging.
love.system.pickFileKinds=function()return'rom,mod'end
local J=Import.init(m,L);T.check(not J.start() and J.mode=='inbox','legacy ROM picker must not open')
T.os='Windows';love.system.pickFile=function()return false end;Platform._resetForTests();actual.chosenPath='C:/music.wav'
local K=Import.init(m,L);T.check(K.start() and K.mode=='desktop','desktop no-op native export shadowed real dialog')
print(('PASS %d platform routing, bounded-reader, file-browser, cancellation and receipt-isolation checks. All OS pickers are simulated.'):format(T.count))
