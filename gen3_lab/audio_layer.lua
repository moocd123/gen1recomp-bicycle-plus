-- FireRed-only independent cycling audio for the isolated AUTOBIKE+ beta.
-- The native Game3 BGM worker remains the owner of map/battle/fanfare music;
-- this module renders FireRed M4A, imported Gen1/2 ChipSynth, or a validated
-- local audio file on a private source.
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
 if type(a)~='table'or type(b)~='table'then return false end
 for k,v in pairs(a)do if b[k]~=v then return false end end
 for k,v in pairs(b)do if a[k]~=v then return false end end
 return true
end

function Layer.attach(mod,settings,S)
 S=S or{}
 local Version=S.Version or require('src.core.GameVersion')
 assert(Version.get()=='firered'and Version.generation()==3,'FireRed audio layer only')
 local Audio=S.Audio or require('src.core.game3.audio')
 local Player=S.Player or require('src.core.game3.m4a_player')
 local ChipSynth=S.ChipSynth or require('src.core.ChipSynth')
 local Legacy=S.Legacy
 local Local=S.Local
 local P=S.PlayerState or require('src.core.game3.player')
 local Runtime=S.Runtime or require('src.mods.Runtime')
 local Assets=S.Assets or require('src.render.Assets')
 local ownerHooks,ownerEvents=Runtime.hooks,Runtime.events
 local currentGame=mod.game
 local disposed=false
 local source,slot,chipEngine,sourceId,sourceKey,sourceKind,paused
 local previewSource,previewSlot,previewChip,previewId,previewKey,previewKind,previewPaused
 local profileApplied=false
 local lastError,previewError
 local BUFFER_SAMPLES=S.bufferSamples or math.min(4096,Player.BUFFER_SAMPLES or 4096)
 local CHIP_BUFFER_SAMPLES=S.chipBufferSamples or 2048
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
  if not e.applied then local _,original=readFilter(src);e.original=original end
  if setFilter(src,level)then local _,actual=readFilter(src);e.last=actual;e.applied=true end
 end
 local function restoreOwnedFilters()for src in pairs(ownedFilters)do ownedFilter(src,0)end end
 local function effectiveSfxFilter(game,riding)
  if riding then
   local v=tonumber(get('riding_sfx_filter',game))
   if v and v>=0 then return clamp(v,0,3,0)end
  end
  return clamp(get('sfx_filter',game),0,3,0)
 end
 local function applySfxFilters(game,riding)
  local level=effectiveSfxFilter(game,riding)
  for _,src in ipairs(Audio._seSources or{})do if src~=Audio._fanfareSource then ownedFilter(src,level)end end
  if Audio._crySource then ownedFilter(Audio._crySource,level)end
 end

 local function releaseSource(src)
  if not src then return end
  if src.stop then pcall(src.stop,src)end
  if src.release then pcall(src.release,src)end
 end
 local function destroyOverlay()
  releaseSource(source)
  source,slot,chipEngine,sourceId,sourceKey,sourceKind,paused=nil,nil,nil,nil,nil,nil,nil
 end
 local function destroyPreview()
  releaseSource(previewSource)
  previewSource,previewSlot,previewChip,previewId,previewKey,previewKind,previewPaused=nil,nil,nil,nil,nil,nil,nil
 end
 local function pauseOverlay()
  if not source then return end
  if source.pause then pcall(source.pause,source)end
  paused=true
 end
 local function pausePreview()
  if not previewSource then return end
  if previewSource.pause then pcall(previewSource.pause,previewSource)end
  previewPaused=true
 end
 local function suspendOverlay(game)
  if not source then return end
  if get('bike_song_resume',game)==true then pauseOverlay()else destroyOverlay()end
 end
 local function resolveSong(game,keyOverride)
  local key=tostring(keyOverride or get('bike_song',game)or'original')
  if key=='original'or key:match('^firered:%d+$')or key:match('^fr:%d+$')then
   local id
   if key=='original'then id=(Audio.role and Audio.role('cycling'))or 282
   else id=tonumber(key:match('(%d+)$'))end
   if not id then return nil,'unsupported FireRed bicycle song'end
   local info=Audio.songInfo and Audio.songInfo(id)
   if not info or info.kind~='bgm'then return nil,'selected FireRed song is unavailable'end
   return{kind='m4a',id=id,key=key}
  end
  if key:match('^game:[a-z]+:[%w_]+$')and Legacy and Legacy.resolve then
   local selected,err=Legacy.resolve(key,game)
   if selected and selected.kind=='chip'then
    return{kind='chip',id=selected.label,key=key,selected=selected}
   end
   return nil,err or'unsupported imported-game bicycle song'
  end
  if key:match('^file:%x+$')and Local and Local.resolve then
   local selected,err=Local.resolve(key,game)
   if selected and selected.kind=='file'and selected.openSource then
    return{kind='file',id=key,key=key,selected=selected}
   end
   return nil,err or'unsupported local bicycle song'
  end
  return nil,'unsupported FireRed bicycle song'
 end
 local function newQueueableSource(rate)
  if S.newQueueableSource then return S.newQueueableSource(rate,16,2,BUFFER_COUNT)end
  if love and love.audio and love.audio.newQueueableSource then
   return love.audio.newQueueableSource(rate,16,2,BUFFER_COUNT)
  end
  return nil,'queueable audio unavailable'
 end
 local function makeOverlay(desc)
  destroyOverlay();lastError=nil
  if desc.kind=='file'then
   local opened,made,err=pcall(desc.selected.openSource)
   if not opened or not made then lastError=tostring(opened and(err or'could not open imported audio')or made);return false end
   if made.setLooping then pcall(made.setLooping,made,true)end
   source,sourceId,sourceKey,sourceKind,paused=made,desc.id,desc.key,'file',false
   return true
  end
  local rate=desc.kind=='chip'and ChipSynth.SAMPLE_RATE or Player.SAMPLE_RATE
  if desc.kind=='m4a'and not(Audio._pack and Audio._cache)then lastError='FireRed audio pack unavailable';return false end
  local ok,made,err=pcall(newQueueableSource,rate)
  if not ok then err=made;made=nil end
  if not made then lastError=tostring(err or'queueable audio unavailable');return false end
  if desc.kind=='m4a'then
   local nextSlot={voices={}}
   local started,value=pcall(Player.start,Audio._pack,Audio._cache,nextSlot,desc.id,{forceSeq=true})
   if not started or value~=true then
    releaseSource(made);lastError=tostring(started and'could not start FireRed song'or value);return false
   end
   slot=nextSlot
  elseif desc.kind=='chip'then
   local selected=desc.selected
   local started,value=pcall(ChipSynth.newEngine,selected.data,selected.def,{allowLoops=true})
   if not started or not value then
    releaseSource(made);lastError=tostring(started and'could not start imported-game song'or value);return false
   end
   chipEngine=value
  else
   releaseSource(made);lastError='unsupported cycling audio backend';return false
  end
  source,sourceId,sourceKey,sourceKind,paused=made,desc.id,desc.key,desc.kind,false
  return true
 end
 local function makePreview(desc)
  destroyPreview();previewError=nil
  if desc.kind=='file'then
   local opened,made,err=pcall(desc.selected.openSource)
   if not opened or not made then previewError=tostring(opened and(err or'could not open imported audio')or made);return false end
   if made.setLooping then pcall(made.setLooping,made,true)end
   previewSource,previewId,previewKey,previewKind,previewPaused=made,desc.id,desc.key,'file',false
   return true
  end
  local rate=desc.kind=='chip'and ChipSynth.SAMPLE_RATE or Player.SAMPLE_RATE
  if desc.kind=='m4a'and not(Audio._pack and Audio._cache)then previewError='FireRed audio pack unavailable';return false end
  local ok,made,err=pcall(newQueueableSource,rate)
  if not ok then err=made;made=nil end
  if not made then previewError=tostring(err or'queueable audio unavailable');return false end
  if desc.kind=='m4a'then
   local nextSlot={voices={}}
   local started,value=pcall(Player.start,Audio._pack,Audio._cache,nextSlot,desc.id,{forceSeq=true})
   if not started or value~=true then releaseSource(made);previewError=tostring(started and'could not start FireRed song'or value);return false end
   previewSlot=nextSlot
  elseif desc.kind=='chip'then
   local selected=desc.selected
   local started,value=pcall(ChipSynth.newEngine,selected.data,selected.def,{allowLoops=true})
   if not started or not value then releaseSource(made);previewError=tostring(started and'could not start imported-game song'or value);return false end
   previewChip=value
  else releaseSource(made);previewError='unsupported preview backend';return false end
  previewSource,previewId,previewKey,previewKind,previewPaused=made,desc.id,desc.key,desc.kind,false
  return true
 end
 local function overlayVolume(game)return clamp(get('bike_volume',game),0,7,7)/7 end
 local function overlayFilter(game)return clamp(get('bike_filter',game),0,3,0)end
 local function configureOverlay(game)
  if not source then return end
  if source.setVolume then pcall(source.setVolume,source,overlayVolume(game))end
  setFilter(source,overlayFilter(game))
 end
 local function configurePreview(game)
  if not previewSource then return end
  if previewSource.setVolume then pcall(previewSource.setVolume,previewSource,overlayVolume(game))end
  setFilter(previewSource,overlayFilter(game))
 end
 local function ensurePlaying()
  if not source then return false end
  if paused then paused=false end
  local playing=false
  if source.isPlaying then local p,v=pcall(source.isPlaying,source);playing=p and v==true end
  if not playing and source.play then
   local p=pcall(source.play,source);if not p then lastError='cycling source could not play';destroyOverlay();return false end
  end
  return true
 end
 local function ensurePreviewPlaying()
  if not previewSource then return false end
  if previewPaused then previewPaused=false end
  local playing=false
  if previewSource.isPlaying then local p,v=pcall(previewSource.isPlaying,previewSource);playing=p and v==true end
  if not playing and previewSource.play then
   local p=pcall(previewSource.play,previewSource);if not p then previewError='preview source could not play';destroyPreview();return false end
  end
  return true
 end
 local function nextBuffer()
  if sourceKind=='chip'then
   if chipEngine.finished and chipEngine:finished()then return nil,'finished'end
   local rendered,data=pcall(ChipSynth.soundData,chipEngine,CHIP_BUFFER_SAMPLES,2)
   if not rendered or not data then return nil,tostring(data or'cycling chip render failed')end
   return data
  end
  local rendered,data=pcall(Player.renderBuffered,slot,BUFFER_SAMPLES,{master=1,sampleRate=Player.SAMPLE_RATE})
  if not rendered or not data then return nil,tostring(data or'cycling render failed')end
  return data
 end
 local function nextPreviewBuffer()
  if previewKind=='chip'then
   if previewChip.finished and previewChip:finished()then return nil,'finished'end
   local rendered,data=pcall(ChipSynth.soundData,previewChip,CHIP_BUFFER_SAMPLES,2)
   if not rendered or not data then return nil,tostring(data or'preview chip render failed')end
   return data
  end
  local rendered,data=pcall(Player.renderBuffered,previewSlot,BUFFER_SAMPLES,{master=1,sampleRate=Player.SAMPLE_RATE})
  if not rendered or not data then return nil,tostring(data or'preview render failed')end
  return data
 end
 local function fillOverlay(game)
  if not source then return false end
  configureOverlay(game)
  if sourceKind=='file'then return ensurePlaying()end
  if(sourceKind=='m4a'and not slot)or(sourceKind=='chip'and not chipEngine)then return false end
  local ok,free=pcall(source.getFreeBufferCount,source)
  if not ok or type(free)~='number'then lastError='cycling audio queue unavailable';destroyOverlay();return false end
  free=math.min(math.max(0,free),MAX_FILL)
  while free>0 do
   local data,err=nextBuffer()
   if not data then
    if err=='finished'then break end
    lastError=err;destroyOverlay();return false
   end
   local queued,q=pcall(source.queue,source,data)
   if data.release then pcall(data.release,data)end
   if not queued or q==false then lastError=tostring(queued and'cycling queue refused buffer'or q);destroyOverlay();return false end
   free=free-1
  end
  return ensurePlaying()
 end
 local function fillPreview(game)
  if not previewSource then return false end
  configurePreview(game)
  if previewKind=='file'then return ensurePreviewPlaying()end
  if(previewKind=='m4a'and not previewSlot)or(previewKind=='chip'and not previewChip)then return false end
  local ok,free=pcall(previewSource.getFreeBufferCount,previewSource)
  if not ok or type(free)~='number'then previewError='preview audio queue unavailable';destroyPreview();return false end
  free=math.min(math.max(0,free),MAX_FILL)
  while free>0 do
   local data,err=nextPreviewBuffer()
   if not data then
    if err=='finished'then break end
    previewError=err;destroyPreview();return false
   end
   local queued,q=pcall(previewSource.queue,previewSource,data)
   if data.release then pcall(data.release,data)end
   if not queued or q==false then previewError=tostring(queued and'preview queue refused buffer'or q);destroyPreview();return false end
   free=free-1
  end
  return ensurePreviewPlaying()
 end
 local function ensureOverlay(game)
  local desc,err=resolveSong(game)
  if not desc then lastError=err;destroyOverlay();return false end
  if not source or sourceId~=desc.id or sourceKey~=desc.key or sourceKind~=desc.kind then
   if not makeOverlay(desc)then return false end
  end
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
  if mode=='bicycle'and overlayReady then area=0 end
  local sfx=ridingLevel(game,'riding_sfx_volume','sfxVol')
  local filter=ridingFilter(game,'riding_area_filter')
  Audio._bgmVolume=area/7;Audio._sfxVolume=sfx/7;Audio._filterLevel=filter>0 and filter or nil
  if Audio.applyGain then pcall(Audio.applyGain)end
  if Audio.applyBgmFilter then pcall(Audio.applyBgmFilter)end
  profileApplied=true
 end

 function api.previewSong(key,game)
  currentGame=game or currentGame or mod.game;game=currentGame
  if not active()then return nil,'Playback unavailable in safe mode'end
  local desc,err=resolveSong(game,key)
  if not desc then return nil,err end
  destroyPreview();pauseOverlay();restoreNativeProfile(game)
  if not makePreview(desc)then return nil,previewError end
  if not fillPreview(game)then local e=previewError or'Preview could not start';destroyPreview();return nil,e end
  api.previewReady=true;return true
 end
 function api.stopPreview()destroyPreview();api.previewReady=false;return true end
 function api.update(game,dt)
  currentGame=game or currentGame or mod.game;game=currentGame
  if not active()then destroyPreview();suspendOverlay(game);restoreNativeProfile(game);restoreOwnedFilters();return false end
  local riding=game and game.phase=='field'and P.biking==true
  local fanfare=Audio._fanfareActive==true
  local mode=tostring(get('riding_music',game)or'bicycle')
  if mode~='area'and mode~='bicycle'and mode~='both'then mode='bicycle'end
  if previewSource then
   pauseOverlay();local ready=false
   if fanfare then pausePreview()else ready=fillPreview(game)end
   if previewSource then
    restoreNativeProfile(game);applySfxFilters(game,false)
    api.riding=riding;api.mode=mode;api.overlayReady=false;api.previewReady=ready and not fanfare
    api.songId=sourceId;api.songKind=sourceKind;api.error=previewError
    return true
   end
  end
  local overlayReady=false
  if riding and not fanfare and mode~='area'then overlayReady=ensureOverlay(game)else suspendOverlay(game)end
  if riding and not fanfare then applyRidingProfile(game,mode,overlayReady)else restoreNativeProfile(game)end
  applySfxFilters(game,riding and not fanfare)
  api.riding=riding;api.mode=mode;api.overlayReady=overlayReady;api.previewReady=false
  api.songId=sourceId;api.songKind=sourceKind;api.error=lastError
  return true
 end
 function api.status()
  return{riding=api.riding==true,mode=api.mode,overlay=source~=nil,ready=api.overlayReady==true,
   paused=paused==true,songId=sourceId,songKey=sourceKey,songKind=sourceKind,error=api.error,
   preview=previewSource~=nil,previewReady=api.previewReady==true,previewKey=previewKey,previewKind=previewKind}
 end
 function api.stop()destroyPreview();destroyOverlay();restoreNativeProfile(currentGame);return true end
 function api.dispose()
  if disposed then return end;disposed=true
  destroyPreview();destroyOverlay();restoreNativeProfile(currentGame);restoreOwnedFilters()
  if Audio.update==api._wrapper then Audio.update=api._priorUpdate end
 end
 api._priorUpdate=Audio.update
 api._wrapper=function(dt)
  local out={api._priorUpdate(dt)};api.update(currentGame or mod.game,dt);return table.unpack(out)
 end
 Audio.update=api._wrapper
 if mod.events and mod.events.on then mod.events:on('game.ready',function(ev)currentGame=ev and ev.game or mod.game or currentGame end)end
 if Assets and Assets.register then Assets.register({release=api.dispose})end
 if mod.hooks and mod.hooks.wrap then
  mod.hooks:wrap('core.quit_to_launcher',function(next,...)api.dispose();return next(...)end,90)
 end
 mod.exports.gen3Audio=api
 return api
end
return Layer
