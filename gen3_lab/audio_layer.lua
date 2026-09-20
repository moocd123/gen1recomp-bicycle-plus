-- FireRed-only independent cycling audio for the isolated AUTOBIKE+ beta.
-- The native Game3 BGM worker remains the owner of map/battle/fanfare music;
-- this module renders a second M4A slot into its own QueueableSource.
local Layer={}
local FILTER_HIGHGAIN={0.4,0.16,0.064}

local function clamp(v,lo,hi,fallback)
 v=tonumber(v)
 if not v or v~=v or v==math.huge or v==-math.huge then v=fallback end
 v=math.floor(v or lo)
 if v<lo then return lo end
 if v>hi then return hi end
 return v
end

local function sameFilter(a,b)
 if a==nil or b==nil then return a==b end
 if type(a)~='table' or type(b)~='table' then return false end
 for k,v in pairs(a)do if b[k]~=v then return false end end
 for k,v in pairs(b)do if a[k]~=v then return false end end
 return true
end

function Layer.attach(mod,settings,S)
 S=S or{}
 local Version=S.Version or require('src.core.GameVersion')
 assert(Version.get()=='firered' and Version.generation()==3,'FireRed audio layer only')
 local Audio=S.Audio or require('src.core.game3.audio')
 local Player=S.Player or require('src.core.game3.m4a_player')
 local P=S.PlayerState or require('src.core.game3.player')
 local Runtime=S.Runtime or require('src.mods.Runtime')
 local Assets=S.Assets or require('src.render.Assets')
 local ownerHooks,ownerEvents=Runtime.hooks,Runtime.events
 local currentGame=mod.game
 local disposed=false
 local source,slot,sourceId,sourceKey,paused
 local profileApplied=false
 local lastError
 local BUFFER_SAMPLES=S.bufferSamples or math.min(4096,Player.BUFFER_SAMPLES or 4096)
 local BUFFER_COUNT=S.bufferCount or 12
 local MAX_FILL=S.maxFill or 2
 local ownedFilters=setmetatable({},{__mode='k'})
 local api={}

 local function active()
  return not disposed and not Runtime.safeMode and Version.get()=='firered'
   and Runtime.hooks==ownerHooks and Runtime.events==ownerEvents
 end
 local function get(key,game)return settings.get(key,game or currentGame or mod.game)end
 local function nativeLevel(game,key,fallback)
  local o=game and game.options or{}
  return clamp(o[key],0,7,fallback or 7)
 end
 local function nativeFilter(game)
  local o=game and game.options or{}
  return clamp(o.musicFilter,0,3,0)
 end
 local function ridingLevel(game,key,nativeKey)
  local v=tonumber(get(key,game))
  if not v or v<0 then return nativeLevel(game,nativeKey,7)end
  return clamp(v,0,7,7)
 end
 local function ridingFilter(game,key)
  local v=tonumber(get(key,game))
  if not v or v<0 then return nativeFilter(game)end
  return clamp(v,0,3,0)
 end
 local function setFilter(src,level)
  if not(src and src.setFilter)then return false end
  level=clamp(level,0,3,0)
  local gain=FILTER_HIGHGAIN[level]
  local ok
  if gain then ok=pcall(src.setFilter,src,{type='lowpass',volume=1,highgain=gain})
  else ok=pcall(src.setFilter,src)end
  return ok
 end
 local function readFilter(src)
  if not(src and src.getFilter)then return false,nil end
  local ok,v=pcall(src.getFilter,src);return ok,v
 end
 local function ownedFilter(src,level)
  if not src then return end
  level=clamp(level,0,3,0)
  local e=ownedFilters[src]
  if not e then e={};ownedFilters[src]=e end
  if level==0 then
   if not e.applied then return end
   local ok,current=readFilter(src)
   if ok and not sameFilter(current,e.last)then e.applied=false;return end
   if e.original then pcall(src.setFilter,src,e.original)
   elseif src.setFilter then pcall(src.setFilter,src)end
   e.applied=false;e.last=nil
   return
  end
  if not e.applied then
   local _,original=readFilter(src);e.original=original
  end
  if setFilter(src,level)then
   local _,actual=readFilter(src);e.last=actual;e.applied=true
  end
 end
 local function restoreOwnedFilters()
  for src in pairs(ownedFilters)do ownedFilter(src,0)end
 end
 local function effectiveSfxFilter(game,riding)
  if riding then
   local v=tonumber(get('riding_sfx_filter',game))
   if v and v>=0 then return clamp(v,0,3,0)end
  end
  return clamp(get('sfx_filter',game),0,3,0)
 end
 local function applySfxFilters(game,riding)
  local level=effectiveSfxFilter(game,riding)
  for _,src in ipairs(Audio._seSources or{})do
   if src~=Audio._fanfareSource then ownedFilter(src,level)end
  end
  if Audio._crySource then ownedFilter(Audio._crySource,level)end
 end

 local function releaseSource(src)
  if not src then return end
  if src.stop then pcall(src.stop,src)end
  if src.release then pcall(src.release,src)end
 end
 local function destroyOverlay()
  releaseSource(source)
  source,slot,sourceId,sourceKey,paused=nil,nil,nil,nil,nil
 end
 local function pauseOverlay()
  if not source then return end
  if source.pause then pcall(source.pause,source)end
  paused=true
 end
 local function suspendOverlay(game)
  if not source then return end
  if get('bike_song_resume',game)==true then pauseOverlay()else destroyOverlay()end
 end
 local function resolveSong(game)
  local key=tostring(get('bike_song',game)or'original')
  local id
  if key=='original'then
   id=(Audio.role and Audio.role('cycling')) or 282
  else
   id=tonumber(key:match('^firered:(%d+)$')or key:match('^fr:(%d+)$'))
  end
  if not id then return nil,key,'unsupported FireRed bicycle song' end
  local info=Audio.songInfo and Audio.songInfo(id)
  if not info or info.kind~='bgm'then return nil,key,'selected FireRed song is unavailable' end
  return id,key
 end
 local function newQueueableSource()
  if S.newQueueableSource then return S.newQueueableSource(Player.SAMPLE_RATE,16,2,BUFFER_COUNT)end
  if love and love.audio and love.audio.newQueueableSource then
   return love.audio.newQueueableSource(Player.SAMPLE_RATE,16,2,BUFFER_COUNT)
  end
  return nil,'queueable audio unavailable'
 end
 local function makeOverlay(id,key)
  destroyOverlay();lastError=nil
  if not(Audio._pack and Audio._cache)then lastError='FireRed audio pack unavailable';return false end
  local made,err
  local ok,res,extra=pcall(newQueueableSource)
  if ok then made,err=res,extra else err=res end
  if not made then lastError=tostring(err or'queueable audio unavailable');return false end
  local nextSlot={voices={}}
  local started,value=pcall(Player.start,Audio._pack,Audio._cache,nextSlot,id,{forceSeq=true})
  if not started or value~=true then
   releaseSource(made);lastError=tostring(started and'could not start FireRed song'or value);return false
  end
  source,slot,sourceId,sourceKey,paused=made,nextSlot,id,key,false
  return true
 end
 local function overlayVolume(game)
  return clamp(get('bike_volume',game),0,7,7)/7
 end
 local function overlayFilter(game)
  return clamp(get('bike_filter',game),0,3,0)
 end
 local function configureOverlay(game)
  if not source then return end
  if source.setVolume then pcall(source.setVolume,source,overlayVolume(game))end
  setFilter(source,overlayFilter(game))
 end
 local function fillOverlay(game)
  if not(source and slot)then return false end
  configureOverlay(game)
  local ok,free=pcall(source.getFreeBufferCount,source)
  if not ok or type(free)~='number'then lastError='cycling audio queue unavailable';destroyOverlay();return false end
  free=math.min(math.max(0,free),MAX_FILL)
  while free>0 do
   local rendered,data=pcall(Player.renderBuffered,slot,BUFFER_SAMPLES,{master=1,sampleRate=Player.SAMPLE_RATE})
   if not rendered or not data then lastError=tostring(data or'cycling render failed');destroyOverlay();return false end
   local queued,q=pcall(source.queue,source,data)
   if not queued or q==false then lastError=tostring(queued and'cycling queue refused buffer'or q);destroyOverlay();return false end
   free=free-1
  end
  if paused then paused=false end
  local playing=false
  if source.isPlaying then local p,v=pcall(source.isPlaying,source);playing=p and v==true end
  if not playing and source.play then
   local p=pcall(source.play,source);if not p then lastError='cycling source could not play';destroyOverlay();return false end
  end
  return true
 end
 local function ensureOverlay(game)
  local id,key,err=resolveSong(game)
  if not id then lastError=err;destroyOverlay();return false end
  if not source or sourceId~=id or sourceKey~=key then if not makeOverlay(id,key)then return false end end
  return fillOverlay(game)
 end

 local function restoreNativeProfile(game)
  if not profileApplied then return end
  if Audio.applyEngineOptions and game and type(game.options)=='table'then
   pcall(Audio.applyEngineOptions,game.options)
  else
   Audio._bgmVolume=nativeLevel(game,'musicVol',7)/7
   Audio._sfxVolume=nativeLevel(game,'sfxVol',7)/7
   local f=nativeFilter(game);Audio._filterLevel=f>0 and f or nil
   if Audio.applyGain then pcall(Audio.applyGain)end
   if Audio.applyBgmFilter then pcall(Audio.applyBgmFilter)end
  end
  profileApplied=false
 end
 local function applyRidingProfile(game,mode,overlayReady)
  local area=ridingLevel(game,'riding_area_volume','musicVol')
  if mode=='bicycle' and overlayReady then area=0 end
  local sfx=ridingLevel(game,'riding_sfx_volume','sfxVol')
  local filter=ridingFilter(game,'riding_area_filter')
  Audio._bgmVolume=area/7
  Audio._sfxVolume=sfx/7
  Audio._filterLevel=filter>0 and filter or nil
  if Audio.applyGain then pcall(Audio.applyGain)end
  if Audio.applyBgmFilter then pcall(Audio.applyBgmFilter)end
  profileApplied=true
 end

 function api.update(game,dt)
  currentGame=game or currentGame or mod.game
  game=currentGame
  if not active()then
   suspendOverlay(game);restoreNativeProfile(game);restoreOwnedFilters();return false
  end
  local riding=game and game.phase=='field' and P.biking==true
  local fanfare=Audio._fanfareActive==true
  local mode=tostring(get('riding_music',game)or'bicycle')
  if mode~='area'and mode~='bicycle'and mode~='both'then mode='bicycle'end
  local overlayReady=false
  if riding and not fanfare and mode~='area'then overlayReady=ensureOverlay(game)
  else suspendOverlay(game)end
  if riding and not fanfare then applyRidingProfile(game,mode,overlayReady)
  else restoreNativeProfile(game)end
  applySfxFilters(game,riding and not fanfare)
  api.riding=riding;api.mode=mode;api.overlayReady=overlayReady;api.songId=sourceId;api.error=lastError
  return true
 end
 function api.status()
  return{riding=api.riding==true,mode=api.mode,overlay=source~=nil,ready=api.overlayReady==true,
   paused=paused==true,songId=sourceId,songKey=sourceKey,error=lastError}
 end
 function api.stop()
  destroyOverlay();restoreNativeProfile(currentGame);return true
 end
 function api.dispose()
  if disposed then return end;disposed=true
  destroyOverlay();restoreNativeProfile(currentGame);restoreOwnedFilters()
  if Audio.update==api._wrapper then Audio.update=api._priorUpdate end
 end

 api._priorUpdate=Audio.update
 api._wrapper=function(dt)
  local out={api._priorUpdate(dt)}
  api.update(currentGame or mod.game,dt)
  return table.unpack(out)
 end
 Audio.update=api._wrapper
 if mod.events and mod.events.on then mod.events:on('game.ready',function(ev)currentGame=ev and ev.game or mod.game or currentGame end)end
 if Assets and Assets.register then Assets.register({release=api.dispose})end
 if mod.hooks and mod.hooks.wrap then
  mod.hooks:wrap('core.quit_to_launcher',function(next,...)
   api.dispose();return next(...)
  end,90)
 end
 mod.exports.gen3Audio=api
 return api
end
return Layer
