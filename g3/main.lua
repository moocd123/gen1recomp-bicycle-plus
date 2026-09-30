-- Eight-game package, GBA arm. Only loaded for FireRed/LeafGreen.
return function(mod)
 local function module(name)return assert(load(assert(mod:read(name..'.lua')),'@'..mod.id..'/'..name..'.lua'))()end
 local Bus=require('src.mods.Runtime')
 local Version=require('src.core.GameVersion')
 local hooks,events=Bus.hooks,Bus.events
 local game=mod.game
 local H=module('colour_values').extend(module('hardware_colours'))
 local Library=module('song_library');local library=Library.init(mod)
 library.attachPicker(module('import_picker').init(mod,library))
 local settings=module('g3/settings').init(mod,H,Library)
 local U=module('g3/ui').init(mod)
 local Paint=module('g3/player_paint').attach(mod,module('g3/parts'),module('g3/shading'),settings)
 local editor=module('g3/editor').init(mod,U,H,settings,Paint)
 local entry=module('g3/text_entry').init(U)
 local audio=module('g3/audio').init(mod,settings,library)
 local get=function(k)return settings.get(k,game)end
 local set=function(g,k,v)return settings.set(g,k,v)end
 local music=module('g3/music_menu').init(mod,{ui=U,menus=U,library=library,audio=audio,
  textEntry=entry,getSetting=get,setSetting=set})
 local audioMenu=module('audio_menu').init(mod,{menus=U,getSetting=get,setSetting=set,
  openSong=function(g)return music.open(g)end})
 local mount=module('g3/native_mount').attach(mod,module('g3/mount'),get)
 local input=module('g3/input').attach(mod,U)
 local closed=false
 local function ensure(g)
  if mod.exports.seedForTest then mod.exports.seedForTest(g)end
  settings.ensure(g)
 end
 local function openRoot(g)
  g=g or game;game=g;ensure(g)
  return U.open(g,{title='AUTOBIKE+',tag='autobike.settings',footer='LR:CHANGE  A:OPEN',rows={
   {label='AUTO BIKE',value=function()return get('auto_mount')and'ON'or'OFF'end,
    step=function()set(g,'auto_mount',not get('auto_mount'))end},
   {label='SFX FILTER',value=function()local n=get('sfx_filter');return n==0 and'OFF'or n..'X'end,
    step=function(d)set(g,'sfx_filter',(get('sfx_filter')+d)%4)end},
   {label='BIKE APPEARANCE',action=function()editor.appearance(g)end},
   {label='BIKE AUDIO',action=function()audioMenu.open(g)end},
   {label='LANGUAGE',value=function()return get('spelling')=='us'and'US'or'UK'end,
    step=function()set(g,'spelling',get('spelling')=='us'and'uk'or'us')end},
  }})
 end
 local Rows=require('src.ui.game3.option_rows');local previous=Rows.build
 local wrapped
 wrapped=function(...)
  local rows=previous(...)
  if closed or Bus.safeMode or Bus.hooks~=hooks or Bus.events~=events then return rows end
  for _,row in ipairs(rows or{})do if row.id==mod.id..'.settings'then return rows end end
  rows[#rows+1]={id=mod.id..'.settings',label='AUTOBIKE+',value=function()return'SETTINGS'end,
   activate=function(ctx)return openRoot(ctx and ctx.game or game)end}
  return rows
 end
 Rows.build=wrapped
 local previousDrop=game.filedropped
 local drop=function(self,file,...)
  if not closed and Bus.hooks==hooks and music.fileDropped(self,file)then return true end
  if previousDrop then return previousDrop(self,file,...)end
 end
 game.filedropped=drop
 local api={}
 function api.update(g,dt)
  if closed then return end
  if Bus.hooks~=hooks or Bus.events~=events then api.dispose();return end
  game=g or game;ensure(game);U.update(dt)
  if library.picker and library.picker.hasWork()then
   local row,err=library.poll(dt)
   if row or err then
    library.lastImport={row=row,error=err}
    if row then settings.set(game,'bike_song',row.id)end
   end
  end
  audio.update(game,dt)
 end
 function api.dispose()
  if closed then return end;closed=true
  U.dispose();input.dispose();mount.dispose();Paint.dispose();audio.dispose();library.shutdown()
  if Rows.build==wrapped then Rows.build=previous end
  if game and game.filedropped==drop then game.filedropped=previousDrop end
 end
 mod.events:on('game.ready',function(e)game=e and e.game or game;ensure(game)end)
 mod.hooks:wrap('core.update',function(next,g,dt)
  local result=next(g,dt);api.update(g,dt);return result
 end,-100)
 mod.hooks:wrap('core.quit_to_launcher',function(next,...)
  api.dispose();return next(...)
 end,100)
 require('src.render.Assets').register({release=api.dispose})
 mod.exports.unified=api;mod.exports.openSettings=openRoot;mod.exports.openAudio=audioMenu.open
 mod.exports.openColours=editor.appearance;mod.exports.openColourPicker=editor.open
 mod.exports.getSetting=get;mod.exports.setSetting=set;mod.exports.hardwareColours=H
 mod.exports.songs=library;mod.exports.audio=audio;mod.exports.mount=mount;mod.exports.paint=Paint
 mod.exports.colourUI=U;mod.exports.picker=editor;mod.exports.resetColours=settings.reset
 mod.exports.update=api.update;mod.exports.songMenu=music;mod.exports.inputBridge=input
 mod.exports.status=function()return{audio=audio.status(),colours=Paint.status(),automount=mount.state}end
end
