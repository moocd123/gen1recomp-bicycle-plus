-- Real LÖVE codec/source check using generated test tones, not game audio.
function love.load(args)
 local ok,err=xpcall(function()
  local repo,engine,fixtures=assert(args[1]),assert(args[2]),assert(args[3])
  package.path=engine..'/?.lua;'..package.path
  local Runtime=require('src.mods.Runtime');Runtime.safeMode=false
  local ImportAccess=require('src.mods.ImportAccess')
  local _,cache=ImportAccess.new({id='bicycle_plus',path='mods/bicycle_plus'},love.filesystem)
  local mod={cache=cache,id='bicycle_plus'}
  local L=assert(loadfile(repo..'/bike_songs.lua'))().init(mod,{})
  local hashes={}
  for _,ext in ipairs({'wav','mp3','ogg'})do
   local file=assert(io.open(fixtures..'/tone.'..ext,'rb'));local bytes=file:read('*a');file:close()
   local id,msg=L.importBytes(bytes,'test tone.'..ext);assert(id,msg)
   local record,why=L.resolve({},id);assert(record,why)
   local src=love.audio.newSource(record.def.file,'stream');assert(src:getDuration()>0)
   src:setLooping(true);src:setVolume(0.2)
   pcall(src.setFilter,src,{type='lowpass',volume=1,highgain=0.4})
   assert(src:play()~=false);love.timer.sleep(.04);src:pause()
   assert(not src:isPlaying());assert(src:play()~=false);src:stop();src:release()
   assert(L.importBytes(bytes,'same content')==id)
   hashes[#hashes+1]=id
   print('PASS actual LÖVE import, decode, streaming source, looping/pause/resume and SHA-256 dedup: '..ext)
  end
  L.clear()
  local nextLibrary=assert(loadfile(repo..'/bike_songs.lua'))().init(mod,{})
  for _,id in ipairs(hashes)do assert(nextLibrary.resolve({},id));assert(nextLibrary.remove(id))end
  nextLibrary.clear();print('PASS actual filesystem library persistence and removal. Null audio driver; not a physical audibility test.')
 end,debug.traceback)
 if not ok then print('FAIL codec check: '..tostring(err))end
 love.event.quit(ok and 0 or 1)
end
