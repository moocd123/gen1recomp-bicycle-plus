-- Read-only bridge from already-imported Gen 1/2 audio caches into the
-- isolated FireRed beta. No ROM bytes are bundled and stable bicycle_plus
-- storage is never read or written. Program copies live under this beta's
-- own mod.cache namespace so ChipSynth bank caches cannot collide by path.
local Legacy={}
local EDITIONS={'red','blue','yellow','gold','silver','crystal'}
local ALLOWED={};for _,id in ipairs(EDITIONS)do ALLOWED[id]=true end

local function copy(t)
 local out={};for k,v in pairs(t or{})do out[k]=type(v)=='table'and copy(v)or v end;return out
end
local function title(label)
 return tostring(label or''):gsub('^[Mm][Uu][Ss][Ii][Cc]_','')
  :gsub('(%l)(%u)','%1 %2'):gsub('_',' '):upper()
end
Legacy.title=title

function Legacy.init(mod,S)
 S=S or{}
 local Cache=S.Cache or require('src.import.CacheFs')
 local Version=S.Version or require('src.core.GameVersion')
 local cache=assert(mod.cache,'FireRed beta requires mod.cache')
 local root='mod_cache/'..mod.id..'/music'
 local foreign={}
 local api={}

 local function digest(bytes)
  if S.hash then return S.hash(bytes)end
  assert(love and love.data and love.data.hash,'SHA-256 support unavailable')
  local raw=love.data.hash('sha256',bytes)
  return(raw:gsub('.',function(c)return('%02x'):format(c:byte())end))
 end
 local function decode(bytes)
  if S.decode then return S.decode(bytes)end
  local Serializer=S.Serializer or require('src.core.SaveSerializer')
  local ok,t,err=pcall(Serializer.decode,bytes,{allowArray=true,allowComments=true,
   maxBytes=8*1024*1024,maxDepth=48,maxNodes=200000,maxStringBytes=2*1024*1024,
   maxTableEntries=100000,rootName='audio cache'})
  if not ok then return nil,t end
  if type(t)~='table'or type(t.songs)~='table'then return nil,err or'Invalid audio cache'end
  return t
 end
 local function metadataPath(edition)
  return Version.cachePrefix(edition)..'data/generated/audio.lua'
 end
 local function ownRead(path)
  local ok,v=pcall(cache.read,cache,path);return ok and type(v)=='string'and v or nil
 end
 local function ownWrite(path,bytes)
  local ok,yes,err=pcall(cache.write,cache,path,bytes)
  if not ok or not yes then return nil,tostring(err or yes or'Write failed')end
  return true
 end

 function api.editions()
  local rows={}
  for _,edition in ipairs(EDITIONS)do
   local present=false
   local ok,v=pcall(Cache.existsAt,metadataPath(edition));present=ok and v==true
   rows[#rows+1]={id=edition,label=edition:upper(),available=present}
  end
  return rows
 end
 function api.gameData(edition)
  if not ALLOWED[edition]then return nil,'Unsupported game'end
  if foreign[edition]then return foreign[edition]end
  local prefix=Version.cachePrefix(edition)
  local bytes=Cache.readAt(prefix..'data/generated/audio.lua')
  local audio,err=decode(bytes)
  if not audio then return nil,'IMPORT '..edition:upper()..' IN THE LAUNCHER FIRST'end
  if audio.programFile~='assets/generated/audio/programs.bin'or type(audio.bankOrder)~='table'
      or #audio.bankOrder<1 or #audio.bankOrder>128 then return nil,'Unsupported sound-program cache'end
  local seen={}
  for _,bank in ipairs(audio.bankOrder)do
   if type(bank)~='number'or bank<0 or bank>1023 or bank~=math.floor(bank)or seen[bank]then
    return nil,'Invalid sound-program bank list'
   end
   seen[bank]=true
  end
  local programs=Cache.readAt(prefix..audio.programFile)
  if type(programs)~='string'or #programs~=#audio.bankOrder*16384 then
   return nil,'Sound-program cache incomplete'
  end
  local hash=digest(programs)
  local rel='music/cache/'..edition..'-'..hash..'.bin'
  local present=ownRead(rel)
  if not present or #present~=#programs or digest(present)~=hash then
   local ok;ok,err=ownWrite(rel,programs);if not ok then return nil,err end
   local checked=ownRead(rel)
   if not checked or #checked~=#programs or digest(checked)~=hash then
    return nil,'Music cache copy could not be verified'
   end
  end
  audio=copy(audio)
  audio.programFile=root..'/cache/'..edition..'-'..hash..'.bin'
  audio.programPrefix=nil
  foreign[edition]={audio=audio}
  return foreign[edition]
 end
 function api.gameSongs(edition)
  local data,err=api.gameData(edition);if not data then return nil,err end
  local rows={}
  for label,def in pairs(data.audio.songs or{})do
   if type(label)=='string'and label:match('^[%w_]+$')and #label<192 and type(def)=='table'
       and label:lower()~='music_nothing'and(def.chip or def.file or(def.bank and def.address))then
    rows[#rows+1]={id='game:'..edition..':'..label,name=title(label),label=label,edition=edition}
   end
  end
  table.sort(rows,function(a,b)return a.name==b.name and a.id<b.id or a.name<b.name end)
  return rows
 end
 function api.resolve(key)
  local edition,label=tostring(key or''):match('^game:([a-z]+):([%w_]+)$')
  if not ALLOWED[edition]then return nil,'Unsupported imported-game song'end
  local data,err=api.gameData(edition);if not data then return nil,err end
  local def=data.audio.songs and data.audio.songs[label]
  if type(def)~='table'then return nil,'Selected track is missing from the imported game'end
  return{key=key,kind='chip',edition=edition,label=label,data=data,def=def,name=edition:upper()..': '..title(label)}
 end
 function api.describe(key)
  local edition,label=tostring(key or''):match('^game:([a-z]+):([%w_]+)$')
  return ALLOWED[edition]and(edition:upper()..': '..title(label))or nil
 end
 function api.refresh()foreign={}end
 mod.exports.gen3LegacySongs=api
 return api
end
return Legacy
