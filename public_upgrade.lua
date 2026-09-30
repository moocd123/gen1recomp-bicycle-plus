-- One-time local-test -> public handoff. Reads the old test namespace only;
-- all writes go through the public mod.cache or the native options-only writer.
-- It never deletes old data, switches games, or writes progress-save files.
local M={}
local TEST='autobike_plus_test'
local MARK='release/v2-adoption.json'
function M.init(mod,H,services)
 services=services or{}
 local Runtime=services.Runtime or require('src.mods.Runtime')
 local Json=services.Json or require('src.link.Json')
 local Cache=services.Cache or require('src.import.CacheFs')
 local Save=services.Save or require('src.core.SaveData')
 local function module(name)return assert(load(assert(mod:read(name..'.lua')),'@'..mod.id..'/'..name))()end
 local own=assert(mod.cache);local api={};local status
 local function decode(b)
  if type(b)~='string'or #b>262144 then return nil end
  local ok,t=pcall(Json.decode,b);return ok and type(t)=='table'and t or nil
 end
 local function warn(e)
  if mod.log and mod.log.warn then mod.log:warn('AUTOBIKE+ public upgrade: %s',tostring(e))end
  api.error=tostring(e);return false
 end
 local function oldRead(rel,limit)
  local made,fs=pcall(Save.persistenceFs)
  if made and fs and fs.getInfo then
   local found,info=pcall(fs.getInfo,'mod_cache/'..TEST..'/'..rel)
   if found and info and (info.type=='directory' or (tonumber(info.size)or 0)>(limit or 262144))then return nil end
  end
  local ok,b=pcall(Cache.readAt,'mod_cache/'..TEST..'/'..rel)
  if not ok or type(b)~='string'or #b>(limit or 262144)then return nil end
  return b
 end
 local function read(rel)local ok,b=pcall(own.read,own,rel);return ok and b or nil end
 local function write(rel,b)
  local ok,yes,err=pcall(own.write,own,rel,b)
  if not ok or not yes or read(rel)~=b then return warn(err or yes or 'Storage write/readback failed: '..rel)end
  return true
 end
 local function mark(t)
  if not write(MARK,Json.encode(t))then return false end;status=t;return true
 end
 local function sourceProfiles()
  -- Reuse the tested journal validator, but give the probe a read-only cache
  -- and a separate safe-mode service, never the live global Runtime.
  local a,b=oldRead('profiles/v1-a.json'),oldRead('profiles/v1-b.json')
  if not a and not b then return nil end
  local source={read=function(_,r)if r=='profiles/v1-a.json'then return a elseif r=='profiles/v1-b.json'then return b end end}
  function source:info(r)local x=self:read(r);return x and {type='file',size=#x}end
  local probe=module('profiles').init({id=TEST,cache=source},H,{Runtime={safeMode=true},historical=function()return{}end})
  probe.get('bike_volume',{options={musicVol=7},mods={}})
  local t=probe.snapshot()
  if not t then return nil,'Test profile journals are unreadable; restore the test backup first'end
  return t
 end
 local function index(b)
  local t=decode(b)
  if not t or t.format~=1 or type(t.seq)~='number'or t.seq<0 or t.seq%1~=0
   or t.seq>9007199254740000 or type(t.tracks)~='table'or #t.tracks>128 then return nil end
  local seen={}
  for _,r in ipairs(t.tracks)do
   local hash=type(r)=='table'and type(r.id)=='string'and r.id:match('^file:(%x+)$')
   if not hash or #hash~=64 or hash~=hash:lower()or seen[hash]
    or not({mp3=true,ogg=true,wav=true,flac=true})[r.ext]
    or type(r.name)~='string'or #r.name>64 then return nil end
   seen[hash]=true
  end
  return t
 end
 local function transferMusic()
  local a,b=index(oldRead('music/index-a.json')),index(oldRead('music/index-b.json'))
  local selected=a and b and(a.seq>=b.seq and a or b)or a or b
  if not selected then return true end
  -- Use the production library's validated import and journal code. Existing
  -- public songs stay present; test files are copied, not moved or deleted.
  local Library=module('song_library');local library=Library.init(mod)
  local ok,err=xpcall(function()
   for _,r in ipairs(selected.tracks)do
    local bytes=oldRead('music/tracks/'..r.id:sub(6)..'.'..r.ext,67108864)
    if bytes then
     assert(Library.hash(bytes)==r.id:sub(6),'Test audio checksum failed: '..r.name)
     local row,why=library.importBytes(bytes,r.name..'.'..r.ext)
     assert(row,why);assert(row.id==r.id,'Imported song identifier changed')
     assert(library.rename(row.id,r.name))
    end
   end
  end,function(e)return tostring(e)end)
  library.shutdown()
  if not ok then return warn(err)end;return true
 end
 local function transferMirrors()
  local Serializer=require('src.core.SaveSerializer')
  for _,edition in ipairs({'firered','leafgreen','emerald'})do
   local pointer=oldRead('soundtracks/'..edition..'/latest.json',4096)
   local p=decode(pointer)
   if p and p.edition==edition and type(p.hash)=='string' and #p.hash==64 and p.hash:match('^%x+$')then
    local base='soundtracks/'..edition..'/'..p.hash..'/'
    local ix,samples=oldRead(base..'index.lua',8388608),oldRead(base..'samples.bin',67108864)
    if ix and samples and module('song_library').hash(ix..samples)==p.hash then
     local ok,t=pcall(Serializer.decode,ix,{allowArray=true,allowComments=true,maxBytes=8388608,maxDepth=32,maxNodes=2000000,maxString=8388608})
     if ok and type(t)=='table' and type(t.songs)=='table'then
      local complete=true
      if not write(base..'index.lua',ix)or not write(base..'samples.bin',samples)then return false end
      for k,def in pairs(t.songs)do
       local id=tonumber(k)
       if id and id>0 and id%1==0 and type(def)=='table'and(def.kind=='bgm'or def.kind=='fanfare')then
        local path=base..'songs/'..id..'.bin';local bytes=oldRead(path,8388608)
        if not bytes then complete=false elseif not write(path,bytes)then return false end
       end
      end
      if complete and not write('soundtracks/'..edition..'/latest.json',pointer)then return false end
     end
    end
   end
  end
  return true
 end
 function api.prepare()
  if mod.id~='bicycle_plus'or Runtime.safeMode then return true end
  local recorded=read(MARK);status=decode(recorded)
  if recorded and not status then return warn('Upgrade record is damaged; restore its backup before retrying')end
  if status and status.format==1 and status.phase=='complete'then return true end
  if status and not(status.format==1 and status.source==TEST and status.phase=='copying')then
   return warn('Upgrade record is unreadable; no settings were overwritten')
  end
  if not status then
   -- A public profile journal already created by 2.x always wins over an
   -- older test. A failed first adoption retains its COPYING checkpoint.
   if read('profiles/v1-a.json')or read('profiles/v1-b.json')then
    return mark({format=1,phase='complete',source='public',optionsDone=true})
   end
   local state,err=sourceProfiles()
   if err then return warn(err)end
   if not state then return mark({format=1,phase='complete',source='legacy',optionsDone=true})end
   if not mark({format=1,phase='copying',source=TEST,optionsDone=false})then return false end
  end
  local state,err=sourceProfiles();if not state then return warn(err or 'Test profiles disappeared during adoption')end
  if not transferMusic()or not transferMirrors()then return false end
  local bytes=Json.encode(state)
  if not write('profiles/v1-a.json',bytes)or not write('profiles/v1-b.json',bytes)then return false end
  return mark({format=1,phase='complete',source=TEST,optionsDone=false})
 end
 function api.options(game)
  if mod.id~='bicycle_plus'or Runtime.safeMode or not status or status.source~=TEST or status.optionsDone then return false end
  local o=game and(game.options or(game.save and game.save.options))
  if type(o)~='table'or not(game.mods and game.writeOptions)then return false end
  o.modOptions=o.modOptions or{};game.mods.modOptions=game.mods.modOptions or{}
  local old=o.modOptions[TEST]or game.mods.modOptions[TEST]or{}
  local target=o.modOptions.bicycle_plus or{};local live=game.mods.modOptions.bicycle_plus or{}
  local before={}
  local values={auto_mount=type(old.auto_mount)=='boolean'and old.auto_mount or nil,
   spelling=(old.spelling=='uk'or old.spelling=='us')and old.spelling or nil}
  -- Lua's and/or idiom cannot carry false; preserve explicit OFF separately.
  if old.auto_mount==false then values.auto_mount=false end
  if type(old.sfx_filter)=='number'and old.sfx_filter>=0 and old.sfx_filter<=3 and old.sfx_filter%1==0 then values.sfx_filter=old.sfx_filter end
  for k in pairs(values)do before[k]=target[k]end
  if not read('release/before-v2-options.json')then
   if not write('release/before-v2-options.json',Json.encode(before))then return false end
  end
  for k,v in pairs(values)do target[k]=v;live[k]=v end
  o.modOptions.bicycle_plus=target;game.mods.modOptions.bicycle_plus=live
  local ok,result=pcall(game.writeOptions,game)
  if not ok or result==false then return warn('Could not save the adopted options; old test data is intact')end
  return mark({format=1,phase='complete',source=TEST,optionsDone=true})
 end
 return api
end
return M
