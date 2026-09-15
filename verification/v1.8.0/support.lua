-- Shared software boundaries for song tests. Not real codecs/OS file dialogs.
local T={count=0,files={},sources={},assetsCallbacks={}}
function T.check(v,m)assert(v,m);T.count=T.count+1 end
function T.eq(a,b,m)T.check(a==b,(m or 'mismatch')..': '..tostring(a)..' / '..tostring(b))end
local noop=function()end
T.noop=noop
function T.read(path)local f=assert(io.open(path,'rb'));local b=f:read('*a');f:close();return b end
function T.fs()
 return {read=function(p)return T.files[p]end,write=function(p,b)T.files[p]=b;return true end,
 getInfo=function(p)if T.files[p]then return{size=#T.files[p],type='file'}end end,
 remove=function(p)T.files[p]=nil;return true end,createDirectory=function()return true end,
 getDirectoryItems=function(p)local out={};for k in pairs(T.files)do local n=k:match('^'..p..'/([^/]+)$');if n then out[#out+1]=n end end;table.sort(out);return out end}
end
function T.source(path,kind)
 if type(path)=='string' and path:find('badfile',1,true)then error('bad audio fixture')end
 local s={path=path,kind=kind,volume=1,filter=nil,playing=false,queued=0,plays=0,pos=0}
 function s:setVolume(v)self.volume=v end;function s:getVolume()return self.volume end
 function s:setFilter(f)self.filter=f end;function s:getFilter()return self.filter end
 function s:setLooping(v)self.loop=v end;function s:isLooping()return self.loop end
 function s:play()assert(not self.released,'play released source');self.playing=true;self.plays=self.plays+1;return true end
 function s:pause()self.playing=false end;function s:stop()self.playing=false;self.pos=0 end
 function s:release()self.released=true;self.playing=false end
 function s:isPlaying()return self.playing end
 function s:getFreeBufferCount()return 4-self.queued end
 function s:queue(b)self.queued=self.queued+1;return true end
 function s:seek(p)self.pos=p end;function s:tell()return self.pos end
 function s:getDuration()return 20 end;function s:setPitch()end
 T.sources[#T.sources+1]=s;return s
end
function T.install()
 T.files={};T.sources={};T.hashIds={};T.assetsCallbacks={}
 love={audio={newSource=T.source,newQueueableSource=function()return T.source('chip','queue')end},
  data={hash=function(kind,bytes)
    local k=kind..bytes;if not T.hashIds[k]then T.hashIds[k]=#T.hashIds+1;T.hashIds[#T.hashIds+1]=k end
    return string.format('%0'..(kind=='sha256'and 64 or 32)..'x',T.hashIds[k])
   end,encode=function(_,_,v)return v end},
  filesystem={newFileData=function(bytes,name)return{bytes=bytes,name=name,release=function(self)self.released=true end}end},
  sound={newDecoder=function(fd)
    assert(not fd.bytes:find('BAD',1,true),'bad codec')
    return{decode=function()return{getSampleCount=function()return 32 end,release=noop}end,release=noop}
   end},graphics={setColor=noop,rectangle=noop,getDimensions=function()return 160,144 end},
  system={getOS=function()return T.os or'Linux'end},timer={getTime=function()return 1 end}}
 package.loaded['src.render.Assets']={resolve=function(p)return p end,register=function(f)T.assetsCallbacks[#T.assetsCallbacks+1]=f end}
 package.loaded['src.render.Font']={drawBox=noop,draw=noop,drawCode=noop}
 package.loaded['src.core.SaveData']={persistenceFs=function()return T.fs()end,gameFolders=function()return{}end}
 local R=require('src.mods.Runtime');local E=require('src.mods.Events').new();local H=require('src.mods.Hooks').new()
 R.install(E,H,{});R.safeMode=false
 T.events,T.hooks=E,H
 return R
end
function T.mod()
 local m={id='bicycle_plus',path='mods/bicycle_plus',exports={},content={screens={}},cache={},hooks={},events={},options={}}
 for _,k in ipairs({'read','write','getInfo','remove'})do end
 function m.cache:read(p)return T.files['mod_cache/bicycle_plus/'..p]end
 function m.cache:write(p,b)T.files['mod_cache/bicycle_plus/'..p]=b;return true end
 function m.cache:delete(p)T.files['mod_cache/bicycle_plus/'..p]=nil;return true end
 function m.cache:info(p)local b=self:read(p);return b and{type='file',size=#b}end
 function m.cache:exists(p)return self:info(p)~=nil end
 function m:read(p)return T.files[self.path..'/'..p]or T.read(p)end
 function m:list(p)return T.fs().getDirectoryItems(self.path..'/'..p)end
 function m:info(p)return T.fs().getInfo(self.path..'/'..p)end
 function m.hooks:wrap(k,f,p)return T.hooks:wrap(k,f,p,'bicycle_plus')end
 function m.events:on(k,f,p)return T.events:on(k,f,p,'bicycle_plus')end
 return m
end
return T
