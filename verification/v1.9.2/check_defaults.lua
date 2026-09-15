-- Native Loader option API + sandbox + Screens/StateStack. The disk, input,
-- graphics, audio and movement services are doubles; this is not gameplay.
local T=dofile('verification/v1.9.0/support.lua').init(assert(arg[1]))
local noop=function()end
love.graphics={setColor=noop,rectangle=noop,push=noop,pop=noop,transformPoint=function(x,y)return x,y end,intersectScissor=noop,getDimensions=function()return 160,144 end}
love.keyboard={isDown=function()return false end}
package.loaded['src.render.Assets']={register=noop}
package.loaded['src.render.Font']={draw=noop,drawBox=noop,drawCode=noop}
package.loaded['src.ui.Theme']={cursor=1}
package.loaded['src.render.PaletteFX']={wholeNamed=function()return{}end,mode='redpp',setMode=noop}
package.loaded['src.render.GbcPalette']={mode='gbc',setMode=noop}
local Loader=require('src.mods.Loader');local Manifest=require('src.mods.Manifest')
local Screens=require('src.ui.Screens');local Stack=require('src.core.StateStack')
local R=T.Runtime;local n,cases=0,0
local function ck(v,m)assert(v,m);n=n+1 end
local function cp(v)if type(v)~='table'then return v end;local out={};for k,x in pairs(v)do out[k]=cp(x)end;return out end
local function eq(a,b)
 if a==b then return true end
 if type(a)~=type(b)then return false end
 if type(a)=='number' and a~=a and b~=b then return true end
 if type(a)~='table'then return false end
 for k,v in pairs(a)do if not eq(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
local service=[[return{init=function()return{update=function()end,stop=function()end,stopPreview=function()end,
 status=function()return{}end,previewZones=function()return{}end,needsColourMode=function()return false end,
 drawPreview=function()return true end}end}]]
local source=T.readDisk('main.lua')
local function boot(edition,initial,music,liveOnly,savedOnly,late)
 Screens.invalidate();R.safeMode=false;require('src.core.GameVersion').set(edition)
 local g={data={screens={},audio={songs={}}},writes=0,input={pressed={},held={}},stack=setmetatable({},{__index=Stack})}
 g.stack:init();function g.input:wasPressed(k)return self.pressed[k]==true end;function g.input:isDown(k)return self.held[k]==true end
 function g:writeOptions()self.writes=self.writes+1 end
 local loader=Loader.new({fs=T.fs,game=g,generation=(edition=='gold'or edition=='silver'or edition=='crystal')and 2 or 1})
 loader.game=g;g.mods=loader;loader.modOptions={bicycle_plus=savedOnly and {} or cp(initial),unrelated={value=0,enabled=false}}
 R.install(loader.events,loader.hooks)
 local save={player={name='SAVE SENTINEL',money=12345},party={{species='PIKACHU',level=17}},options={musicVol=music,musicFilter=2,sfxVol=3,modOptions={bicycle_plus=liveOnly and {}or cp(initial),unrelated={value=0,enabled=false}}}}
 if not late then g.save=save;g.options=save.options end
 local record={path='mods/bicycle_plus',manifest=Manifest.validate({id='bicycle_plus',name='AUTOBIKE+',version='1.9.2',api=2,entry='main.lua',games={edition},permissions={'engine_internals','filesystem'}},'bicycle_plus')}
 local mod=loader:_api(record);mod.env=loader:_modEnv(record)
 local nativeGet,nativeDefine=mod.options.get,mod.options.define
 function mod:read(p)
  if p=='audio.lua'or p=='automount.lua'or p=='colours.lua'then return service end
  return T.readDisk(p)
 end
 function mod.content.screens:register(k,v)g.data.screens[k]=v end
 assert(require('src.mods.Sandbox').compile(source,'@main.lua',mod.env))()(mod)
 ck(mod.options.get==nativeGet and mod.options.define==nativeDefine,'native options API replaced')
 if late then
  ck(g.writes==0 and g.save==nil,'entry wrote before save became available')
  g.save=save;g.options=save.options
 end
 local before=cp(save)
 return g,mod,loader,before
end
local function run(edition,initial,music,expectedVolume,expectedMode,expectedAuto,where,late)
 cases=cases+1
 initial=cp(initial)
 if initial.bike_centres_colour==nil then initial.bike_centres_colour='original'end
 local g,m,l,before=boot(edition,initial,music,where=='live',where=='saved',late)
 l.events:emit('game.ready',{game=g})
 local saved=g.save.options.modOptions.bicycle_plus;local live=l.modOptions.bicycle_plus
 ck(saved.bike_volume==expectedVolume and live.bike_volume==expectedVolume,'first volume/preserved value incorrect')
 ck(saved.riding_music==expectedMode and live.riding_music==expectedMode,'default/retained mode incorrect')
 ck(saved.auto_mount==expectedAuto and live.auto_mount==expectedAuto,'default/retained auto flag incorrect')
 ck(saved._audio_layout==5 and live._audio_layout==5,'initialisation marker missing')
 ck(m.exports.getSetting('bike_volume')==tonumber(expectedVolume),'native option fallback masks saved gain')
 ck(m.exports.getSetting('riding_music')==expectedMode and m.exports.getSetting('auto_mount')==expectedAuto,'runtime defaults disagree')
 local want=cp(before)
 -- Keep the saved store untouched except the explicit initialisation keys.
 want.options.modOptions.bicycle_plus.bike_volume=expectedVolume
 want.options.modOptions.bicycle_plus.riding_music=expectedMode
 want.options.modOptions.bicycle_plus.auto_mount=expectedAuto
 want.options.modOptions.bicycle_plus._audio_layout=5
 if not eq(g.save,want) then
  local function diff(a,b,path)
   if eq(a,b)then return end
   if type(a)=='table'and type(b)=='table'then for k,v in pairs(a)do diff(v,b[k],path..'.'..k)end;for k,v in pairs(b)do if a[k]==nil then print(path..'.'..k,'MISSING',v)end end
   else print(path,tostring(a),tostring(b))end
  end
  print('CASE',cases,edition,music,where);diff(g.save,want,'save')
 end
 ck(eq(g.save,want),'initialisation edited unrelated settings/progress')
 local schema=l.optionSchemas.bicycle_plus;local byKey={};for _,row in ipairs(schema)do byKey[row.key]=row end
 ck(byKey.auto_mount.default==true and byKey.riding_music.default=='bicycle','schema defaults incorrect')
 local writes=g.writes
 for i=1,3 do l.events:emit('game.ready',{game=g});m.exports.update(g,.016)end
 ck(g.writes==writes,'initialisation repeats on updates')
 g.save.options.musicVol=6
 m.exports.update(g,.016)
 ck(saved.bike_volume==expectedVolume,'later native Music edit changed bike volume')
 m.exports.openSettings(g);local root=g.stack:top()
 ck(root.rows[1].label=='AUTO BIKE' and root.rows[1].value()==(expectedAuto and'ON'or'OFF'),'root auto row wrong')
 root.rows[4].action(root);local audio=g.stack:top()
 ck(audio.rows[1].label=='ON BIKE' and audio.rows[1].value()==expectedMode:upper(),'selector row wrong')
 local snapshot=cp(saved)
 for i=1,6 do
  audio.rows[1].step(1,audio)
  local mode=saved.riding_music;saved.riding_music=snapshot.riding_music
  ck(eq(saved,snapshot),'changing selector changed volumes/filters')
  saved.riding_music=mode
 end
 ck(saved.riding_music==expectedMode,'three-way selector cycle wrong')
 ck(m.exports.setSetting(g,'bike_volume',0),'bike mute edit failed')
 ck(m.exports.setSetting(g,'auto_mount',false),'manual auto disable failed')
 ck(m.exports.setSetting(g,'riding_music','area'),'manual mode edit failed')
 l.events:emit('game.ready',{game=g})
 ck(saved.bike_volume==0 and saved.auto_mount==false and saved.riding_music=='area','user edits were reset')
 -- A fresh mod instance after update/reinstall must keep persisted 0/false.
 local retained=cp(saved)
 while g.stack:top()do g.stack:pop()end
 local g2,m2,l2=boot(edition,retained,7,false,false,true)
 l2.events:emit('game.ready',{game=g2})
 ck(m2.exports.getSetting('bike_volume')==0 and m2.exports.getSetting('auto_mount')==false and m2.exports.getSetting('riding_music')=='area','reinstall overwrote saved preferences')
end
for _,edition in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 for music=0,7 do
  run(edition,{},music,music,'bicycle',true,nil,true)
  for bike=0,7 do
   for _,mode in ipairs({'area','bicycle','both'})do
    run(edition,{bike_volume=bike,riding_music=mode,auto_mount=false,_audio_layout=4,bike_filter=3,riding_area_volume=2,riding_sfx_volume=-1},music,bike,mode,false,(bike%2==0 and'live'or'saved'),false)
   end
  end
 end
 run(edition,{_audio_layout=2,music_mode='cycling',bike_volume=2},1,2,'bicycle',true)
 run(edition,{_audio_layout=2,music_mode='area',bike_volume=0},7,0,'area',true)
 run(edition,{_audio_layout=3,riding_music='both',bike_volume=0,riding_area_volume=0},4,0,'both',true)
 run(edition,{_audio_layout=4,riding_music='both'},3,3,'both',true)
 run(edition,{},nil,7,'bicycle',true)
 run(edition,{},'2',2,'bicycle',true)
 run(edition,{},2.9,2,'bicycle',true)
 run(edition,{},-1,0,'bicycle',true)
 run(edition,{},50,7,'bicycle',true)
 run(edition,{},math.huge,7,'bicycle',true)
 run(edition,{},0/0,7,'bicycle',true)
 -- Safe mode rejects even initialisation, without materialising defaults.
 local g,m,l,before=boot(edition,{bike_centres_colour='original'},2)
 R.safeMode=true;l.events:emit('game.ready',{game=g});m.exports.update(g,.016)
 ck(g.writes==0 and eq(before,g.save),'safe mode wrote defaults');R.safeMode=false
 l.events:emit('game.ready',{game=g});ck(m.exports.getSetting('bike_volume')==2,'safe-mode deferral lost Music setting')
end
print(('PASS %d first-install/update/reinstall cases; %d assertions using native Loader option API, sandbox and screens. Movement/audio/device boundaries mocked.'):format(cases,n))
