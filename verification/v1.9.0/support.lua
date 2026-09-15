-- Native sandbox/compat and scoped-cache bridge around an in-memory disk.
-- Device and decoder doubles are explicit; a separate LÖVE test uses codecs.
local H={}
function H.init(engine)
  local T=dofile('verification/v1.8.0/test_support.lua').init(engine)
  local oldSource=T.audio.newSource
  function T.fs.newFileData(bytes,name)
    assert(type(bytes)=='string' and type(name)=='string')
    return {bytes=bytes,name=name,release=function(self)self.released=true end}
  end
  function T.audio.newSource(input,kind)
    if type(input)=='table' and input.bytes then
      assert(not input.bytes:find('CORRUPT',1,true),'decoder rejected data')
      local s=T.audio.make(kind);s.dataBytes=input.bytes;s.path=input.name;return s
    end
    return oldSource(input,kind)
  end
  T.fs.getWorkingDirectory=function()return '/tmp'end
  T.fs.getSource=function()return '/tmp'end
  T.fs.isFused=function()return false end
  T.fs.getSourceBaseDirectory=function()return '/tmp'end
  -- Exact shape of native File: seek/read ranges, used by scoped APIs.
  local newFile=T.fs.newFile
  function T.fs.newFile(path,mode)
    local f=newFile(path);f.offset=0
    function f:seek(offset)self.offset=offset;return true end
    function f:read(n)
      local bytes=T.files[self.path]
      if not bytes then return nil,'missing'end
      local chunk=bytes:sub(self.offset+1,n and self.offset+n or -1)
      self.offset=self.offset+#chunk;return chunk
    end
    if mode then f:open(mode)end
    return f
  end
  local SaveData=require('src.core.SaveData')
  SaveData.persistenceFs=function(fs)return fs end -- no physical portable disk
  local Cache=require('src.import.CacheFs')
  Cache.prefix='';Cache.write=function(path,bytes)return T.fs.write(Cache.prefix..path,bytes)end
  Cache.remove=function(path)return T.fs.remove(Cache.prefix..path)end
  Cache.root=function()return nil end
  T.Cache=Cache
  local nativePickerPath=''
  function H.load(mod,name)
    return assert(require('src.mods.Sandbox').compile(T.readDisk(name..'.lua'),'@'..name,mod.env))()
  end
  function T.mod(game)
    local mod={id='bicycle_plus',path='mods/bicycle_plus',manifest={id='bicycle_plus',path='mods/bicycle_plus',optional_imports={}},game=game}
    local _,cache=require('src.mods.ImportAccess').new(mod.manifest,T.fs);mod.cache=cache
    function mod:read(name)
      local onDisk=T.files[self.path..'/'..name]
      if onDisk then return onDisk end
      local f=io.open(name,'rb');if not f then return nil end;local b=f:read('*a');f:close();return b
    end
    local compat=require('src.mods.LegacyCompat').new({modId=mod.id,modPath=mod.path,fs=T.fs,game=function()return game end})
    mod.env=require('src.mods.Sandbox').envFor({modId=mod.id,permissions={engine_internals=true,filesystem=true},compat=compat})
    return mod
  end
  T.load=H.load
  return T
end
return H
