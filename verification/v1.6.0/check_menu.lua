local engine=assert(arg[1]);package.path=engine..'/?.lua;'..engine..'/?/init.lua;'..package.path
local H=dofile('verification/v1.6.0/support.lua');H.install()
local Runtime=require('src.mods.Runtime');local Screens=require('src.ui.Screens');local Stack=require('src.core.StateStack')
package.loaded['src.render.PaletteFX']={wholeNamed=function()return {}end}
local n=0;local function check(v,s)assert(v,s);n=n+1 end
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local inert='return {init=function()return {update=function()end,stop=function()end,open=function()end,status=function()end}end}'
local preview=[[return {init=function()return {update=function()end,status=function()end,artStyle=function()return 'GEN 2'end,
 needsColourMode=function(g)return g.retro==true end,colourModeName=function()return 'ADVANCED'end,
 enableColourMode=function(g)g.retro=false end,previewZones=function()return {}end,
 drawPreview=function(g,x,y,s,t,v)g.lastPreview=v;return g.previewOK,g.previewStatus end,
 drawSidePreview=function(g,x,y,s,t,v)g.lastPreview=v;return true end}end}]]
local keys={'bike_colour','bike_stripes_colour','bike_centres_colour','bike_tyres_colour','bike_frame_colour','bike_handlebars_colour'}
for _,edition in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 Screens.invalidate();Runtime.safeMode=false
 local game={data={edition=edition,screens={}},save={options={modOptions={bicycle_plus={}},musicVol=5,soundVol=4}},
 mods={modOptions={bicycle_plus={}},modSave={trainer_skins={skin='Hilbert',skin_color='blue'}}},writes=0,previewOK=true,input={}}
 if edition=='gold'or edition=='silver'or edition=='crystal'then game.data.gen2Sprites={}end
 game.stack=setmetatable({},{__index=Stack});game.stack:init()
 function game:writeOptions()self.writes=self.writes+1;return not self.failWrite end
 function game.input:wasPressed(k)return self.pressed and self.pressed[k]end
 function game.input:isDown(k)return self.held and self.held[k]end
 local save,live=game.save.options.modOptions.bicycle_plus,game.mods.modOptions.bicycle_plus
 for _,t in ipairs({save,live})do
  t._audio_layout=2;t.auto_mount=false;t.bike_volume=4;t.riding_area_volume=2;t.bike_filter=2;t.spelling='uk'
  for i=1,5 do t[keys[i]]='blue'end
 end
 local mod={id='bicycle_plus',exports={},options={},hooks={wrap=function()end},events={on=function()end},content={screens={}}};local schema
 function mod.options:define(r)schema=r end
 function mod.options:get(k)if live[k]~=nil then return live[k]end;for _,r in ipairs(schema or{})do if r.key==k then return r.default end end end
 function mod.content.screens:register(id,f)game.data.screens[id]=f end
 function mod:read(p)
  if p=='audio.lua'or p=='audio_menu.lua'or p=='automount.lua'then return inert end
  if p=='colours.lua'then return preview end
  return read(p)
 end
 assert(loadfile('main.lua'))()(mod);local P=mod.exports.hardwareColours
 local function tap(k)game.input.pressed={[k]=true};game.stack:update(1/60);game.input.pressed={}end
 local function draw()H.clear();game.stack:top():draw()end
 mod.exports.openColours(game);local parts=game.stack:top()
 check(#parts.rows==7 and game.writes==0,'six parts and reset, no writes on open')
 check(mod.exports.getSetting(keys[6])=='original','handlebars default Original')
 for i=1,7 do parts.index=i;draw()end
 for _,state in ipairs({{false,nil},{true,'Custom bike art kept original'},{true,'Colour readback unavailable'},{true,nil}})do
  game.previewOK,game.previewStatus=state[1],state[2];draw()
 end
 parts.index=6;tap('a');local picker=game.stack:top();draw()
 check(picker.mode=='sections' and picker.sections[1].original,'Original followed by sections')
 for i,expected in ipairs({'DMG','POCKET','LIGHT','GBC','TRAINER'})do check(picker.sections[i+1].label==expected,'system order')end
 for i,section in ipairs(picker.sections)do
  picker.sectionIndex=i;draw()
  if section.rows then
   tap('a');check(picker.mode=='presets','section opens grid')
   for j,row in ipairs(picker.rows)do picker.index=j;picker.draft=row.id;draw()end
   tap('select');draw();tap('b');check(picker.mode=='presets','RGB returns to same section')
   tap('b');check(picker.mode=='sections','B returns to section selection')
  end
 end
 check(game.writes==0,'all section browsing only previews')
 picker.sectionIndex=6;tap('a');tap('right');draw()
 check(game.lastPreview[keys[6]]==picker.draft,'staged handlebar preview')
 tap('start');check(game.stack:top()==parts and live[keys[6]]==nil,'START cancels without saving')
 tap('a');picker=game.stack:top();tap('select');draw();check(picker.mode=='rgb','full grid shortcut')
 tap('right');tap('select');tap('right');draw();local value=picker.draft;tap('a')
 check(game.writes==1 and save[keys[6]]==value and live[keys[6]]==value,'one confirmed colour persisted in both stores')
 for _,key in ipairs(keys)do check(mod.exports.setSetting(game,key,'red'),'prepare colour reset')end
 parts.index=7;local before=game.writes;tap('left');tap('right');check(game.writes==before,'reset needs confirmation')
 tap('a');draw();check(game.stack:top().index==1,'confirmation defaults NO');tap('a')
 check(game.stack:top()==parts and game.writes==before,'NO cancels')
 tap('a');tap('down');tap('b');check(game.writes==before,'B cancels')
 game.failWrite=true;check(not mod.exports.resetColours(game),'persistence error reported')
 for _,key in ipairs(keys)do check(live[key]==P.canonical('red'),'failed reset rolls back memory')end
 game.failWrite=false;before=game.writes;local events=0
 game.mods.events={emit=function()
  events=events+1;for _,key in ipairs(keys)do check(live[key]=='original' and save[key]=='original','atomic six-part reset')end
 end}
 tap('a');tap('down');tap('a');check(game.writes==before+1 and events==6,'one write for all six colours')
 check(live.auto_mount==false and live.bike_volume==4 and live.bike_filter==2 and live.riding_area_volume==2,'audio and automount untouched')
 check(game.save.options.musicVol==5 and game.save.options.soundVol==4,'native audio untouched')
 check(game.mods.modSave.trainer_skins.skin_color=='blue','trainer untouched')
 game.mods.events=nil;Runtime.safeMode=true;before=game.writes
 check(not mod.exports.resetColours(game) and game.writes==before,'safe mode protects reset')
 check(not mod.exports.openColourPicker(game,keys[6],'HANDLEBARS'),'safe mode protects picker')
 Runtime.safeMode=false;mod.exports.setSetting(game,'spelling','us');draw();tap('a');draw();tap('b')
 parts.index=6;tap('a');draw();tap('b');game.retro=true;tap('select');check(not game.retro,'explicit colour-mode shortcut retained')
 tap('b');check(game.stack:top()==nil,'clean stack on exit')
end
print(('PASS: %d six-edition menu checks; sections, full labels, native bounds, reset isolation/rollback and persistence.'):format(n))
