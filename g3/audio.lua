-- Separate GBA bicycle bus. Native area/battle/fanfare owns its existing worker.
-- Normal options remain normal options; routing never writes a gain/filter.
local M={}
function M.init(mod,settings,library)
 local Native=require('src.core.game3.audio')
 local P=require('src.core.game3.player')
 local Battle=require('src.core.game3.battle')
 local Version=require('src.core.GameVersion')
 local Bus=require('src.mods.Runtime')
 local Chip=require('src.core.ChipSynth')
 local Output=assert(load(assert(mod:read('output_mode.lua')),'@autobike/output_mode'))()
 local hooks,events=Bus.hooks,Bus.events
 local bindings,tracked={},setmetatable({},{__mode='k'})
 local game=mod.game
 local ride,preview,closed=nil,nil,false
 local lastError,retry= nil,0
 local routeDepth=0
 local clock=0
 local applied={}
 local api={}
 local function get(k)return settings.get(k,game)end
 local function clamp(n,hi,default)n=tonumber(n);if not n or n~=n then n=default end;return math.max(0,math.min(hi,math.floor(n)))end
 local function active()return not closed and not Bus.safeMode and Bus.hooks==hooks and Bus.events==events
   and (Version.get()=='firered'or Version.get()=='leafgreen')end
 local function call(s,method,...)
  if not(s and s[method])then return false end
  return pcall(s[method],s,...)
 end
 local function release(layer)
  if layer then call(layer.source,'stop');call(layer.source,'release')end
 end
 local FILTER={.4,.16,.064}
 local function setFilter(src,value)
  if FILTER[value]then return call(src,'setFilter',{type='lowpass',volume=1,highgain=FILTER[value]})end
  return call(src,'setFilter')
 end
 local function same(a,b)
  if type(a)~='table'or type(b)~='table'then return a==b end
  for k,v in pairs(a)do if b[k]~=v then return false end end
  for k in pairs(b)do if a[k]==nil then return false end end;return true
 end
 local function restoreFilter(s,e)
  if not e.applied then return end
  local ok,now=call(s,'getFilter')
  if ok and not same(now,e.last)then e.applied=false;return end
  if e.original then call(s,'setFilter',e.original)else call(s,'setFilter')end
  e.applied=false
 end
 local function sfxFilter(s,level)
  if not s then return end
  local e=tracked[s];if not e then e={};tracked[s]=e end
  if level==0 then restoreFilter(s,e);return end
  if not e.applied then local _,old=call(s,'getFilter');e.original=old end
  setFilter(s,level);local _,now=call(s,'getFilter');e.last=now;e.applied=true
 end
 local function blocked()
  if not game or game.phase~='field'or not game.session then return true end
  if Battle.isActive and Battle.isActive()then return true end
  local transition=package.loaded['src.core.game3.battle_transition']
  if transition and transition.isActive and transition.isActive()then return true end
  return false
 end
 local function onBike()return not blocked()and P.biking==true and not P.surfing and not P.surfHopping end
 local function mapCue()
  if not onBike()then return false end
  if Native._savedSong and Native._savedSong~=Native.MUS_CYCLING then return false end
  local current=Native.currentSong and Native.currentSong()or Native._currentSong
  local id=type(current)=='table'and current.id or current
  local base=Native._mapSong
  local pending=Native._fadeOut and Native._fadeOut.nextSong
  return base~=nil and (id==base or id==Native.MUS_CYCLING or pending==base or id==nil)
 end
 local function profile()
  return active()and mapCue()and not Native._fanfareActive
 end
 local function normal()
  local o=game and(game.options or(game.save and game.save.options))or{}
  return clamp(o.musicVol,7,7),clamp(o.musicFilter,3,0),clamp(o.sfxVol,7,7),clamp(get('sfx_filter'),3,0)
 end
 local function value(k,native,max,cycling)
  local v=tonumber(get(k))
  return cycling and v and v>=0 and clamp(v,max,native)or native
 end
 local function sync(muteArea)
  if closed then return end
  local mv,mf,sv,sf=normal();local cycling=profile()
  local av=value('riding_area_volume',mv,7,cycling)
  local af=value('riding_area_filter',mf,3,cycling)
  local sx=value('riding_sfx_volume',sv,7,cycling)
  local fx=value('riding_sfx_filter',sf,3,cycling)
  if muteArea and not Native._fanfareActive and not blocked()then av=0 end
  local gain=av/7;local sfx=sx/7;local filter=af>0 and af or nil
  if applied.volume~=gain or Native._bgmVolume~=gain then
   Native._bgmVolume=gain;applied.volume=gain
   if Native.applyGain then Native.applyGain()end
  end
  if applied.filter~=af or Native._filterLevel~=filter then
   Native._filterLevel=filter;applied.filter=af
   if Native.applyBgmFilter then Native.applyBgmFilter()end
  end
  Native._sfxVolume=sfx
  for _,s in ipairs(Native._seSources or{})do if s~=Native._fanfareSource then sfxFilter(s,fx)end end
  sfxFilter(Native._crySource,fx)
  -- Fanfares have their own cached Source, not the native BGM Source.
  -- Cycling-only routing must never bake a zero gain into that Source.
  if Native._fanfareActive and Native._fanfareSource then
   call(Native._fanfareSource,'setVolume',mv/7)
   setFilter(Native._fanfareSource,mf)
  end
  api.effective={cycling=cycling,area=av,areaFilter=af,sfx=sx,sfxFilter=fx}
 end
 local function originalId()
  local id=Native.role('cycling')or Native.MUS_CYCLING
  return id and library.sequenceSources.byId(Version.get(),id)
 end
 local function make(id)
  local actual=id=='original'and originalId()or id
  if not actual then return nil,'Original bicycle song is not available'end
  local desc,why=library.resolve(actual,game);if not desc then return nil,why end
  local layer={id=id,actualId=actual,paused=true}
  local ok,err=pcall(function()
   if desc.kind=='file' and desc.openSource then
    local src,e=desc.openSource();if not src then error(e or 'Cannot open song')end
    layer.source=src;call(src,'setLooping',true)
   elseif desc.def and (desc.def.chip or(desc.def.address and desc.def.bank))then
    layer.engine=Chip.newEngine(desc.data,desc.def,{allowLoops=true})
    layer.source=love.audio.newQueueableSource(Chip.SAMPLE_RATE,16,2,16)
   elseif desc.def and desc.def.file then
    layer.source=love.audio.newSource(desc.def.file,'stream');call(layer.source,'setLooping',true)
   else error('Unsupported song definition')end
  end)
  if not ok then release(layer);return nil,tostring(err)end
  return layer
 end
 local function pause(layer)
  if layer and not layer.paused then call(layer.source,'pause');layer.paused=true end
 end
 local function play(layer)
  if not layer then return false end
  local ok,err=pcall(function()
   if layer.engine then
    local available=layer.source:getFreeBufferCount()
    for _=1,math.min(available,3)do
     if layer.engine:finished()then break end
     local before=Chip.getStereo();Chip.setStereo(not Output.mono(game))
     local ok,sd=pcall(Chip.soundData,layer.engine,2048,2)
     Chip.setStereo(before);if not ok then error(sd,0)end
     if Output.mono(game)then Output.fold(sd)end
     local yes=layer.source:queue(sd);sd:release();if yes==false then error('Audio queue rejected PCM')end
    end
   end
   local gain=clamp(get('bike_volume'),7,7)/7
   -- Native cry/SE ducking affects music, not the saved cycling volume.
   gain=gain*math.min(Native._duck or 1,Native._seDuck or 1)*(Native._helpActive and .5 or 1)
   layer.source:setVolume(gain);setFilter(layer.source,clamp(get('bike_filter'),3,0))
   if layer.paused or not layer.source:isPlaying()then layer.source:play()end
   layer.paused=false;layer.gain=gain
  end)
  if not ok then lastError=tostring(err);pause(layer);return false end
  return true
 end
 function api.stop()
  release(ride);ride=nil
  if active()then sync(false)end
 end
 function api.stopPreview()
  release(preview);preview=nil
  if active()then sync(false)end
 end
 function api.previewSong(id,g)
  if not active()then return nil,'Preview disabled'end
  game=g or game;api.stopPreview()
  local layer,err=make(id);if not layer then lastError=err;return nil,err end
  pause(ride);preview=layer;lastError=nil
  if not play(preview)then api.stopPreview();return nil,lastError end
  sync(true);return true
 end
 function api.update(g,dt)
  if closed then return end
  if not active()then api.dispose();return end
  game=g or game;clock=clock+math.max(0,math.min(1,tonumber(dt)or 0))
  local suspended=Native._suspended or Native._bgmPaused or Native._fanfareActive
  if preview then
   pause(ride)
   if suspended or blocked()then pause(preview);sync(false)
   else local ok=play(preview);sync(ok)end
   return
  end
  local eligible=profile();local mode=get('riding_music')
  local wanted=eligible and mode~='area'and get('bike_volume')>0
  if not wanted then
   if ride then
    if onBike()or get('bike_song_resume')then pause(ride)else release(ride);ride=nil end
   end
   sync(false);return
  end
  if suspended then pause(ride);sync(false);return end
  local id=get('bike_song')or'original'
  if ride and ride.id~=id then release(ride);ride=nil;retry=0 end
  if not ride and clock>=retry then
   local layer,err=make(id)
   if not layer then
    lastError=err;retry=clock+5
    if id~='original'then layer=make('original');if layer then layer.id=id;layer.fallback=true end end
   else lastError=nil end
   ride=layer
  end
  local ok=ride and play(ride)
  sync(ok and mode=='bicycle') -- fail open to area music if a custom source fails
 end
 local function pack(...)return{n=select('#',...),...}end
 local function wrap(name,factory)
  local old=Native[name];if type(old)~='function'then return end
  local new=factory(old);Native[name]=new;bindings[#bindings+1]={name=name,old=old,new=new}
 end
 -- Keep native mount bookkeeping; only divert the cycling cue to its area bus.
 wrap('specialMapSong',function(old)return function(...)
  local id=old(...)
  if active()and P.biking and id==Native.MUS_CYCLING then return Native._mapSong or id end
  return id
 end end)
 wrap('bikeMusic',function(old)return function(...)
  if not active()then return old(...)end
  routeDepth=routeDepth+1;local result=pack(pcall(old,...));routeDepth=routeDepth-1
  if not result[1]then error(result[2],0)end
  api.update(game,0);return unpack(result,2,result.n)
 end end)
 wrap('changeMusicTo',function(old)return function(id,...)
  if active()and routeDepth>0 and id==Native.MUS_CYCLING then id=Native._mapSong or id end
  return old(id,...)
 end end)
 wrap('playMapSong',function(old)return function(id,opts,...)
  if active()and id==Native.MUS_CYCLING and P.biking then id=(opts and opts.mapSong)or Native._mapSong or id end
  return old(id,opts,...)
 end end)
 -- Native fanfare creation snapshots _bgmVolume/_filterLevel immediately,
 -- including when the sound is already cached. Restore the normal music
 -- settings before that snapshot, then let the native countdown restore BGM.
 wrap('playFanfare',function(old)return function(...)
  if not active()then return old(...)end
  pause(ride);pause(preview)
  local mv,mf=normal();Native._bgmVolume=mv/7;Native._filterLevel=mf>0 and mf or nil
  local result=pack(old(...));api.update(game,0)
  return unpack(result,1,result.n)
 end end)
 -- SFX gain is baked by the host. Apply the current profile before creation;
 -- filter the resulting cached/new Source afterwards, preserving other filters.
 for _,name in ipairs({'playSe','playCry'})do
  wrap(name,function(old)return function(...)
   if not active()then return old(...)end
   local mute=ride and not ride.paused and get('riding_music')=='bicycle'
   sync(mute);local result=pack(old(...));sync(mute);return unpack(result,1,result.n)
  end end)
 end
 wrap('rebuildPlayback',function(old)return function(...)
  if active()then api.stop();api.stopPreview()end
  return old(...)
 end end)
 wrap('setSuspended',function(old)return function(flag,...)
  if flag and active()then pause(ride);pause(preview)end
  return old(flag,...)
 end end)
 wrap('endSession',function(old)return function(...)
  if not closed then api.dispose()end
  return old(...)
 end end)
 function api.status()
  return{previewActive=preview~=nil,layerActive=ride~=nil,layerPaused=ride and ride.paused or false,
   error=lastError,songError=lastError,ridingMusic=get('riding_music'),effective=api.effective,
   song=get('bike_song'),bikeGain=ride and ride.gain or 0}
 end
 function api.dispose()
  if closed then return end
  -- Restore off-bike parameters using the latest user options, not stale values.
  release(ride);release(preview);ride=nil;preview=nil
  local mv,mf,sv=normal()
  Native._bgmVolume=mv/7;Native._sfxVolume=sv/7;Native._filterLevel=mf>0 and mf or nil
  if Native.applyGain then pcall(Native.applyGain)end
  if Native.applyBgmFilter then pcall(Native.applyBgmFilter)end
  for s,e in pairs(tracked)do restoreFilter(s,e)end
  closed=true
  for i=#bindings,1,-1 do local b=bindings[i];if Native[b.name]==b.new then Native[b.name]=b.old end end
  bindings={};tracked={}
 end
 mod.events:on('mod.options_changed',function(e)if active()and e.mod==mod.id then api.update(game,0)end end)
 require('src.render.Assets').register({release=api.dispose})
 return api
end
return M
