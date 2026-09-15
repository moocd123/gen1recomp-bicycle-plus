-- Local music catalogue. No network requests, ROM patching or game switching.
-- The library lives outside the mod install directory so Update All cannot
-- replace imported tracks. Only explicitly selected files / the dedicated
-- inbox and the six already-imported audio caches are read.
local Library = {}
Library.ROOT = 'mod_data/bicycle_plus/music'
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
  local api={revision=0,notice=nil,pending=false}
  local foreign={}; local index={seq=0,tracks={}}; local loaded=false
  local function info(path) local ok,v=pcall(fs.getInfo,path,'file');return ok and v or nil end
  local function anyInfo(path) local ok,v=pcall(fs.getInfo,path);return ok and v or nil end
  local function read(path) local ok,v=pcall(fs.read,path);return ok and v or nil end
  local function mkdir(path)
    local ok,yes,err=pcall(fs.createDirectory,path)
    return ok and yes, ok and err or yes
  end
  local function write(path,bytes)
    local ok,yes,err=pcall(fs.write,path,bytes)
    if not ok or not yes then return nil,tostring(err or yes or 'Write failed') end
    return true
  end
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
  local function validateAudio(path)
    if not (love.audio and love.audio.newSource) then return nil,'Audio decoding unavailable on this build' end
    local ok,source=pcall(love.audio.newSource,path,'stream')
    if not ok then return nil,'Audio format could not be decoded on this device' end
    local good,duration=pcall(source.getDuration,source,'seconds')
    pcall(source.release,source)
    if not good or type(duration)~='number' or duration~=duration or duration<=0 or duration==math.huge then return nil,'Audio has no readable duration' end
    return duration
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
    local made,err=mkdir(root..'/tracks');if not made then return nil,err end
    local stage=root..'/import.'..ext
    local wrote;wrote,err=write(stage,bytes);if not wrote then return nil,err end
    local duration;duration,err=validateAudio(stage)
    fs.remove(stage)
    if not duration then return nil,err end
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
    -- Only a path returned by the native desktop picker calls this method.
    if type(path)~='string' or path:find('%z') or not (io and io.open) then return nil,'Cannot read selected path on this build' end
    local called,f,err=pcall(io.open,path,'rb');if not called or not f then return nil,tostring(err or f) end
    local ok,bytes=pcall(f.read,f,Library.MAX_BYTES+1);pcall(f.close,f)
    if not ok then return nil,'Cannot read selected file' end
    return api.importBytes(bytes,path)
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
    fs.remove(row.path);return true
  end
  -- Portable browser scope: the dedicated inbox and its child folders.
  -- Never enumerate a player's home, saves, installed mods or ROM folders.
  local function inboxRelative(value)
    if type(value)~='string' or #value>1024 or value:find('[\\:%z]')
        or value:sub(1,1)=='/' or value:find('//',1,true) then return nil end
    local count=0
    for part in value:gmatch('[^/]+') do
      count=count+1
      if part=='.' or part=='..' or count>16 then return nil end
    end
    return value:gsub('/$','')
  end
  function api.inbox(relative)
    relative=inboxRelative(relative or '')
    if relative==nil then return {},'Invalid inbox folder' end
    local base=root..'/inbox'
    if not Runtime.safeMode then mkdir(base) end
    local folder=base..(relative~='' and '/'..relative or '')
    local ok,items=pcall(fs.getDirectoryItems,folder)
    if not ok or type(items)~='table' then return {},'Cannot list inbox folder' end
    local rows={}
    for _,name in ipairs(items) do
      if type(name)=='string' and name~='.' and name~='..' and not name:find('[/\\%z]') then
        local child=relative~='' and relative..'/'..name or name
        local path=base..'/'..child;local details=anyInfo(path)
        local ext=name:lower():match('%.([a-z0-9]+)$')
        if details and (details.type=='directory' or (details.type=='file' and formats[ext])) then
          rows[#rows+1]={name=name,relative=child,path=path,directory=details.type=='directory'}
        end
      end
    end
    table.sort(rows,function(a,b)
      if a.directory~=b.directory then return a.directory end
      if a.name:lower()==b.name:lower() then return a.name<b.name end
      return a.name:lower()<b.name:lower()
    end)
    return rows
  end
  function api.importInbox(relative)
    relative=inboxRelative(relative)
    if not relative or relative=='' then return nil,'Invalid inbox file' end
    local parent=relative:match('^(.*)/[^/]+$') or ''
    for _,row in ipairs(api.inbox(parent)) do if row.relative==relative and not row.directory then
      local details=info(row.path)
      if not details then return nil,'Inbox file no longer exists' end
      if details.size>Library.MAX_BYTES then return nil,'Choose a file no larger than 64 MiB' end
      return api.importBytes(read(row.path),row.name)
    end end
    return nil,'Inbox file not found'
  end
  function api.inboxPath()
    local ok,dir=pcall(fs.getSaveDirectory)
    return ok and type(dir)=='string' and dir..'/'..root..'/inbox' or root..'/inbox'
  end
  function api.copyInboxPath()
    if not (love.system and love.system.setClipboardText) then return nil,'Clipboard unavailable on this build' end
    local ok,err=pcall(love.system.setClipboardText,api.inboxPath())
    return ok,ok and 'INBOX PATH COPIED' or tostring(err)
  end
  function api.openInboxFolder()
    if Runtime.safeMode then return nil,'Safe mode: folder opening disabled' end
    mkdir(root..'/inbox')
    if not (love.system and love.system.openURL) then return nil,'No folder opener on this build' end
    local path=api.inboxPath():gsub('\\','/')
    local uri='file://'..(path:sub(1,1)=='/' and '' or '/')..path:gsub('[^%w%-%._~/:]',function(c)return ('%%%02X'):format(c:byte())end)
    local ok,yes=pcall(love.system.openURL,uri)
    if ok and yes then return true end
    return nil,'Open the music inbox using your platform file manager or storage transfer tool'
  end
  -- Both mobile bridges permit the dedicated mod/baseroms staging location.
  -- It is temporary only; imported audio is copied outside the install tree.
  -- Never fall back to the engine's picked_rom/mod/save destinations.
  function api.chooseFile()
    if Runtime.safeMode then return nil,'Safe mode: import disabled' end
    if api.pending then return nil,'A file selection is already open' end
    mkdir(root)
    if love.system and type(love.system.pickFile)=='function' and type(love.system.pickFileKinds)=='function' then
      local ok,kinds=pcall(love.system.pickFileKinds)
      if ok and type(kinds)=='string' and (','..kinds..','):find(',required_import,',1,true) then
        if info(Library.PENDING..'.part') then return nil,'Previous file is still being copied' end
        api.discardedPick=false
        fs.remove(Library.PENDING)
        local oldMarker=read('pick_complete.flag')
        if oldMarker and oldMarker:find('\n'..Library.PENDING..'\n',1,true) then fs.remove('pick_complete.flag') end
        local flag,flagErr=write(root..'/awaiting.txt','1')
        if not flag then return nil,flagErr end
        local shown,yes=pcall(love.system.pickFile,'required_import',Library.PENDING)
        if shown and yes then api.pending=true;api.notice='CHOOSE AN AUDIO FILE';return 'pending' end
        fs.remove(root..'/awaiting.txt')
      end
    end
    local ok,Picker=pcall(require,'src.core.FilePicker')
    local available,canPick=false,false
    if ok and type(Picker)=='table' and type(Picker.available)=='function' then available,canPick=pcall(Picker.available) end
    if available and canPick then
      local yes,path=pcall(Picker.open,'Import bicycle music',{label='Audio',exts={'mp3','ogg','wav','flac'},tempName='bicycle_plus_audio'})
      if not yes or not path then return 'browser','PICKER CLOSED / UNAVAILABLE' end
      return api.importPath(path)
    end
    return 'browser','NO SYSTEM PICKER ON THIS BUILD'
  end
  function api.poll()
    if Runtime.safeMode or (not api.pending and not api.discardedPick) then return end
    local errorFlag=read('pick_error.flag')
    if errorFlag and errorFlag:find(Library.PENDING,1,true) then
      api.pending=false;api.discardedPick=false;fs.remove(root..'/awaiting.txt');fs.remove('pick_error.flag');api.notice=errorFlag:find('cancelled:',1,true) and 'IMPORT CANCELLED' or 'FILE PICKER ERROR'
      fs.remove(Library.PENDING..'.part')
      return nil,api.notice
    end
    local marker=read('pick_complete.flag')
    if not marker or not marker:find('\n'..Library.PENDING..'\n',1,true) then return end
    local fileInfo=info(Library.PENDING)
    if not fileInfo then return end
    -- Wait for the native completion marker, not merely the preceding rename.
    -- Consume only our own marker, leaving another mod/importer untouched.
    fs.remove('pick_complete.flag')
    api.pending=false;fs.remove(root..'/awaiting.txt')
    if api.discardedPick then api.discardedPick=false;fs.remove(Library.PENDING);return end
    if fileInfo.size>Library.MAX_BYTES then fs.remove(Library.PENDING);api.notice='FILE EXCEEDS 64 MIB';return nil,api.notice end
    local bytes=read(Library.PENDING);fs.remove(Library.PENDING)
    local row,err=api.importBytes(bytes,nil);api.notice=row and ('IMPORTED '..row.name) or err
    return row,err
  end
  function api.cancelPick()
    if api.pending then
      api.pending=false;api.discardedPick=true;write(root..'/awaiting.txt','discard')
    end
  end

  local function loadTable(bytes,where)
    if type(bytes)~='string' or #bytes>4*1024*1024 then return nil,'Audio cache is missing or too large' end
    local at=1
    if not bytes:match('^%s*return%s*{') then return nil,'Expected a generated table' end
    while at<=#bytes do
      local char=bytes:sub(at,at)
      if char:match('%s') then at=at+1
      elseif char=='"' then
        at=at+1;local closed=false
        while at<=#bytes do
          local c=bytes:sub(at,at)
          if c=='\\' then at=at+2
          elseif c=='"' then at=at+1;closed=true;break
          else at=at+1 end
        end
        if not closed then return nil,'Invalid cache string' end
      elseif char:match('[%a_]') then
        local token=bytes:sub(at):match('^[%a_][%w_]*');at=at+#token
        if token~='return' and token~='true' and token~='false' and token~='nil'
            and not bytes:sub(at):match('^%s*=') then return nil,'Executable audio metadata is not permitted' end
      elseif char:match('[%d%-]') then
        local num=bytes:sub(at):match('^%-?%d+%.?%d*[eE]?[+%-]?%d*')
        if not num or not tonumber(num) then return nil,'Invalid cache number' end
        at=at+#num
      elseif char:match('[{}%[%]=,]') then at=at+1
      else return nil,'Unsupported audio metadata token' end
    end
    local chunk,err
    if loadstring then chunk,err=loadstring(bytes,'@'..where);if chunk and setfenv then setfenv(chunk,{}) end
    else chunk,err=load(bytes,'@'..where,'t',{}) end
    if not chunk then return nil,'Invalid audio cache' end
    local ok,t=pcall(chunk)
    if not ok or type(t)~='table' or type(t.songs)~='table' then return nil,'Unreadable audio cache' end
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
    local present=read(file)
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
      return {key=id,label=row.name,data={audio={}},def={file=row.path},custom=true,kind='file'}
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
  function api.shutdown()api.pending=false;foreign={} end
  api.pending=read(root..'/awaiting.txt')=='1'
  api.discardedPick=read(root..'/awaiting.txt')=='discard'
  return api
end
return Library
