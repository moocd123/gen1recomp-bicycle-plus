-- Isolated local-audio library for the FireRed beta. It never touches the
-- stable bicycle_plus cache. Tracks are content-addressed and validated by
-- the host decoder before they are indexed.
local Local={MAX_BYTES=64*1024*1024,MAX_TRACKS=128}
local FORMATS={mp3=true,ogg=true,wav=true,flac=true}
local function copy(t)local o={};for k,v in pairs(t or{})do o[k]=type(v)=='table'and copy(v)or v end;return o end
local function cleanName(name,fallback)
 name=tostring(name or''):match('([^/\\]+)$')or''
 name=name:gsub('%.[%w]+$',''):gsub('[^%w %-%._]',' '):gsub('_',' '):gsub('%s+',' '):match('^%s*(.-)%s*$')
 if name=='' then name=fallback or'IMPORTED SONG'end
 return name:sub(1,64)
end
local function sniff(bytes,name)
 if type(bytes)~='string'then return nil end
 if bytes:sub(1,4)=='RIFF'and bytes:sub(9,12)=='WAVE'then return'wav'end
 if bytes:sub(1,4)=='fLaC'then return'flac'end
 if bytes:sub(1,4)=='OggS'then return'ogg'end
 if bytes:sub(1,3)=='ID3'then return'mp3'end
 local a,b=bytes:byte(1,2);if a==255 and b and b>=224 then return'mp3'end
 local ext=tostring(name or''):lower():match('%.([a-z0-9]+)$');return FORMATS[ext]and ext or nil
end
Local.sniff=sniff
function Local.valid(id)return type(id)=='string'and id:match('^file:%x+$')~=nil and #id==69 and id==id:lower()end
function Local.init(mod,S)
 S=S or{}
 local Runtime=S.Runtime or require('src.mods.Runtime')
 local Json=S.Json or require('src.link.Json')
 local cache=assert(mod.cache,'FireRed beta requires mod.cache')
 local api={revision=0,pending=false,lastImport=nil}
 local index={format=1,seq=0,tracks={}};local loaded=false
 local function digest(bytes)
  if S.hash then return S.hash(bytes)end
  assert(love and love.data and love.data.hash,'SHA-256 support unavailable')
  local raw=love.data.hash('sha256',bytes)
  return(raw:gsub('.',function(c)return('%02x'):format(c:byte())end))
 end
 local function read(path)local ok,v=pcall(cache.read,cache,path);return ok and type(v)=='string'and v or nil end
 local function write(path,bytes)
  if Runtime.safeMode then return nil,'Safe mode: library changes disabled'end
  local ok,yes,err=pcall(cache.write,cache,path,bytes)
  if not ok or not yes then return nil,tostring(err or yes or'Write failed')end
  return true
 end
 local function remove(path)if Runtime.safeMode then return false end;local ok,v=pcall(cache.delete,cache,path);return ok and v~=false end
 local function info(path)
  local ok,v=pcall(cache.info,cache,path);if ok and v and v.type=='file'then return v end
  local b=read(path);return b and{type='file',size=#b}or nil
 end
 local function decodeIndex(text)
  if type(text)~='string'or#text>256*1024 then return nil end
  local ok,t=pcall(Json.decode,text);if not ok or type(t)~='table'or t.format~=1 or type(t.seq)~='number'or t.seq~=math.floor(t.seq)or t.seq<0 or type(t.tracks)~='table'or#t.tracks>Local.MAX_TRACKS then return nil end
  local seen={}
  for _,r in ipairs(t.tracks)do
   if type(r)~='table'or not Local.valid(r.id)or not FORMATS[r.ext]or type(r.name)~='string'or#r.name>64 or seen[r.id]then return nil end
   seen[r.id]=true
  end
  return t
 end
 local function load()
  if loaded then return end
  local a=decodeIndex(read('music/local/index-a.json'));local b=decodeIndex(read('music/local/index-b.json'))
  index=(a and b and(a.seq>b.seq and a or b))or a or b or{format=1,seq=0,tracks={}};loaded=true
 end
 local function save(nextIndex)
  nextIndex.format=1;nextIndex.seq=(index.seq or 0)+1
  local bytes=Json.encode(nextIndex);local path=nextIndex.seq%2==1 and'music/local/index-a.json'or'music/local/index-b.json'
  local ok,err=write(path,bytes);if not ok then return nil,err end
  local checked=decodeIndex(read(path));if not checked or checked.seq~=nextIndex.seq then return nil,'Library index could not be verified'end
  index=checked;api.revision=api.revision+1;return true
 end
 local function pathFor(row)return'music/local/tracks/'..row.id:sub(6)..'.'..row.ext end
 function api.files()
  load();local rows={}
  for _,r in ipairs(index.tracks)do local row=copy(r);row.path=pathFor(row);row.missing=not info(row.path);rows[#rows+1]=row end
  table.sort(rows,function(a,b)local aa,bb=a.name:upper(),b.name:upper();return aa==bb and a.id<b.id or aa<bb end);return rows
 end
 local function find(id)for _,r in ipairs(api.files())do if r.id==id then return r end end end
 local function sourceFromBytes(bytes,name)
  if S.sourceFromBytes then return S.sourceFromBytes(bytes,name)end
  local fs=love and love.filesystem
  if not(love and love.audio and love.audio.newSource and fs and fs.newFileData)then return nil,'Audio decoding unavailable on this build'end
  local ok,data=pcall(fs.newFileData,bytes,name);if not ok or not data then return nil,'Could not prepare audio data'end
  local made,src=pcall(love.audio.newSource,data,'stream');if data.release then pcall(data.release,data)end
  if not made or not src then return nil,'Cannot decode audio: '..tostring(src)end
  return src
 end
 local function duration(bytes,name)
  local src,err=sourceFromBytes(bytes,name);if not src then return nil,err end
  local ok,d=pcall(src.getDuration,src,'seconds');if src.release then pcall(src.release,src)end
  if not ok or type(d)~='number'or d~=d or d<=0 or d==math.huge then return nil,'Audio has no readable duration'end
  return d
 end
 function api.importBytes(bytes,name)
  if Runtime.safeMode then return nil,'Safe mode: import disabled'end
  if type(bytes)~='string'or#bytes<12 then return nil,'Empty or invalid audio file'end
  if#bytes>Local.MAX_BYTES then return nil,'Choose a file no larger than 64 MiB'end
  local ext=sniff(bytes,name);if not ext then return nil,'Use MP3, OGG, WAV or FLAC audio'end
  load();local ok,hash=pcall(digest,bytes);if not ok or type(hash)~='string'or#hash~=64 then return nil,'SHA-256 support unavailable'end
  local id='file:'..hash:lower();local existing=find(id)
  if existing and not existing.missing then return existing,'ALREADY IMPORTED'end
  if not existing and#index.tracks>=Local.MAX_TRACKS then return nil,'Library full: remove a song first (128 max)'end
  local d,err=duration(bytes,'autobike-gen3-import.'..ext);if not d then return nil,err end
  local row={id=id,ext=ext,name=cleanName(name,'IMPORTED '..hash:sub(1,8)),bytes=#bytes,duration=d}
  local path=pathFor(row);local wrote;wrote,err=write(path,bytes);if not wrote then return nil,err end
  local check=read(path);if not check or#check~=#bytes or digest(check)~=hash then return nil,'Imported copy failed integrity check'end
  local nextIndex=copy(index)
  if existing then for i,r in ipairs(nextIndex.tracks)do if r.id==id then row.name=r.name;nextIndex.tracks[i]=copy(row)end end
  else nextIndex.tracks[#nextIndex.tracks+1]=copy(row)end
  local saved;saved,err=save(nextIndex);if not saved then return nil,err end
  row.path=path;return row,'IMPORTED'
 end
 function api.openSource(id)
  local row=find(id);if not row then return nil,'Imported song is missing'end
  local meta=info(row.path);if not meta or(tonumber(meta.size)or 0)>Local.MAX_BYTES then return nil,'Imported song is missing or too large'end
  local bytes=read(row.path);if not bytes or#bytes>Local.MAX_BYTES or digest(bytes)~=id:sub(6)then return nil,'Imported audio copy is damaged; import the original again'end
  return sourceFromBytes(bytes,'autobike-gen3-'..id:sub(6)..'.'..row.ext)
 end
 function api.resolve(id)
  if not Local.valid(id)then return nil,'Unsupported local song'end
  local row=find(id);if not row or row.missing then return nil,'Imported song is missing'end
  return{kind='file',key=id,name=row.name,row=row,openSource=function()return api.openSource(id)end}
 end
 function api.describe(id)local row=Local.valid(id)and find(id)or nil;return row and row.name:upper()or nil end
 function api.rename(id,name)
  load();if not find(id)then return nil,'Song not found'end
  local nextIndex=copy(index);for _,r in ipairs(nextIndex.tracks)do if r.id==id then r.name=cleanName(name,'IMPORTED SONG')end end
  return save(nextIndex)
 end
 function api.remove(id)
  load();local row=find(id);if not row then return nil,'Song not found'end
  local nextIndex=copy(index);nextIndex.tracks={};for _,r in ipairs(index.tracks)do if r.id~=id then nextIndex.tracks[#nextIndex.tracks+1]=copy(r)end end
  local ok,err=save(nextIndex);if not ok then return nil,err end;remove(row.path);return true
 end
 function api.refresh()loaded=false;index={format=1,seq=0,tracks={}};api.revision=api.revision+1 end
 mod.exports.gen3LocalSongs=api;return api
end
return Local
