-- Entry used only by the staged FireRed test package. The stable main.lua is
-- intentionally not generation-dispatched until this beta is proven.
return function(mod)
 local function module(name)
  return assert(load(assert(mod:read(name..'.lua')),'@autobike_plus_firered_beta/'..name..'.lua'))()
 end
 local settings=module('settings').init(mod)
 local menu=module('native_menu').new()
 local picker=module('colour_picker').new(mod,settings)
 local pointer=module('pointer_bridge').attach(mod,picker)
 local songMenu=module('song_menu').new(mod,settings,menu,module('song_catalog'))
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
 local audio=module('audio_layer').attach(mod,settings)
 integration.paint=paint;integration.colourPicker=picker;integration.pointerBridge=pointer;integration.audio=audio;integration.songMenu=songMenu
 mod.exports.playerPaint=paint
 mod.exports.colourPicker=picker
 mod.exports.pointerBridge=pointer
 mod.exports.gen3Audio=audio
 mod.exports.gen3SongMenu=songMenu
 mod.exports.beta=integration
end
