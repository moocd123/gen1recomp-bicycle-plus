local T=dofile('verification/v1.8.0/test_support.lua').init(assert(arg[1]))
local Runtime=T.Runtime;local Screens=require('src.ui.Screens');local Stack=require('src.core.StateStack')
local noop=function()end
love.graphics={setColor=noop,rectangle=noop,push=noop,pop=noop,transformPoint=function(x,y)return x,y end,intersectScissor=noop}
package.loaded['src.render.Font']={draw=noop,drawBox=noop,drawCode=noop}
package.loaded['src.ui.Theme']={cursor=1}
package.loaded['src.render.PaletteFX']={wholeNamed=function()return{}end}
local services='return{init=function()return{update=function()end,stop=function()end,open=function()end,status=function()return{}end}end}'
local audioMock=[[return{init=function()local on=false;return{update=function()end,stop=function()end,
 stopPreview=function()on=false end,previewSong=function()on=true;return true end,
 status=function()return{previewActive=on}end}end}]]
local paintMock=[[return{init=function()return{update=function()end,status=function()end,artStyle=function()return'GEN 2'end,
 previewZones=function()return{}end,needsColourMode=function()return false end,
 drawPreview=function()return true end}end}]]
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
for _,edition in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 require('src.core.GameVersion').set(edition);Screens.invalidate();Runtime.safeMode=false
 local g={data={screens={},audio={songs={Music_Test={file='a.ogg'}}}},input={pressed={}},stack=setmetatable({},{__index=Stack}),
  mods={modOptions={bicycle_plus={}},modSave={trainer_skins={skin='Hilbert',skin_color='blue'}}},save={options={modOptions={bicycle_plus={}},musicVol=4}},writes=0}
 g.stack:init();function g:writeOptions()self.writes=self.writes+1 end
 function g.input:wasPressed(k)return self.pressed[k]==true end
 function g.input:isDown()return false end
 local live=g.mods.modOptions.bicycle_plus;local saved=g.save.options.modOptions.bicycle_plus
 for _,o in ipairs({live,saved})do o._audio_layout=2;o.bike_centres_colour='original';o.bike_colour='rgb:112233';o.bike_volume=5;o.auto_mount=false end
 local mod={id='bicycle_plus',game=g,content={screens={}},options={},exports={},hooks={},events={}}
 local schema,handlers={},{}
 function mod.options:get(k)if live[k]~=nil then return live[k]end;for _,s in ipairs(schema)do if s.key==k then return s.default end end end
 function mod.options:define(t)schema=t end
 function mod.hooks:wrap(k,f)handlers[k]=f;return noop end
 function mod.events:on()return noop end
 function mod.content.screens:register(k,v)g.data.screens[k]=v end
 function mod:read(path)
  if path=='audio.lua'then return audioMock elseif path=='audio_menu.lua'or path=='automount.lua'then return services
  elseif path=='colours.lua'then return paintMock end
  return T.readDisk(path)
 end
 local forwarded=0;local originalDrop=function()forwarded=forwarded+1 end;love.filedropped=originalDrop
 assert(loadfile('main.lua'))()(mod)
 local U=mod.exports.colourUI;local originalText=U.text
 U.text=function(s,x,y,scale)
  ck(x>=0 and y>=0 and x+U.width(s,scale)<=160 and y+7*(scale or 1)<=144,'menu text out of bounds '..s)
  return originalText(s,x,y,scale)
 end
 local function tap(k)g.input.pressed={[k]=true};g.stack:update(.016);g.input.pressed={}end
 local function draw()g.stack:top():draw()end
 local L=mod.exports.songLibrary;local file=assert(L.importBytes('ID3'..string.rep('tone',200),'User Song.mp3'))
 mod.exports.openSongs(g);local root=g.stack:top();draw();ck(#root.rows==9,'root actions')
 ck(mod.exports.getSetting('bike_song')=='original','default changed theme')
 root.index=2;tap('a');draw();local tracks=g.stack:top();ck(tracks.title==edition:upper()..' SOUNDTRACK','current edition')
 tap('a');draw();local detail=g.stack:top();ck(detail.bicycleMusicPreview,'audition flag')
 tap('a');ck(mod.exports.audio.status().previewActive,'preview action')
 detail.index=2;tap('a');ck(mod.exports.getSetting('bike_song')=='game:'..edition..':Music_Test','selected game song')
 ck(not mod.exports.audio.status().previewActive,'preview cleaned up')
 tap('b');ck(g.stack:top()==root,'return to root')
 root.index=4;tap('a');draw();local list=g.stack:top();tap('a');detail=g.stack:top();draw()
 detail.index=3;tap('a');local rename=g.stack:top();draw();rename:key('CLEAR');rename:key('R');rename:key('E');rename:key('N');rename:key('A');rename:key('M');rename:key('E');rename:key('SAVE')
 ck(L.describe(file.id)=='RENAME','rename saved');draw()
 detail.index=2;tap('a');ck(mod.exports.getSetting('bike_song')==file.id,'file selected');tap('b')
 root.index=7;local before=g.writes;tap('a');ck(mod.exports.getSetting('bike_song_resume')==true and g.writes==before+1,'resume persisted')
 ck(live.bike_colour=='rgb:112233'and live.bike_volume==5 and live.auto_mount==false,'music damaged existing settings')
 -- The root is pointer-addressable through the existing UI routing.
 root:pointer({phase='moved',source='mouse'},10,39);ck(root.index==1,'pointer hover')
 root:pointer({phase='pressed',source='mouse',button=1},10,39);ck(mod.exports.getSetting('bike_song')=='original','pointer select Original')
 Runtime.safeMode=true;ck(not mod.exports.setSetting(g,'bike_song',file.id),'safe mode selection');Runtime.safeMode=false
 ck(not mod.exports.setSetting(g,'bike_song','../../save.lua'),'invalid ID rejected')
 -- Native AUDIO and CYCLING integration is exercised separately, not mocked here.
 root.index=4;tap('a');tap('a');detail=g.stack:top();detail.index=4;tap('a');draw();tap('a')
 ck(#L.files()>=1,'default delete confirmation not cancelled')
 detail.index=4;tap('a');tap('down');tap('a');ck(not L.resolve(file.id,g),'confirmed removal')
 -- All-platform inbox browser, empty folders, path help and native-picker fallback.
 while g.stack:top()do tap('b')end
 mod.exports.openSongs(g);root=g.stack:top();root.index=5;tap('a');draw()
 ck(g.stack:top().title=='AUDIO FILE BROWSER','missing system picker does not open browser')
 tap('b');root.index=8;tap('a');draw();tap('b')
 -- Drag and drop imports only from a music menu; unrelated callbacks retain ownership.
 local drop=L.importBytes
 T.files['drag.wav']='RIFF1234WAVE'..string.rep('drop',70)
 local fileDrop=T.fs.newFile('drag.wav')
 love.filedropped(fileDrop);ck(g.stack:top().title=='SONG OPTIONS','file drop not imported')
 tap('b');ck(not mod.exports.songMenu.fileDropped(g,nil),'nil file drop claimed')
 mod.exports.openColours(g)
 ck(not mod.exports.songMenu.fileDropped(g,fileDrop),'file drop outside song UI claimed')
 love.filedropped(fileDrop);ck(forwarded==1,'previous drop callback not forwarded')
 tap('b')
 while g.stack:top()do tap('b')end
 handlers['core.quit_to_launcher'](noop)
 ck(love.filedropped==originalDrop,'original drop callback not restored')
 for _,entry in ipairs(L.files())do assert(L.remove(entry.id))end

end
print(('PASS %d native screen/menu/control/storage checks across six edition contexts; audio/graphics boundaries simulated.'):format(n))
