-- Independent GBA soundtrack Sources, available from every game generation.
-- Only read-only cache bytes cross into a private, explicitly permitted compute
-- worker. The main game cannot load Gen3 modules in Gen1/2, and does not try to.
local Module={}
function Module.init(mod)
 local Cache=require('src.import.CacheFs');local Version=require('src.core.GameVersion')
 local Serializer=require('src.core.SaveSerializer');local Runtime=require('src.mods.Runtime')
 local names=assert(load(assert(mod:read('song_names.lua')),'@autobike/song_names'))()
 local worker=assert(mod:read('m4a_worker.lua'))
 local ownerHooks,ownerEvents=Runtime.hooks,Runtime.events
 local packs,sources={},{};local closed=false;local counter=0
 local stamp=tostring(love.timer.getTime()):gsub('[^%w]','_')
 local api={};local supported={firered=true,leafgreen=true,emerald=true}
 local ROOT='data/generated/gba/audio'
 local Reader=assert(load(assert(mod:read('imported_cache.lua')),'@autobike/imported_cache'))().init(mod)
 local Output=assert(load(assert(mod:read('output_mode.lua')),'@autobike/output_mode'))()
 local Json=require('src.link.Json');local activeGame=mod.game
 local mirrors={}
 local function mirror(edition)
  if mirrors[edition]~=nil then return mirrors[edition]or nil end
  local ok,raw=pcall(mod.cache.read,mod.cache,'soundtracks/'..edition..'/latest.json')
  if not ok or type(raw)~='string'or #raw>4096 then mirrors[edition]=false;return nil end
  local yes,info=pcall(Json.decode,raw)
  if not yes or type(info)~='table'or info.edition~=edition or type(info.hash)~='string'
   or #info.hash~=64 or not info.hash:match('^%x+$')then mirrors[edition]=false;return nil end
  mirrors[edition]='soundtracks/'..edition..'/'..info.hash..'/'
  return mirrors[edition]
 end
 local function read(edition,rel)
  if not supported[edition]or type(rel)~='string'or rel:sub(1,#ROOT+1)~=ROOT..'/'
   or rel:find('..',1,true)or rel:find('\\',1,true)then return nil end
  local bytes=Reader.read(edition,rel)
  if bytes then return bytes end
  local base=mirror(edition);if not base then return nil end
  local ok,b=pcall(mod.cache.read,mod.cache,base..rel:sub(#ROOT+2))
  return ok and type(b)=='string'and b or nil
 end
 function api.available(edition)
  return supported[edition]and read(edition,ROOT..'/index.lua')~=nil or false
 end
 -- A native GBA session may reach cache bytes its launcher's mounted lookup
 -- hides after switching to GB. Save a verified private copy while reachable.
 -- The pointer is committed last; incomplete copies are never advertised.
 local function snapshot(edition,p)
  if Runtime.safeMode then return end
  local digest=love.data.hash('sha256',p.indexBytes..p.samples)
  local hash=(digest:gsub('.',function(c)return('%02x'):format(c:byte())end))
  local base='soundtracks/'..edition..'/'..hash..'/'
  if mirror(edition)==base then return end
  local function write(rel,b)
   if not b or #b>67108864 then return false end
   local ok,yes=pcall(mod.cache.write,mod.cache,base..rel,b)
   if not ok or not yes then return false end
   local check,value=pcall(mod.cache.read,mod.cache,base..rel)
   return check and value==b
  end
  if not write('index.lua',p.indexBytes)or not write('samples.bin',p.samples)then return end
  for key,info in pairs(p.index.songs)do
   local id=tonumber(key)
   if id and id>0 and id%1==0 and type(info)=='table'and(info.kind=='bgm'or info.kind=='fanfare')then
    local rel='songs/'..id..'.bin';local bytes=read(edition,ROOT..'/'..rel)
    if not write(rel,bytes)then return end
   end
  end
  local ok,yes=pcall(mod.cache.write,mod.cache,'soundtracks/'..edition..'/latest.json',Json.encode({format=1,edition=edition,hash=hash}))
  if ok and yes then mirrors[edition]=base end
 end
 local function pack(edition)
  if packs[edition]then return packs[edition]end
  local index=read(edition,ROOT..'/index.lua')
  if not index then return nil,'IMPORT '..tostring(edition):upper()..' IN THE LAUNCHER FIRST'end
  local ok,data,err=pcall(Serializer.decode,index,{allowArray=true,allowComments=true,maxBytes=8388608,
    maxDepth=32,maxNodes=2000000,maxString=8388608})
  if not ok or type(data)~='table'or type(data.songs)~='table'then return nil,'Invalid soundtrack index: '..tostring(err or data)end
  local samples=read(edition,ROOT..'/samples.bin')
  if type(samples)~='string'or #samples==0 then return nil,'Incomplete '..edition:upper()..' sound cache'end
  local p={indexBytes=index,index=data,samples=samples,edition=edition};packs[edition]=p;snapshot(edition,p);return p
 end
 function api.data(edition)
  local p,err=pack(edition);if not p then return nil,err end
  if p.data then return p.data end
  local songs={};local known=names[edition=='leafgreen'and'firered'or edition]or{}
  for key,info in pairs(p.index.songs)do
   local id=tonumber(key)
   if id and id>0 and type(info)=='table'and(info.kind=='bgm'or info.kind=='fanfare')then
    local label=known[id]or info.name or('TRACK_'..id)
    label=label:gsub('[^%w_]','_')
    if songs[label]then label=label..'_'..id end
    songs[label]={autobikeM4A=true,songId=id,name=label,edition=edition}
   end
  end
  p.data={audio={songs=songs,generation=3},autobikeEdition=edition};return p.data
 end
 function api.byId(edition,id)
  local d,err=api.data(edition);if not d then return nil,err end
  for label,def in pairs(d.audio.songs)do if def.songId==id then return'game:'..edition..':'..label end end
  return nil,'Song is not in the imported soundtrack'
 end
 function api.open(edition,id)
  if closed or Runtime.safeMode then return nil,'Soundtrack playback disabled'end
  local p,err=pack(edition);if not p then return nil,err end
  id=tonumber(id);local info=p.index.songs[id]
  if not info then return nil,'Unknown soundtrack song'end
  local sequence=read(edition,ROOT..'/songs/'..id..'.bin')
  if not sequence then return nil,'Missing soundtrack sequence'end
  local okThread,Thread=pcall(function()return love.thread end)
  if not okThread or not Thread or not Thread.newThread then return nil,'This build needs background audio (compute) support'end
  counter=counter+1;local base=mod.id..'_m4a_'..stamp..'_'..counter
  local cmd=Thread.getChannel(base..'_cmd');local out=Thread.getChannel(base..'_out');local status=Thread.getChannel(base..'_status')
  local native,thread
  local ok,why=pcall(function()
   native=love.audio.newQueueableSource(44100,16,2,16)
   thread=Thread.newThread(worker);thread:start(base..'_cmd',base..'_out',base..'_status')
  end)
  if not ok then if native then native:release()end;return nil,tostring(why)end
  local s={native=native,thread=thread,kind='m4a',edition=edition,songId=id,playing=false,mono=Output.mono(activeGame),
   released=false,looping=true,position=0,error=nil,rate=44100,volume=1,epoch=1,ready=false,queued=0}
  sources[s]=true
  cmd:push({op='install',index=p.indexBytes,samples=p.samples,sequence=sequence,id=id,epoch=s.epoch,mono=s.mono})
  function s:_fill()
   if self.released then return end
   local note=status:pop()
   while note do
    if note.error then self.error=note.error;self.playing=false;self.native:stop()
    elseif note.epoch==self.epoch then
     if note.ready then self.ready=true end
     if note.ended then self.ended=true end
    end
    note=status:pop()
   end
   local fail=self.thread:getError();if fail then self.error=fail;self.playing=false end
   if self.error then return end
   local good,reason=pcall(function()
    while self.native:getFreeBufferCount()>0 do
     local buffer=out:pop();if not buffer then break end
     if buffer.epoch==self.epoch then
      if self.mono then Output.fold(buffer.data)end
      assert(self.native:queue(buffer.data),'GBA queue rejected audio');self.queued=self.queued+buffer.data:getSampleCount()
     end
     buffer.data:release()
    end
    if self.playing and self.native:getFreeBufferCount()<16 and not self.native:isPlaying()then self.native:play()end
   end)
   if not good then self.error=tostring(reason);self.playing=false end
  end
  function s:setMono(value)
   value=not not value
   if self.mono~=value then self.mono=value;cmd:push({op='mix',mono=value})end
  end
  function s:play()
   assert(not self.released,'Released soundtrack source')
   if not self.playing then self.playing=true;cmd:push({op='resume'})end
   self:_fill();if self.error then error(self.error,0)end
   if self.native:getFreeBufferCount()<16 then self.native:play()end
   return true
  end
  function s:pause()
   if not self.released then self.playing=false;self.native:pause();cmd:push({op='pause'})end
  end
  function s:stop()
   if self.released then return end
   self.playing=false;self.native:stop();self.position=0;self.queued=0;self.epoch=self.epoch+1
   cmd:push({op='reset',epoch=self.epoch})
   out:clear()
  end
  function s:release()
   if self.released then return end
   self.released=true;self.playing=false;sources[self]=nil;cmd:push({op='quit'})
   pcall(self.native.stop,self.native);self.native:release()
   -- Worker mixes bounded 4096-sample batches and checks quit each batch.
   -- Waiting here guarantees no background thread survives the game session.
   pcall(self.thread.wait,self.thread);cmd:clear();out:clear();status:clear()
   self.thread:release()
  end
  function s:isPlaying()
   self:_fill();if self.error then error(self.error,0)end
   return not self.released and self.playing and self.native:isPlaying()
  end
  function s:setVolume(v)self.volume=v;self.native:setVolume(v)end
  function s:getVolume()return self.native:getVolume()end
  function s:setFilter(...)return self.native:setFilter(...)end
  function s:getFilter()return self.native:getFilter()end
  function s:setPitch(v)return self.native:setPitch(v)end
  function s:getPitch()return self.native:getPitch()end
  function s:setLooping(v)self.looping=not not v;cmd:push({op='loop',value=self.looping})end
  function s:isLooping()return self.looping end
  function s:tell(unit)return unit=='samples'and math.floor(self.position*self.rate)or self.position end
  function s:getDuration()return math.huge end
  function s:seek(offset)
   if tonumber(offset)~=0 then error('Sequenced soundtrack seeking supports restart only',0)end
   local play=self.playing;self:stop();if play then self:play()end
  end
  return s
 end
 function api.update(dt)
  if closed then return end
  if Runtime.hooks~=ownerHooks or Runtime.events~=ownerEvents then api.dispose();return end
  for s in pairs(sources)do
   if not s.released then
    s:setMono(Output.mono(activeGame))
    if s.playing and s.native:isPlaying()then s.position=s.position+math.max(0,math.min(.25,tonumber(dt)or 0))end
    s:_fill()
   end
  end
 end
 function api.refresh()packs={};mirrors={}end
 function api.status()
  local n,errors,ready,queued=0,{},0,0
  for s in pairs(sources)do n=n+1;if s.error then errors[#errors+1]=s.error end;if s.ready then ready=ready+1 end;queued=queued+s.queued end
  return{sources=n,errors=errors,ready=ready,queuedSamples=queued}
 end
 function api.dispose()
  if closed then return end;closed=true
  local all={};for s in pairs(sources)do all[#all+1]=s end
  for _,s in ipairs(all)do s:release()end;packs={}
 end
 mod.hooks:wrap('core.update',function(next,game,dt)activeGame=game;local result=next(game,dt);api.update(dt);return result end,-1000)
 require('src.render.Assets').register({release=api.dispose})
 return api
end
return Module
