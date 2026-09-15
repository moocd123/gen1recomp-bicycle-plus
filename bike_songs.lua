-- Bicycle Plus song catalogue and installation-scoped personal audio library.
-- No music is shipped. Cross-game data comes only from engine-validated imports.
local Songs={MAX_BYTES=64*1024*1024,MAX_FILES=128}
local EDITIONS={'red','blue','yellow','gold','silver','crystal'}
local EDITION={red=true,blue=true,yellow=true,gold=true,silver=true,crystal=true}
local EXT={mp3=true,ogg=true,wav=true}
local function clean(text,fallback)
  local s=tostring(text or ''):gsub('.*[/\\]',''):gsub('%.[%a%d]+$','')
  s=s:gsub('[^%w %-%._]',' '):gsub('%s+',' '):match('^%s*(.-)%s*$')
  return s~='' and s:sub(1,48) or (fallback or 'IMPORTED AUDIO')
end
function Songs.canonical(id)
  if id=='original' then return id end
  if type(id)~='string' or #id>220 then return nil end
  local v,label=id:match('^game:([a-z]+):([%w_%-]+)$')
  if (v=='current' or EDITION[v]) and label then return id end
  local hash=id:match('^file:(%x+)$')
  if hash and #hash==64 then return 'file:'..hash:lower() end
end
function Songs.title(label)
  return clean(tostring(label):gsub('^Music_',''):gsub('^MUSIC_','')
    :gsub('(%l)(%u)','%1 %2'):gsub('_',' '),'UNKNOWN SONG'):upper()
end
function Songs.sniff(bytes)
  if type(bytes)~='string' then return nil end
  if bytes:sub(1,4)=='RIFF' and bytes:sub(9,12)=='WAVE' then return 'wav' end
  if bytes:sub(1,4)=='OggS' then return 'ogg' end
  if bytes:sub(1,3)=='ID3' then return 'mp3' end
  local a,b=bytes:byte(1,2)
  if a==255 and b and b>=224 and math.floor(b/2)%4~=0 then return 'mp3' end
end
local function release(obj)if (type(obj)=='table' or type(obj)=='userdata') and obj.release then pcall(obj.release,obj)end end
function Songs.init(mod,settings)
  local Json=require('src.link.Json')
  local GameVersion=require('src.core.GameVersion')
  local Runtime=require('src.mods.Runtime')
  local api={revision=0,error=nil,notice=nil,pending=nil}
  local index,foreign,files=nil,{},{}
  local cache=mod.cache
  local function decode(text)
    if type(text)~='string' or #text>128*1024 then return nil end
    local ok,v=pcall(Json.decode,text)
    if not ok or type(v)~='table' or v.format~=1 or type(v.tracks)~='table' or #v.tracks>Songs.MAX_FILES then return nil end
    local seen={}
    for _,r in ipairs(v.tracks)do
      if type(r)~='table' or type(r.id)~='string' or not r.id:match('^[0-9a-f]+$') or #r.id~=64 or seen[r.id]
        or not EXT[r.ext] or type(r.name)~='string' or #r.name>48
        or type(r.bytes)~='number' or r.bytes<=0 or r.bytes>Songs.MAX_BYTES then return nil end
      seen[r.id]=true
    end
    return v
  end
  local function loadIndex()
    if index then return index end
    local text=cache and cache:read('music/library.json')
    local old=decode(text)
    if not old then old=decode(cache and cache:read('music/library.bak'))end
    -- Never overwrite corrupt metadata with an empty catalogue silently.
    if not old and text then return nil,'Music library metadata is damaged; restore its backup.' end
    index=old or {format=1,tracks={}}
    return index
  end
  local function commit(nextIndex)
    if Runtime.safeMode then return false,'Safe mode: changes disabled.' end
    local old,err=loadIndex();if not old then return false,err end
    local ok,why=cache:write('music/library.bak',Json.encode(old))
    if not ok then return false,why end
    local text=Json.encode(nextIndex)
    ok,why=cache:write('music/library.json',text)
    if not ok or cache:read('music/library.json')~=text then return false,why or 'Could not save music library.'end
    index=nextIndex;api.revision=api.revision+1;return true
  end
  local function find(id)
    local v,err=loadIndex();if not v then return nil,err end
    for _,r in ipairs(v.tracks)do if 'file:'..r.id==id then return r end end
  end
  local function copyIndex()
    local old,err=loadIndex();if not old then return nil,err end
    local v={format=1,tracks={}}
    for _,r in ipairs(old.tracks)do
      local n={};for k,x in pairs(r)do n[k]=x end;v.tracks[#v.tracks+1]=n
    end
    return v
  end
  local function filepath(r)return 'music/'..r.id..'.'..r.ext end
  function api.myAudio()
    local v,err=loadIndex();if not v then return {},err end
    local out={}
    for _,r in ipairs(v.tracks)do
      out[#out+1]={id='file:'..r.id,title=r.name:upper(),name=r.name,bytes=r.bytes}
    end
    table.sort(out,function(a,b)if a.title==b.title then return a.id<b.id end;return a.title<b.title end)
    return out
  end
  function api.rename(id,name)
    if not find(id) then return false,'Audio not found.'end
    local v,err=copyIndex();if not v then return false,err end
    for _,r in ipairs(v.tracks)do if 'file:'..r.id==id then r.name=clean(name,r.name)end end
    return commit(v)
  end
  function api.remove(id)
    local row=find(id);if not row then return false,'Audio not found.'end
    local v,err=copyIndex();if not v then return false,err end
    for i,r in ipairs(v.tracks)do if 'file:'..r.id==id then table.remove(v.tracks,i);break end end
    local ok,why=commit(v);if not ok then return false,why end
    if files[id]then release(files[id].fileData);files[id]=nil end
    -- Delete only this library's copy; never the user-selected original file.
    cache:delete(filepath(row));return true
  end
  function api.importBytes(bytes,name)
    if Runtime.safeMode then return nil,'Safe mode: importing disabled.'end
    if type(bytes)~='string' or #bytes<12 or #bytes>Songs.MAX_BYTES then return nil,'Use a non-empty file under 64 MiB.'end
    local ext=Songs.sniff(bytes);if not ext then return nil,'Choose MP3, Ogg Vorbis or WAV audio.'end
    if not(cache and love and love.data and love.filesystem and love.sound and love.audio)then return nil,'Audio import is unavailable in this build.'end
    local hash=love.data.encode('string','hex',love.data.hash('sha256',bytes)):lower()
    local id='file:'..hash;local row=find(id)
    if row and cache:exists(filepath(row))then api.notice='Already imported: '..row.name;return id end
    local nextIndex,err=copyIndex();if not nextIndex then return nil,err end
    if not row and #nextIndex.tracks>=Songs.MAX_FILES then return nil,'Library full (128 songs). Remove one first.'end
    local fileData=love.filesystem.newFileData(bytes,'bicycle_song.'..ext)
    local ok,decoder=pcall(love.sound.newDecoder,fileData)
    if not ok then release(fileData);return nil,'Audio could not be decoded. Try standard MP3, Vorbis or PCM WAV.'end
    local decoded,chunk=pcall(decoder.decode,decoder)
    local usable=decoded and chunk and chunk:getSampleCount()>0
    release(chunk);release(decoder)
    if not usable then release(fileData);return nil,'Audio has no decodable samples.'end
    -- Validate the streaming source without playing, or decoding an entire song.
    local made,source=pcall(love.audio.newSource,fileData,'stream')
    release(source);release(fileData)
    if not made then return nil,'This audio format cannot be streamed on this device.'end
    local record={id=hash,ext=ext,name=clean(name,'IMPORTED '..hash:sub(1,6):upper()),bytes=#bytes}
    local written,why=cache:write(filepath(record),bytes)
    if not written then return nil,why or 'Could not copy audio.'end
    local check=cache:info(filepath(record))
    if check and check.size and check.size~=#bytes then return nil,'Incomplete audio copy.'end
    if row then
      for i,r in ipairs(nextIndex.tracks)do if r.id==hash then nextIndex.tracks[i]=record end end
    else nextIndex.tracks[#nextIndex.tracks+1]=record end
    local saved,saveErr=commit(nextIndex)
    if not saved then return nil,saveErr end
    api.notice='Imported '..record.name;return id
  end
  local function inactive(version)
    if foreign[version] then return foreign[version] end
    if not(mod.datasets and mod.datasets.open)then return nil,'Imported-game access unavailable.'end
    local view,why=mod.datasets:open(version)
    if not view then return nil,'Import '..version:upper()..' in the launcher first.'end
    local registry=view.content and view.content.audio
    if not registry then return nil,'Imported game has no audio registry.'end
    local a={}
    for _,key in ipairs({'generation','songs','programFile','bankOrder','waveBanks','noiseHeaders','drumkits'})do a[key]=registry:get(key)end
    if type(a.songs)~='table' or type(a.programFile)~='string' then return nil,'Imported audio data is missing.'end
    local info=view.assets:info(a.programFile)
    if not info then return nil,'Imported sound programs are missing; reimport that ROM.'end
    -- Unique full paths prevent ChipSynth's programFile-only bank cache from
    -- confusing two editions that both call their file assets/.../programs.bin.
    local path=view.assets:path(a.programFile)
    if type(path)~='string' or path==''then return nil,'Imported audio path unavailable.'end
    a.programFile=path;a.programPrefix=nil
    for _,def in pairs(a.songs)do
      if type(def)=='table' then
        for _,key in ipairs({'file','loopFile'})do if def[key]then
          local ok,p=pcall(view.assets.path,view.assets,def[key]);def[key]=ok and p or nil
        end end
      end
    end
    foreign[version]={audio=a};return foreign[version]
  end
  function api.gameList(game,version)
    local data,err
    if version=='current' then data=game and game.data else data,err=inactive(version)end
    local out={}
    for label,def in pairs(data and data.audio and data.audio.songs or {})do
      if type(label)=='string' and label:match('^[%w_%-]+$')and type(def)=='table'
        and (def.file or def.chip or (def.address and def.bank))then
        out[#out+1]={id='game:'..(version=='current' and GameVersion.get() or version)..':'..label,title=Songs.title(def.name or label),label=label}
      end
    end
    table.sort(out,function(a,b)if a.title==b.title then return a.label<b.label end;return a.title<b.title end)
    return out,err
  end
  function api.editions(game)
    local out={}
    if not(mod.datasets and mod.datasets.open)then return out end
    for _,v in ipairs(EDITIONS)do
      -- Opening the bounded dataset view checks the engine-owned import marker,
      -- never switches GameVersion or mounts another game over the running one.
      local ok,view=pcall(mod.datasets.open,mod.datasets,v)
      out[#out+1]={version=v,title=v:upper(),available=ok and view~=nil}
    end
    return out
  end
  function api.resolve(game,id)
    id=Songs.canonical(id)
    if not id or id=='original' then return nil end
    if id:sub(1,5)=='file:'then
      local r,why=find(id);if not r then return nil,why or 'Selected local audio was removed.'end
      if not cache:exists(filepath(r))then return nil,'Selected local audio is missing.'end
      local f=files[id]
      if not f then
        -- Retain only one compressed personal file in memory, not the library.
        for key,entry in pairs(files)do release(entry.fileData);files[key]=nil end
        local bytes=cache:read(filepath(r))
        if not bytes or #bytes~=r.bytes or #bytes>Songs.MAX_BYTES then return nil,'Stored audio is incomplete.'end
        f={fileData=love.filesystem.newFileData(bytes,'song.'..r.ext)}
        f.def={file=f.fileData};f.data={audio={songs={[id]=f.def}}};files[id]=f
      end
      return {key=id,label=id,title=r.name,data=f.data,def=f.def,custom=true}
    end
    local version,label=id:match('^game:([a-z]+):(.+)$')
    local data,err
    if version=='current' or version==GameVersion.get()then data=game and game.data else data,err=inactive(version)end
    if not data then return nil,err end
    local def=data.audio and data.audio.songs and data.audio.songs[label]
    if not def then return nil,'Selected game song is unavailable.'end
    return {key=id,label=label,title=Songs.title(label),data=data,def=def,custom=true}
  end
  function api.title(id)
    if id=='original' or not Songs.canonical(id)then return 'ORIGINAL BICYCLE' end
    local r=find(id);if r then return r.name:upper()end
    local v,label=id:match('^game:([a-z]+):(.+)$')
    return label and ((v=='current' and '' or v:upper()..' - ')..Songs.title(label)) or 'MISSING LOCAL AUDIO'
  end
  function api.clear()
    for key,f in pairs(files)do release(f.fileData);files[key]=nil end
    foreign={};api.revision=api.revision+1
  end
  api.canonical=Songs.canonical;api.cleanName=clean
  return api
end
return Songs
