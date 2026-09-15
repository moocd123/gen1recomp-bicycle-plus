-- Real LÖVE/PhysFS/FileData/audio decoders with the actual mod sandbox.
-- OpenAL null output is an API/decoder test, not a speaker/listening test.
local function disk(path)local f=assert(io.open(path,'rb'));local b=f:read('*a');f:close();return b end
local function run(args)
 local root,engine,tones=assert(args[1]),assert(args[2]),assert(args[3])
 package.path=engine..'/?.lua;'..package.path
 local Runtime=require('src.mods.Runtime')
 local Hooks=require('src.mods.Hooks');local Events=require('src.mods.Events')
 Runtime.install(Events.new(),Hooks.new())
 local game={save={options={}},data={screens={}}}
 local mod={id='bicycle_plus',path='mods/bicycle_plus',manifest={id='bicycle_plus',path='mods/bicycle_plus'},game=game}
 local _,cache=require('src.mods.ImportAccess').new(mod.manifest,love.filesystem);mod.cache=cache
 function mod:read(path)
  if path:match('^baseroms/')then return love.filesystem.read(self.path..'/'..path)end
  return disk(root..'/'..path)
 end
 local compat=require('src.mods.LegacyCompat').new({modId=mod.id,modPath=mod.path,fs=love.filesystem,game=function()return game end})
 local env=require('src.mods.Sandbox').envFor({modId=mod.id,permissions={engine_internals=true},compat=compat})
 local function module(name)return assert(require('src.mods.Sandbox').compile(mod:read(name..'.lua'),'@'..name,env))()end
 local Library=module('song_library');local L=Library.init(mod)
 local Picker=module('import_picker').init(mod,L);L.attachPicker(Picker)
 local n=0;local function ck(v,m)assert(v,m);n=n+1 end
 -- Protected files are synthetic sentinels in a dedicated CI save identity.
 love.filesystem.write('save.lua','PROGRESS SENTINEL')
 love.filesystem.write('options.lua','OPTIONS SENTINEL')
 for _,ext in ipairs({'wav','ogg','mp3','flac'})do
  local path=tones..'/test.'..ext;local bytes=disk(path)
  local row,err=Picker.readSelected(path)
  ck(row,'native sized reader / '..ext..': '..tostring(err))
  local descriptor=assert(L.resolve(row.id,game))
  local source,why=descriptor.openSource()
  ck(source,'FileData source / '..ext..': '..tostring(why))
  ck(source:getDuration('seconds')>.1,'decoder duration / '..ext)
  source:setLooping(true);source:setVolume(.3);source:play();love.timer.sleep(.03)
  ck(source:isPlaying(),'streaming Source did not play / '..ext)
  source:pause();source:seek(.05,'seconds');source:play();love.timer.sleep(.03)
  ck(source:tell('seconds')>=.05,'resume / '..ext)
  source:stop();source:release()
  -- Reload from persisted scoped cache, independent of the host input path.
  local restarted=Library.init(mod);local again=assert(restarted.openSource(row.id))
  ck(again:getDuration('seconds')>.1,'persisted reload / '..ext);again:release()
  -- Real decoder rejects non-audio despite a plausible file extension.
  ck(not L.importBytes('not an audio file at all','invalid.'..ext),'invalid audio accepted')
  print('PASS real LÖVE '..ext..' decode/stream/seek/reload through Sandbox and scoped cache')
 end
 -- Reproduce old code's virtual-path mismatch against real PhysFS, not mocks.
 local wav=disk(tones..'/test.wav')
 local alias='mod_data/bicycle_plus/music/legacy-reproduction.wav'
 env.love.filesystem.write(alias,wav)
 ck(not pcall(love.audio.newSource,alias,'stream'),'legacy mismatch not reproduced')
 ck(env.love.filesystem.read(alias)==wav,'compat path content missing')
 -- A foreign sound bank written by the library must be readable by raw engine
 -- ChipSynth in its own environment (unlike the old compat path).
 love.filesystem.createDirectory('gold/data/generated');love.filesystem.createDirectory('gold/assets/generated/audio')
 love.filesystem.write('gold/data/generated/audio.lua','return {programFile="assets/generated/audio/programs.bin",bankOrder={1},songs={Music_Bicycle={bank=1,address=16384}}}')
 love.filesystem.write('gold/assets/generated/audio/programs.bin',string.rep('A',16384))
 local foreign=assert(L.gameData('gold',game));local synth=require('src.core.ChipSynth');synth.invalidateBanks()
 ck(synth._loadBanksForTest(foreign)[1]==string.rep('A',16384),'native foreign sound bank not readable')
 ck(require('src.core.GameVersion').get()=='red','active edition changed')
 ck(love.filesystem.read('save.lua')=='PROGRESS SENTINEL','progress file changed')
 ck(love.filesystem.read('options.lua')=='OPTIONS SENTINEL','options file changed by library')
 print(('PASS %d real LÖVE decoder/stream/seek/storage/sandbox checks. OpenAL output is null; OS dialogs are separately simulated.'):format(n))
end
function love.load(args)
 local ok,err=xpcall(function()run(args)end,debug.traceback)
 if not ok then io.stderr:write(tostring(err)..'\n')end
 love.event.quit(ok and 0 or 1)
end
function love.errorhandler(err)
 io.stderr:write(tostring(err)..'\n');return function()return 1 end
end
