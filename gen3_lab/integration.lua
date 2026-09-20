-- FireRed-only lifecycle/menu integration for the isolated AUTOBIKE+ beta.
-- Rendering and cycling-audio backends plug in through callbacks; this module
-- deliberately does not alter the stable Gen 1/2 entry.
local Integration={}
function Integration.attach(mod,S)
 S=S or{}
 local Version=S.Version or require('src.core.GameVersion')
 assert(Version.get()=='firered' and Version.generation()==3,'FireRed beta only')
 local Runtime=S.Runtime or require('src.mods.Runtime')
 local Rows=S.Rows or require('src.ui.game3.option_rows')
 local Assets=S.Assets or require('src.render.Assets')
 local settings=assert(S.settings,'settings required')
 local menu=assert(S.menu,'native menu required')
 local NativeMount=assert(S.NativeMount,'native mount adapter required')
 local Machine=assert(S.Machine,'mount state machine required')
 local currentGame=mod.game
 local ownerHooks,ownerEvents=Runtime.hooks,Runtime.events
 local disposed=false
 local api={}
 local mount=NativeMount.attach(mod,Machine,function(key)return settings.get(key,currentGame or mod.game)end)
 api.mount=mount
 local function active()
  return not disposed and not Runtime.safeMode and Version.get()=='firered'
   and Runtime.hooks==ownerHooks and Runtime.events==ownerEvents
 end
 local function set(game,key,value)return settings.set(game,key,value)end
 local modes={'area','bicycle','both'}
 local function cycle(game,key,choices,dir)
  local cur=settings.get(key,game);local at=1
  for i,v in ipairs(choices)do if v==cur then at=i break end end
  return set(game,key,choices[(at-1+(dir<0 and -1 or 1))%#choices+1])
 end
 local function step(game,key,lo,hi,dir)
  return set(game,key,math.max(lo,math.min(hi,(tonumber(settings.get(key,game))or lo)+(dir<0 and -1 or 1))))
 end
 local function vol(v,inherit)
  v=tonumber(v)or(inherit and -1 or 0);if inherit and v<0 then return'SAME'end
  return v==0 and'OFF'or tostring(v)
 end
 local function filter(v,inherit)
  v=tonumber(v)or(inherit and -1 or 0);if inherit and v<0 then return'SAME'end
  return v==0 and'OFF'or tostring(v)..'X'
 end
 local PARTS={{'FRAME','bike_frame_colour'},{'TYRES','bike_tyres_colour'},{'RIMS','bike_rims_colour'},
  {'SPOKES','bike_spokes_colour'},{'HANDLEBARS','bike_handlebars_colour'}}
 local function colourLabel(v)
  if v=='original'then return'ORIGINAL'end
  return tostring(v or'original'):upper()
 end
 function api.openAppearance(game)
  if S.openAppearance then return S.openAppearance(game,settings)end
  local rows={}
  for _,p in ipairs(PARTS)do
   local label,key=p[1],p[2]
   rows[#rows+1]={label=label,value=function()return colourLabel(settings.get(key,game))end,
    activate=S.openColourPart and function()return S.openColourPart(game,key,label,settings)end or nil}
  end
  rows[#rows+1]={label='RESET PAINT',activate=function()
   local ok=true;for _,p in ipairs(PARTS)do ok=settings.set(game,p[2],'original')and ok end
   if S.invalidatePaint then S.invalidatePaint()end
   return ok
  end}
  local opts=S.drawAppearancePreview and{preview=S.drawAppearancePreview}or nil
  return menu.open(game,'BIKE APPEARANCE',rows,opts)
 end
 function api.openAudio(game)
  local rows={
   {label='ON BIKE',value=function()return settings.get('riding_music',game):upper()end,
    step=function(d)return cycle(game,'riding_music',modes,d)end},
   {label='AREA VOLUME',value=function()return vol(settings.get('riding_area_volume',game),true)end,
    step=function(d)return step(game,'riding_area_volume',-1,7,d)end},
   {label='AREA FILTER',value=function()return filter(settings.get('riding_area_filter',game),true)end,
    step=function(d)return step(game,'riding_area_filter',-1,3,d)end},
   {label='SFX VOLUME',value=function()return vol(settings.get('riding_sfx_volume',game),true)end,
    step=function(d)return step(game,'riding_sfx_volume',-1,7,d)end},
   {label='SFX FILTER',value=function()return filter(settings.get('riding_sfx_filter',game),true)end,
    step=function(d)return step(game,'riding_sfx_filter',-1,3,d)end},
   {label='CYCLING MUSIC VOLUME',value=function()return vol(settings.get('bike_volume',game),false)end,
    step=function(d)return step(game,'bike_volume',0,7,d)end},
   {label='CYCLING MUSIC FILTER',value=function()return filter(settings.get('bike_filter',game),false)end,
    step=function(d)return step(game,'bike_filter',0,3,d)end},
   {label='BIKE SONG',value=function()return tostring(settings.get('bike_song',game)or'original'):upper()end,
    activate=S.openSong and function()return S.openSong(game,settings)end or nil},
   {label='ON MOUNT',value=function()return settings.get('bike_song_resume',game)and'RESUME'or'RESTART'end,
    step=function()return set(game,'bike_song_resume',not settings.get('bike_song_resume',game))end},
  }
  return menu.open(game,'BIKE AUDIO',rows)
 end
 function api.openSettings(game)
  game=game or currentGame or mod.game;assert(game,'game required');currentGame=game;settings.ensure(game)
  local rows={
   {label='AUTO BIKE',value=function()return settings.get('auto_mount',game)and'ON'or'OFF'end,
    step=function()return set(game,'auto_mount',not settings.get('auto_mount',game))end},
   {label='SFX FILTER',value=function()return filter(settings.get('sfx_filter',game),false)end,
    step=function(d)return step(game,'sfx_filter',0,3,d)end},
   {label='BIKE APPEARANCE',activate=function()return api.openAppearance(game)end},
   {label='BIKE AUDIO',activate=function()return api.openAudio(game)end},
   {label='LANGUAGE',value=function()return settings.get('spelling',game)=='us'and'US'or'UK'end,
    step=function(d)return cycle(game,'spelling',{'uk','us'},d)end},
  }
  return menu.open(game,'AUTOBIKE+',rows)
 end
 local priorBuild=Rows.build
 local wrappedBuild
 wrappedBuild=function(...)
  local rows=priorBuild(...)
  if not active()or type(rows)~='table'then return rows end
  for _,r in ipairs(rows)do if r.id=='autobike_plus_firered_beta.settings'then return rows end end
  rows[#rows+1]={id='autobike_plus_firered_beta.settings',label='AUTOBIKE+',
   value=function()return'SETTINGS'end,
   activate=function(ctx)return api.openSettings(ctx and ctx.game or currentGame or mod.game)end}
  return rows
 end
 Rows.build=wrappedBuild
 local function ready(ev)
  currentGame=ev and ev.game or mod.game or currentGame
  if currentGame then settings.ensure(currentGame)end
 end
 if mod.events and mod.events.on then mod.events:on('game.ready',ready)end
 function api.dispose()
  if disposed then return end;disposed=true
  if Rows.build==wrappedBuild then Rows.build=priorBuild end
  if mount and mount.dispose then mount.dispose()end
 end
 if Assets and Assets.register then Assets.register({release=api.dispose})end
 if mod.hooks and mod.hooks.wrap then
  mod.hooks:wrap('core.quit_to_launcher',function(next,...)
   api.dispose();return next(...)
  end,100)
 end
 mod.exports.gen3Integration=api
 mod.exports.openSettings=api.openSettings
 mod.exports.openAudio=api.openAudio
 mod.exports.openAppearance=api.openAppearance
 mod.exports.gen3Settings=settings
 return api
end
return Integration
