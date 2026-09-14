-- Bicycle Plus: source-only native mod for Gen1ReComp++ 0.2.59.
return function(mod)
  local function module(name)
    return assert(load(assert(mod:read(name .. ".lua")),
      "@bicycle_plus/" .. name .. ".lua"))()
  end

  local Hardware = module("hardware_colours")
  local colourChoices = Hardware.quickChoices
  local colourKeys = {bike_colour=true, bike_stripes_colour=true,
    bike_centres_colour=true, bike_tyres_colour=true, bike_frame_colour=true}
  local spellingChoices = {{"ENGLISH UK", "uk"}, {"ENGLISH US", "us"}}
  local filterChoices = {{"OFF", 0}, {"1X", 1}, {"2X", 2}, {"3X", 3}}
  local ridingMusicChoices = {{"BICYCLE", "bicycle"}, {"AREA", "area"}, {"BOTH", "both"}}
  local ridingFilterChoices = {{"SAME", -1}, {"OFF", 0}, {"1X", 1}, {"2X", 2}, {"3X", 3}}
  local ridingVolumeChoices = {{"SAME", -1}, {"OFF", 0}, {"1", 1}, {"2", 2},
    {"3", 3}, {"4", 4}, {"5", 5}, {"6", 6}, {"7", 7}}
  local ridingOverrides = {
    riding_area_volume=7, riding_area_filter=3, riding_sfx_volume=7, riding_sfx_filter=3,
  }
  local defaults = {auto_mount=true, bike_volume=7, bike_filter=0,
    sfx_filter=0, bike_colour="original", bike_stripes_colour="original",
    bike_centres_colour="original", bike_tyres_colour="original", bike_frame_colour="original",
    spelling="uk", riding_music="both",
    riding_area_volume=-1, riding_area_filter=-1, riding_sfx_volume=-1, riding_sfx_filter=-1}
  local function allowed(choices, value)
    for _, choice in ipairs(choices) do if choice[2] == value then return true end end
    return false
  end
  local function getSetting(key)
    local v = mod.options:get(key)
    if key == "auto_mount" then return v ~= false end
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
      {key="auto_mount", type="toggle", label="AUTO BICYCLE", default=true},
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
      {key="bike_volume", type="number", label="BIKE VOLUME", default=7,
        min=0, max=7, step=1},
      {key="riding_music", type="choice", label="MUSIC ON BIKE", default="both",
        choices=ridingMusicChoices},
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
  local audio = module("audio").init(mod, getSetting)
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
    if key == "spelling" or colourKeys[key] then defineOptions() end
    return true
  end

  -- Old AREA/BICYCLE/BOTH preferences become independent native-scale gains.
  -- Retain the old keys as migration history, but never consume them at runtime.
  local function migrateAudio(game)
    if Runtime.safeMode or not (game and game.save and game.save.options and game.mods) then return end
    local options = game.save.options
    options.modOptions = options.modOptions or {}
    game.mods.modOptions = game.mods.modOptions or {}
    local saved = options.modOptions[mod.id] or {}
    local live = game.mods.modOptions[mod.id] or {}
    if live._audio_layout == 2 or saved._audio_layout == 2 then return end
    local old = live.music_mode or saved.music_mode
    local legacy = old ~= nil
    local function put(key,value) saved[key]=value; live[key]=value end
    if legacy then
      if old == "area" then put("bike_volume",0)
      elseif old == "cycling" then
        options.musicVol = 0
        require("src.core.Music").setVolumeLevel(0)
      end
      if live.bike_filter == nil and saved.bike_filter == nil then
        put("bike_filter",math.max(0,math.min(3,tonumber(options.musicFilter) or 0)))
      end
    end
    put("_audio_layout",2)
    options.modOptions[mod.id], game.mods.modOptions[mod.id] = saved, live
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
  local audioMenu = module("audio_menu").init(mod, {
    getSetting=getSetting, setSetting=setSetting,
  })

  local picker = module("colour_picker").init(mod, {
    hardware=Hardware, colours=colours, getSetting=getSetting, setSetting=setSetting,
    colourWord=colourWord,
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
  local function menuRows()
    return {
      {id="bicycle_plus.auto",label="AUTO BICYCLE",
        value=function() return getSetting("auto_mount") and "ON" or "OFF" end,
        step=function(g) return setSetting(g,"auto_mount",not getSetting("auto_mount")) end},
      {id="bicycle_plus.audio",label="AUDIO",
        value=function() return "VOLUMES/FILTERS" end,
        activate=function(g) audioMenu.open(g) end},
      {id="bicycle_plus.colour",label=function() return "BIKE " .. colourWord() end,
        value=function() return "WHEEL:" .. Hardware.label(getSetting("bike_colour")) end,
        activate=function(g) Screens.push(g,"BicyclePlusColours") end},
      {id="bicycle_plus.spelling",label="LANGUAGE",
        value=function() return label(spellingChoices,getSetting("spelling")) end,
        step=function(g,d) return setSetting(g,"spelling",cycle(spellingChoices,getSetting("spelling"),d)) end},
    }
  end

  mod.content.screens:register("BicyclePlusSettings", {new=function(game)
    local self = {game=game,isOpaque=true,isModOptions=true,index=1,rows=menuRows(),sgbPalettes=palette}
    function self:update()
      local input = self.game.input
      if input:wasPressed("b") or input:wasPressed("start") then self.game.stack:pop() return end
      local last=#self.rows+1
      if input:wasPressed("up") then self.index=(self.index-2)%last+1
      elseif input:wasPressed("down") then self.index=self.index%last+1
      elseif input:wasPressed("left") or input:wasPressed("right") or input:wasPressed("a") then
        local row=self.rows[self.index]
        if not row then if input:wasPressed("a") then self.game.stack:pop() end
        elseif row.activate then if input:wasPressed("a") then row.activate(self.game) end
        else row.step(self.game,input:wasPressed("left") and -1 or 1) end
      end
    end
    function self:draw()
      -- The game's four-box volume-menu layout, built from the shared font
      -- API so this screen works on both generations without a Gen1-only UI.
      local G=love.graphics
      G.setColor(1,1,1,1) G.rectangle("fill",0,0,160,144)
      for i,row in ipairs(self.rows) do
        Font.drawBox(0,(i-1)*4,20,4)
        G.setColor(0,0,0,1)
        Font.draw(type(row.label)=="function" and row.label() or row.label,16,(i-1)*32+8)
        Font.draw(row.value(self.game),24,(i-1)*32+16)
        if i==self.index then Font.drawCode(Theme.cursor,8,(i-1)*32+8) end
        G.setColor(1,1,1,1)
      end
      G.setColor(0,0,0,1) Font.draw("BACK",16,136)
      if self.index==#self.rows+1 then Font.drawCode(Theme.cursor,8,136) end
      G.setColor(1,1,1,1)
    end
    return self
  end})

  mod.content.screens:register("BicyclePlusColours", {new=function(game)
    migrateSettings(game)
    local self={game=game,isOpaque=true,isModOptions=true,timer=0,index=1,
      sgbPalettes=previewPalette,bicyclePlusPreviewRect={x=16,y=24,scale=2},
      rows={
        {key="bike_colour",label=function() return "WHEEL" end},
        {key="bike_stripes_colour",label=function() return "STRIPE" end},
        {key="bike_centres_colour",label=centreWord},
        {key="bike_tyres_colour",label=function() return "EDGE" end},
        {key="bike_frame_colour",label=function() return "DETAILS" end},
      }}
    function self:update(dt)
      self.timer=self.timer+(dt or 0)
      local input=self.game.input
      if input:wasPressed("b") or input:wasPressed("start") then
        self.game.stack:pop() return
      end
      if input:wasPressed("a") then
        local row=self.rows[self.index]
        picker.open(self.game,row.key,row.label())
        return
      end
      if input:wasPressed("select") and colours.needsColourMode(self.game) then
        colours.enableColourMode(self.game); return
      end
      if input:wasPressed("up") then self.index=(self.index-2)%#self.rows+1
      elseif input:wasPressed("down") then self.index=self.index%#self.rows+1
      elseif input:wasPressed("left") or input:wasPressed("right") then
        local key=self.rows[self.index].key
        setSetting(self.game,key,cycle(colourChoices,getSetting(key),input:wasPressed("left") and -1 or 1))
      end
    end
    function self:draw()
      local G=love.graphics
      G.setColor(1,1,1,1) G.rectangle("fill",0,0,160,144)
      Font.drawBox(0,0,20,18)
      G.setColor(0,0,0,1)
      local title = "BICYCLE " .. colourWord()
      Font.draw(title,math.floor((160-#title*8)/2),8)
      G.setColor(1,1,1,1)
      local rect=self.bicyclePlusPreviewRect
      -- Read all five saved parts together so the preview and world agree.
      local ok,status=colours.drawPreview(self.game,rect.x,rect.y,rect.scale,self.timer)
      G.setColor(0,0,0,1)
      if ok == false then Font.draw("ENTER GAME FIRST",16,56)
      elseif status == "Custom bike art kept original" then Font.draw("ART KEPT ORIGINAL",12,56)
      elseif status == "Colour readback unavailable" then Font.draw(colourWord() .. " NOT READY",16,56) end
      for i,row in ipairs(self.rows) do
        local y=64+(i-1)*11
        local value=Hardware.label(getSetting(row.key))
        Font.draw(row.label(),16,y)
        Font.draw(value,144-#value*8,y)
        if i==self.index then Font.drawCode(Theme.cursor,8,y) end
      end
      Font.draw("A:PICK LR:QUICK",16,120)
      if colours.needsColourMode(self.game) then
        Font.draw("SEL:" .. colours.colourModeName(self.game) .. " B:BACK",4,128)
      else Font.draw("B:BACK  SAVED",24,128) end
      G.setColor(1,1,1,1)
    end
    return self
  end})

  mod.hooks:wrap("ui.options.rows", function(next,game,rows)
    migrateSettings(game)
    audioMenu.update(game)
    rows=next(game,rows)
    for _,row in ipairs(rows) do if row.id=="bicycle_plus.settings" then return rows end end
    rows[#rows+1]={id="bicycle_plus.settings",label="BICYCLE +",port=true,
      value=function() return "SETTINGS" end,
      activate=function(g) Screens.push(g,"BicyclePlusSettings") end}
    return rows
  end)

  local function update(game,dt)
    currentGame=game
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
    migrateSettings(currentGame)
    audioMenu.update(currentGame)
  end)
  mod.events:on("save.loading",function() audio.stop() end)
  mod.hooks:wrap("core.quit_to_launcher",function(next,...)
    audio.stop()
    return next(...)
  end)
  -- Diagnostics and automated verification; no global variables or hotkeys.
  mod.exports.update=update
  mod.exports.getSetting=getSetting
  mod.exports.hardwareColours=Hardware
  mod.exports.openColourPicker=picker.open
  mod.exports.setSetting=setSetting
  mod.exports.status=function()
    return {automount=automount.status and automount.status(),
      audio=audio.status and audio.status(),colours=colours.status and colours.status(currentGame)}
  end
  mod.exports.openSettings=function(game)
    game=game or currentGame; migrateSettings(game)
    Screens.push(game,"BicyclePlusSettings")
  end
  mod.exports.openColours=function(game)
    game=game or currentGame; migrateSettings(game)
    Screens.push(game,"BicyclePlusColours")
  end
  mod.exports.openAudio=function(game)
    game=game or currentGame; migrateSettings(game); return audioMenu.open(game)
  end
end
