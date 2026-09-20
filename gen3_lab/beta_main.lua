-- Entry used only by the staged FireRed test package. The stable main.lua is
-- intentionally not generation-dispatched until this beta is proven.
return function(mod)
 local function module(name)
  return assert(load(assert(mod:read(name..'.lua')),'@autobike_plus_firered_beta/'..name..'.lua'))()
 end
 local settings=module('settings').init(mod)
 local menu=module('native_menu').new()
 local picker=module('colour_picker').new(mod,settings)
 local legacy=module('legacy_songs').init(mod)
 local localSongs=module('local_songs').init(mod)
 local importer=module('import_picker').init(mod,localSongs)
 local audio=module('audio_layer').attach(mod,settings,{Legacy=legacy,Local=localSongs})
 local textEntry=module('text_entry').new(mod)
 local songMenu=module('song_menu').new(mod,settings,menu,module('song_catalog'),
  {Legacy=legacy,Local=localSongs,Importer=importer,Preview=audio,TextEntry=textEntry})
 local pointer=module('pointer_bridge').attach(mod,picker)
 local paint
 local integration=module('integration').attach(mod,{
  settings=settings,menu=menu,Machine=module('mount'),NativeMount=module('native_mount'),
  openColourPart=function(game,key,label)return picker.open(game,key,label)end,
  openSong=function(game)return songMenu.open(game)end,
  describeSong=function(game)return songMenu.describe(game)end,
  invalidatePaint=function()if paint and paint.invalidate then paint.invalidate()end end,
  drawAppearancePreview=function(game,x,y,scale,timer)
   if paint and paint.drawPreview then return paint.drawPreview(game,x,y,scale,timer)end
   return false
  end,
 })
 paint=module('player_paint').attach(mod,module('parts'),module('shading'),settings)
 if mod.hooks and mod.hooks.wrap then
  mod.hooks:wrap('core.update',function(next,game,dt)
   local result=next(game,dt);songMenu.poll(game,dt);return result
  end,-90)
  mod.hooks:wrap('core.quit_to_launcher',function(next,...)
   if importer and importer.cancel then importer.cancel()end
   return next(...)
  end,90)
 end
 integration.paint=paint;integration.colourPicker=picker;integration.pointerBridge=pointer
 integration.audio=audio;integration.songMenu=songMenu;integration.importPicker=importer
 integration.legacySongs=legacy;integration.localSongs=localSongs;integration.textEntry=textEntry
 mod.exports.playerPaint=paint;mod.exports.colourPicker=picker;mod.exports.pointerBridge=pointer
 mod.exports.gen3Audio=audio;mod.exports.gen3SongMenu=songMenu;mod.exports.gen3ImportPicker=importer
 mod.exports.gen3LegacySongs=legacy;mod.exports.gen3LocalSongs=localSongs;mod.exports.gen3TextEntry=textEntry
 mod.exports.beta=integration
end
