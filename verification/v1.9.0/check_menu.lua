-- Actual mod Sandbox/LegacyCompat + native Screens/StateStack/OptionsMenu.
-- Audio sources, graphics, input and OS dialog response remain simulated.
local T=dofile('verification/v1.9.0/support.lua').init(assert(arg[1]))
local Runtime=T.Runtime;local Screens=require('src.ui.Screens');local Stack=require('src.core.StateStack')
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
local audioMock=[[return{init=function()local on=false;return{update=function()end,stop=function()end,
 stopPreview=function()on=false end,previewSong=function()on=true;return true end,
 status=function()return{previewActive=on}end}end}]]
local mountMock=[[return{init=function()return{update=function()end,status=function()end}end}]]
local paintMock=[[return{init=function()return{update=function()end,status=function()end,artStyle=function()return'GEN 2'end,
 previewZones=function()return{}end,needsColourMode=function()return false end,drawPreview=function()return true end}end}]]
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local function label(row,s)return type(row.label)=='function'and row.label(s)or row.label end
for index,edition in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 require('src.core.GameVersion').set(edition);Screens.invalidate();Runtime.safeMode=false
 local Hooks=require('src.mods.Hooks');local Events=require('src.mods.Events')
 local hooks,events=Hooks.new(),Events.new();Runtime.install(events,hooks)
 local g={data={screens={},audio={songs={Music_Test={file='a.ogg'}}}},input={pressed={},held={}},stack=setmetatable({},{__index=Stack}),
  mods={modOptions={bicycle_plus={}},modSave={trainer_skins={skin='Hilbert',skin_color='blue'}}},save={options={modOptions={bicycle_plus={}},musicVol=4,musicFilter=1,sfxVol=6}},writes=0}
 g.stack:init();function g:writeOptions()self.writes=self.writes+1 end;g.options=g.save.options
 function g.input:wasPressed(k)return self.pressed[k]==true end
 function g.input:isDown(k)return self.held[k]==true end
 local live=g.mods.modOptions.bicycle_plus;local saved=g.save.options.modOptions.bicycle_plus
 local mode=({'bicycle','area','both'})[(index-1)%3+1]
 for _,o in ipairs({live,saved})do o._audio_layout=2;o.riding_music=mode;o.bike_centres_colour='original';o.bike_colour='rgb:112233';o.bike_volume=5;o.auto_mount=false end
 local mod=T.mod(g);mod.content={screens={}};mod.options={};mod.exports={};mod.hooks={};mod.events={}
 local schema,handlers={},{}
 function mod.options:get(k)if live[k]~=nil then return live[k]end;for _,s in ipairs(schema)do if s.key==k then return s.default end end end
 function mod.options:define(t)schema=t end
 function mod.hooks:wrap(k,f,p)handlers[k]=f;return hooks:wrap(k,f,p,'bicycle_plus')end
 function mod.events:on(k,f,p)return events:on(k,f,p,'bicycle_plus')end
 function mod.content.screens:register(k,v)g.data.screens[k]=v end
 local originalRead=mod.read
 function mod:read(path)
  if path=='audio.lua'then return audioMock elseif path=='automount.lua'then return mountMock
  elseif path=='colours.lua'then return paintMock end
  return originalRead(self,path)
 end
 T.load(mod,'main')(mod)
 local U=mod.exports.colourUI;local originalText=U.text;local positions={}
 U.text=function(s,x,y,scale)
  ck(x>=0 and y>=0 and x+U.width(s,scale)<=160 and y+7*(scale or 1)<=144,'out of bounds '..s)
  positions[#positions+1]={s=s,x=x,y=y,w=U.width(s,scale),h=7*(scale or 1)}
  return originalText(s,x,y,scale)
 end
 local function tap(k)g.input.pressed={[k]=true};g.stack:update(.016);g.input.pressed={}end
 local function draw()
  positions={};g.stack:top():draw()
  for i,a in ipairs(positions)do for j=1,i-1 do local b=positions[j]
   ck(not(a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h),'text overlap '..a.s..' / '..b.s)
  end end
 end
 ck(One.new==constructors[1]and Two.new==constructors[2],'native Audio constructors modified')
 local native=(index<=3 and One or Two).new(g)
 local openers=0
 for _,row in ipairs(native.rows)do
  if row.id=='bicycle_plus.settings'then openers=openers+1;ck(label(row)=='AUTOBIKE+','old mod name in options')end
  ck(row.id~='bicycle_plus.song'and row.id~='bicycle_plus.cycling','native Audio injected')
 end
 ck(openers==1,'single mod entry missing/duplicated')
 local audioGroup
 for _,r in ipairs(native.view)do if r.id=='group.audio'then audioGroup=r end end
 ck(audioGroup,'native Audio group missing');audioGroup.activate(g)
 local nativeAudio=g.stack:top();local names={}
 for _,r in ipairs(nativeAudio.view)do names[#names+1]=label(r);ck(not tostring(label(r)):find('BIKE',1,true),'mod row leaked to native Audio');ck(label(r)~='SFX FILTER'and label(r)~='AREA VOL','native row renamed')end
 ck(table.concat(names,'|'):find('MUSIC VOL',1,true)and table.concat(names,'|'):find('MUSIC FILTER',1,true),'native music settings missing')
 tap('b')
 mod.exports.openSettings(g);local root=g.stack:top();draw()
 ck(root.title=='AUTOBIKE+','main menu brand')
 for i,name in ipairs({'AUTO BIKE','SFX FILTER','BIKE APPEARANCE','BIKE AUDIO','LANGUAGE'})do ck(label(root.rows[i])==name,'main menu ordering')end
 ck(#root.rows==5,'duplicate root music or volume rows')
 ck(live._audio_layout==3 and live.riding_music=='both','mode migration')
 if mode=='bicycle'then ck(live.riding_area_volume==0,'old bicycle only lost')elseif mode=='area'then ck(live.bike_volume==0,'old area only lost')end
 ck(g.save.options.musicVol==4 and g.save.options.musicFilter==1 and g.save.options.sfxVol==6,'migration changed normal settings')
 tap('a');ck(live.auto_mount==true,'auto toggle');g.input.held={down=true};for i=1,80 do g.stack:update(.05)end;g.input.held={};ck(root.index==1,'held direction advanced menu')
 root.index=2;tap('right');ck(live.sfx_filter==1,'off-bike SFX filter')
 root.index=3;tap('a');draw();local colours=g.stack:top();g.input.held={down=true};for i=1,80 do g.stack:update(.05)end;g.input.held={};ck(colours.index==1,'held direction skipped appearance rows');tap('down');ck(colours.index==2,'tap appearance not one row');tap('b')
 root.index=4;tap('a');draw();local audioPage=g.stack:top()
 for i,name in ipairs({'AREA VOLUME','AREA FILTER','SFX VOLUME','SFX FILTER','CYCLING MUSIC VOLUME','CYCLING MUSIC FILTER','BIKE SONG','ON MOUNT'})do ck(label(audioPage.rows[i])==name,'cycling row ordering')end
 ck(#audioPage.rows==8,'duplicate cycling rows')
 audioPage.index=1;tap('right');draw();audioPage.index=5;tap('right');draw();audioPage.index=8;tap('a');ck(live.bike_song_resume,'resume setting')
 audioPage.index=7;tap('a');draw();local songs=g.stack:top();ck(#songs.rows==5,'song chooser not simplified');ck(songs.tag=='autobike.songs','wrong song chooser')
 local L=mod.exports.songLibrary
 local row=assert(L.importBytes('RIFF0000WAVE'..string.rep('tone',200),'A song with a ridiculously long filename that must stay on one line.wav'))
 songs.index=4;tap('a');draw();local list=g.stack:top();local first=positions[3]and positions[3].s;g.stack:update(5);draw();ck(positions[3]and positions[3].s~=first,'long title did not scroll')
 tap('a');draw();local detail=g.stack:top();ck(detail.bicycleMusicPreview,'detail preview flag')
 tap('a');ck(mod.exports.audio.status().previewActive,'preview action');detail.index=2;tap('a');ck(live.bike_song==row.id,'saved chosen import');tap('b')
 ck(g.stack:top()==songs,'song list return')
 songs.index=2;tap('a');draw();tap('a');detail=g.stack:top();detail.index=2;tap('a');ck(live.bike_song=='game:'..edition..':Music_Test','current game track choice');tap('b')
 -- Import action opens only the picker and auto-selects returned file.
 L.picker.choose=function()return row end
 songs.index=5;tap('a');ck(g.stack:top()==songs and live.bike_song==row.id,'import did not directly select');draw();g.stack:update(6);draw()
 songs.index=1;tap('a');ck(live.bike_song=='original','original theme')
 ck(live.bike_colour=='rgb:112233'and g.mods.modSave.trainer_skins.skin_color=='blue','song selection damaged colours/trainer')
 Runtime.safeMode=true;ck(not mod.exports.setSetting(g,'bike_song',row.id),'safe mode selection');Runtime.safeMode=false
 ck(not mod.exports.setSetting(g,'bike_song','../../save.lua'),'unsafe song ID')
 while g.stack:top()do tap('b')end
 handlers['core.quit_to_launcher'](noop)
end
print(('PASS %d native menu, unchanged native Audio, layout, tap navigation, migration and sandbox integration checks over six contexts.'):format(n))
