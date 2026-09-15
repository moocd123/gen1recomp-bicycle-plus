-- Test-only virtual filesystem/device boundaries; production never uses this.
local T={}
function T.init(engine)
  package.path=engine..'/?.lua;'..package.path
  if not pcall(require,'bit') then package.preload.bit=function()return require('bit32')end end
  local files, dirs={},{}
  local fs={}
  function fs.write(p,s)files[p]=s;return true end
  function fs.read(p) return files[p], files[p] and #files[p] or 'missing' end
  function fs.getInfo(p,kind)
    if files[p] then return{size=#files[p],type='file',modtime=1}end
    if dirs[p] and kind~='file'then return{type='directory'}end
  end
  function fs.createDirectory(p)dirs[p]=true;return true end
  function fs.remove(p)files[p]=nil;return true end
  function fs.getDirectoryItems(p)
    local out,seen={},{};for _,group in ipairs({files,dirs}) do for n in pairs(group)do
      local name=n:sub(1,#p+1)==p..'/' and n:sub(#p+2):match('^([^/]+)')
      if name and not seen[name] then seen[name]=true;out[#out+1]=name end
    end end;return out
  end
  function fs.newFile(path)
    local f={path=path,opened=false}
    function f:getFilename()return self.path end
    function f:isOpen()return self.opened end
    function f:open(mode)self.opened=true;return true end
    function f:getSize()return files[self.path] and #files[self.path] or 0 end
    function f:read(n)local s=files[self.path];return s and s:sub(1,n)or nil end
    function f:close()self.opened=false end
    return f
  end
  fs.getSaveDirectory=function()return'/virtual/save'end
  local audio={sources={}}
  function audio.make(kind)
    local s={kind=kind,volume=1,playing=false,paused=false,position=0,released=false,buffers=0}
    function s:release()self.released=true;self.playing=false end
    function s:stop()self.playing=false;self.position=0;self.buffers=0 end
    function s:pause()self.playing=false;self.paused=true end
    function s:play()if self.failPlay then return false end;assert(not self.released);self.playing=true;self.paused=false;return true end
    function s:isPlaying()return self.playing end
    function s:setVolume(v)self.volume=v end
    function s:getVolume()return self.volume end
    function s:setLooping(v)self.looping=v end
    function s:getDuration()return 120 end
    function s:setFilter(v)self.filter=v end
    function s:getFilter()return self.filter end
    function s:getFreeBufferCount()return 12-self.buffers end
    function s:queue(b)self.buffers=self.buffers+1;return true end
    function s:tell()return self.position end
    function s:seek(v)self.position=v end
    audio.sources[#audio.sources+1]=s;return s
  end
  function audio.newSource(path,kind)
    assert(files[path] and not files[path]:find('CORRUPT',1,true),'decoder rejected file')
    local s=audio.make(kind);s.path=path;return s
  end
  function audio.newQueueableSource()return audio.make('queue')end
  local hasSha,sha=pcall(require,'sha2')
  local function digest(s)
    if hasSha then return sha.digest256(s) end
    -- Test runner fallback only (not shipped in the installable ZIP).
    local path=os.tmpname();local f=assert(io.open(path,'wb'));f:write(s);f:close()
    assert(not path:find("'",1,true))
    local p=assert(io.popen("openssl dgst -sha256 -binary < '"..path.."'"))
    local result=p:read('*a');p:close();os.remove(path);assert(#result==32);return result
  end
  love={filesystem=fs,audio=audio,system={},data={hash=function(alg,s)assert(alg=='sha256');return digest(s)end}}
  T.files,T.dirs,T.fs,T.audio=files,dirs,fs,audio
  T.Runtime=require('src.mods.Runtime')
  package.loaded['src.import.CacheFs']={readAt=fs.read,existsAt=function(p)return fs.getInfo(p)~=nil end}
  package.loaded['src.core.FilePicker']={available=function()return false end}
  return T
end
function T.readDisk(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
return T
