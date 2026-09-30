-- Shared paint/audio profiles. Only this test mod's installation cache is written.
-- Per-game selections point at named profiles; editing a profile changes its
-- value everywhere it is selected, without copying it into the other profiles.
local M={}
M.ORDER={'red','blue','yellow','gold','silver','crystal','firered','leafgreen'}
M.COLOURS={'bike_colour','bike_stripes_colour','bike_centres_colour','bike_tyres_colour','bike_handlebars_colour'}
local known,colour={},{};for _,g in ipairs(M.ORDER)do known[g]=true end;for _,k in ipairs(M.COLOURS)do colour[k]=true end
local audioDefault={riding_music='bicycle',bike_song='original',bike_song_resume=false,
 bike_filter=0,riding_area_filter=0,riding_sfx_filter=0}
local volumeDefault={bike_volume=7,riding_area_volume=-1,riding_sfx_volume=-1}
local audio={};for k in pairs(audioDefault)do audio[k]=true end;for k in pairs(volumeDefault)do audio[k]=true end
local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
local function integer(v,lo,hi)
 v=tonumber(v);if not v or v~=v or v==math.huge or v==-math.huge or v%1~=0 or v<lo or v>hi then return nil end;return v
end
local function song(v)
 if v=='original'then return true end
 if type(v)~='string'or #v>240 then return false end
 local h=v:match('^file:(%x+)$');if h then return #h==64 and h==h:lower()end
 local g,l=v:match('^game:([a-z]+):([%w_]+)$');return (known[g]or g=='emerald')and l~=nil or false
end
function M.managed(k)return colour[k]or audio[k]or k=='bike_frame_colour'end
function M.init(mod,H,services)
 services=services or{}
 local Version=services.Version or require('src.core.GameVersion')
 local Runtime=services.Runtime or require('src.mods.Runtime')
 local Json=services.Json or require('src.link.Json')
 local Save=services.SaveData or require('src.core.SaveData')
 local Serializer=services.Serializer or require('src.core.SaveSerializer')
 local cache=assert(mod.cache,'Shared profiles require mod.cache')
 local api={revision=0,lastError=nil};local state,loaded,game,readyId,notifying
 local function normal(k,v)
  if k=='bike_frame_colour'then k='bike_handlebars_colour'end
  if colour[k]then return H.canonical(v)end
  if k=='bike_song'then return song(v)and v or nil end
  if k=='bike_song_resume'then if type(v)=='boolean'then return v end;return nil end
  if k=='riding_music'then return(v=='bicycle'or v=='area'or v=='both')and v or nil end
  if volumeDefault[k]~=nil then return integer(v,k=='bike_volume'and 0 or -1,7)end
  if audioDefault[k]~=nil then return integer(v,k=='bike_filter'and 0 or -1,3)end
 end
 local function validate(t)
  if type(t)~='table'or t.format~=1 or not integer(t.seq,0,9007199254740000)
   or type(t.profiles)~='table'or type(t.games)~='table'or type(t.volumes)~='table'then return nil end
  for k in pairs(volumeDefault)do if normal(k,t.volumes[k])==nil then return nil end end
  for _,id in ipairs(M.ORDER)do if not t.profiles[id]or not t.games[id]then return nil end end
  for id,p in pairs(t.profiles)do
   if not known[id]or type(p)~='table'or type(p.colours)~='table'then return nil end
   for k,v in pairs(p.colours)do if not colour[k]or normal(k,v)==nil then return nil end end
   if p.audio~=nil then
    if type(p.audio)~='table'then return nil end
    for k,v in pairs(p.audio)do if not audio[k]or normal(k,v)==nil then return nil end end
   end
  end
  for id,g in pairs(t.games)do
   if not known[id]or type(g)~='table'or type(g.parts)~='table'or not(g.audio=='original'or known[g.audio])then return nil end
   for _,k in ipairs(M.COLOURS)do if not(g.parts[k]=='original'or known[g.parts[k]])then return nil end end
  end
  return t
 end
 local function decode(bytes)
  if type(bytes)~='string'or #bytes>262144 then return nil end
  local ok,t=pcall(Json.decode,bytes);if not ok then return nil end;return validate(t)
 end
 local function read(slot)
  local ok,b=pcall(cache.read,cache,'profiles/v1-'..slot..'.json');return ok and decode(b)or nil
 end
 local function latest()
  local a,b=read('a'),read('b');return a and b and(a.seq>=b.seq and a or b)or a or b
 end
 local function report(err)
  api.lastError=tostring(err);if mod.log and mod.log.warn then mod.log:warn('AUTOBIKE+ profiles: %s',api.lastError)end
  return false,api.lastError
 end
 local function commit(nextState)
  if Runtime.safeMode then return report('Profiles are read-only in safe mode')end
  nextState.format=1;nextState.seq=(state and state.seq or 0)+1
  assert(validate(nextState),'Invalid profile state')
  local bytes=Json.encode(nextState);if #bytes>262144 then return report('Profile storage limit reached')end
  local path='profiles/v1-'..(nextState.seq%2==1 and'a'or'b')..'.json'
  local function failed(reason)
   -- The first journal has no older slot to fall back to. Remove only that
   -- just-created incomplete slot so making space permits a clean retry.
   if not state and cache.delete then pcall(cache.delete,cache,path)end
   return report(reason)
  end
  local ok,yes,err=pcall(cache.write,cache,path,bytes)
  if not ok or not yes then return failed(err or yes or'Profile write failed')end
  local good,check=pcall(cache.read,cache,path)
  if not good or check~=bytes or not decode(check)then return failed('Profile write verification failed; previous settings retained')end
  state=nextState;loaded=true;api.revision=api.revision+1;api.lastError=nil;return true
 end
 local function opts(g)return g and(g.options or(g.save and g.save.options))end
 local function buckets(o)
  local m=type(o)=='table'and o.modOptions or{}
  if type(m)~='table'then return{}end
  local out=type(m.bicycle_plus)=='table'and copy(m.bicycle_plus)or{}
  -- The test bucket may have only AUTO BIKE/LANGUAGE seeded so far. Merge
  -- present keys, never let that partial bucket hide older paint/audio.
  local t=m[mod.id];if type(t)=='table'then for k,v in pairs(t)do out[k]=v end end
  return out
 end
 local function projectOld(raw)
  local r={}
  for k in pairs(audio)do local v=normal(k,raw[k]);if v~=nil then r[k]=v end end
  if r.riding_music==nil and(raw.music_mode=='cycling'or raw.music_mode=='bicycle')then r.riding_music='bicycle'
  elseif r.riding_music==nil and(raw.music_mode=='area'or raw.music_mode=='both')then r.riding_music=raw.music_mode end
  for _,k in ipairs(M.COLOURS)do
   local v=normal(k,raw[k]);if v then r[k]=v end
   local m=normal(k,raw[k..'_custom']);if m then r[k..'_custom']=m end
  end
  if r.bike_handlebars_colour==nil or r.bike_handlebars_colour=='original'then
   local v=H.canonical(raw.bike_frame_colour);if v and v~='original'then r.bike_handlebars_colour=v end
  end
  if type(raw.auto_mount)=='boolean'then r.auto_mount=raw.auto_mount end
  if raw.spelling=='uk'or raw.spelling=='us'then r.spelling=raw.spelling end
  if integer(raw.sfx_filter,0,3)then r.sfx_filter=raw.sfx_filter end
  return r
 end
 local function fsread(fs,path)
  local ok,info=pcall(fs.getInfo,path)
  if not ok or not info or info.type=='directory'or(tonumber(info.size)or 0)>8388608 then return nil end
  local good,bytes=pcall(fs.read,path);if not good or type(bytes)~='string'or #bytes>8388608 then return nil end
  local yes,t=pcall(Serializer.decode,bytes);return yes and type(t)=='table'and t or nil
 end
 -- This does not call listSlots/load/save: those native helpers may migrate
 -- save slots. We only READ already-present, narrowly validated save paths.
 local function historical(g)
  if services.historical then return services.historical(g)end
  local fs=Save.persistenceFs and Save.persistenceFs()or nil
  local out={};if not(fs and fs.getInfo and fs.read)then return out end
  local disk=fsread(fs,'options.lua')or opts(g)or{}
  for _,id in ipairs(M.ORDER)do
   local entries={};local reg=type(disk.saveSlots)=='table'and disk.saveSlots[id]
   if type(reg)=='table'and type(reg.list)=='table'then
    if type(reg.active)=='string'and reg.active:match('^slot%d+$')then entries[#entries+1]='saves/'..id..'/'..reg.active..'.lua'end
    for _,slot in ipairs(reg.list)do if type(slot)=='string'and #slot<24 and slot:match('^slot%d+$')then entries[#entries+1]='saves/'..id..'/'..slot..'.lua'end end
   end
   entries[#entries+1]='save'..(Version.saveSuffix(id)or'_'..id)..'.lua'
   for _,path in ipairs(entries)do
    local t=fsread(fs,path)or fsread(fs,path..'.bak')or fsread(fs,path..'.tmp')
    if t and(t.player or t.party or t.map or t.engine)then
     out[id]={played=true,raw=type(t.options)=='table'and projectOld(buckets(t.options))or nil,source=path};break
    end
   end
  end
  return out
 end
 local function newGameEntry()
  local t={parts={},audio='original',visited=false};for _,k in ipairs(M.COLOURS)do t.parts[k]='original'end;return t
 end
 local function initialise(g)
  local o=opts(g);if type(o)~='table'or not(g and g.mods)then return false end
  local raw=projectOld(buckets(o));local live=g.mods.modOptions and g.mods.modOptions[mod.id]
  if type(live)=='table'then for k,v in pairs(projectOld(live))do raw[k]=v end end
  local t={format=1,seq=0,profiles={},games={},volumes={},migration={method='existing-save-evidence',legacy=copy(raw),sources={}}}
  for k,d in pairs(volumeDefault)do t.volumes[k]=raw[k]~=nil and raw[k]or(k=='bike_volume'and(integer(o.musicVol,0,7)or 7)or d)end
  local past=historical(g)
  for _,id in ipairs(M.ORDER)do
   local p={colours={}};local select=newGameEntry();t.profiles[id]=p;t.games[id]=select
   local h=past[id]
   if h and h.played then
    -- Gen1/2 historically shared global options. GBA saves may also retain
    -- an edition-specific snapshot: use that when it actually exists.
    local r=raw
    if Version.generation(id)==3 and type(h.raw)=='table'and next(h.raw)then r=projectOld(h.raw)end
    select.visited=true;t.migration.sources[id]=h.source or'existing-save'
    for _,k in ipairs(M.COLOURS)do
     local value=H.canonical(r[k])or'original';local remember=H.canonical(r[k..'_custom'])
     p.colours[k]=value~='original'and value or remember and remember~='original'and remember or nil
     if value~='original'then select.parts[k]=id end
    end
    local changed=false
    for k,def in pairs(audioDefault)do
     local v=r[k]
     if v~=nil and v~=def and not((k=='riding_area_filter'or k=='riding_sfx_filter')and v==-1)then changed=true end
    end
    for _,k in ipairs({'riding_area_volume','riding_sfx_volume'})do if r[k]~=nil and r[k]~=-1 then changed=true end end
    if changed then
     p.audio={};for k,d in pairs(audioDefault)do local v=r[k];if v==nil then v=d end;p.audio[k]=v end
     for k in pairs(volumeDefault)do local v=r[k];if v==nil then v=t.volumes[k]end;p.audio[k]=v end
     select.audio=id
    end
   end
  end
  -- Backup contains only mod settings, not Pokémon progress or ROM content.
  if not Runtime.safeMode then
   local ok,info=pcall(cache.info,cache,'profiles/before-profiles.json')
   if ok and not info then pcall(cache.write,cache,'profiles/before-profiles.json',Json.encode(t))end
  end
  if Runtime.safeMode then state=t;return false end
  -- Do not publish an initial in-memory journal until its first disk write
  -- has succeeded and been verified. A failed first save can safely retry.
  return commit(t)
 end
 local function loadState(g)
  if loaded then return true end
  local found=latest();if found then state=found;loaded=true;return true end
  -- Do not silently replace unreadable profiles with defaults.
  for _,s in ipairs({'a','b'})do local ok,info=pcall(cache.info,cache,'profiles/v1-'..s..'.json');if ok and info then return report('Both profile journal copies are unreadable; restore your backup')end end
  return initialise(g)
 end
 local function gameId()local id=Version.get();return known[id]and id or'red'end
 local function audioValue(k,selection)
  local p=selection and selection~='original'and state.profiles[selection]
  if p and p.audio and p.audio[k]~=nil then return p.audio[k]end
  if volumeDefault[k]~=nil then return state.volumes[k]end
  return audioDefault[k]
 end
 local function resolve(k,id)
  local s=state.games[id]
  if colour[k]then
   local pick=s.parts[k];local p=pick~='original'and state.profiles[pick]
   return p and p.colours[k]or'original'
  end
  return audioValue(k,s.audio)
 end
 function api.get(k,g)
  if k=='bike_frame_colour'then k='bike_handlebars_colour'end
  if not M.managed(k)then return nil end
  g=g or game or mod.game
  if not loadState(g)or not state then
   if colour[k]then return'original'end
   if volumeDefault[k]~=nil then local o=opts(g)or{};return k=='bike_volume'and(integer(o.musicVol,0,7)or 7)or volumeDefault[k]end
   return audioDefault[k]
  end
  return resolve(k,gameId())
 end
 local function project(g)
  local o=opts(g);if not(state and type(o)=='table'and g.mods)then return end
  o.modOptions=o.modOptions or{};g.mods.modOptions=g.mods.modOptions or{}
  local a=o.modOptions[mod.id]or{};local b=g.mods.modOptions[mod.id]or{}
  for _,k in ipairs(M.COLOURS)do local v=resolve(k,gameId());a[k]=v;b[k]=v end
  for k in pairs(audio)do local v=resolve(k,gameId());a[k]=v;b[k]=v end
  a._shared_profiles=1;b._shared_profiles=1
  o.modOptions[mod.id]=a;g.mods.modOptions[mod.id]=b
 end
 local function emit(g,key,v)
  project(g);notifying=true
  if g and g.mods and g.mods.events then g.mods.events:emit('mod.options_changed',{mod=mod.id,key=key,value=v,autobikeProfile=true})end
  notifying=false
 end
 function api.ensure(g)
  game=g or game or mod.game
  if not loadState(game)then return false end
  if readyId==gameId()then return true end
  local fresh=latest();if fresh and fresh.seq>state.seq then state=fresh;api.revision=api.revision+1 end
  if not Runtime.safeMode and not state.games[gameId()].visited then
   local nextState=copy(state);nextState.games[gameId()].visited=true
   if not commit(nextState)then return false end
  end
  readyId=gameId();project(game);return true
 end
 local function mutate(g,fn,key,value)
  if Runtime.safeMode then return false,'Safe mode'end
  if not api.ensure(g)then return false,api.lastError end
  local fresh=latest();if fresh and fresh.seq>state.seq then state=fresh end
  local t=copy(state);fn(t,t.games[gameId()],gameId())
  if not commit(t)then return false,api.lastError end
  emit(g or game,key,value);return true
 end
 function api.order()
  local ids={'original',gameId()};for _,id in ipairs(M.ORDER)do if id~=gameId()then ids[#ids+1]=id end end;return ids
 end
 function api.selection(key,g)
  api.ensure(g);if not state then return'original'end
  local s=state.games[gameId()];return key=='audio'and s.audio or s.parts[key]or'original'
 end
 function api.select(g,key,id)
  if not(id=='original'or known[id])or not(key=='audio'or colour[key])then return false,'Invalid profile'end
  return mutate(g,function(_,s)if key=='audio'then s.audio=id else s.parts[key]=id end end,'profile',id)
 end
 function api.step(g,key,dir)
  local values=api.order();local v=api.selection(key,g);local index=1
  for i,x in ipairs(values)do if x==v then index=i;break end end
  return api.select(g,key,values[(index-1+(dir<0 and-1 or 1))%#values+1])
 end
 function api.set(g,k,v)
  if k=='bike_frame_colour'then k='bike_handlebars_colour'end
  if not M.managed(k)then return false,'Unmanaged setting'end
  v=normal(k,v);if v==nil then return false,'Invalid setting'end
  return mutate(g,function(t,s,id)
   if colour[k]then
    if s.parts[k]=='original'then
     if v=='original'then return end
     s.parts[k]=id
    end
    t.profiles[s.parts[k]].colours[k]=v
   else
    if s.audio=='original'then s.audio=id end
    local p=t.profiles[s.audio]
    if not p.audio then
     p.audio=copy(audioDefault);for key in pairs(volumeDefault)do p.audio[key]=t.volumes[key]end
    end
    p.audio[k]=v
    if volumeDefault[k]~=nil then t.volumes[k]=v end
   end
  end,k,v)
 end
 function api.remembered(g,k)
  local v=api.get(k,g);if v and v~='original'then return v end
  return H.canonical('green')or'rgb:008400'
 end
 function api.resetColours(g)
  return mutate(g,function(_,s)for _,k in ipairs(M.COLOURS)do s.parts[k]='original'end end,'reset_colours',true)
 end
 function api.snapshot()return state and copy(state)or nil end
 function api.refresh(g)readyId=nil;local t=latest();if t then state=t;loaded=true end;return api.ensure(g)end
 api.managed=M.managed
 -- Changes from the native mod manager must join the same profile model.
 if mod.events then mod.events:on('mod.options_changed',function(e)
  if not notifying and e and e.mod==mod.id and M.managed(e.key)and e.value~=nil and not Runtime.safeMode then api.set(game or mod.game,e.key,e.value)end
 end,-1000)end
 return api
end
return M
