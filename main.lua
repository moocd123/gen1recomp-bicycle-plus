-- AUTOBIKE+: retain bicycle_plus as the update/settings identity.
return function(mod)
  local function module(name)
    return assert(load(assert(mod:read(name .. ".lua")),
      "@bicycle_plus/" .. name .. ".lua"))()
  end

  local SongLibrary = module("song_library")
  local songs = SongLibrary.init(mod)
  songs.attachPicker(module("import_picker").init(mod,songs))
  local songMenu

  local Hardware = module("colour_values").extend(module("hardware_colours"))
  local colourChoices = Hardware.quickChoices
  local colourKeys = {bike_colour=true, bike_stripes_colour=true,
    bike_centres_colour=true, bike_tyres_colour=true, bike_frame_colour=true, bike_handlebars_colour=true}
  local spellingChoices = {{"ENGLISH UK", "uk"}, {"ENGLISH US", "us"}}
  local filterChoices = {{"OFF", 0}, {"1X", 1}, {"2X", 2}, {"3X", 3}}
  local ridingMusicChoices = {{"AREA", "area"}, {"BICYCLE", "bicycle"}, {"BOTH", "both"}}
  local ridingFilterChoices = {{"SAME", -1}, {"OFF", 0}, {"1X", 1}, {"2X", 2}, {"3X", 3}}
  local ridingVolumeChoices = {{"SAME", -1}, {"OFF", 0}, {"1", 1}, {"2", 2},
    {"3", 3}, {"4", 4}, {"5", 5}, {"6", 6}, {"7", 7}}
  local ridingOverrides = {
    riding_area_volume=7, riding_area_filter=3, riding_sfx_volume=7, riding_sfx_filter=3,
  }
  local defaults = {bike_song="original", bike_song_resume=false, auto_mount=true, bike_volume=7, bike_filter=0,
    sfx_filter=0, bike_colour="original", bike_stripes_colour="original",
    bike_centres_colour="original", bike_tyres_colour="original", bike_frame_colour="original", bike_handlebars_colour="original",
    spelling="uk", riding_music="both",
    riding_area_volume=-1, riding_area_filter=-1, riding_sfx_volume=-1, riding_sfx_filter=-1}
  local function allowed(choices, value)
    for _, choice in ipairs(choices) do if choice[2] == value then return true end end
    return false
  end
  local function getSetting(key)
    local v = mod.options:get(key)
    if key == "auto_mount" then return v ~= false end
    if key == "bike_song" then return SongLibrary.valid(v) and v or "original" end
    if key == "bike_song_resume" then return v == true end
    if key == "bike_volume" then
      return math.max(0, math.min(7, math.floor(tonumber(v) or 7)))
    end
    if key == "bike_filter" or key == "sfx_filter" then
      return math.max(0, math.min(3, math.floor(tonumber(v) or 0)))
    end
    if key == "spelling" and not allowed(spellingChoices,v) then return "uk" end
    if colourKeys[key] then return Hardware.canonical(v) or "original" end
    if key == "riding_music" and not allowed(ridingMusicChoices,v) then return "both" end
    if ridingOverrides[key] then
      return math.max(-1, math.min(ridingOverrides[key], math.floor(tonumber(v) or -1)))
    end
    if v == nil then return defaults[key] end
    return v
  end

  local function colourWord() return getSetting("spelling") == "us" and "COLOR" or "COLOUR" end
  local function centreWord() return getSetting("spelling") == "us" and "CENTER" or "CENTRE" end
  local function choicesFor(key)
    local choices={}
    local raw=mod.options:get(key)
    for i,row in ipairs(colourChoices) do
      -- The native manager reads raw storage; preserve a legacy alias only
      -- for its matching row, never display a duplicate of the same colour.
      choices[i]={row[1],Hardware.canonical(raw)==row[2] and raw or row[2]}
    end
    local current=getSetting(key)
    if not allowed(colourChoices,current) then choices[#choices+1]={Hardware.label(current),current} end
    -- The generic mod-manager stays small; the full picker lives in-game.
    return choices
  end
  local function defineOptions()
    mod.options:define({
      {key="auto_mount", type="toggle", label="AUTO BIKE", default=true},
      {key="bike_song_resume",type="toggle",label="RESUME BIKE SONG",default=false},
      {key="bike_colour", type="choice", label="WHEEL " .. colourWord(),
        default="original", choices=choicesFor("bike_colour")},
      {key="bike_stripes_colour", type="choice", label="STRIPE " .. colourWord(),
        default="original", choices=choicesFor("bike_stripes_colour")},
      {key="bike_centres_colour", type="choice", label=centreWord() .. " " .. colourWord(),
        default="original", choices=choicesFor("bike_centres_colour")},
      {key="bike_tyres_colour", type="choice", label="EDGE " .. colourWord(),
        default="original", choices=choicesFor("bike_tyres_colour")},
      {key="bike_frame_colour", type="choice", label="DETAILS " .. colourWord(),
        default="original", choices=choicesFor("bike_frame_colour")},
      {key="bike_handlebars_colour", type="choice", label="HANDLEBARS " .. colourWord(),
        default="original", choices=choicesFor("bike_handlebars_colour")},
      {key="riding_music", type="choice", label="MUSIC ON BIKE", default="both",
        choices=ridingMusicChoices},
      {key="bike_volume", type="number", label="BIKE VOLUME", default=7,
        min=0, max=7, step=1},
      {key="riding_area_volume", type="choice", label="RIDING AREA VOL", default=-1,
        choices=ridingVolumeChoices},
      {key="riding_area_filter", type="choice", label="RIDING AREA FILTER", default=-1,
        choices=ridingFilterChoices},
      {key="riding_sfx_volume", type="choice", label="RIDING SFX VOL", default=-1,
        choices=ridingVolumeChoices},
      {key="riding_sfx_filter", type="choice", label="RIDING SFX FILTER", default=-1,
        choices=ridingFilterChoices},
      {key="bike_filter", type="choice", label="BIKE FILTER", default=0,
        choices=filterChoices},
      {key="sfx_filter", type="choice", label="SFX FILTER", default=0,
        choices=filterChoices},
      {key="spelling", type="choice", label="LANGUAGE", default="uk",
        choices=spellingChoices},
    })
  end
  defineOptions()

  local automount = module("automount").init(mod, getSetting)
  local audio = module("audio").init(mod, getSetting, songs)
  local colours = module("colours").init(mod, getSetting, module("bike_parts"), Hardware)
  local Runtime = require("src.mods.Runtime")
  local Font = require("src.render.Font")
  local Theme = require("src.ui.Theme")
  local PaletteFX = require("src.render.PaletteFX")
  local Screens = require("src.ui.Screens")
  local currentGame, migrateSettings

  local function setSetting(game, key, value)
    if Runtime.safeMode or defaults[key] == nil then return false end
    if migrateSettings then migrateSettings(game) end
    if key == "auto_mount" then value = value == true end
    if key == "bike_song_resume" then value = value == true end
    if key == "bike_song" and not SongLibrary.valid(value) then return false end
    if key == "bike_volume" then
      value = math.max(0,math.min(7,math.floor(tonumber(value) or 7)))
    end
    if key == "bike_filter" or key == "sfx_filter" then
      value = math.max(0,math.min(3,math.floor(tonumber(value) or 0)))
    end
    if key == "spelling" and not allowed(spellingChoices,value) then return false end
    if colourKeys[key] then
      value=Hardware.canonical(value)
      if not value then return false end
    end
    if key == "riding_music" and not allowed(ridingMusicChoices,value) then return false end
    if ridingOverrides[key] then
      value = math.max(-1, math.min(ridingOverrides[key], math.floor(tonumber(value) or -1)))
    end
    if not (game and game.save and game.save.options and game.mods) then return false end
    local options = game.save.options
    options.modOptions = options.modOptions or {}
    options.modOptions[mod.id] = options.modOptions[mod.id] or {}
    options.modOptions[mod.id][key] = value
    game.mods.modOptions = game.mods.modOptions or {}
    game.mods.modOptions[mod.id] = game.mods.modOptions[mod.id] or {}
    game.mods.modOptions[mod.id][key] = value
    -- Same two stores and persistence method as the native mod manager.
    if game.writeOptions then game:writeOptions() end
    if game.mods.events then
      game.mods.events:emit("mod.options_changed", {mod=mod.id,key=key,value=value})
    end
    if key == "spelling" or key == "bike_song" or colourKeys[key] then defineOptions() end
    return true
  end

  -- Routing and gain are independent. Never turn a stored volume down just
  -- because the player chooses not to hear that track for the current ride.
  local function migrateAudio(game)
    if Runtime.safeMode or not (game and game.save and game.save.options and game.mods) then return end
    local o=game.save.options;o.modOptions=o.modOptions or {};game.mods.modOptions=game.mods.modOptions or {}
    local saved=o.modOptions[mod.id] or {};local live=game.mods.modOptions[mod.id] or {}
    if (tonumber(saved._audio_layout) or 0)>=4 or (tonumber(live._audio_layout) or 0)>=4 then return end
    local mode=live.riding_music or saved.riding_music or live.music_mode or saved.music_mode
    if mode=='cycling' then mode='bicycle' end
    if not allowed(ridingMusicChoices,mode) then mode='both' end
    -- v1.9.0 stored BOTH and explicit zero volumes. Keep those values exactly:
    -- it did not retain the previous gains, so guessing would overwrite user edits.
    -- Direct upgrades from earlier versions retain their saved routing choice.
    saved.riding_music,live.riding_music=mode,mode
    saved._audio_layout,live._audio_layout=4,4
    o.modOptions[mod.id],game.mods.modOptions[mod.id]=saved,live
    if game.writeOptions then game:writeOptions() end
  end

  -- Version 1.3 coloured wheel centres and outlines with one TYRES setting.
  -- Keep its saved key for EDGE and seed the new CENTRE only when it has never
  -- been set. Read the raw stores: options:get substitutes schema defaults,
  -- so it cannot distinguish an absent setting from an explicit ORIGINAL.
  local function migrateColours(game)
    if Runtime.safeMode or not (game and game.save and game.save.options and game.mods) then return end
    local options=game.save.options
    local saved=options.modOptions and options.modOptions[mod.id] or {}
    local live=game.mods.modOptions and game.mods.modOptions[mod.id] or {}
    if live.bike_centres_colour ~= nil or saved.bike_centres_colour ~= nil then return end
    local old=live.bike_tyres_colour
    if old == nil then old=saved.bike_tyres_colour end
    -- Persist ORIGINAL even on a fresh install. Otherwise the first new EDGE
    -- edit could be mistaken for a legacy combined setting on the next update.
    local value=Hardware.canonical(old) or "original"
    saved.bike_centres_colour=value
    live.bike_centres_colour=value
    options.modOptions=options.modOptions or {}
    game.mods.modOptions=game.mods.modOptions or {}
    options.modOptions[mod.id],game.mods.modOptions[mod.id]=saved,live
    if game.writeOptions then game:writeOptions() end
  end
  migrateSettings=function(game)
    migrateAudio(game)
    migrateColours(game)
  end
  local UI = module("colour_ui").init(mod)
  local menus = module("settings_menu").init(mod,UI)
  songMenu = module("music_menu").init(mod, {
    ui=UI,menus=menus,library=songs,audio=audio,getSetting=getSetting,setSetting=setSetting,
  })
  local audioMenu = module("audio_menu").init(mod, {
    menus=menus,getSetting=getSetting,setSetting=setSetting,
    openSong=function(game)return songMenu.open(game)end,
  })
  -- Chained callback scoped to a visible music menu. Other dropped files
  -- and other screens retain the engine/previous mod handler unchanged.
  local previousDrop=love.filedropped
  local dropState={active=true,menu=songMenu,game=mod.game,hooks=Runtime.hooks,events=Runtime.events}
  local dropWrapper
  dropWrapper=function(file,...)
    if dropState.hooks~=Runtime.hooks or dropState.events~=Runtime.events then
      dropState.active=false;dropState.game=nil;dropState.menu=nil
    end
    if dropState.active and dropState.menu.fileDropped(dropState.game,file) then return end
    if previousDrop then return previousDrop(file,...) end
  end
  love.filedropped=dropWrapper
  local function retireLibrary()
    dropState.active=false;dropState.menu=nil;dropState.game=nil
    songs.shutdown()
    if love.filedropped==dropWrapper then love.filedropped=previousDrop end
  end
  require("src.render.Assets").register({release=retireLibrary})

  local picker = module("colour_picker").init(mod, {
    hardware=Hardware, colours=colours, getSetting=getSetting, setSetting=setSetting,
    colourWord=colourWord, ui=UI,
  })

  local function cycle(choices, value, direction)
    local at = 1
    for i, choice in ipairs(choices) do if choice[2] == value then at=i break end end
    return choices[(at-1+(direction < 0 and -1 or 1)) % #choices + 1][2]
  end
  local function label(choices, value)
    for _, choice in ipairs(choices) do if choice[2] == value then return choice[1] end end
    return "ORIGINAL"
  end
  local function palette(self, game)
    -- Keep menu text readable in the engine's SGB/Advanced colour passes.
    return PaletteFX.wholeNamed((game or self.game).data, "MEWMON")
  end
  local function previewPalette(self, game)
    local g = game or self.game
    local zones = palette(self,g)
    local rect = self.bicyclePlusPreviewRect
    for _,zone in ipairs(colours.previewZones(g,rect.x,rect.y,rect.scale)) do zones[#zones+1]=zone end
    return zones
  end
  local function openSettings(game)
    return menus.open(game,{title='AUTOBIKE+',tag='autobike.settings',rows={
      {label='AUTO BIKE',value=function()return getSetting('auto_mount') and 'ON' or 'OFF'end,
       step=function(_,s)setSetting(s.game,'auto_mount',not getSetting('auto_mount'))end},
      {label='SFX FILTER',value=function()return label(filterChoices,getSetting('sfx_filter'))end,
       step=function(d,s)setSetting(s.game,'sfx_filter',cycle(filterChoices,getSetting('sfx_filter'),d))end},
      {label='BIKE APPEARANCE',action=function(s)Screens.push(s.game,'BicyclePlusColours')end},
      {label='BIKE AUDIO',action=function(s)audioMenu.open(s.game)end},
      {label='LANGUAGE',value=function()return getSetting('spelling')=='us' and 'US' or 'UK'end,
       step=function(d,s)setSetting(s.game,'spelling',cycle(spellingChoices,getSetting('spelling'),d))end},
    },footer='LR:CHANGE  A:OPEN'})
  end

  local controls = module("colour_controls").init(mod, {
    hardware=Hardware, colours=colours, picker=picker, getSetting=getSetting,
    setSetting=setSetting, migrate=migrateSettings, refreshOptions=defineOptions,
    colourWord=colourWord, ui=UI, centreWord=centreWord, palette=palette, previewPalette=previewPalette,
  })

  mod.hooks:wrap("ui.options.rows", function(next,game,rows)
    migrateSettings(game)
    audioMenu.update(game)
    rows=next(game,rows)
    for _,row in ipairs(rows) do if row.id=="bicycle_plus.settings" then return rows end end
    rows[#rows+1]={id="bicycle_plus.settings",label="AUTOBIKE+",port=true,
      value=function() return "SETTINGS" end,
      activate=function(g) openSettings(g) end}
    return rows
  end)

  local function update(game,dt)
    currentGame=game
    dropState.game=game
    if songs.picker and songs.picker.hasWork() then
      local row,err=songs.poll()
      if row or err then songs.lastImport={row=row,error=err} end
    end
    migrateSettings(game)
    audioMenu.update(game)
    automount.update(game)
    colours.update(game)
    audio.update(game,dt)
  end
  mod.hooks:wrap("core.update",function(next,game,dt)
    local result=next(game,dt)
    update(game,dt)
    return result
  end,-100)
  -- Native fixed-step callback also covers engine frame drivers and avoids
  -- missing a free tile boundary while a direction is held continuously.
  mod.hooks:wrap("input.step",function(next,game,dt)
    currentGame=game
    automount.update(game)
    return next(game,dt)
  end,-100)
  mod.events:on("game.ready",function(ev)
    currentGame=ev.game
    dropState.game=ev.game
    migrateSettings(currentGame)
    audioMenu.update(currentGame)
  end)
  mod.events:on("save.loading",function() audio.stop() end)
  mod.hooks:wrap("core.quit_to_launcher",function(next,...)
    audio.stopPreview()
    audio.stop()
    retireLibrary()
    return next(...)
  end)
  -- Diagnostics and automated verification; no global variables or hotkeys.
  mod.exports.audioMenu=audioMenu
  mod.exports.menus=menus
  mod.exports.songLibrary=songs
  mod.exports.songMenu=songMenu
  mod.exports.openSongs=songMenu.open
  mod.exports.audio=audio
  mod.exports.update=update
  mod.exports.getSetting=getSetting
  mod.exports.hardwareColours=Hardware
  mod.exports.openColourPicker=picker.open
  mod.exports.resetColours=controls.reset
  mod.exports.bikeArtStyle=colours.artStyle
  mod.exports.colourUI=UI
  mod.exports.picker=picker
  mod.exports.setSetting=setSetting
  mod.exports.status=function()
    return {automount=automount.status and automount.status(),
      audio=audio.status and audio.status(),colours=colours.status and colours.status(currentGame)}
  end
  mod.exports.openSettings=function(game)
    game=game or currentGame; migrateSettings(game)
    return openSettings(game)
  end
  mod.exports.openColours=function(game)
    game=game or currentGame; migrateSettings(game)
    Screens.push(game,"BicyclePlusColours")
  end
  mod.exports.openAudio=function(game)
    game=game or currentGame; migrateSettings(game); return audioMenu.open(game)
  end
end