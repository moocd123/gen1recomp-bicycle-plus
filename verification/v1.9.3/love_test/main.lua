-- Real PhysFS, native Sandbox/import reader, MD5/SHA256 and LÖVE decoders.
-- OS callbacks alone are simulated; audio uses null output, not listening.
local function disk(path)local f=assert(io.open(path,'rb'));local b=f:read('*a');f:close();return b end
local function run(args)
 local root,engine,tones=assert(args[1]),assert(args[2]),assert(args[3])
 package.path=engine..'/?.lua;'..package.path
 local R=require('src.mods.Runtime');R.install(require('src.mods.Events').new(),require('src.mods.Hooks').new())
 local Platform=require('src.core.Platform');local game={save={options={}},data={screens={}}}
 local mod={id='bicycle_plus',path='mods/bicycle_plus',manifest={id='bicycle_plus',path='mods/bicycle_plus'},game=game}
 local _,cache=require('src.mods.ImportAccess').new(mod.manifest,love.filesystem);mod.cache=cache
 function mod:read(path)return disk(root..'/'..path)end
 local compat=require('src.mods.LegacyCompat').new({modId=mod.id,modPath=mod.path,fs=love.filesystem,game=function()return game end})
 local env=require('src.mods.Sandbox').envFor({modId=mod.id,permissions={engine_internals=true},compat=compat})
 local function module(name)return assert(require('src.mods.Sandbox').compile(mod:read(name..'.lua'),'@'..name,env))()end
 local Lib=module('song_library');local Adapter=module('import_picker')
 local n=0;local function ck(v,m)assert(v,m);n=n+1 end
 local protected={'save.lua','options.lua','picked_rom.gb','picked_save.sav','picked_mod.zip','unrelated-mod.txt'}
 for _,p in ipairs(protected)do assert(love.filesystem.write(p,'KEEP:'..p))end
 local oldOS,oldPick,oldKinds=love.system.getOS,love.system.pickFile,love.system.pickFileKinds
 for _,osname in ipairs({'Android','iOS'})do
  for _,ext in ipairs({'wav','ogg','mp3','flac'})do
   for _,delivery in ipairs({'direct','markerless','legacy'})do
    local dest
    love.system.getOS=function()return osname end
    love.system.pickFileKinds=function()return'required_import,rom,mod,sav'end
    love.system.pickFile=function(kind,path)ck(kind=='required_import','must not use ROM staging');dest=path;return true end
    Platform._resetForTests()
    local L=Lib.init(mod);local P=Adapter.init(mod,L);L.attachPicker(P)
    ck(P.choose()=='pending','native picker request failed')
    local raw=disk(tones..'/test.'..ext)
    local stage=delivery=='legacy'and'picked_required_import.bin'or dest
    assert(love.filesystem.createDirectory('mods/bicycle_plus/baseroms'))
    assert(love.filesystem.write(stage,raw))
    if delivery=='direct'then
     local hash=(love.data.hash('md5',raw):gsub('.',function(c)return('%02x'):format(c:byte())end))
     assert(love.filesystem.write('pick_complete.flag','v1\n'..stage..'\n'..hash..'\n'..#raw..'\n'))
    end
    local row,err=P.poll(.3)
    if delivery~='direct'then ck(not row and L.pending,'markerless data not stabilised');row,err=P.poll(.3)end
    ck(row,osname..' '..delivery..' '..ext..': '..tostring(err))
    ck(not L.pending and not P.request,'pending state not cleared')
    ck(not love.filesystem.getInfo(stage),'own staging was not cleaned')
    local src,why=L.openSource(row.id);ck(src,'source open: '..tostring(why))
    ck(src:getType()=='stream'and src:getDuration('seconds')>.5,'incorrect real decoder/stream')
    src:setLooping(true);src:play();love.timer.sleep(.02);ck(src:isPlaying(),'stream did not start')
    src:pause();src:seek(.1,'seconds');src:play();love.timer.sleep(.02);ck(src:tell('seconds')>=.1,'seek/resume failed');src:stop();src:release()
    local fresh=Lib.init(mod);local reloaded=assert(fresh.openSource(row.id));ck(reloaded:getDuration('seconds')>.5,'persistent reopen failed');reloaded:release()
    for _,p in ipairs(protected)do ck(love.filesystem.read(p)=='KEEP:'..p,'protected file modified: '..p)end
    ck(disk(tones..'/test.'..ext)==raw,'source audio altered')
    print('PASS real decoder/import completion '..osname..' '..delivery..' '..ext)
   end
  end
 end
 -- Verify corruption rejects before adding an import and retry is possible.
 local L=Lib.init(mod);local P=Adapter.init(mod,L);L.attachPicker(P);local dest
 love.system.pickFile=function(_,p)dest=p;return true end
 P.choose();love.filesystem.write(dest,'RIFF0000WAVECORRUPT DATA')
 P.poll(.3);local row,err=P.poll(.3);ck(not row and err and not L.pending,'real corrupt audio did not fail cleanly')
 ck(P.choose()=='pending','retry after corrupt audio failed');P.cancel()
 love.system.getOS, love.system.pickFile,love.system.pickFileKinds=oldOS,oldPick,oldKinds;Platform._resetForTests()
 print(('PASS %d real-file/native-reader/decoder/stream/reload checks; simulated native callbacks, null audio output.'):format(n))
end
function love.load(args)
 local ok,err=xpcall(function()run(args)end,debug.traceback)
 if not ok then io.stderr:write(tostring(err)..'\n')end
 love.event.quit(ok and 0 or 1)
end
function love.errorhandler(err)io.stderr:write(tostring(err)..'\n');return function()return 1 end end
