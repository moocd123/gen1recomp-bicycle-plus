-- Local music catalogue. No network requests, ROM patching or game switching.
-- The library lives outside the mod install directory so Update All cannot
-- replace imported tracks. Only explicitly selected files / the dedicated
-- inbox and the six already-imported audio caches are read.
local Library = {}
Library.ROOT = 'mod_cache/bicycle_plus/music'
Library.LEGACY_ROOT = 'mod_data/bicycle_plus/music'
Library.PENDING = 'mods/bicycle_plus/baseroms/bicycle_plus_audio_pick.bin'
Library.MAX_BYTES = 64 * 1024 * 1024
Library.MAX_TRACKS = 128
local editions = {'red','blue','yellow','gold','silver','crystal'}
local allowed = {}; for _,id in ipairs(editions) do allowed[id]=true end
local formats = {mp3=true,ogg=true,wav=true,flac=true}

function Library.valid(id)
  if id == 'original' then return true end
  if type(id) ~= 'string' or #id > 240 then return false end
  local hash=id:match('^file:(%x+)$')
  if hash then return #hash==64 and hash==hash:lower() end
  local edition,label=id:match('^game:([a-z]+):([%w_]+)$')
  return allowed[edition] == true and label ~= nil
end

local function cleanName(name, fallback)
  name=tostring(name or ''):match('([^/\\]+)$') or ''
  name=name:gsub('%.[%w]+$',''):gsub('[^%w %-%._]',' '):gsub('_',' '):gsub('%s+',' '):match('^%s*(.-)%s*$')
  if name=='' or name=='bicycle plus audio pick' then name=fallback or 'IMPORTED SONG' end
  return name:sub(1,64)
end
function Library.title(label)
  return tostring(label or ''):gsub('^[Mm][Uu][Ss][Ii][Cc]_','')
    :gsub('(%l)(%u)','%1 %2'):gsub('_',' '):upper()
end
local function magic(bytes, name)
  if bytes:sub(1,4)=='RIFF' and bytes:sub(9,12)=='WAVE' then return 'wav' end
  if bytes:sub(1,4)=='fLaC' then return 'flac' end
  if bytes:sub(1,4)=='OggS' then return 'ogg' end
  if bytes:sub(1,3)=='ID3' then return 'mp3' end
  local a,b=bytes:byte(1,2)
  if a==255 and b and b>=224 then return 'mp3' end
  -- A recognised extension still must pass the actual decoder below.
  local ext=tostring(name or ''):lower():match('%.([a-z0-9]+)$')
  return formats[ext] and ext or nil
end
local function copy(t)
  local r={};for k,v in pairs(t) do r[k]=type(v)=='table' and copy(v) or v end;return r
end
local function hash(bytes)
  assert(love.data and love.data.hash,'SHA-256 support unavailable')
  local digest=love.data.hash('sha256',bytes)
  return (digest:gsub('.',function(c)return ('%02x'):format(c:byte())end))
end
Library.hash=hash
Library.sniff=magic

function Library.init(mod)
  local fs=assert(love.filesystem)
  local Json=require('src.link.Json')
  local Cache=require('src.import.CacheFs')
  local Version=require('src.core.GameVersion')
  local Runtime=require('src.mods.Runtime')
  local root=Library.ROOT
  local cache=assert(mod.cache, 'AUTOBIKE+ requires the engine mod.cache API')
  local api={revision=0,notice=nil,pending=false}
  local foreign={}; local index={seq=0,tracks={}}; local loaded=false
  -- A sandbox filesystem path is an overlay alias, not an audio-engine path.
  -- Use the engine-owned installation cache; legacy storage is read-only.
  local function rel(path)
    assert(type(path)=='string' and path:sub(1,#root+1)==root..'/', 'Outside music library')
    local tail=path:sub(#root+2)
    assert(not tail:find('..',1,true) and not tail:find('\\',1,true), 'Invalid music path')
    return 'music/'..tail
  end
  local function legacy(path)
    return Library.LEGACY_ROOT..path:sub(#root+1)
  end
  local function read(path)
    local ok,v=pcall(cache.read,cache,rel(path))
    if ok and type(v)=='string' then return v end
    -- v1.8 stores in the compatibility overlay; old non-sandbox copies may
    -- reside at the historical native path. Neither source is removed.
    ok,v=pcall(fs.read,legacy(path))
    if ok and type(v)=='string' then return v end
    ok,v=pcall(Cache.readAt,legacy(path))
    return ok and type(v)=='string' and v or nil
  end
  local function info(path)
    local ok,v=pcall(cache.info,cache,rel(path))
    if ok and v and v.type=='file' then return v end
    ok,v=pcall(fs.getInfo,legacy(path),'file')
    if ok and v then return v end
    local bytes=read(path)
    return bytes and {type='file',size=#bytes} or nil
  end
  local function write(path,bytes)
    if Runtime.safeMode then return nil,'Safe mode: library changes disabled' end
    local ok,yes,err=pcall(cache.write,cache,rel(path),bytes)
    if not ok or not yes then return nil,tostring(err or yes or 'Write failed') end
    return true
  end
  local function remove(path)
    if Runtime.safeMode then return false end
    return cache:delete(rel(path))
  end
  local function mkdir() return true end -- cache:write creates confined parents
  local function decodeIndex(text)
    if type(text)~='string' or #text>256*1024 then return nil end
    local ok,t=pcall(Json.decode,text)
    if not ok or type(t)~='table' or t.format~=1 or type(t.seq)~='number'
        or t.seq~=math.floor(t.seq) or t.seq<0 or t.seq>9007199254740990 or type(t.tracks)~='table' or #t.tracks>Library.MAX_TRACKS then return nil end
    local seen={}
    for _,r in ipairs(t.tracks) do
      if type(r)~='table' or not Library.valid(r.id) or r.id:sub(1,5)~='file:'
          or not formats[r.ext] or type(r.name)~='string' or #r.name>64 or seen[r.id] then return nil end
      seen[r.id]=true
    end
    return t
  end
  local function loadIndex()
    if loaded then return end
    local a=decodeIndex(read(root..'/index-a.json'));local b=decodeIndex(read(root..'/index-b.json'))
    index=(a and b and (a.seq>b.seq and a or b)) or a or b or {format=1,seq=0,tracks={}}
    loaded=true
  end
  local function saveIndex(nextIndex)
    if Runtime.safeMode then return nil,'Safe mode: library changes disabled' end
    nextIndex.format=1;nextIndex.seq=index.seq+1
    local bytes=Json.encode(nextIndex);local path=root..(nextIndex.seq%2==1 and '/index-a.json' or '/index-b.json')
    local made,err=mkdir(root);if not made then return nil,err end
    local ok;ok,err=write(path,bytes);if not ok then return nil,err end
    -- Keep the older slot intact if storage fails midway through writing.
    local verified=decodeIndex(read(path))
    if not verified or verified.seq~=nextIndex.seq then return nil,'Library index could not be verified' end
    index=verified;api.revision=api.revision+1;return true
  end
  function api.files()
    loadIndex();local rows={}
    for _,r in ipairs(index.tracks) do
      local row=copy(r);row.path=root..'/tracks/'..row.id:sub(6)..'.'..row.ext
      row.missing=not info(row.path);rows[#rows+1]=row
    end
    table.sort(rows,function(a,b)if a.name:upper()==b.name:upper() then return a.id<b.id end;return a.name:upper()<b.name:upper()end)
    return rows
  end
  local function findFile(id)
    for _,r in ipairs(api.files()) do if r.id==id then return r end end
  end
  local function sourceFromBytes(bytes,name)
    if not (love.audio and love.audio.newSource and fs.newFileData) then
      return nil,'Audio decoding unavailable on this build'
    end
    -- Two-argument newFileData constructs data, not a sandbox File proxy.
    local made,data=pcall(fs.newFileData,bytes,name)
    if not made or not data then return nil,'Could not prepare audio data' end
    local ok,source=pcall(love.audio.newSource,data,'stream')
    if data.release then pcall(data.release,data) end
    if not ok then return nil,'Cannot decode audio: '..tostring(source) end
    return source
  end
  local function validateAudio(bytes,name)
    local source,err=sourceFromBytes(bytes,name);if not source then return nil,err end
    local good,duration=pcall(source.getDuration,source,'seconds')
    pcall(source.release,source)
    if not good or type(duration)~='number' or duration~=duration or duration<=0 or duration==math.huge then
      return nil,'Audio has no readable duration'
    end
    return duration
  end
  function api.openSource(id)
    local row=findFile(id)
    if not row then return nil,'Imported song is missing' end
    local details=info(row.path)
    if not details or (tonumber(details.size) or 0)>Library.MAX_BYTES then return nil,'Imported song is missing or too large' end
    local bytes=read(row.path)
    if not bytes or #bytes>Library.MAX_BYTES or hash(bytes)~=id:sub(6) then
      return nil,'Imported audio copy is damaged; import the original again'
    end
    return sourceFromBytes(bytes,'autobike-'..id:sub(6)..'.'..row.ext)
  end
  function api.importBytes(bytes,name)
    if Runtime.safeMode then return nil,'Safe mode: import disabled' end
    if type(bytes)~='string' or #bytes<12 then return nil,'Empty or invalid audio file' end
    if #bytes>Library.MAX_BYTES then return nil,'Choose a file no larger than 64 MiB' end
    local ext=magic(bytes,name);if not ext then return nil,'Use MP3, OGG, WAV or FLAC audio' end
    loadIndex()
    local ok,digest=pcall(hash,bytes);if not ok then return nil,'SHA-256 support unavailable' end
    local id='file:'..digest;local existing=findFile(id)
    if existing and not existing.missing then return existing,'ALREADY IMPORTED' end
    if not existing and #index.tracks>=Library.MAX_TRACKS then return nil,'Library full: remove a song first (128 max)' end
    local duration,err=validateAudio(bytes,'autobike-import.'..ext)
    if not duration then return nil,err end
    local wrote
    local dest=root..'/tracks/'..digest..'.'..ext
    wrote,err=write(dest,bytes);if not wrote then return nil,err end
    local check=read(dest)
    if not check or #check~=#bytes or hash(check)~=digest then return nil,'Imported copy failed integrity check' end
    local row={id=id,ext=ext,name=cleanName(name,'IMPORTED '..digest:sub(1,8)),bytes=#bytes,duration=duration}
    local nextIndex=copy(index)
    if existing then
      for i,r in ipairs(nextIndex.tracks) do if r.id==id then row.name=r.name;nextIndex.tracks[i]=row end end
    else nextIndex.tracks[#nextIndex.tracks+1]=row end
    local saved;saved,err=saveIndex(nextIndex)
    if not saved then return nil,err end
    row.path=dest;return row,'IMPORTED'
  end
  function api.importFile(file)
    if Runtime.safeMode then return nil,'Safe mode: import disabled' end
    if not file or not file.read then return nil,'No readable file selected' end
    local ok,size=pcall(file.getSize,file)
    if ok and size and size>Library.MAX_BYTES then return nil,'Choose a file no larger than 64 MiB' end
    if file.isOpen then
      local openOk,isOpen=pcall(file.isOpen,file)
      if openOk and not isOpen then
        local called,yes=pcall(file.open,file,'r')
        if not called or not yes then return nil,'Cannot open selected file' end
      end
    end
    local readOk,bytes=pcall(file.read,file,Library.MAX_BYTES+1)
    local nameOk,name=pcall(file.getFilename,file)
    if file.close then pcall(file.close,file) end
    if not readOk then return nil,'Cannot read selected file' end
    return api.importBytes(bytes,nameOk and name or nil)
  end
  function api.importPath(path)
    return api.picker.readSelected(path)
  end
  function api.rename(id,name)
    loadIndex();if not findFile(id) then return nil,'Song not found' end
    local nextIndex=copy(index)
    for _,r in ipairs(nextIndex.tracks) do if r.id==id then r.name=cleanName(name,'IMPORTED SONG') end end
    return saveIndex(nextIndex)
  end
  function api.remove(id)
    loadIndex();local row=findFile(id);if not row then return nil,'Song not found' end
    local nextIndex=copy(index);nextIndex.tracks={}
    for _,r in ipairs(index.tracks) do if r.id~=id then nextIndex.tracks[#nextIndex.tracks+1]=copy(r) end end
    local ok,err=saveIndex(nextIndex);if not ok then return nil,err end
    -- Delete only this library's hashed copy; never the user's source file.
    remove(row.path);return true
  end
  local function loadTable(bytes,where)
    if type(bytes)~='string' or #bytes>8*1024*1024 then return nil,'Unreadable audio cache' end
    local Serializer=require('src.core.SaveSerializer')
    local ok,t,err=pcall(Serializer.decode,bytes,{allowArray=true,allowComments=true,
      maxBytes=8*1024*1024,maxDepth=48,maxNodes=200000,maxStringBytes=2*1024*1024,
      maxTableEntries=100000,rootName='audio cache'})
    if not ok or type(t)~='table' or type(t.songs)~='table' then
      return nil,'Invalid audio cache: '..tostring(err or t)
    end
    return t
  end

  local function currentEdition() return Version.get() end
  function api.gameData(edition,game)
    if not allowed[edition] then return nil,'Unsupported game' end
    if edition==currentEdition() and game and game.data and game.data.audio then return game.data end
    if foreign[edition] then return foreign[edition] end
    local prefix=Version.cachePrefix(edition)
    local metadata=Cache.readAt(prefix..'data/generated/audio.lua')
    local audio,err=loadTable(metadata,prefix..'data/generated/audio.lua');if not audio then return nil,'IMPORT '..edition:upper()..' IN THE LAUNCHER FIRST' end
    if audio.programFile~='assets/generated/audio/programs.bin' or type(audio.bankOrder)~='table'
        or #audio.bankOrder<1 or #audio.bankOrder>128 then return nil,'Unsupported sound-program cache' end
    local banks,seen={},{}
    for _,bank in ipairs(audio.bankOrder) do
      if type(bank)~='number' or bank<0 or bank>1023 or bank~=math.floor(bank) or seen[bank] then return nil,'Invalid sound-program bank list' end
      seen[bank]=true;banks[#banks+1]=bank
    end
    local programs=Cache.readAt(prefix..audio.programFile)
    if type(programs)~='string' or #programs~=#banks*16384 then return nil,'Sound-program cache incomplete' end
    -- The engine's bank cache is keyed by programFile, NOT game or prefix.
    -- Use a unique immutable file per edition+content to avoid bank collisions
    -- while the active area's soundtrack is playing from another cartridge.
    local digest=hash(programs);local file=root..'/cache/'..edition..'-'..digest..'.bin'
    local ok;ok,err=mkdir(root..'/cache');if not ok then return nil,err end
    local present=cache:read(rel(file))
    if not present or #present~=#programs or hash(present)~=digest then
      ok,err=write(file,programs);if not ok then return nil,err end
      local checked=read(file)
      if not checked or #checked~=#programs or hash(checked)~=digest then return nil,'Music cache copy could not be verified' end
    end
    audio.programFile=file;audio.programPrefix=nil
    foreign[edition]={audio=audio};return foreign[edition]
  end
  function api.editions(game)
    local rows={}
    for _,edition in ipairs(editions) do
      local present=edition==currentEdition() and game and game.data and game.data.audio
      if not present then present=Cache.existsAt(Version.cachePrefix(edition)..'data/generated/audio.lua') end
      rows[#rows+1]={id=edition,label=edition:upper(),available=not not present}
    end
    return rows
  end
  function api.gameSongs(edition,game)
    local data,err=api.gameData(edition,game);if not data then return nil,err end
    local rows={}
    for label,def in pairs(data.audio.songs) do
      if type(label)=='string' and label:match('^[%w_]+$') and #label<192 and type(def)=='table'
          and label:lower()~='music_nothing' and (def.chip or def.file or (def.bank and def.address)) then
        rows[#rows+1]={id='game:'..edition..':'..label,name=Library.title(label),label=label,edition=edition}
      end
    end
    table.sort(rows,function(a,b)if a.name==b.name then return a.id<b.id end;return a.name<b.name end)
    return rows
  end
  function api.resolve(id,game)
    if id=='original' then return nil end
    if not Library.valid(id) then return nil,'Invalid selected song' end
    if id:sub(1,5)=='file:' then
      local row=findFile(id)
      if not row or row.missing then return nil,'Selected audio file is missing; original theme will play' end
      return {key=id,label=row.name,data={audio={}},def={file=row.path},custom=true,kind='file',
        openSource=function()return api.openSource(id)end}
    end
    local edition,label=id:match('^game:([a-z]+):([%w_]+)$')
    local data,err=api.gameData(edition,game);if not data then return nil,err end
    local def=data.audio.songs[label]
    if type(def)~='table' then return nil,'Selected track is missing from the imported game' end
    return {key=id,label=label,data=data,def=def,custom=true,kind='game',edition=edition}
  end
  function api.describe(id)
    if id=='original' then return 'ORIGINAL BICYCLE' end
    local row=id and id:sub(1,5)=='file:' and findFile(id)
    if row then return row.name end
    local e,l=tostring(id):match('^game:([a-z]+):([%w_]+)$')
    return e and (e:upper()..': '..Library.title(l)) or 'MISSING SONG'
  end
  function api.currentEdition()return currentEdition()end
  function api.refresh()foreign={};api.revision=api.revision+1 end
  function api.shutdown()if api.picker then api.picker.cancel()end;api.pending=false;foreign={} end
  function api.attachPicker(picker) api.picker=picker end
  function api.chooseFile()return api.picker.choose()end
  function api.poll(dt)return api.picker.poll(dt)end
  function api.cancelPick()return api.picker.cancel()end
  return api
end
return Library
