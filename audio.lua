-- Bicycle Plus: independent native-scale area and bicycle music buses.
-- Targets Gen1ReComp++ 0.2.59. All hooks call the rest of their chain.
-- No ROM bytes, replacement songs or edits to the engine are shipped here.
local Audio = {}

local function level(value, fallback)
  value = tonumber(value)
  if not value or value ~= value then value = fallback end
  return math.max(0, math.min(7, value))
end

function Audio.init(mod, settings, songs)
  local Music = require("src.core.Music")
  local Sound = require("src.core.Sound")
  local ChipAudio = require("src.core.ChipAudio")
  local ChipSynth = require("src.core.ChipSynth")
  local Assets = require("src.render.Assets")
  local Runtime = require("src.mods.Runtime")
  local ownedHooks, ownedEvents = Runtime.hooks, Runtime.events
  local api = {}
  local currentGame
  local overlay
  local preview, previewOwner
  local parkLayer, stopPreview
  local selectedMapSong, activeMapSong
  local areaSuppressed = false
  local musicDepth, layerDepth = 0, 0
  local nativeSources = setmetatable({}, {__mode = "k"})
  local syncLayer, setAreaSuppressed, syncProfiles
  local ridingProfile = false
  local normalMusicLevel, normalAreaFilter, normalSfxLevel
  local lastAreaLevel, lastAreaFilter, lastSfxLevel
  local mapCueActive = false
  local fanfares = {}
  local clock, retryAt = 0, 0
  local warned = {}
  local lastFailure
  local subscriptions = {}
  local disposed = false
  local BUFFER_SAMPLES, BUFFER_COUNT, MAX_FILL = 2048, 12, 3
  local FILTER_HIGHGAIN = { 0.4, 0.16, 0.064 }
  local soundDepth = 0
  local soundSources = setmetatable({}, {__mode = "k"})
  local methodWrappers = {}
  local lastSfxFilter
  local filterUnavailable = false

  local function setting(key)
    if type(settings) == "function" then return settings(key) end
    if type(settings) == "table" then return settings[key] end
    return mod and mod.options and mod.options:get(key)
  end

  local function ridingMusic()
    local value = setting("riding_music")
    if value == "bicycle" or value == "area" then return value end
    -- Missing and unknown values preserve 1.1.0's independent mix.
    return "both"
  end

  local function filterLevel(value)
    return math.max(0, math.min(3, math.floor(tonumber(value) or 0)))
  end

  local function profileValue(key, fallback, maximum)
    local value = tonumber(setting(key))
    if not ridingProfile or not value or value ~= value or value < 0 then return fallback end
    return math.max(0, math.min(maximum, math.floor(value)))
  end

  local function effectiveSfxFilter()
    return profileValue("riding_sfx_filter", filterLevel(setting("sfx_filter")), 3)
  end

  local function gameData(game)
    return game and game.data
  end

  local function options(game)
    return game and (game.options or (game.save and game.save.options)) or {}
  end

  local function bikeLabel(data)
    return Music.special(data, "bike")
  end

  local function bicycleState(game)
    if not game then return false, nil, false end
    local world = game.world or game.overworld
    if not (world and world.map) then return false, nil, false end
    local riding, surfing
    if game.world then
      -- Gen 2 stores the locomotion mode in World.playerState.
      riding = world.playerState == "bike"
      surfing = world.playerState == "surf" or world.playerState == "surf_pika"
    else
      riding = game.save and game.save.onBike == true
      surfing = world.player and world.player.surfing == true
    end
    return riding, world, surfing
  end

  local function release(source)
    if not source then return end
    pcall(source.stop, source)
    if source.release then pcall(source.release, source) end
  end

  function api.stop()
    if preview then release(preview.source); release(preview.loopSource); preview=nil; previewOwner=nil end
    if setAreaSuppressed then setAreaSuppressed(false) end
    if overlay then
      release(overlay.source)
      release(overlay.loopSource)
      overlay = nil
    end
  end

  local function report(message)
    message = tostring(message)
    lastFailure = message
    retryAt = clock + 5
    if not warned[message] then
      warned[message] = true
      if mod.log and mod.log.warn then
        mod.log:warn("Bicycle music layer could not start: %s. Area music remains available.", message)
      end
    end
    api.stop()
  end

  local function withSource(source, method, ...)
    if not source or not source[method] then return false end
    return pcall(source[method], source, ...)
  end

  local function makeOverlay(data, label, requested, strict)
    local request = requested or setting("bike_song") or "original"
    local spec, why
    if songs and request ~= "original" then spec, why = songs.resolve(currentGame, request) end
    if strict and request ~= "original" and not spec then return nil, why or "Song unavailable" end
    if songs then songs.error = why end
    local baseLabel = label
    local custom = spec ~= nil
    if spec then
      data, label = spec.data, spec.label
    else
      local _, world = bicycleState(currentGame)
      label = Runtime.call("music.select", function(song) return song end, label, {
        reason = "map", onBike = true, surfing = false,
        mapSong = selectedMapSong, mapId = world and world.map.id,
        bicyclePlusLayer = true,
      })
      if not label or (not strict and label == Music.current()) then return nil end
    end
    local def = spec and spec.def or (data and data.audio and data.audio.songs and data.audio.songs[label])
    if not def then return nil, "No playable song in the selected audio registry" end
    if not (love and love.audio) then return nil, "Audio device unavailable" end
    local result = {label=label, baseLabel=baseLabel, data=data, def=def, started=false,
      request=request, custom=custom, revision=songs and songs.revision or 0}
    if def.chip or (def.address and def.bank) then
      if not (love.audio.newQueueableSource and love.sound) then return nil, "Queueable audio unavailable" end
      local ok, engine = pcall(ChipSynth.newEngine, data, def, {allowLoops=true})
      if not ok then return nil, engine end
      result.engine, result.rate = engine, ChipSynth.SAMPLE_RATE
      result.stereo = ChipSynth.getStereo()
      local made, source = pcall(love.audio.newQueueableSource,result.rate,16,2,BUFFER_COUNT)
      if not made then return nil, source end
      result.source, result.chip = source, true
    elseif def.file then
      local file = type(def.file)=="string" and Assets.resolve(def.file) or def.file
      local ok, source = pcall(love.audio.newSource, file, "stream")
      if not ok then return nil, source end
      result.source = source
      if def.loopFile then
        local loop = type(def.loopFile)=="string" and Assets.resolve(def.loopFile) or def.loopFile
        local loopOk, loopSource = pcall(love.audio.newSource,loop,"stream")
        if not loopOk then release(source);return nil,loopSource end
        result.loopSource=loopSource
      end
      withSource(result.source,"setLooping",result.loopSource==nil)
      withSource(result.loopSource,"setLooping",true)
    else return nil,"Unsupported song definition" end
    return result
  end

  local function fillBuffers(layer)
    layer = layer or overlay
    if not (layer and layer.chip) then return true end
    local ok, free = withSource(layer.source, "getFreeBufferCount")
    if not ok or type(free) ~= "number" then return false, "audio queue unavailable" end
    local count = math.min(free, MAX_FILL)
    while count > 0 and not layer.engine:finished() do
      local rendered, buffer = pcall(ChipSynth.soundData, layer.engine, BUFFER_SAMPLES, 2)
      if not rendered then return false, buffer end
      local queued, err = withSource(layer.source, "queue", buffer)
      -- QueueableSource copies the PCM into OpenAL; drop temporary buffers.
      if buffer and buffer.release then pcall(buffer.release, buffer) end
      if not queued then return false, err or "could not queue bicycle audio" end
      count = count - 1
    end
    return true
  end

  local function pauseLayer()
    if overlay then
      withSource(overlay.source, "pause")
      overlay.paused = true
    end
  end

  parkLayer = function()
    if setAreaSuppressed then setAreaSuppressed(false) end
    if preview then release(preview.source);release(preview.loopSource);preview=nil;previewOwner=nil end
    if overlay and overlay.custom and setting("bike_song_restart")=="resume" then
      pauseLayer();overlay.parked=true
    elseif overlay then release(overlay.source);release(overlay.loopSource);overlay=nil end
  end

  local function fanfareActive()
    local active = false
    for name in pairs(fanfares) do
      if Sound.isPlaying(name) then active = true else fanfares[name] = nil end
    end
    return active
  end

  local function applyFilter(source, value)
    if not source then return end
    local ok
    if FILTER_HIGHGAIN[value] then
      ok = withSource(source, "setFilter", {
        type = "lowpass", volume = 1, highgain = FILTER_HIGHGAIN[value],
      })
    else
      ok = withSource(source, "setFilter")
    end
    if not ok then filterUnavailable = true end
  end

  local function sameFilter(a, b)
    if a == nil or b == nil then return a == b end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do if b[k] ~= v then return false end end
    for k, v in pairs(b) do if a[k] ~= v then return false end end
    return true
  end

  local function readFilter(source)
    local ok, result = withSource(source, "getFilter")
    return ok, result
  end

  local function restoreSfxFilter(source, entry)
    if not entry.applied then return end
    local ok, current = readFilter(source)
    -- Another mod may have changed the filter after ours. Its newer
    -- setting wins, including when Bicycle Plus is disabled or reloaded.
    if ok and not sameFilter(current, entry.last) then
      entry.applied = false
      return
    end
    if entry.original then
      withSource(source, "setFilter", entry.original)
    else
      withSource(source, "setFilter")
    end
    entry.applied = false
  end

  local function applySfxFilter(source, entry, value)
    if value == 0 then restoreSfxFilter(source, entry); return end
    if not entry.applied then
      local _, original = readFilter(source)
      entry.original = original
    end
    applyFilter(source, value)
    local _, actual = readFilter(source)
    entry.last = actual
    entry.applied = true
  end

  local function trackSound(source)
    if (type(source) ~= "table" and type(source) ~= "userdata")
        or not source.setFilter then return end
    local entry = soundSources[source]
    if not entry then entry = {}; soundSources[source] = entry end
    applySfxFilter(source, entry, effectiveSfxFilter())
  end

  local function active()
    if disposed then return false end
    if Runtime.hooks ~= ownedHooks or Runtime.events ~= ownedEvents then
      -- A loader can replace the buses before any old update callback
      -- runs. Retire now, before even a cached SFX reaches the new session.
      api.dispose()
      return false
    end
    return true
  end

  local function pack(...) return {n=select("#", ...), ...} end
  local unpackValues = table.unpack or unpack
  local function installWrapper(target, name, make)
    local previous = target and target[name]
    if type(previous) ~= "function" then return end
    local wrapper = make(previous)
    target[name] = wrapper
    methodWrappers[#methodWrappers + 1] = {
      target=target, name=name, wrapper=wrapper, previous=previous,
    }
  end

  -- v0.2.59 has no sound.filter hook and playMove/startLoop return no
  -- Source. Capture only sources created synchronously inside a native
  -- Sound call. Music and other mods' unrelated sources pass untouched.
  -- Wrappers retain the existing call chain, every argument and return.
  for _, name in ipairs({"newSource", "newQueueableSource"}) do
    installWrapper(love and love.audio, name, function(previous)
      return function(...)
        local results = pack(previous(...))
        if active() then
          if soundDepth > 0 then trackSound(results[1])
          elseif musicDepth > 0 and layerDepth == 0 then nativeSources[results[1]] = true end
        end
        return unpackValues(results, 1, results.n)
      end
    end)
  end
  for _, name in ipairs({"play", "playStereo", "playMove", "playCry",
      "playPikaCry", "startLoop"}) do
    installWrapper(Sound, name, function(previous)
      return function(...)
        if not active() then return previous(...) end
        if syncProfiles then syncProfiles(currentGame or (mod and mod.game)) end
        soundDepth = soundDepth + 1
        local results = pack(pcall(previous, ...))
        soundDepth = soundDepth - 1
        if not results[1] then error(results[2], 0) end
        -- Cached ordinary SFX/cries have a returned Source. Move sounds
        -- and loops were captured at construction and stay in the weak set.
        trackSound(results[2])
        return unpackValues(results, 2, results.n)
      end
    end)
  end

  local function applyOverlayVolume(game, layer)
    layer = layer or overlay
    if not layer then return end
    -- Exactly Music.lua's native gain, with the BICYCLE slider as its
    -- optionScale. The AREA slider never multiplies or mutes this bus.
    local scale = level(setting("bike_volume"), 7) / 7
    local volume = 0.7 * scale
    local _, world, surfing = bicycleState(game)
    volume = Runtime.call("music.volume", function(v) return v end, volume, {
      song = layer.label, mapSong = Music.mapSong(), onBike = true,
      surfing = surfing, fading = false, optionScale = scale,
      mapId = world and world.map and world.map.id,
      x = world and world.player and world.player.cellX,
      y = world and world.player and world.player.cellY,
      tod = world and world.tod, bicyclePlusLayer = true,
    })
    volume = tonumber(volume) or (0.7 * scale)
    if volume ~= volume then volume = 0 end
    volume = math.max(0, volume)
    withSource(layer.source, "setVolume", volume)
    withSource(layer.loopSource, "setVolume", volume)
    layer.volume = volume
    local filter = filterLevel(setting("bike_filter"))
    if layer.filter ~= filter then
      layer.filter = filter
      applyFilter(layer.source, filter)
      applyFilter(layer.loopSource, filter)
    end
  end

  -- Native volume/filter setters keep ownership of cached Sources,
  -- Pikachu voice trim and existing wrapper chains. Remember the normal
  -- requested setting, substituting only the effective cycling value.
  -- No game/save option is ever rewritten by this profile.
  local initial = options(mod and mod.game)
  normalMusicLevel = level(initial.musicVol, 7)
  normalAreaFilter = filterLevel(initial.musicFilter)
  normalSfxLevel = level(initial.sfxVol, 7)
  installWrapper(Music, "setVolumeLevel", function(previous)
    return function(value, ...)
      if not active() then return previous(value, ...) end
      normalMusicLevel = level(value, 7)
      lastAreaLevel = profileValue("riding_area_volume", normalMusicLevel, 7)
      return previous(lastAreaLevel, ...)
    end
  end)
  installWrapper(Music, "setFilterLevel", function(previous)
    return function(value, ...)
      if not active() then return previous(value, ...) end
      normalAreaFilter = filterLevel(value)
      lastAreaFilter = profileValue("riding_area_filter", normalAreaFilter, 3)
      return previous(lastAreaFilter, ...)
    end
  end)
  installWrapper(Sound, "setVolumeLevel", function(previous)
    return function(value, ...)
      if not active() then return previous(value, ...) end
      normalSfxLevel = level(value, 7)
      lastSfxLevel = profileValue("riding_sfx_volume", normalSfxLevel, 7)
      return previous(lastSfxLevel, ...)
    end
  end)

  syncProfiles = function(game, cue)
    local riding, world, surfing = bicycleState(game)
    if cue then riding, surfing = cue.riding, cue.surfing end
    ridingProfile = not not (riding and not surfing and world and mapCueActive
      and (cue or Music.current() == selectedMapSong or Music.current() == activeMapSong)
      and not Music.oneShotPlaying())
    local areaLevel = profileValue("riding_area_volume", normalMusicLevel, 7)
    local areaFilter = profileValue("riding_area_filter", normalAreaFilter, 3)
    local sfxLevel = profileValue("riding_sfx_volume", normalSfxLevel, 7)
    if lastAreaLevel ~= areaLevel then Music.setVolumeLevel(normalMusicLevel) end
    if lastAreaFilter ~= areaFilter then Music.setFilterLevel(normalAreaFilter) end
    if lastSfxLevel ~= sfxLevel then Sound.setVolumeLevel(normalSfxLevel) end
    local sfxFilter = effectiveSfxFilter()
    if sfxFilter ~= lastSfxFilter then
      for source, entry in pairs(soundSources) do applySfxFilter(source, entry, sfxFilter) end
      lastSfxFilter = sfxFilter
    end
  end

  -- Keep the native slider and every downstream gain modifier intact.
  -- Only the currently playing map stream is gated; the bicycle layer
  -- has its own optionScale and never passes through this gate.
  subscriptions[#subscriptions + 1] = mod.hooks:wrap("music.volume", function(nextLink, volume, context)
    local result = nextLink(volume, context)
    if not (context and context.bicyclePlusLayer) then
      if areaSuppressed then return 0 end
    end
    return result
  end, 100)

  setAreaSuppressed = function(value)
    value = value == true
    if areaSuppressed == value then return end
    areaSuppressed = value
    -- Reapply the existing native scale, without changing the saved
    -- slider, so dismounts and setting changes take effect immediately.
    Music.setVolumeLevel(normalMusicLevel)
  end

  local function maskNativeFade()
    if not areaSuppressed then return end
    -- Music.update's fade ramp writes Source volume directly, bypassing
    -- music.volume. Capture only Sources made inside native Music calls
    -- and reapply our zero after those writes. Never touch other mods'
    -- independent sources or the bicycle layer.
    for source in pairs(nativeSources) do withSource(source, "setVolume", 0) end
    -- Stereo/device changes can construct a replacement outside Music.
    if ChipAudio.currentSource then
      withSource(ChipAudio.currentSource(), "setVolume", 0)
    end
  end

  for _, name in ipairs({"play", "update", "applyOptions", "onDeviceReset"}) do
    local name = name
    installWrapper(Music, name, function(previous)
      return function(...)
        if not active() then return previous(...) end
        musicDepth = musicDepth + 1
        local pendingBike
        if name == "play" then
          local context = select(4, ...) or {}
          local reason = context.reason
          pendingBike = reason == "bike"
          if context.selected and (reason == "map" or reason == "bike"
              or ((reason == "audiorate" or reason == "devicereset")
                and select(2, ...) == selectedMapSong)) then
            -- Queued fades and native audio restarts bypass music.select.
            -- Re-arm the map profile before the replacement Source plays.
            local game = currentGame or (mod and mod.game)
            local riding, _, surfing = bicycleState(game)
            selectedMapSong, mapCueActive = select(2, ...), true
            syncLayer(game, 0, {riding=pendingBike or riding, surfing=surfing,
              song=selectedMapSong})
          end
          if reason ~= "map" and reason ~= "bike"
              and reason ~= "audiorate" and reason ~= "devicereset" then
            -- Clear before native play applies volume using its previous
            -- song label; this prevents a battle/scene's first buffer
            -- inheriting the suppressed area's gain.
            mapCueActive = false
            syncProfiles(currentGame or (mod and mod.game))
            parkLayer()
          end
        elseif name == "update" and syncLayer then
          syncLayer(currentGame or (mod and mod.game), 0)
        end
        local results = pack(pcall(previous, ...))
        musicDepth = musicDepth - 1
        if not results[1] then error(results[2], 0) end
        if syncLayer then
          local cue = pendingBike and {riding=true, surfing=false, song=selectedMapSong} or nil
          syncLayer(currentGame or (mod and mod.game), 0, cue)
        end
        maskNativeFade()
        return unpackValues(results, 2, results.n)
      end
    end)
  end

  subscriptions[#subscriptions + 1] = mod.hooks:wrap("music.select", function(nextLink, song, context)
    local ctx = context or {}
    local game = currentGame or (mod and mod.game)
    local data = gameData(game)
    if ctx.bicyclePlusLayer then return nextLink(song, context) end
    if (ctx.reason ~= "map" and ctx.reason ~= "bike") or not data then
      return nextLink(song, context)
    end
    local riding, world, surfing = bicycleState(game)
    -- Gold/Silver/Crystal use a distinct bike cue BEFORE the mount script
    -- changes playerState, and map seams do not populate context.onBike.
    riding = ctx.onBike or riding or ctx.reason == "bike"
    surfing = ctx.surfing or surfing
    local selected = song
    if riding and not surfing then
      local area = ctx.mapSong
      -- Gen 2 writes MUSIC_BICYCLE into wMapMusic while riding. Ask its
      -- native resolver for the location's actual (story-aware) song.
      if game.world and world and world.mapMusicSong then
        -- The method returns only story overrides, not ordinary map
        -- themes; vanilla Music.playMap supplies the registry fallback.
        area = world:mapMusicSong(world.map.id)
          or (data.audio and data.audio.mapSongs and data.audio.mapSongs[world.map.id])
          or area
      end
      if area then selected = area end
    end
    -- Substitute before nextLink so another mod sees the intended song and
    -- can replace it, mute it or apply its own selection rules normally.
    local final = nextLink(selected, context)
    selectedMapSong = final
    mapCueActive = final ~= nil
    if syncLayer then
      -- Native Gen 2 requests reason="bike" before changing playerState.
      -- Prepare the independent source now, before the area Source plays,
      -- while preserving area audio if preparation fails.
      syncLayer(game, 0, {riding = riding, surfing = surfing, song = final})
    end
    return final
  end, 50)

  subscriptions[#subscriptions + 1] = mod.events:on("music.started", function(event)
    if event.reason == "map" or event.reason == "bike" then
      selectedMapSong, activeMapSong, mapCueActive = event.song, event.song, true
    elseif (event.reason == "audiorate" or event.reason == "devicereset")
        and event.song == selectedMapSong then
      mapCueActive = true
    else
      mapCueActive = false
      syncProfiles(currentGame or (mod and mod.game))
      parkLayer()
    end
  end)

  subscriptions[#subscriptions + 1] = mod.events:on("music.stopped", function()
    mapCueActive = false
    syncProfiles(currentGame or (mod and mod.game))
    parkLayer()
  end)

  subscriptions[#subscriptions + 1] = mod.events:on("sound.played", function(event)
    local data = gameData(currentGame or (mod and mod.game))
    if event.kind == "sfx" and data and Sound.ducksMusic(data, event.name) then
      fanfares[event.name] = true
      pauseLayer()
    end
  end)

  subscriptions[#subscriptions + 1] = mod.events:on("save.loading", function()
    selectedMapSong, activeMapSong, mapCueActive, fanfares = nil, nil, false, {}
    syncProfiles(currentGame or (mod and mod.game))
    api.stop()
  end)

  function api.refresh(game)
    if disposed then return end
    currentGame = game or currentGame or (mod and mod.game)
    local data = gameData(currentGame)
    local riding, world, surfing = bicycleState(currentGame)
    -- Do not replace battle, title, evolution, radio or one-shot scene music
    -- when the player changes a setting from an options page over that scene.
    if data and world and mapCueActive and Music.current() == selectedMapSong
        and not Music.oneShotPlaying() then
      Music.playMap(data, world.map.id, riding, surfing, nil, Music.mapSong())
    end
    api.stop()
    retryAt = 0
    if syncLayer then syncLayer(currentGame, 0) end
  end

  local function runLayer(layer,game)
    applyOverlayVolume(game,layer)
    local filled,err=fillBuffers(layer)
    if not filled then return false,err end
    local ok,playing=withSource(layer.source,"isPlaying")
    if not ok then return false,"Audio source became unavailable" end
    if not playing then
      if layer.started and not layer.paused and layer.loopSource then
        release(layer.source);layer.source,layer.loopSource=layer.loopSource,nil
      elseif layer.chip and layer.started and not layer.paused and layer.engine:finished() then
        -- Finite soundtrack cues have no native repeat: start a fresh sequencer
        -- only after all queued samples have drained, rather than spin on silence.
        layer.engine=ChipSynth.newEngine(layer.data,layer.def,{allowLoops=true})
        local done,why=fillBuffers(layer);if not done then return false,why end
      end
      local started,playErr=withSource(layer.source,"play")
      if not started or playErr==false then return false,playErr or "Could not start audio" end
    end
    layer.started,layer.paused,layer.parked=true,false,false
    return true
  end
  function api.stopPreview()
    if preview then release(preview.source);release(preview.loopSource);preview=nil end
    previewOwner=nil;setAreaSuppressed(false)
  end
  function api.preview(game,request,owner)
    if disposed or Runtime.safeMode then return false,"Preview unavailable" end
    currentGame=game or currentGame
    if not mapCueActive or Music.oneShotPlaying() then return false,"Preview from the overworld" end
    api.stopPreview();pauseLayer()
    layerDepth=layerDepth+1
    local ok,result,err=pcall(makeOverlay,gameData(currentGame),bikeLabel(gameData(currentGame)),request,true)
    layerDepth=layerDepth-1
    if not ok then err,result=result,nil end
    if not result then return false,tostring(err or "Song unavailable") end
    preview,previewOwner=result,owner
    local played,why=pcall(runLayer,preview,currentGame)
    if not played or not why then api.stopPreview();return false,"Could not play preview" end
    setAreaSuppressed(true);return true
  end
  function api.isPreviewing()return preview~=nil end

  syncLayer = function(game, dt, cue)
    if disposed then return end
    if Runtime.hooks ~= ownedHooks or Runtime.events ~= ownedEvents then
      api.dispose()
      return
    end
    currentGame = game or currentGame or (mod and mod.game)
    dt = tonumber(dt) or 0
    if dt == dt and dt > 0 then clock = clock + math.min(dt, 1) end
    syncProfiles(currentGame, cue)
    local riding, world, surfing = bicycleState(currentGame)
    local data = gameData(currentGame)
    local label = data and bikeLabel(data)
    if cue then riding, surfing = cue.riding, cue.surfing end
    if preview then
      local owns=previewOwner and currentGame and currentGame.stack and currentGame.stack:top()==previewOwner
      if not owns or not mapCueActive or Music.oneShotPlaying() then api.stopPreview()
      elseif ChipAudio.isSuspended() or fanfareActive() then
        withSource(preview.source,"pause");preview.paused=true;return
      else
        local ok,worked,why=pcall(runLayer,preview,currentGame)
        if not ok or not worked then api.stopPreview();lastFailure=tostring(why or worked)
        else setAreaSuppressed(true) end
        return
      end
    end
    if ridingMusic() == "area" then parkLayer(); return end
    if not riding or surfing or not world or not data
        or not mapCueActive
        or (not cue and Music.current() ~= selectedMapSong and Music.current() ~= activeMapSong)
        or (cue and cue.song == label) or (not cue and Music.current() == label)
        or Music.oneShotPlaying() then
      parkLayer()
      return
    end
    -- AREA OFF is independent; only BICYCLE OFF stops this sequencer.
    if level(setting("bike_volume"), 7) == 0 then
      parkLayer()
      setAreaSuppressed(ridingMusic() == "bicycle")
      return
    end
    if ChipAudio.isSuspended() or fanfareActive() then
      setAreaSuppressed(ridingMusic() == "bicycle" and overlay ~= nil)
      pauseLayer()
      return
    end
    if overlay and (overlay.request ~= (setting("bike_song") or "original")
        or overlay.revision ~= (songs and songs.revision or 0)
        or (not overlay.custom and (overlay.data ~= data or overlay.baseLabel ~= label
          or overlay.def ~= (data.audio.songs and data.audio.songs[overlay.label])))
        or (overlay.chip and (overlay.rate ~= ChipSynth.SAMPLE_RATE
          or overlay.stereo ~= ChipSynth.getStereo()))) then
      api.stop()
    end
    if not overlay then
      if clock < retryAt then return end
      layerDepth = layerDepth + 1
      local made, result, err = pcall(makeOverlay, data, label)
      layerDepth = layerDepth - 1
      if not made then err, result = result, nil end
      if not result and (setting('bike_song') or 'original')~='original' then
        local why=tostring(err or 'Custom song unavailable')
        layerDepth=layerDepth+1
        local ok,fallback=pcall(makeOverlay,data,label,'original')
        layerDepth=layerDepth-1
        if ok and fallback then
          result=fallback;result.request=setting('bike_song');result.fallback=true
          if songs then songs.error=why end
        end
      end
      if not result then
        -- A downstream selection mod deliberately muted or merged the two
        -- labels. Honour that decision without flagging it as an error.
        if err then report(err) else retryAt = clock + 0.5 end
        return
      end
      overlay = result
      lastFailure = nil
    end
    local ran,worked,err=pcall(runLayer,overlay,currentGame)
    if not ran or not worked then report(err or worked);return end
    setAreaSuppressed(ridingMusic() == "bicycle")
  end

  function api.update(game, dt)
    syncLayer(game, dt)
  end

  subscriptions[#subscriptions + 1] = mod.events:on("mod.options_changed", function(event)
    if not disposed and mod and mod.id and event.mod == mod.id then
      -- Native menu and mod-manager writes both emit this event after
      -- saving. Apply the profile now without restarting either song.
      api.update(currentGame or mod.game, 0)
    end
  end)

  function api.status()
    local game = currentGame or (mod and mod.game)
    local riding = bicycleState(game)
    return { mode = "independent", ridingMusic = ridingMusic(),
      areaSuppressed = areaSuppressed, ridingProfile = ridingProfile,
      effectiveAreaVolume = profileValue("riding_area_volume", normalMusicLevel, 7),
      effectiveAreaFilter = profileValue("riding_area_filter", normalAreaFilter, 3),
      effectiveSfxVolume = profileValue("riding_sfx_volume", normalSfxLevel, 7),
      effectiveSfxFilter = effectiveSfxFilter(), layerActive = overlay ~= nil,
      layerPaused = overlay and overlay.paused or false, error = lastFailure,
      mapCueActive = mapCueActive, selectedMapSong = selectedMapSong,
      currentSong = Music.current(), onBike = riding,
      bikeVolume = level(setting("bike_volume"), 7),
      musicVolume = level(options(game).musicVol, 7),
      bikeGain = overlay and overlay.volume or 0,
      bikeFilter = filterLevel(setting("bike_filter")),
      areaFilter = filterLevel(options(game).musicFilter),
      sfxFilter = filterLevel(setting("sfx_filter")),
      filterUnavailable = filterUnavailable, song=setting("bike_song") or "original",
      songError=songs and songs.error, previewActive=preview~=nil,
      layerSong=overlay and overlay.label, parked=overlay and overlay.parked or false }
  end

  function api.dispose()
    if disposed then return end
    ridingProfile = false
    areaSuppressed = false
    disposed = true
    -- The native setters now bypass our retired wrappers and restore the
    -- latest normal settings before the next session can reuse Sources.
    Music.setVolumeLevel(normalMusicLevel)
    Music.setFilterLevel(normalAreaFilter)
    Sound.setVolumeLevel(normalSfxLevel)
    api.stop()
    for source, entry in pairs(soundSources) do restoreSfxFilter(source, entry) end
    soundSources = setmetatable({}, {__mode="k"})
    for i = #methodWrappers, 1, -1 do
      local item = methodWrappers[i]
      if item.target[item.name] == item.wrapper then item.target[item.name] = item.previous end
    end
    methodWrappers = {}
    for _, unsubscribe in ipairs(subscriptions) do unsubscribe() end
    subscriptions = {}
    currentGame = nil
    nativeSources = setmetatable({}, {__mode="k"})
    selectedMapSong, activeMapSong, mapCueActive, fanfares = nil, nil, false, {}
    -- Assets.register retains callbacks for the process lifetime. Cut the
    -- loader, settings closure and old buses out of those retained closures.
    if songs then songs.clear() end
    mod, settings, ownedHooks, ownedEvents, songs = nil, nil, nil, nil, nil
  end

  -- These callbacks run for asset reloads and before a mounted game's data
  -- is discarded, so neither an old Source nor old ROM-program engine leaks
  -- into the next loaded game. They retain no reference to the game object.
  Assets.register({
    invalidate = function()
      api.stop()
      if songs then songs.clear()end
      retryAt, warned = 0, {}
      if Runtime.hooks ~= ownedHooks or Runtime.events ~= ownedEvents then api.dispose() end
    end,
    release = function()
      -- releaseSession is session teardown, unlike a hot-reload flush.
      -- It precedes Runtime.reset, so disposal must happen immediately.
      api.dispose()
    end,
  })
  return api
end

return Audio
