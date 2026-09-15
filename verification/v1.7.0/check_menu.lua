local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
local H=dofile('verification/v1.7.0/support.lua');H.install()
local Runtime=require('src.mods.Runtime');local Screens=require('src.ui.Screens');local Stack=require('src.core.StateStack')
package.loaded['src.render.PaletteFX']={wholeNamed=function()return{}end}
package.loaded['src.render.Playfield']={rect=function()return 0,0,1000,600 end}
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local noop=function()end
local services='return{init=function()return{update=function()end,stop=function()end,open=function()end,status=function()return{}end}end}'
local preview=[[return{init=function()return{update=function()end,status=function()end,artStyle=function()return'GEN 2'end,
 previewZones=function()return{}end,needsColourMode=function()return false end,
 drawPreview=function(g,x,y,s,t,o)g.preview=o;g.face=x==118 and'down'or'left';return true end,
 drawSinglePreview=function(g,x,y,s,t,o,face)g.preview=o;g.face=face;return true end}end}]]
local keys={'bike_colour','bike_stripes_colour','bike_centres_colour','bike_tyres_colour','bike_frame_colour','bike_handlebars_colour'}
for _,ed in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 Screens.invalidate();Runtime.safeMode=false
 local g={data={edition=ed,screens={}},mods={modOptions={bicycle_plus={}},modSave={trainer_skins={skin='Hilbert',skin_color='blue'}}},save={options={modOptions={bicycle_plus={}},musicVol=5}},input={pressed={},held={}},writes=0}
 if ed=='gold'or ed=='silver'or ed=='crystal'then g.data.gen2Sprites={}end
 function g:writeOptions()self.writes=self.writes+1 end
 function g.input:wasPressed(k)return self.pressed[k]==true end
 function g.input:isDown(k)return self.held[k]==true end
 g.stack=setmetatable({},{__index=Stack});g.stack:init()
 local save,live=g.save.options.modOptions.bicycle_plus,g.mods.modOptions.bicycle_plus
 for _,v in ipairs({save,live})do v._audio_layout=2;v.auto_mount=false;v.bike_volume=4;v.riding_area_filter=2;v.spelling='uk';for _,k in ipairs(keys)do v[k]='original'end end
 local mod={id='bicycle_plus',exports={},options={},hooks={},events={},content={screens={}}};local schema,handlers={},{}
 function mod.options:get(k)if live[k]~=nil then return live[k]end;for _,o in ipairs(schema)do if o.key==k then return o.default end end end
 function mod.options:define(v)schema=v end
 function mod.hooks:wrap(k,fn)handlers[k]=fn end
 function mod.events:on()end
 function mod.content.screens:register(k,v)g.data.screens[k]=v end
 function mod:read(p)if p=='audio.lua'or p=='audio_menu.lua'or p=='automount.lua'then return services elseif p=='colours.lua'then return preview else return read(p)end end
 assert(loadfile('main.lua'))()(mod)
 local P,U=mod.exports.hardwareColours,mod.exports.colourUI
 local origText=U.text;local texts={}
 U.text=function(s,x,y,scale)
  scale=scale or 1;ck(x>=0 and x+U.width(s,scale)<=160 and y>=0 and y+7*scale<=144,'text outside native screen: '..s)
  texts[#texts+1]={s=s,x=x,y=y,w=U.width(s,scale),h=7*scale};return origText(s,x,y,scale)
 end
 local function draw()
  H.reset();texts={};g.stack:top():draw()
  for i,a in ipairs(texts)do for j=1,i-1 do local b=texts[j]
   ck(not(a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h),'overlapping text '..a.s..' / '..b.s)
  end end
 end
 local function tap(k)g.input.pressed={[k]=true};g.stack:update(1/60);g.input.pressed={}end
 local function key(k)return handlers['input.key'](noop,g,{phase='pressed',key=k})end
 local function pointer(phase,x,y,id,source,button)
  return handlers['input.pointer'](function()return false end,g,{phase=phase,gameX=20+x*3,gameY=30+y*3,id=id or'mouse',source=source or'mouse',button=button or 1})
 end
 handlers['render.hud'](noop,g,{gameX=20,gameY=30,gameWidth=480,gameHeight=432})
 mod.exports.openColours(g);local menu=g.stack:top();draw();ck(g.writes==0,'opening writes settings')
 for i,k in ipairs(keys)do
  menu.index=i;draw();tap('a');ck(g.stack:top()==menu,'Original opens editor')
  tap('right');ck(live[k]~='original','right did not choose Custom');tap('a');local picker=g.stack:top()
  ck(picker.screenId=='BicyclePlusPicker','Custom must open one chart');draw();local before=g.writes
  tap('right');ck(g.writes==before,'browsing saved colour');draw()
  picker:beginEdit('hex');draw();key('f');key('f');key('f');key('f');key('c');key('e');key('return')
  ck(picker.draft=='rgb:FFFFCE','typed exact hex failed');draw();tap('b');ck(g.writes==before,'Cancel saved draft')
  tap('a');picker=g.stack:top();picker:beginEdit('hex');picker:typeText('8b00ba',true);ck(picker:commitEdit(),'valid hex rejected')
  picker:apply();ck(live[k]=='rgb:8B00BA'and save[k]==live[k],'exact RGB not stored')
  tap('left');ck(live[k]=='original','left not Original');tap('right');ck(live[k]=='rgb:8B00BA','Custom memory lost')
  tap('a');picker=g.stack:top()
  for _,field in ipairs({'r','g','b'})do picker:beginEdit(field);picker:typeText('256',true);ck(not picker:commitEdit(),'out of range accepted');draw();picker:typeText('1',true);ck(picker:commitEdit(),'channel rejected')end
  ck(picker.draft=='rgb:010101','unrounded channel entry');tap('b')
 end
 menu.index=6;tap('a');local picker=g.stack:top();draw();ck(g.face=='down','handlebars preview facing')
 -- Controller/keypad entry independent of a keyboard mapping.
 picker:beginEdit('hex');picker.edit.replace=true;picker.edit.index=1;tap('a');ck(picker.edit.buffer=='0','controller keypad A')
 tap('select');ck(picker.edit.buffer=='','controller erase');tap('b');ck(not picker.edit,'controller field cancel')
 -- Numeric and invalid paste; engine hotkeys are suppressed only while editing.
 picker:beginEdit('r');local continued=0
 ck(handlers['input.key'](function()continued=continued+1 end,g,{phase='pressed',key='f5'})==true and continued==0,'editing leaked engine hotkey')
 handlers['input.key'](function()continued=continued+1 end,g,{phase='released',key='f5'});ck(continued==1,'key release not forwarded')
 key('escape');key('tab');ck(picker.focus=='g','Tab focus')
 -- Pointer maps LOVE window units to native pixels; drags survive leaving bounds.
 pointer('pressed',10,20,'finger','touch');pointer('moved',90,60,'finger','touch');local a=picker.draft
 pointer('released',10,20,'other','touch');ck(picker.drag~=nil,'unrelated touch ended drag')
 pointer('moved',200,300,'finger','touch');ck(picker.draft~=a,'outside drag not clamped');pointer('released',200,300,'finger','touch');ck(not picker.drag,'release left drag stuck')
 pointer('pressed',120,51);ck(picker.edit and picker.edit.field=='r','mouse field entry');picker.edit=nil
 pointer('pressed',104,28);ck(picker.drag and picker.drag.target=='light','brightness hit');pointer('cancelled',0,0);ck(not picker.drag,'cancellation did not clear mouse drag')
 picker:setRGB(255,0,0);picker.focus='plane';draw();local tex=picker.planeImage;tap('right');draw();ck(picker.planeImage==tex,'hue drag recreated large chart unnecessarily')
 picker.focus='light';tap('down');draw();ck(picker.planeImage~=tex and tex.released,'brightness image not replaced/released')
 picker:beginEdit('hex');love.keyboard={isDown=function(k)return k=='lctrl'end};love.system={getClipboardText=function()return'#123aBc'end};key('v');key('return');love.keyboard=nil
 ck(picker.draft=='rgb:123ABC','paste failed');tap('b');ck(picker.planeImage==nil,'picker image leaked after exit')
 -- Confirm-only reset and isolation.
 local before=g.writes;menu.index=7;tap('a');draw();tap('a');ck(g.writes==before,'default reset must cancel')
 tap('a');tap('right');tap('a');ck(g.writes==before+1,'reset should be one write')
 for _,k in ipairs(keys)do ck(live[k]=='original'and save[k]=='original','reset part failed')end
 ck(live.auto_mount==false and live.bike_volume==4 and live.riding_area_filter==2 and g.save.options.musicVol==5,'reset damaged audio/mount prefs')
 ck(g.mods.modSave.trainer_skins.skin_color=='blue','reset damaged trainer')
 -- Original saved IDs survive reopening and editing without conversion.
 live[keys[1]]='gbc:0EE7';save[keys[1]]=live[keys[1]];menu.index=1;tap('a');picker=g.stack:top();picker:apply();ck(live[keys[1]]=='gbc:0EE7','opening+Apply migrated unchanged ID')
 mod.exports.setSetting(g,'spelling','us');draw();ck(mod.exports.getSetting('spelling')=='us','US spelling state')
 -- Gen 2 frameFit conversion and external viewport offsets.
 g.frameFit=function()return 2,100,50 end
 local x,y=U.coordinates(g,{gameX=124,gameY=70,phase='pressed'});ck(x==12 and y==10,'Gen2 pointer transformation')
 g.frameFit=nil
 local out=handlers['render.zones'](function()return{{colors={}}}end,g,{})
 ck(out[#out].colors==false and out[#out].w==160,'picker/menu palette exemption')
 Runtime.safeMode=true;before=g.writes;ck(not mod.exports.resetColours(g),'safe mode reset');ck(not mod.exports.openColourPicker(g,keys[1],'WHEEL'),'safe mode editor')
 ck(g.writes==before,'safe mode wrote settings');Runtime.safeMode=false;tap('b');ck(not g.stack:top(),'stack leaked')
end
print(('PASS %d menu/layout/input/persistence assertions over six game contexts; native Screens/StateStack, simulated graphics/device/input boundaries.'):format(n))
