-- Real mod sandbox, Screens/StateStack and native options; device/graphics/audio mocked.
local T=dofile('verification/v1.9.0/support.lua').init(assert(arg[1]))
local R=T.Runtime;local Screens=require('src.ui.Screens');local Stack=require('src.core.StateStack')
local noop=function()end
love.graphics={setColor=noop,rectangle=noop,push=noop,pop=noop,transformPoint=function(x,y)return x,y end,intersectScissor=noop,getDimensions=function()return 160,144 end}
love.keyboard={isDown=function()return false end}
package.loaded['src.render.Assets']={register=noop}
package.loaded['src.render.Font']={draw=noop,drawBox=noop,drawCode=noop}
package.loaded['src.ui.Theme']={cursor=1}
package.loaded['src.render.PaletteFX']={wholeNamed=function()return{}end,mode='redpp',setMode=noop}
package.loaded['src.render.GbcPalette']={mode='gbc',setMode=noop}
local One=require('src.ui.OptionsMenu');local Two=require('src.ui.gen2.OptionsMenu')
local constructors={One.new,Two.new}
local service=[[return{init=function()return{update=function()end,stop=function()end,stopPreview=function()end,
 status=function()return{}end,previewZones=function()return{}end,needsColourMode=function()return false end,
 drawPreview=function()return true end}end}]]
local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local function eq(a,b)
 if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not eq(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local modes={'area','bicycle','both'}
local cases={
 {layout=2,mode='area'},{layout=2,mode='bicycle'},{layout=2,mode='both'},
 {layout=3,mode='both',area=0},{layout=3,mode='both',bike=0},
 {layout=3,mode='both'}, {legacy='cycling'}, {legacy='area'}, {},
}
for index,edition in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 for _,case in ipairs(cases)do
  require('src.core.GameVersion').set(edition);Screens.invalidate();R.safeMode=false
  local hooks=require('src.mods.Hooks').new();local events=require('src.mods.Events').new();R.install(events,hooks)
  local g={data={screens={},audio={songs={}}},input={pressed={},held={}},stack=setmetatable({},{__index=Stack}),
   mods={modOptions={},modSave={trainer_skins={skin='Hilbert',skin_color='blue'}},events=events},
   save={player={name='SAVE SENTINEL'},options={musicVol=7,musicFilter=1,sfxVol=6,modOptions={}}},writes=0}
  g.stack:init();g.options=g.save.options
  function g:writeOptions()self.writes=self.writes+1 end
  function g.input:wasPressed(k)return self.pressed[k]==true end
  function g.input:isDown(k)return self.held[k]==true end
  local initial={_audio_layout=case.layout,riding_music=case.mode,music_mode=case.legacy,
   riding_area_volume=case.area or 2,bike_volume=case.bike or 5,riding_area_filter=2,bike_filter=3,
   riding_sfx_volume=4,riding_sfx_filter=1,sfx_filter=2,bike_song='original',bike_song_resume=true,
   bike_centres_colour='original',bike_colour='rgb:112233',auto_mount=false,spelling='uk'}
  local live,saved=copy(initial),copy(initial);g.mods.modOptions.bicycle_plus=live;g.save.options.modOptions.bicycle_plus=saved
  local mod=T.mod(g);mod.content={screens={}};mod.options={};mod.exports={};mod.hooks={};mod.events={}
  local schema,handlers={},{}
  function mod.options:get(k)if live[k]~=nil then return live[k]end;for _,s in ipairs(schema)do if s.key==k then return s.default end end end
  function mod.options:define(t)schema=t end
  function mod.hooks:wrap(k,f,p)handlers[k]=f;return hooks:wrap(k,f,p,'bicycle_plus')end
  function mod.events:on(k,f,p)return events:on(k,f,p,'bicycle_plus')end
  function mod.content.screens:register(k,v)g.data.screens[k]=v end
  local rd=mod.read
  function mod:read(p)if p=='audio.lua'or p=='automount.lua'or p=='colours.lua'then return service end;return rd(self,p)end
  T.load(mod,'main')(mod)
  local before=copy(g.save);mod.exports.openSettings(g)
  local expected=case.mode or(case.legacy=='cycling'and'bicycle')or case.legacy or'both'
  local normalized=copy(before);normalized.options.modOptions.bicycle_plus.riding_music=expected;normalized.options.modOptions.bicycle_plus._audio_layout=4
  ck(eq(g.save,normalized),'migration changed gains, filters, progress or other settings')
  ck(eq(live,saved),'migration stores inconsistent')
  local root=g.stack:top();ck(root.rows[1].label=='AUTO BIKE'and #root.rows==5,'root structure changed')
  root.rows[4].action(root);local page=g.stack:top()
  local labels={'ON BIKE','AREA VOLUME','AREA FILTER','SFX VOLUME','SFX FILTER','CYCLING MUSIC VOLUME','CYCLING MUSIC FILTER','BIKE SONG','ON MOUNT'}
  ck(#page.rows==#labels,'extra bike audio rows')
  for i,label in ipairs(labels)do ck(page.rows[i].label==label,'audio order')end
  local row=page.rows[1];ck(row.value()==expected:upper(),'current mode label')
  local U=mod.exports.colourUI;local oldText=U.text;local texts={}
  U.text=function(s,x,y,scale)
   ck(x>=0 and y>=0 and x+U.width(s,scale)<=160 and y+7*(scale or 1)<=144,'text bounds')
   texts[#texts+1]={s=s,x=x,y=y,w=U.width(s,scale),h=7*(scale or 1)};return oldText(s,x,y,scale)
  end
  local function draw()
   texts={};page:draw()
   for i,a in ipairs(texts)do for j=1,i-1 do local b=texts[j]
    ck(not(a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h),'text overlap')
   end end
  end
  local steady=copy(g.save);local writeStart=g.writes
  local eventCount=0;events:on('mod.options_changed',function(e)if e.key=='riding_music'then eventCount=eventCount+1 end end)
  local function tap(k)g.input.pressed={[k]=true};g.stack:update(.016);g.input.pressed={}end
  for i=1,12 do
   tap(i%2==0 and'left'or'right')
   local want=copy(steady);want.options.modOptions.bicycle_plus.riding_music=live.riding_music
   ck(eq(g.save,want),'mode toggle rewrote the saved mix');ck(eq(live,saved),'mode stores inconsistent')
   draw()
  end
  ck(g.writes==writeStart+12 and eventCount==12,'one setting write/event per switch')
  local current=live.riding_music;g.input.held={right=true};for i=1,80 do g.stack:update(.1)end;g.input.held={}
  ck(live.riding_music==current,'held direction changed mode')
  tap('a');ck(live.riding_music~=current,'A did not cycle selector')
  page:pointer({phase='pressed',source='mouse',button=1},140,36);draw()
  ck(g.stack:top()==page,'selector pointer opened another menu')
  page.index=9;draw();ck(page.scroll==1,'last row not reachable after new selector')
  local untouched=copy(g.save);local writes=g.writes
  R.safeMode=true;ck(not mod.exports.setSetting(g,'riding_music','area'),'safe mode write accepted');R.safeMode=false
  ck(not mod.exports.setSetting(g,'riding_music','INVALID'),'invalid mode accepted')
  ck(eq(g.save,untouched)and g.writes==writes,'invalid/safe mode altered settings')
  tap('b');tap('b');mod.exports.openSettings(g);ck(g.writes==writes,'migration repeated on reopen')
  ck(One.new==constructors[1]and Two.new==constructors[2],'native Audio constructors changed')
  tap('b');local native=(index<=3 and One or Two).new(g)
  for _,r in ipairs(native.view)do if r.id=='group.audio'then r.activate(g)end end
  for _,r in ipairs(g.stack:top().view)do
   local text=type(r.label)=='function'and r.label()or r.label
   ck(text~='ON BIKE'and text~='SFX FILTER'and not tostring(text):find('BIKE'),'mod leaked into native Audio')
  end
  while g.stack:top()do tap('b')end
  handlers['core.quit_to_launcher'](noop)
 end
end
print(('PASS %d native menu/migration/routing-persistence checks, 54 upgrade/game contexts. Graphics and playback are simulated.'):format(n))
